
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
    80000068:	17c78793          	addi	a5,a5,380 # 800061e0 <timervec>
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
    80000122:	6e0080e7          	jalr	1760(ra) # 800027fe <either_copyin>
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
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7f2080e7          	jalr	2034(ra) # 800019a4 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	230080e7          	jalr	560(ra) # 800023f2 <sleep>
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
    80000202:	5a8080e7          	jalr	1448(ra) # 800027a6 <either_copyout>
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
    800002e2:	578080e7          	jalr	1400(ra) # 80002856 <procdump>
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
    80000436:	14e080e7          	jalr	334(ra) # 80002580 <wakeup>
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
    80000882:	d02080e7          	jalr	-766(ra) # 80002580 <wakeup>
    
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
    8000090e:	ae8080e7          	jalr	-1304(ra) # 800023f2 <sleep>
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
    80000b60:	e2c080e7          	jalr	-468(ra) # 80001988 <mycpu>
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
    80000b92:	dfa080e7          	jalr	-518(ra) # 80001988 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dee080e7          	jalr	-530(ra) # 80001988 <mycpu>
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
    80000bb6:	dd6080e7          	jalr	-554(ra) # 80001988 <mycpu>
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
    80000bf6:	d96080e7          	jalr	-618(ra) # 80001988 <mycpu>
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
    80000c34:	d58080e7          	jalr	-680(ra) # 80001988 <mycpu>
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
    80000e9c:	ae0080e7          	jalr	-1312(ra) # 80001978 <cpuid>
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
    80000eb8:	ac4080e7          	jalr	-1340(ra) # 80001978 <cpuid>
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
    80000eda:	cae080e7          	jalr	-850(ra) # 80002b84 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	342080e7          	jalr	834(ra) # 80006220 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	1da080e7          	jalr	474(ra) # 800020c0 <scheduler>
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
    80000f4a:	980080e7          	jalr	-1664(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	c0e080e7          	jalr	-1010(ra) # 80002b5c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	c2e080e7          	jalr	-978(ra) # 80002b84 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	2ac080e7          	jalr	684(ra) # 8000620a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	2ba080e7          	jalr	698(ra) # 80006220 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	45a080e7          	jalr	1114(ra) # 800033c8 <binit>
    iinit();         // inode cache
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	aec080e7          	jalr	-1300(ra) # 80003a62 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	a9a080e7          	jalr	-1382(ra) # 80004a18 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	3bc080e7          	jalr	956(ra) # 80006342 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	d6a080e7          	jalr	-662(ra) # 80001cf8 <userinit>
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
    80001234:	600080e7          	jalr	1536(ra) # 80001830 <proc_mapstacks>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3000>
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

0000000080001830 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001830:	7139                	addi	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	addi	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	e8a48493          	addi	s1,s1,-374 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	addi	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	addi	s2,s2,-1
    8000185e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001860:	0001ca17          	auipc	s4,0x1c
    80001864:	e70a0a13          	addi	s4,s4,-400 # 8001d6d0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	26a080e7          	jalr	618(ra) # 80000ad2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if(pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	85a1                	srai	a1,a1,0x8
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addiw	a1,a1,1
    80001884:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8ae080e7          	jalr	-1874(ra) # 80001140 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189a:	30048493          	addi	s1,s1,768
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	addi	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92a50513          	addi	a0,a0,-1750 # 800081e0 <digits+0x1a0>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c6c080e7          	jalr	-916(ra) # 8000052a <panic>

00000000800018c6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018c6:	7139                	addi	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90e58593          	addi	a1,a1,-1778 # 800081e8 <digits+0x1a8>
    800018e2:	00010517          	auipc	a0,0x10
    800018e6:	9be50513          	addi	a0,a0,-1602 # 800112a0 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	248080e7          	jalr	584(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8fe58593          	addi	a1,a1,-1794 # 800081f0 <digits+0x1b0>
    800018fa:	00010517          	auipc	a0,0x10
    800018fe:	9be50513          	addi	a0,a0,-1602 # 800112b8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	230080e7          	jalr	560(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190a:	00010497          	auipc	s1,0x10
    8000190e:	dc648493          	addi	s1,s1,-570 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8eeb0b13          	addi	s6,s6,-1810 # 80008200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	addi	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	addi	s2,s2,-1
    8000192a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	0001c997          	auipc	s3,0x1c
    80001930:	da498993          	addi	s3,s3,-604 # 8001d6d0 <tickslock>
      initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	1fa080e7          	jalr	506(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001940:	415487b3          	sub	a5,s1,s5
    80001944:	87a1                	srai	a5,a5,0x8
    80001946:	000a3703          	ld	a4,0(s4)
    8000194a:	02e787b3          	mul	a5,a5,a4
    8000194e:	2785                	addiw	a5,a5,1
    80001950:	00d7979b          	slliw	a5,a5,0xd
    80001954:	40f907b3          	sub	a5,s2,a5
    80001958:	1cf4bc23          	sd	a5,472(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	30048493          	addi	s1,s1,768
    80001960:	fd349ae3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001964:	70e2                	ld	ra,56(sp)
    80001966:	7442                	ld	s0,48(sp)
    80001968:	74a2                	ld	s1,40(sp)
    8000196a:	7902                	ld	s2,32(sp)
    8000196c:	69e2                	ld	s3,24(sp)
    8000196e:	6a42                	ld	s4,16(sp)
    80001970:	6aa2                	ld	s5,8(sp)
    80001972:	6b02                	ld	s6,0(sp)
    80001974:	6121                	addi	sp,sp,64
    80001976:	8082                	ret

0000000080001978 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001978:	1141                	addi	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000197e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001980:	2501                	sext.w	a0,a0
    80001982:	6422                	ld	s0,8(sp)
    80001984:	0141                	addi	sp,sp,16
    80001986:	8082                	ret

0000000080001988 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001988:	1141                	addi	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	addi	s0,sp,16
    8000198e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001990:	2781                	sext.w	a5,a5
    80001992:	079e                	slli	a5,a5,0x7
  return c;
}
    80001994:	00010517          	auipc	a0,0x10
    80001998:	93c50513          	addi	a0,a0,-1732 # 800112d0 <cpus>
    8000199c:	953e                	add	a0,a0,a5
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019a4:	1101                	addi	sp,sp,-32
    800019a6:	ec06                	sd	ra,24(sp)
    800019a8:	e822                	sd	s0,16(sp)
    800019aa:	e426                	sd	s1,8(sp)
    800019ac:	1000                	addi	s0,sp,32
  push_off();
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	1c8080e7          	jalr	456(ra) # 80000b76 <push_off>
    800019b6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019b8:	2781                	sext.w	a5,a5
    800019ba:	079e                	slli	a5,a5,0x7
    800019bc:	00010717          	auipc	a4,0x10
    800019c0:	8e470713          	addi	a4,a4,-1820 # 800112a0 <pid_lock>
    800019c4:	97ba                	add	a5,a5,a4
    800019c6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	260080e7          	jalr	608(ra) # 80000c28 <pop_off>
  return p;
}
    800019d0:	8526                	mv	a0,s1
    800019d2:	60e2                	ld	ra,24(sp)
    800019d4:	6442                	ld	s0,16(sp)
    800019d6:	64a2                	ld	s1,8(sp)
    800019d8:	6105                	addi	sp,sp,32
    800019da:	8082                	ret

00000000800019dc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019dc:	1141                	addi	sp,sp,-16
    800019de:	e406                	sd	ra,8(sp)
    800019e0:	e022                	sd	s0,0(sp)
    800019e2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	fc0080e7          	jalr	-64(ra) # 800019a4 <myproc>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	29c080e7          	jalr	668(ra) # 80000c88 <release>

  if (first) {
    800019f4:	00007797          	auipc	a5,0x7
    800019f8:	e5c7a783          	lw	a5,-420(a5) # 80008850 <first.1>
    800019fc:	eb89                	bnez	a5,80001a0e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019fe:	00001097          	auipc	ra,0x1
    80001a02:	19e080e7          	jalr	414(ra) # 80002b9c <usertrapret>
}
    80001a06:	60a2                	ld	ra,8(sp)
    80001a08:	6402                	ld	s0,0(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret
    first = 0;
    80001a0e:	00007797          	auipc	a5,0x7
    80001a12:	e407a123          	sw	zero,-446(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a16:	4505                	li	a0,1
    80001a18:	00002097          	auipc	ra,0x2
    80001a1c:	fca080e7          	jalr	-54(ra) # 800039e2 <fsinit>
    80001a20:	bff9                	j	800019fe <forkret+0x22>

0000000080001a22 <allocpid>:
allocpid() {
    80001a22:	1101                	addi	sp,sp,-32
    80001a24:	ec06                	sd	ra,24(sp)
    80001a26:	e822                	sd	s0,16(sp)
    80001a28:	e426                	sd	s1,8(sp)
    80001a2a:	e04a                	sd	s2,0(sp)
    80001a2c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a2e:	00010917          	auipc	s2,0x10
    80001a32:	87290913          	addi	s2,s2,-1934 # 800112a0 <pid_lock>
    80001a36:	854a                	mv	a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	18a080e7          	jalr	394(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a40:	00007797          	auipc	a5,0x7
    80001a44:	e1478793          	addi	a5,a5,-492 # 80008854 <nextpid>
    80001a48:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4a:	0014871b          	addiw	a4,s1,1
    80001a4e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a50:	854a                	mv	a0,s2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	236080e7          	jalr	566(ra) # 80000c88 <release>
}
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	60e2                	ld	ra,24(sp)
    80001a5e:	6442                	ld	s0,16(sp)
    80001a60:	64a2                	ld	s1,8(sp)
    80001a62:	6902                	ld	s2,0(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <proc_pagetable>:
{
    80001a68:	1101                	addi	sp,sp,-32
    80001a6a:	ec06                	sd	ra,24(sp)
    80001a6c:	e822                	sd	s0,16(sp)
    80001a6e:	e426                	sd	s1,8(sp)
    80001a70:	e04a                	sd	s2,0(sp)
    80001a72:	1000                	addi	s0,sp,32
    80001a74:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a76:	00000097          	auipc	ra,0x0
    80001a7a:	8b4080e7          	jalr	-1868(ra) # 8000132a <uvmcreate>
    80001a7e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a80:	c121                	beqz	a0,80001ac0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a82:	4729                	li	a4,10
    80001a84:	00005697          	auipc	a3,0x5
    80001a88:	57c68693          	addi	a3,a3,1404 # 80007000 <_trampoline>
    80001a8c:	6605                	lui	a2,0x1
    80001a8e:	040005b7          	lui	a1,0x4000
    80001a92:	15fd                	addi	a1,a1,-1
    80001a94:	05b2                	slli	a1,a1,0xc
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	61c080e7          	jalr	1564(ra) # 800010b2 <mappages>
    80001a9e:	02054863          	bltz	a0,80001ace <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa2:	4719                	li	a4,6
    80001aa4:	1f093683          	ld	a3,496(s2)
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	020005b7          	lui	a1,0x2000
    80001aae:	15fd                	addi	a1,a1,-1
    80001ab0:	05b6                	slli	a1,a1,0xd
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	5fe080e7          	jalr	1534(ra) # 800010b2 <mappages>
    80001abc:	02054163          	bltz	a0,80001ade <proc_pagetable+0x76>
}
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	60e2                	ld	ra,24(sp)
    80001ac4:	6442                	ld	s0,16(sp)
    80001ac6:	64a2                	ld	s1,8(sp)
    80001ac8:	6902                	ld	s2,0(sp)
    80001aca:	6105                	addi	sp,sp,32
    80001acc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a54080e7          	jalr	-1452(ra) # 80001526 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	b7d5                	j	80001ac0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ade:	4681                	li	a3,0
    80001ae0:	4605                	li	a2,1
    80001ae2:	040005b7          	lui	a1,0x4000
    80001ae6:	15fd                	addi	a1,a1,-1
    80001ae8:	05b2                	slli	a1,a1,0xc
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	77a080e7          	jalr	1914(ra) # 80001266 <uvmunmap>
    uvmfree(pagetable, 0);
    80001af4:	4581                	li	a1,0
    80001af6:	8526                	mv	a0,s1
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	a2e080e7          	jalr	-1490(ra) # 80001526 <uvmfree>
    return 0;
    80001b00:	4481                	li	s1,0
    80001b02:	bf7d                	j	80001ac0 <proc_pagetable+0x58>

0000000080001b04 <proc_freepagetable>:
{
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	addi	s0,sp,32
    80001b10:	84aa                	mv	s1,a0
    80001b12:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b14:	4681                	li	a3,0
    80001b16:	4605                	li	a2,1
    80001b18:	040005b7          	lui	a1,0x4000
    80001b1c:	15fd                	addi	a1,a1,-1
    80001b1e:	05b2                	slli	a1,a1,0xc
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	746080e7          	jalr	1862(ra) # 80001266 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	020005b7          	lui	a1,0x2000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b6                	slli	a1,a1,0xd
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	730080e7          	jalr	1840(ra) # 80001266 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b3e:	85ca                	mv	a1,s2
    80001b40:	8526                	mv	a0,s1
    80001b42:	00000097          	auipc	ra,0x0
    80001b46:	9e4080e7          	jalr	-1564(ra) # 80001526 <uvmfree>
}
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <freeproc>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	1000                	addi	s0,sp,32
    80001b60:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b62:	1f053503          	ld	a0,496(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e6e080e7          	jalr	-402(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b70:	1e04b823          	sd	zero,496(s1)
  if(p->trapframe_backup)
    80001b74:	1c04b503          	ld	a0,448(s1)
    80001b78:	c509                	beqz	a0,80001b82 <freeproc+0x2c>
    kfree((void*)p->trapframe_backup);
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	e5c080e7          	jalr	-420(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001b82:	1c04b023          	sd	zero,448(s1)
  if(p->pagetable)
    80001b86:	1e84b503          	ld	a0,488(s1)
    80001b8a:	c519                	beqz	a0,80001b98 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8c:	1e04b583          	ld	a1,480(s1)
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	f74080e7          	jalr	-140(ra) # 80001b04 <proc_freepagetable>
  p->pagetable = 0;
    80001b98:	1e04b423          	sd	zero,488(s1)
  p->sz = 0;
    80001b9c:	1e04b023          	sd	zero,480(s1)
  p->pid = 0;
    80001ba0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba4:	1c04b823          	sd	zero,464(s1)
  p->name[0] = 0;
    80001ba8:	2e048823          	sb	zero,752(s1)
  p->chan = 0;
    80001bac:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb0:	0204a423          	sw	zero,40(s1)
  p->stopped = 0;
    80001bb4:	1c04a423          	sw	zero,456(s1)
  p->xstate = 0;
    80001bb8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bbc:	0004ac23          	sw	zero,24(s1)
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <allocproc>:
{
    80001bca:	7179                	addi	sp,sp,-48
    80001bcc:	f406                	sd	ra,40(sp)
    80001bce:	f022                	sd	s0,32(sp)
    80001bd0:	ec26                	sd	s1,24(sp)
    80001bd2:	e84a                	sd	s2,16(sp)
    80001bd4:	e44e                	sd	s3,8(sp)
    80001bd6:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd8:	00010497          	auipc	s1,0x10
    80001bdc:	af848493          	addi	s1,s1,-1288 # 800116d0 <proc>
    80001be0:	0001c997          	auipc	s3,0x1c
    80001be4:	af098993          	addi	s3,s3,-1296 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	fd8080e7          	jalr	-40(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bf2:	4c9c                	lw	a5,24(s1)
    80001bf4:	cf81                	beqz	a5,80001c0c <allocproc+0x42>
      release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	090080e7          	jalr	144(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c00:	30048493          	addi	s1,s1,768
    80001c04:	ff3492e3          	bne	s1,s3,80001be8 <allocproc+0x1e>
  return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	a059                	j	80001c90 <allocproc+0xc6>
  p->pid = allocpid();
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e16080e7          	jalr	-490(ra) # 80001a22 <allocpid>
    80001c14:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c16:	4785                	li	a5,1
    80001c18:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001c1a:	0204aa23          	sw	zero,52(s1)
  p->signal_mask = 0;
    80001c1e:	0204ac23          	sw	zero,56(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001c22:	04048793          	addi	a5,s1,64
    80001c26:	14048713          	addi	a4,s1,320
    p->signal_handlers[signum] = SIG_DFL;
    80001c2a:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001c2e:	07a1                	addi	a5,a5,8
    80001c30:	fee79de3          	bne	a5,a4,80001c2a <allocproc+0x60>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	e9e080e7          	jalr	-354(ra) # 80000ad2 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	1ea4b823          	sd	a0,496(s1)
    80001c42:	cd39                	beqz	a0,80001ca0 <allocproc+0xd6>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	e8e080e7          	jalr	-370(ra) # 80000ad2 <kalloc>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	1ca4b023          	sd	a0,448(s1)
    80001c52:	c13d                	beqz	a0,80001cb8 <allocproc+0xee>
  p->pagetable = proc_pagetable(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	e12080e7          	jalr	-494(ra) # 80001a68 <proc_pagetable>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	1ea4b423          	sd	a0,488(s1)
  if(p->pagetable == 0){
    80001c64:	cd35                	beqz	a0,80001ce0 <allocproc+0x116>
  memset(&p->context, 0, sizeof(p->context));
    80001c66:	07000613          	li	a2,112
    80001c6a:	4581                	li	a1,0
    80001c6c:	1f848513          	addi	a0,s1,504
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	072080e7          	jalr	114(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001c78:	00000797          	auipc	a5,0x0
    80001c7c:	d6478793          	addi	a5,a5,-668 # 800019dc <forkret>
    80001c80:	1ef4bc23          	sd	a5,504(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c84:	1d84b783          	ld	a5,472(s1)
    80001c88:	6705                	lui	a4,0x1
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	20f4b023          	sd	a5,512(s1)
}
    80001c90:	8526                	mv	a0,s1
    80001c92:	70a2                	ld	ra,40(sp)
    80001c94:	7402                	ld	s0,32(sp)
    80001c96:	64e2                	ld	s1,24(sp)
    80001c98:	6942                	ld	s2,16(sp)
    80001c9a:	69a2                	ld	s3,8(sp)
    80001c9c:	6145                	addi	sp,sp,48
    80001c9e:	8082                	ret
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	eb4080e7          	jalr	-332(ra) # 80001b56 <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fdc080e7          	jalr	-36(ra) # 80000c88 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	bfe9                	j	80001c90 <allocproc+0xc6>
    printf("FAILED ALLOC TRAPFRAME BACKUP\n");//TODO REMOVE
    80001cb8:	00006517          	auipc	a0,0x6
    80001cbc:	55050513          	addi	a0,a0,1360 # 80008208 <digits+0x1c8>
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	8b4080e7          	jalr	-1868(ra) # 80000574 <printf>
    freeproc(p);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	e8c080e7          	jalr	-372(ra) # 80001b56 <freeproc>
    release(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fb4080e7          	jalr	-76(ra) # 80000c88 <release>
    return 0;
    80001cdc:	84ca                	mv	s1,s2
    80001cde:	bf4d                	j	80001c90 <allocproc+0xc6>
    freeproc(p);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	e74080e7          	jalr	-396(ra) # 80001b56 <freeproc>
    release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	f9c080e7          	jalr	-100(ra) # 80000c88 <release>
    return 0;
    80001cf4:	84ca                	mv	s1,s2
    80001cf6:	bf69                	j	80001c90 <allocproc+0xc6>

0000000080001cf8 <userinit>:
{
    80001cf8:	1101                	addi	sp,sp,-32
    80001cfa:	ec06                	sd	ra,24(sp)
    80001cfc:	e822                	sd	s0,16(sp)
    80001cfe:	e426                	sd	s1,8(sp)
    80001d00:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d02:	00000097          	auipc	ra,0x0
    80001d06:	ec8080e7          	jalr	-312(ra) # 80001bca <allocproc>
    80001d0a:	84aa                	mv	s1,a0
  initproc = p;
    80001d0c:	00007797          	auipc	a5,0x7
    80001d10:	30a7be23          	sd	a0,796(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d14:	03400613          	li	a2,52
    80001d18:	00007597          	auipc	a1,0x7
    80001d1c:	b4858593          	addi	a1,a1,-1208 # 80008860 <initcode>
    80001d20:	1e853503          	ld	a0,488(a0)
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	634080e7          	jalr	1588(ra) # 80001358 <uvminit>
  p->sz = PGSIZE;
    80001d2c:	6785                	lui	a5,0x1
    80001d2e:	1ef4b023          	sd	a5,480(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d32:	1f04b703          	ld	a4,496(s1)
    80001d36:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d3a:	1f04b703          	ld	a4,496(s1)
    80001d3e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d40:	4641                	li	a2,16
    80001d42:	00006597          	auipc	a1,0x6
    80001d46:	4e658593          	addi	a1,a1,1254 # 80008228 <digits+0x1e8>
    80001d4a:	2f048513          	addi	a0,s1,752
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	0e6080e7          	jalr	230(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d56:	00006517          	auipc	a0,0x6
    80001d5a:	4e250513          	addi	a0,a0,1250 # 80008238 <digits+0x1f8>
    80001d5e:	00002097          	auipc	ra,0x2
    80001d62:	6b2080e7          	jalr	1714(ra) # 80004410 <namei>
    80001d66:	2ea4b423          	sd	a0,744(s1)
  p->state = RUNNABLE;
    80001d6a:	478d                	li	a5,3
    80001d6c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d6e:	8526                	mv	a0,s1
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	f18080e7          	jalr	-232(ra) # 80000c88 <release>
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret

0000000080001d82 <growproc>:
{
    80001d82:	1101                	addi	sp,sp,-32
    80001d84:	ec06                	sd	ra,24(sp)
    80001d86:	e822                	sd	s0,16(sp)
    80001d88:	e426                	sd	s1,8(sp)
    80001d8a:	e04a                	sd	s2,0(sp)
    80001d8c:	1000                	addi	s0,sp,32
    80001d8e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	c14080e7          	jalr	-1004(ra) # 800019a4 <myproc>
    80001d98:	892a                	mv	s2,a0
  sz = p->sz;
    80001d9a:	1e053583          	ld	a1,480(a0)
    80001d9e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001da2:	00904f63          	bgtz	s1,80001dc0 <growproc+0x3e>
  } else if(n < 0){
    80001da6:	0204cd63          	bltz	s1,80001de0 <growproc+0x5e>
  p->sz = sz;
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	1ec93023          	sd	a2,480(s2)
  return 0;
    80001db2:	4501                	li	a0,0
}
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6902                	ld	s2,0(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc0:	9e25                	addw	a2,a2,s1
    80001dc2:	1602                	slli	a2,a2,0x20
    80001dc4:	9201                	srli	a2,a2,0x20
    80001dc6:	1582                	slli	a1,a1,0x20
    80001dc8:	9181                	srli	a1,a1,0x20
    80001dca:	1e853503          	ld	a0,488(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	644080e7          	jalr	1604(ra) # 80001412 <uvmalloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	fa61                	bnez	a2,80001daa <growproc+0x28>
      return -1;
    80001ddc:	557d                	li	a0,-1
    80001dde:	bfd9                	j	80001db4 <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de0:	9e25                	addw	a2,a2,s1
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	1582                	slli	a1,a1,0x20
    80001de8:	9181                	srli	a1,a1,0x20
    80001dea:	1e853503          	ld	a0,488(a0)
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	5dc080e7          	jalr	1500(ra) # 800013ca <uvmdealloc>
    80001df6:	0005061b          	sext.w	a2,a0
    80001dfa:	bf45                	j	80001daa <growproc+0x28>

0000000080001dfc <fork>:
{
    80001dfc:	7139                	addi	sp,sp,-64
    80001dfe:	fc06                	sd	ra,56(sp)
    80001e00:	f822                	sd	s0,48(sp)
    80001e02:	f426                	sd	s1,40(sp)
    80001e04:	f04a                	sd	s2,32(sp)
    80001e06:	ec4e                	sd	s3,24(sp)
    80001e08:	e852                	sd	s4,16(sp)
    80001e0a:	e456                	sd	s5,8(sp)
    80001e0c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	b96080e7          	jalr	-1130(ra) # 800019a4 <myproc>
    80001e16:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	db2080e7          	jalr	-590(ra) # 80001bca <allocproc>
    80001e20:	12050f63          	beqz	a0,80001f5e <fork+0x162>
    80001e24:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e26:	1e093603          	ld	a2,480(s2)
    80001e2a:	1e853583          	ld	a1,488(a0)
    80001e2e:	1e893503          	ld	a0,488(s2)
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	72c080e7          	jalr	1836(ra) # 8000155e <uvmcopy>
    80001e3a:	04054863          	bltz	a0,80001e8a <fork+0x8e>
  np->sz = p->sz;
    80001e3e:	1e093783          	ld	a5,480(s2)
    80001e42:	1efa3023          	sd	a5,480(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e46:	1f093683          	ld	a3,496(s2)
    80001e4a:	87b6                	mv	a5,a3
    80001e4c:	1f0a3703          	ld	a4,496(s4)
    80001e50:	12068693          	addi	a3,a3,288
    80001e54:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e58:	6788                	ld	a0,8(a5)
    80001e5a:	6b8c                	ld	a1,16(a5)
    80001e5c:	6f90                	ld	a2,24(a5)
    80001e5e:	01073023          	sd	a6,0(a4)
    80001e62:	e708                	sd	a0,8(a4)
    80001e64:	eb0c                	sd	a1,16(a4)
    80001e66:	ef10                	sd	a2,24(a4)
    80001e68:	02078793          	addi	a5,a5,32
    80001e6c:	02070713          	addi	a4,a4,32
    80001e70:	fed792e3          	bne	a5,a3,80001e54 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e74:	1f0a3783          	ld	a5,496(s4)
    80001e78:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e7c:	26890493          	addi	s1,s2,616
    80001e80:	268a0993          	addi	s3,s4,616
    80001e84:	2e890a93          	addi	s5,s2,744
    80001e88:	a00d                	j	80001eaa <fork+0xae>
    freeproc(np);
    80001e8a:	8552                	mv	a0,s4
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	cca080e7          	jalr	-822(ra) # 80001b56 <freeproc>
    release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df2080e7          	jalr	-526(ra) # 80000c88 <release>
    return -1;
    80001e9e:	59fd                	li	s3,-1
    80001ea0:	a06d                	j	80001f4a <fork+0x14e>
  for(i = 0; i < NOFILE; i++)
    80001ea2:	04a1                	addi	s1,s1,8
    80001ea4:	09a1                	addi	s3,s3,8
    80001ea6:	01548b63          	beq	s1,s5,80001ebc <fork+0xc0>
    if(p->ofile[i])
    80001eaa:	6088                	ld	a0,0(s1)
    80001eac:	d97d                	beqz	a0,80001ea2 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eae:	00003097          	auipc	ra,0x3
    80001eb2:	bfc080e7          	jalr	-1028(ra) # 80004aaa <filedup>
    80001eb6:	00a9b023          	sd	a0,0(s3)
    80001eba:	b7e5                	j	80001ea2 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001ebc:	2e893503          	ld	a0,744(s2)
    80001ec0:	00002097          	auipc	ra,0x2
    80001ec4:	d5c080e7          	jalr	-676(ra) # 80003c1c <idup>
    80001ec8:	2eaa3423          	sd	a0,744(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ecc:	4641                	li	a2,16
    80001ece:	2f090593          	addi	a1,s2,752
    80001ed2:	2f0a0513          	addi	a0,s4,752
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	f5e080e7          	jalr	-162(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001ede:	030a2983          	lw	s3,48(s4)
  release(&np->lock);
    80001ee2:	8552                	mv	a0,s4
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da4080e7          	jalr	-604(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	3cc48493          	addi	s1,s1,972 # 800112b8 <wait_lock>
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	ccc080e7          	jalr	-820(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001efe:	1d2a3823          	sd	s2,464(s4)
  release(&wait_lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d84080e7          	jalr	-636(ra) # 80000c88 <release>
  acquire(&np->lock);
    80001f0c:	8552                	mv	a0,s4
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	cb4080e7          	jalr	-844(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001f16:	478d                	li	a5,3
    80001f18:	00fa2c23          	sw	a5,24(s4)
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80001f1c:	03892783          	lw	a5,56(s2)
    80001f20:	02fa2c23          	sw	a5,56(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001f24:	04090793          	addi	a5,s2,64
    80001f28:	040a0713          	addi	a4,s4,64
    80001f2c:	14090613          	addi	a2,s2,320
    np->signal_handlers[i] = p->signal_handlers[i];    
    80001f30:	6394                	ld	a3,0(a5)
    80001f32:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001f34:	07a1                	addi	a5,a5,8
    80001f36:	0721                	addi	a4,a4,8
    80001f38:	fec79ce3          	bne	a5,a2,80001f30 <fork+0x134>
  np->pending_signals = 0; // ADDED Q2.1.2
    80001f3c:	020a2a23          	sw	zero,52(s4)
  release(&np->lock);
    80001f40:	8552                	mv	a0,s4
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d46080e7          	jalr	-698(ra) # 80000c88 <release>
}
    80001f4a:	854e                	mv	a0,s3
    80001f4c:	70e2                	ld	ra,56(sp)
    80001f4e:	7442                	ld	s0,48(sp)
    80001f50:	74a2                	ld	s1,40(sp)
    80001f52:	7902                	ld	s2,32(sp)
    80001f54:	69e2                	ld	s3,24(sp)
    80001f56:	6a42                	ld	s4,16(sp)
    80001f58:	6aa2                	ld	s5,8(sp)
    80001f5a:	6121                	addi	sp,sp,64
    80001f5c:	8082                	ret
    return -1;
    80001f5e:	59fd                	li	s3,-1
    80001f60:	b7ed                	j	80001f4a <fork+0x14e>

0000000080001f62 <kill_handler>:
{
    80001f62:	1141                	addi	sp,sp,-16
    80001f64:	e406                	sd	ra,8(sp)
    80001f66:	e022                	sd	s0,0(sp)
    80001f68:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001f6a:	00000097          	auipc	ra,0x0
    80001f6e:	a3a080e7          	jalr	-1478(ra) # 800019a4 <myproc>
  p->killed = 1; 
    80001f72:	4785                	li	a5,1
    80001f74:	d51c                	sw	a5,40(a0)
  if (p->state == SLEEPING) {
    80001f76:	4d18                	lw	a4,24(a0)
    80001f78:	4789                	li	a5,2
    80001f7a:	00f70663          	beq	a4,a5,80001f86 <kill_handler+0x24>
}
    80001f7e:	60a2                	ld	ra,8(sp)
    80001f80:	6402                	ld	s0,0(sp)
    80001f82:	0141                	addi	sp,sp,16
    80001f84:	8082                	ret
    p->state = RUNNABLE;
    80001f86:	478d                	li	a5,3
    80001f88:	cd1c                	sw	a5,24(a0)
}
    80001f8a:	bfd5                	j	80001f7e <kill_handler+0x1c>

0000000080001f8c <received_continue>:
{
    80001f8c:	1101                	addi	sp,sp,-32
    80001f8e:	ec06                	sd	ra,24(sp)
    80001f90:	e822                	sd	s0,16(sp)
    80001f92:	e426                	sd	s1,8(sp)
    80001f94:	e04a                	sd	s2,0(sp)
    80001f96:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	a0c080e7          	jalr	-1524(ra) # 800019a4 <myproc>
    80001fa0:	892a                	mv	s2,a0
    acquire(&p->lock);
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	c20080e7          	jalr	-992(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80001faa:	03892683          	lw	a3,56(s2)
    80001fae:	fff6c693          	not	a3,a3
    80001fb2:	03492783          	lw	a5,52(s2)
    80001fb6:	8efd                	and	a3,a3,a5
    80001fb8:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fba:	04090713          	addi	a4,s2,64
    80001fbe:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001fc0:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fc2:	02000613          	li	a2,32
    80001fc6:	a801                	j	80001fd6 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001fc8:	630c                	ld	a1,0(a4)
    80001fca:	00a58f63          	beq	a1,a0,80001fe8 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fce:	2785                	addiw	a5,a5,1
    80001fd0:	0721                	addi	a4,a4,8
    80001fd2:	02c78163          	beq	a5,a2,80001ff4 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80001fd6:	40f6d4bb          	sraw	s1,a3,a5
    80001fda:	8885                	andi	s1,s1,1
    80001fdc:	d8ed                	beqz	s1,80001fce <received_continue+0x42>
    80001fde:	0d893583          	ld	a1,216(s2)
    80001fe2:	f1fd                	bnez	a1,80001fc8 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001fe4:	fea792e3          	bne	a5,a0,80001fc8 <received_continue+0x3c>
            release(&p->lock);
    80001fe8:	854a                	mv	a0,s2
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	c9e080e7          	jalr	-866(ra) # 80000c88 <release>
            return 1;
    80001ff2:	a039                	j	80002000 <received_continue+0x74>
    release(&p->lock);
    80001ff4:	854a                	mv	a0,s2
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c92080e7          	jalr	-878(ra) # 80000c88 <release>
    return 0;
    80001ffe:	4481                	li	s1,0
}
    80002000:	8526                	mv	a0,s1
    80002002:	60e2                	ld	ra,24(sp)
    80002004:	6442                	ld	s0,16(sp)
    80002006:	64a2                	ld	s1,8(sp)
    80002008:	6902                	ld	s2,0(sp)
    8000200a:	6105                	addi	sp,sp,32
    8000200c:	8082                	ret

000000008000200e <continue_handler>:
{
    8000200e:	1141                	addi	sp,sp,-16
    80002010:	e406                	sd	ra,8(sp)
    80002012:	e022                	sd	s0,0(sp)
    80002014:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	98e080e7          	jalr	-1650(ra) # 800019a4 <myproc>
  p->stopped = 0;
    8000201e:	1c052423          	sw	zero,456(a0)
}
    80002022:	60a2                	ld	ra,8(sp)
    80002024:	6402                	ld	s0,0(sp)
    80002026:	0141                	addi	sp,sp,16
    80002028:	8082                	ret

000000008000202a <handle_user_signals>:
handle_user_signals(int signum) {
    8000202a:	1101                	addi	sp,sp,-32
    8000202c:	ec06                	sd	ra,24(sp)
    8000202e:	e822                	sd	s0,16(sp)
    80002030:	e426                	sd	s1,8(sp)
    80002032:	e04a                	sd	s2,0(sp)
    80002034:	1000                	addi	s0,sp,32
    80002036:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	96c080e7          	jalr	-1684(ra) # 800019a4 <myproc>
    80002040:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    80002042:	5d1c                	lw	a5,56(a0)
    80002044:	dd5c                	sw	a5,60(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    80002046:	05090793          	addi	a5,s2,80
    8000204a:	078a                	slli	a5,a5,0x2
    8000204c:	97aa                	add	a5,a5,a0
    8000204e:	439c                	lw	a5,0(a5)
    80002050:	dd1c                	sw	a5,56(a0)
  memmove(p->trapframe_backup, p->trapframe, sizeof(struct trapframe));
    80002052:	12000613          	li	a2,288
    80002056:	1f053583          	ld	a1,496(a0)
    8000205a:	1c053503          	ld	a0,448(a0)
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	ce0080e7          	jalr	-800(ra) # 80000d3e <memmove>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80002066:	1f04b703          	ld	a4,496(s1)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    8000206a:	00005617          	auipc	a2,0x5
    8000206e:	0a860613          	addi	a2,a2,168 # 80007112 <start_inject_sigret>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80002072:	00005697          	auipc	a3,0x5
    80002076:	0a668693          	addi	a3,a3,166 # 80007118 <end_inject_sigret>
    8000207a:	9e91                	subw	a3,a3,a2
    8000207c:	7b1c                	ld	a5,48(a4)
    8000207e:	8f95                	sub	a5,a5,a3
    80002080:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (p->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    80002082:	1f04b783          	ld	a5,496(s1)
    80002086:	7b8c                	ld	a1,48(a5)
    80002088:	1e84b503          	ld	a0,488(s1)
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	5d6080e7          	jalr	1494(ra) # 80001662 <copyout>
  p->trapframe->a0 = signum;
    80002094:	1f04b783          	ld	a5,496(s1)
    80002098:	0727b823          	sd	s2,112(a5)
  p->trapframe->epc = (uint64)p->signal_handlers[signum];
    8000209c:	1f04b783          	ld	a5,496(s1)
    800020a0:	0921                	addi	s2,s2,8
    800020a2:	090e                	slli	s2,s2,0x3
    800020a4:	9926                	add	s2,s2,s1
    800020a6:	00093703          	ld	a4,0(s2)
    800020aa:	ef98                	sd	a4,24(a5)
  p->trapframe->ra = p->trapframe->sp;
    800020ac:	1f04b783          	ld	a5,496(s1)
    800020b0:	7b98                	ld	a4,48(a5)
    800020b2:	f798                	sd	a4,40(a5)
}
    800020b4:	60e2                	ld	ra,24(sp)
    800020b6:	6442                	ld	s0,16(sp)
    800020b8:	64a2                	ld	s1,8(sp)
    800020ba:	6902                	ld	s2,0(sp)
    800020bc:	6105                	addi	sp,sp,32
    800020be:	8082                	ret

00000000800020c0 <scheduler>:
{
    800020c0:	7139                	addi	sp,sp,-64
    800020c2:	fc06                	sd	ra,56(sp)
    800020c4:	f822                	sd	s0,48(sp)
    800020c6:	f426                	sd	s1,40(sp)
    800020c8:	f04a                	sd	s2,32(sp)
    800020ca:	ec4e                	sd	s3,24(sp)
    800020cc:	e852                	sd	s4,16(sp)
    800020ce:	e456                	sd	s5,8(sp)
    800020d0:	e05a                	sd	s6,0(sp)
    800020d2:	0080                	addi	s0,sp,64
    800020d4:	8792                	mv	a5,tp
  int id = r_tp();
    800020d6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020d8:	00779a93          	slli	s5,a5,0x7
    800020dc:	0000f717          	auipc	a4,0xf
    800020e0:	1c470713          	addi	a4,a4,452 # 800112a0 <pid_lock>
    800020e4:	9756                	add	a4,a4,s5
    800020e6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020ea:	0000f717          	auipc	a4,0xf
    800020ee:	1ee70713          	addi	a4,a4,494 # 800112d8 <cpus+0x8>
    800020f2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020f4:	498d                	li	s3,3
        p->state = RUNNING;
    800020f6:	4b11                	li	s6,4
        c->proc = p;
    800020f8:	079e                	slli	a5,a5,0x7
    800020fa:	0000fa17          	auipc	s4,0xf
    800020fe:	1a6a0a13          	addi	s4,s4,422 # 800112a0 <pid_lock>
    80002102:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002104:	0001b917          	auipc	s2,0x1b
    80002108:	5cc90913          	addi	s2,s2,1484 # 8001d6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002110:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002114:	10079073          	csrw	sstatus,a5
    80002118:	0000f497          	auipc	s1,0xf
    8000211c:	5b848493          	addi	s1,s1,1464 # 800116d0 <proc>
    80002120:	a811                	j	80002134 <scheduler+0x74>
      release(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	b64080e7          	jalr	-1180(ra) # 80000c88 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000212c:	30048493          	addi	s1,s1,768
    80002130:	fd248ee3          	beq	s1,s2,8000210c <scheduler+0x4c>
      acquire(&p->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	a8c080e7          	jalr	-1396(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    8000213e:	4c9c                	lw	a5,24(s1)
    80002140:	ff3791e3          	bne	a5,s3,80002122 <scheduler+0x62>
        p->state = RUNNING;
    80002144:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002148:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000214c:	1f848593          	addi	a1,s1,504
    80002150:	8556                	mv	a0,s5
    80002152:	00001097          	auipc	ra,0x1
    80002156:	9a0080e7          	jalr	-1632(ra) # 80002af2 <swtch>
        c->proc = 0;
    8000215a:	020a3823          	sd	zero,48(s4)
    8000215e:	b7d1                	j	80002122 <scheduler+0x62>

0000000080002160 <sched>:
{
    80002160:	7179                	addi	sp,sp,-48
    80002162:	f406                	sd	ra,40(sp)
    80002164:	f022                	sd	s0,32(sp)
    80002166:	ec26                	sd	s1,24(sp)
    80002168:	e84a                	sd	s2,16(sp)
    8000216a:	e44e                	sd	s3,8(sp)
    8000216c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	836080e7          	jalr	-1994(ra) # 800019a4 <myproc>
    80002176:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	9d0080e7          	jalr	-1584(ra) # 80000b48 <holding>
    80002180:	c93d                	beqz	a0,800021f6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002182:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002184:	2781                	sext.w	a5,a5
    80002186:	079e                	slli	a5,a5,0x7
    80002188:	0000f717          	auipc	a4,0xf
    8000218c:	11870713          	addi	a4,a4,280 # 800112a0 <pid_lock>
    80002190:	97ba                	add	a5,a5,a4
    80002192:	0a87a703          	lw	a4,168(a5)
    80002196:	4785                	li	a5,1
    80002198:	06f71763          	bne	a4,a5,80002206 <sched+0xa6>
  if(p->state == RUNNING)
    8000219c:	4c98                	lw	a4,24(s1)
    8000219e:	4791                	li	a5,4
    800021a0:	06f70b63          	beq	a4,a5,80002216 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021a8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021aa:	efb5                	bnez	a5,80002226 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ae:	0000f917          	auipc	s2,0xf
    800021b2:	0f290913          	addi	s2,s2,242 # 800112a0 <pid_lock>
    800021b6:	2781                	sext.w	a5,a5
    800021b8:	079e                	slli	a5,a5,0x7
    800021ba:	97ca                	add	a5,a5,s2
    800021bc:	0ac7a983          	lw	s3,172(a5)
    800021c0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
    800021c6:	0000f597          	auipc	a1,0xf
    800021ca:	11258593          	addi	a1,a1,274 # 800112d8 <cpus+0x8>
    800021ce:	95be                	add	a1,a1,a5
    800021d0:	1f848513          	addi	a0,s1,504
    800021d4:	00001097          	auipc	ra,0x1
    800021d8:	91e080e7          	jalr	-1762(ra) # 80002af2 <swtch>
    800021dc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021de:	2781                	sext.w	a5,a5
    800021e0:	079e                	slli	a5,a5,0x7
    800021e2:	97ca                	add	a5,a5,s2
    800021e4:	0b37a623          	sw	s3,172(a5)
}
    800021e8:	70a2                	ld	ra,40(sp)
    800021ea:	7402                	ld	s0,32(sp)
    800021ec:	64e2                	ld	s1,24(sp)
    800021ee:	6942                	ld	s2,16(sp)
    800021f0:	69a2                	ld	s3,8(sp)
    800021f2:	6145                	addi	sp,sp,48
    800021f4:	8082                	ret
    panic("sched p->lock");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	04a50513          	addi	a0,a0,74 # 80008240 <digits+0x200>
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	32c080e7          	jalr	812(ra) # 8000052a <panic>
    panic("sched locks");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	04a50513          	addi	a0,a0,74 # 80008250 <digits+0x210>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	31c080e7          	jalr	796(ra) # 8000052a <panic>
    panic("sched running");
    80002216:	00006517          	auipc	a0,0x6
    8000221a:	04a50513          	addi	a0,a0,74 # 80008260 <digits+0x220>
    8000221e:	ffffe097          	auipc	ra,0xffffe
    80002222:	30c080e7          	jalr	780(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	04a50513          	addi	a0,a0,74 # 80008270 <digits+0x230>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	2fc080e7          	jalr	764(ra) # 8000052a <panic>

0000000080002236 <yield>:
{
    80002236:	1101                	addi	sp,sp,-32
    80002238:	ec06                	sd	ra,24(sp)
    8000223a:	e822                	sd	s0,16(sp)
    8000223c:	e426                	sd	s1,8(sp)
    8000223e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	764080e7          	jalr	1892(ra) # 800019a4 <myproc>
    80002248:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	978080e7          	jalr	-1672(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002252:	478d                	li	a5,3
    80002254:	cc9c                	sw	a5,24(s1)
  sched();
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	f0a080e7          	jalr	-246(ra) # 80002160 <sched>
  release(&p->lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a28080e7          	jalr	-1496(ra) # 80000c88 <release>
}
    80002268:	60e2                	ld	ra,24(sp)
    8000226a:	6442                	ld	s0,16(sp)
    8000226c:	64a2                	ld	s1,8(sp)
    8000226e:	6105                	addi	sp,sp,32
    80002270:	8082                	ret

0000000080002272 <stop_handler>:
{
    80002272:	1101                	addi	sp,sp,-32
    80002274:	ec06                	sd	ra,24(sp)
    80002276:	e822                	sd	s0,16(sp)
    80002278:	e426                	sd	s1,8(sp)
    8000227a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	728080e7          	jalr	1832(ra) # 800019a4 <myproc>
    80002284:	84aa                	mv	s1,a0
  p->stopped = 1;
    80002286:	4785                	li	a5,1
    80002288:	1cf52423          	sw	a5,456(a0)
  release(&p->lock);
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	9fc080e7          	jalr	-1540(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    80002294:	1c84a783          	lw	a5,456(s1)
    80002298:	cf89                	beqz	a5,800022b2 <stop_handler+0x40>
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	cf2080e7          	jalr	-782(ra) # 80001f8c <received_continue>
    800022a2:	e901                	bnez	a0,800022b2 <stop_handler+0x40>
      yield();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	f92080e7          	jalr	-110(ra) # 80002236 <yield>
  while (p->stopped && !received_continue())
    800022ac:	1c84a783          	lw	a5,456(s1)
    800022b0:	f7ed                	bnez	a5,8000229a <stop_handler+0x28>
  acquire(&p->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	90e080e7          	jalr	-1778(ra) # 80000bc2 <acquire>
}
    800022bc:	60e2                	ld	ra,24(sp)
    800022be:	6442                	ld	s0,16(sp)
    800022c0:	64a2                	ld	s1,8(sp)
    800022c2:	6105                	addi	sp,sp,32
    800022c4:	8082                	ret

00000000800022c6 <handle_signals>:
{
    800022c6:	711d                	addi	sp,sp,-96
    800022c8:	ec86                	sd	ra,88(sp)
    800022ca:	e8a2                	sd	s0,80(sp)
    800022cc:	e4a6                	sd	s1,72(sp)
    800022ce:	e0ca                	sd	s2,64(sp)
    800022d0:	fc4e                	sd	s3,56(sp)
    800022d2:	f852                	sd	s4,48(sp)
    800022d4:	f456                	sd	s5,40(sp)
    800022d6:	f05a                	sd	s6,32(sp)
    800022d8:	ec5e                	sd	s7,24(sp)
    800022da:	e862                	sd	s8,16(sp)
    800022dc:	e466                	sd	s9,8(sp)
    800022de:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	6c4080e7          	jalr	1732(ra) # 800019a4 <myproc>
    800022e8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	8d8080e7          	jalr	-1832(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    800022f2:	04090993          	addi	s3,s2,64
    800022f6:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800022f8:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800022fa:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800022fc:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800022fe:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002300:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002302:	02000a13          	li	s4,32
    80002306:	a0a1                	j	8000234e <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002308:	03548263          	beq	s1,s5,8000232c <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    8000230c:	09748b63          	beq	s1,s7,800023a2 <handle_signals+0xdc>
        kill_handler();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	c52080e7          	jalr	-942(ra) # 80001f62 <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002318:	009b17bb          	sllw	a5,s6,s1
    8000231c:	fff7c793          	not	a5,a5
    80002320:	03492703          	lw	a4,52(s2)
    80002324:	8ff9                	and	a5,a5,a4
    80002326:	02f92a23          	sw	a5,52(s2)
    8000232a:	a831                	j	80002346 <handle_signals+0x80>
        stop_handler();
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	f46080e7          	jalr	-186(ra) # 80002272 <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002334:	009b17bb          	sllw	a5,s6,s1
    80002338:	fff7c793          	not	a5,a5
    8000233c:	03492703          	lw	a4,52(s2)
    80002340:	8ff9                	and	a5,a5,a4
    80002342:	02f92a23          	sw	a5,52(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002346:	2485                	addiw	s1,s1,1
    80002348:	09a1                	addi	s3,s3,8
    8000234a:	09448263          	beq	s1,s4,800023ce <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    8000234e:	03492703          	lw	a4,52(s2)
    80002352:	03892783          	lw	a5,56(s2)
    80002356:	fff7c793          	not	a5,a5
    8000235a:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    8000235c:	4097d7bb          	sraw	a5,a5,s1
    80002360:	8b85                	andi	a5,a5,1
    80002362:	d3f5                	beqz	a5,80002346 <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002364:	0009b783          	ld	a5,0(s3)
    80002368:	d3c5                	beqz	a5,80002308 <handle_signals+0x42>
    8000236a:	fd5781e3          	beq	a5,s5,8000232c <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    8000236e:	03778a63          	beq	a5,s7,800023a2 <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002372:	f9878fe3          	beq	a5,s8,80002310 <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002376:	05978463          	beq	a5,s9,800023be <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    8000237a:	1cc92783          	lw	a5,460(s2)
    8000237e:	f7e1                	bnez	a5,80002346 <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    80002380:	1d992623          	sw	s9,460(s2)
        handle_user_signals(signum);
    80002384:	8526                	mv	a0,s1
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	ca4080e7          	jalr	-860(ra) # 8000202a <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000238e:	009b17bb          	sllw	a5,s6,s1
    80002392:	fff7c793          	not	a5,a5
    80002396:	03492703          	lw	a4,52(s2)
    8000239a:	8ff9                	and	a5,a5,a4
    8000239c:	02f92a23          	sw	a5,52(s2)
    800023a0:	b75d                	j	80002346 <handle_signals+0x80>
        continue_handler();
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	c6c080e7          	jalr	-916(ra) # 8000200e <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800023aa:	009b17bb          	sllw	a5,s6,s1
    800023ae:	fff7c793          	not	a5,a5
    800023b2:	03492703          	lw	a4,52(s2)
    800023b6:	8ff9                	and	a5,a5,a4
    800023b8:	02f92a23          	sw	a5,52(s2)
    800023bc:	b769                	j	80002346 <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800023be:	009b17bb          	sllw	a5,s6,s1
    800023c2:	fff7c793          	not	a5,a5
    800023c6:	8f7d                	and	a4,a4,a5
    800023c8:	02e92a23          	sw	a4,52(s2)
    800023cc:	bfad                	j	80002346 <handle_signals+0x80>
  release(&p->lock);
    800023ce:	854a                	mv	a0,s2
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8b8080e7          	jalr	-1864(ra) # 80000c88 <release>
}
    800023d8:	60e6                	ld	ra,88(sp)
    800023da:	6446                	ld	s0,80(sp)
    800023dc:	64a6                	ld	s1,72(sp)
    800023de:	6906                	ld	s2,64(sp)
    800023e0:	79e2                	ld	s3,56(sp)
    800023e2:	7a42                	ld	s4,48(sp)
    800023e4:	7aa2                	ld	s5,40(sp)
    800023e6:	7b02                	ld	s6,32(sp)
    800023e8:	6be2                	ld	s7,24(sp)
    800023ea:	6c42                	ld	s8,16(sp)
    800023ec:	6ca2                	ld	s9,8(sp)
    800023ee:	6125                	addi	sp,sp,96
    800023f0:	8082                	ret

00000000800023f2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023f2:	7179                	addi	sp,sp,-48
    800023f4:	f406                	sd	ra,40(sp)
    800023f6:	f022                	sd	s0,32(sp)
    800023f8:	ec26                	sd	s1,24(sp)
    800023fa:	e84a                	sd	s2,16(sp)
    800023fc:	e44e                	sd	s3,8(sp)
    800023fe:	1800                	addi	s0,sp,48
    80002400:	89aa                	mv	s3,a0
    80002402:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	5a0080e7          	jalr	1440(ra) # 800019a4 <myproc>
    8000240c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7b4080e7          	jalr	1972(ra) # 80000bc2 <acquire>
  release(lk);
    80002416:	854a                	mv	a0,s2
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	870080e7          	jalr	-1936(ra) # 80000c88 <release>

  // Go to sleep.
  p->chan = chan;
    80002420:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002424:	4789                	li	a5,2
    80002426:	cc9c                	sw	a5,24(s1)

  sched();
    80002428:	00000097          	auipc	ra,0x0
    8000242c:	d38080e7          	jalr	-712(ra) # 80002160 <sched>

  // Tidy up.
  p->chan = 0;
    80002430:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	852080e7          	jalr	-1966(ra) # 80000c88 <release>
  acquire(lk);
    8000243e:	854a                	mv	a0,s2
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	782080e7          	jalr	1922(ra) # 80000bc2 <acquire>
}
    80002448:	70a2                	ld	ra,40(sp)
    8000244a:	7402                	ld	s0,32(sp)
    8000244c:	64e2                	ld	s1,24(sp)
    8000244e:	6942                	ld	s2,16(sp)
    80002450:	69a2                	ld	s3,8(sp)
    80002452:	6145                	addi	sp,sp,48
    80002454:	8082                	ret

0000000080002456 <wait>:
{
    80002456:	715d                	addi	sp,sp,-80
    80002458:	e486                	sd	ra,72(sp)
    8000245a:	e0a2                	sd	s0,64(sp)
    8000245c:	fc26                	sd	s1,56(sp)
    8000245e:	f84a                	sd	s2,48(sp)
    80002460:	f44e                	sd	s3,40(sp)
    80002462:	f052                	sd	s4,32(sp)
    80002464:	ec56                	sd	s5,24(sp)
    80002466:	e85a                	sd	s6,16(sp)
    80002468:	e45e                	sd	s7,8(sp)
    8000246a:	e062                	sd	s8,0(sp)
    8000246c:	0880                	addi	s0,sp,80
    8000246e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	534080e7          	jalr	1332(ra) # 800019a4 <myproc>
    80002478:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000247a:	0000f517          	auipc	a0,0xf
    8000247e:	e3e50513          	addi	a0,a0,-450 # 800112b8 <wait_lock>
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	740080e7          	jalr	1856(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000248a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000248c:	4a15                	li	s4,5
        havekids = 1;
    8000248e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002490:	0001b997          	auipc	s3,0x1b
    80002494:	24098993          	addi	s3,s3,576 # 8001d6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002498:	0000fc17          	auipc	s8,0xf
    8000249c:	e20c0c13          	addi	s8,s8,-480 # 800112b8 <wait_lock>
    havekids = 0;
    800024a0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024a2:	0000f497          	auipc	s1,0xf
    800024a6:	22e48493          	addi	s1,s1,558 # 800116d0 <proc>
    800024aa:	a0bd                	j	80002518 <wait+0xc2>
          pid = np->pid;
    800024ac:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024b0:	000b0e63          	beqz	s6,800024cc <wait+0x76>
    800024b4:	4691                	li	a3,4
    800024b6:	02c48613          	addi	a2,s1,44
    800024ba:	85da                	mv	a1,s6
    800024bc:	1e893503          	ld	a0,488(s2)
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	1a2080e7          	jalr	418(ra) # 80001662 <copyout>
    800024c8:	02054563          	bltz	a0,800024f2 <wait+0x9c>
          freeproc(np);
    800024cc:	8526                	mv	a0,s1
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	688080e7          	jalr	1672(ra) # 80001b56 <freeproc>
          release(&np->lock);
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	7b0080e7          	jalr	1968(ra) # 80000c88 <release>
          release(&wait_lock);
    800024e0:	0000f517          	auipc	a0,0xf
    800024e4:	dd850513          	addi	a0,a0,-552 # 800112b8 <wait_lock>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7a0080e7          	jalr	1952(ra) # 80000c88 <release>
          return pid;
    800024f0:	a0a5                	j	80002558 <wait+0x102>
            release(&np->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	794080e7          	jalr	1940(ra) # 80000c88 <release>
            release(&wait_lock);
    800024fc:	0000f517          	auipc	a0,0xf
    80002500:	dbc50513          	addi	a0,a0,-580 # 800112b8 <wait_lock>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	784080e7          	jalr	1924(ra) # 80000c88 <release>
            return -1;
    8000250c:	59fd                	li	s3,-1
    8000250e:	a0a9                	j	80002558 <wait+0x102>
    for(np = proc; np < &proc[NPROC]; np++){
    80002510:	30048493          	addi	s1,s1,768
    80002514:	03348563          	beq	s1,s3,8000253e <wait+0xe8>
      if(np->parent == p){
    80002518:	1d04b783          	ld	a5,464(s1)
    8000251c:	ff279ae3          	bne	a5,s2,80002510 <wait+0xba>
        acquire(&np->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6a0080e7          	jalr	1696(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000252a:	4c9c                	lw	a5,24(s1)
    8000252c:	f94780e3          	beq	a5,s4,800024ac <wait+0x56>
        release(&np->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	756080e7          	jalr	1878(ra) # 80000c88 <release>
        havekids = 1;
    8000253a:	8756                	mv	a4,s5
    8000253c:	bfd1                	j	80002510 <wait+0xba>
    if(!havekids || p->killed){
    8000253e:	c701                	beqz	a4,80002546 <wait+0xf0>
    80002540:	02892783          	lw	a5,40(s2)
    80002544:	c79d                	beqz	a5,80002572 <wait+0x11c>
      release(&wait_lock);
    80002546:	0000f517          	auipc	a0,0xf
    8000254a:	d7250513          	addi	a0,a0,-654 # 800112b8 <wait_lock>
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	73a080e7          	jalr	1850(ra) # 80000c88 <release>
      return -1;
    80002556:	59fd                	li	s3,-1
}
    80002558:	854e                	mv	a0,s3
    8000255a:	60a6                	ld	ra,72(sp)
    8000255c:	6406                	ld	s0,64(sp)
    8000255e:	74e2                	ld	s1,56(sp)
    80002560:	7942                	ld	s2,48(sp)
    80002562:	79a2                	ld	s3,40(sp)
    80002564:	7a02                	ld	s4,32(sp)
    80002566:	6ae2                	ld	s5,24(sp)
    80002568:	6b42                	ld	s6,16(sp)
    8000256a:	6ba2                	ld	s7,8(sp)
    8000256c:	6c02                	ld	s8,0(sp)
    8000256e:	6161                	addi	sp,sp,80
    80002570:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002572:	85e2                	mv	a1,s8
    80002574:	854a                	mv	a0,s2
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	e7c080e7          	jalr	-388(ra) # 800023f2 <sleep>
    havekids = 0;
    8000257e:	b70d                	j	800024a0 <wait+0x4a>

0000000080002580 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002580:	7139                	addi	sp,sp,-64
    80002582:	fc06                	sd	ra,56(sp)
    80002584:	f822                	sd	s0,48(sp)
    80002586:	f426                	sd	s1,40(sp)
    80002588:	f04a                	sd	s2,32(sp)
    8000258a:	ec4e                	sd	s3,24(sp)
    8000258c:	e852                	sd	s4,16(sp)
    8000258e:	e456                	sd	s5,8(sp)
    80002590:	0080                	addi	s0,sp,64
    80002592:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002594:	0000f497          	auipc	s1,0xf
    80002598:	13c48493          	addi	s1,s1,316 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000259c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000259e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800025a0:	0001b917          	auipc	s2,0x1b
    800025a4:	13090913          	addi	s2,s2,304 # 8001d6d0 <tickslock>
    800025a8:	a811                	j	800025bc <wakeup+0x3c>
      }
      release(&p->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	6dc080e7          	jalr	1756(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b4:	30048493          	addi	s1,s1,768
    800025b8:	03248663          	beq	s1,s2,800025e4 <wakeup+0x64>
    if(p != myproc()){
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	3e8080e7          	jalr	1000(ra) # 800019a4 <myproc>
    800025c4:	fea488e3          	beq	s1,a0,800025b4 <wakeup+0x34>
      acquire(&p->lock);
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	5f8080e7          	jalr	1528(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025d2:	4c9c                	lw	a5,24(s1)
    800025d4:	fd379be3          	bne	a5,s3,800025aa <wakeup+0x2a>
    800025d8:	709c                	ld	a5,32(s1)
    800025da:	fd4798e3          	bne	a5,s4,800025aa <wakeup+0x2a>
        p->state = RUNNABLE;
    800025de:	0154ac23          	sw	s5,24(s1)
    800025e2:	b7e1                	j	800025aa <wakeup+0x2a>
    }
  }
}
    800025e4:	70e2                	ld	ra,56(sp)
    800025e6:	7442                	ld	s0,48(sp)
    800025e8:	74a2                	ld	s1,40(sp)
    800025ea:	7902                	ld	s2,32(sp)
    800025ec:	69e2                	ld	s3,24(sp)
    800025ee:	6a42                	ld	s4,16(sp)
    800025f0:	6aa2                	ld	s5,8(sp)
    800025f2:	6121                	addi	sp,sp,64
    800025f4:	8082                	ret

00000000800025f6 <reparent>:
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	e052                	sd	s4,0(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002608:	0000f497          	auipc	s1,0xf
    8000260c:	0c848493          	addi	s1,s1,200 # 800116d0 <proc>
      pp->parent = initproc;
    80002610:	00007a17          	auipc	s4,0x7
    80002614:	a18a0a13          	addi	s4,s4,-1512 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002618:	0001b997          	auipc	s3,0x1b
    8000261c:	0b898993          	addi	s3,s3,184 # 8001d6d0 <tickslock>
    80002620:	a029                	j	8000262a <reparent+0x34>
    80002622:	30048493          	addi	s1,s1,768
    80002626:	01348f63          	beq	s1,s3,80002644 <reparent+0x4e>
    if(pp->parent == p){
    8000262a:	1d04b783          	ld	a5,464(s1)
    8000262e:	ff279ae3          	bne	a5,s2,80002622 <reparent+0x2c>
      pp->parent = initproc;
    80002632:	000a3503          	ld	a0,0(s4)
    80002636:	1ca4b823          	sd	a0,464(s1)
      wakeup(initproc);
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	f46080e7          	jalr	-186(ra) # 80002580 <wakeup>
    80002642:	b7c5                	j	80002622 <reparent+0x2c>
}
    80002644:	70a2                	ld	ra,40(sp)
    80002646:	7402                	ld	s0,32(sp)
    80002648:	64e2                	ld	s1,24(sp)
    8000264a:	6942                	ld	s2,16(sp)
    8000264c:	69a2                	ld	s3,8(sp)
    8000264e:	6a02                	ld	s4,0(sp)
    80002650:	6145                	addi	sp,sp,48
    80002652:	8082                	ret

0000000080002654 <exit>:
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	33e080e7          	jalr	830(ra) # 800019a4 <myproc>
    8000266e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002670:	00007797          	auipc	a5,0x7
    80002674:	9b87b783          	ld	a5,-1608(a5) # 80009028 <initproc>
    80002678:	26850493          	addi	s1,a0,616
    8000267c:	2e850913          	addi	s2,a0,744
    80002680:	02a79363          	bne	a5,a0,800026a6 <exit+0x52>
    panic("init exiting");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	c0450513          	addi	a0,a0,-1020 # 80008288 <digits+0x248>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	e9e080e7          	jalr	-354(ra) # 8000052a <panic>
      fileclose(f);
    80002694:	00002097          	auipc	ra,0x2
    80002698:	468080e7          	jalr	1128(ra) # 80004afc <fileclose>
      p->ofile[fd] = 0;
    8000269c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026a0:	04a1                	addi	s1,s1,8
    800026a2:	01248563          	beq	s1,s2,800026ac <exit+0x58>
    if(p->ofile[fd]){
    800026a6:	6088                	ld	a0,0(s1)
    800026a8:	f575                	bnez	a0,80002694 <exit+0x40>
    800026aa:	bfdd                	j	800026a0 <exit+0x4c>
  begin_op();
    800026ac:	00002097          	auipc	ra,0x2
    800026b0:	f84080e7          	jalr	-124(ra) # 80004630 <begin_op>
  iput(p->cwd);
    800026b4:	2e89b503          	ld	a0,744(s3)
    800026b8:	00001097          	auipc	ra,0x1
    800026bc:	75c080e7          	jalr	1884(ra) # 80003e14 <iput>
  end_op();
    800026c0:	00002097          	auipc	ra,0x2
    800026c4:	ff0080e7          	jalr	-16(ra) # 800046b0 <end_op>
  p->cwd = 0;
    800026c8:	2e09b423          	sd	zero,744(s3)
  acquire(&wait_lock);
    800026cc:	0000f497          	auipc	s1,0xf
    800026d0:	bec48493          	addi	s1,s1,-1044 # 800112b8 <wait_lock>
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	4ec080e7          	jalr	1260(ra) # 80000bc2 <acquire>
  reparent(p);
    800026de:	854e                	mv	a0,s3
    800026e0:	00000097          	auipc	ra,0x0
    800026e4:	f16080e7          	jalr	-234(ra) # 800025f6 <reparent>
  wakeup(p->parent);
    800026e8:	1d09b503          	ld	a0,464(s3)
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	e94080e7          	jalr	-364(ra) # 80002580 <wakeup>
  acquire(&p->lock);
    800026f4:	854e                	mv	a0,s3
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	4cc080e7          	jalr	1228(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026fe:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002702:	4795                	li	a5,5
    80002704:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	57e080e7          	jalr	1406(ra) # 80000c88 <release>
  sched();
    80002712:	00000097          	auipc	ra,0x0
    80002716:	a4e080e7          	jalr	-1458(ra) # 80002160 <sched>
  panic("zombie exit");
    8000271a:	00006517          	auipc	a0,0x6
    8000271e:	b7e50513          	addi	a0,a0,-1154 # 80008298 <digits+0x258>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	e08080e7          	jalr	-504(ra) # 8000052a <panic>

000000008000272a <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    8000272a:	47fd                	li	a5,31
    8000272c:	06b7eb63          	bltu	a5,a1,800027a2 <kill+0x78>
{
    80002730:	7179                	addi	sp,sp,-48
    80002732:	f406                	sd	ra,40(sp)
    80002734:	f022                	sd	s0,32(sp)
    80002736:	ec26                	sd	s1,24(sp)
    80002738:	e84a                	sd	s2,16(sp)
    8000273a:	e44e                	sd	s3,8(sp)
    8000273c:	e052                	sd	s4,0(sp)
    8000273e:	1800                	addi	s0,sp,48
    80002740:	892a                	mv	s2,a0
    80002742:	8a2e                	mv	s4,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002744:	0000f497          	auipc	s1,0xf
    80002748:	f8c48493          	addi	s1,s1,-116 # 800116d0 <proc>
    8000274c:	0001b997          	auipc	s3,0x1b
    80002750:	f8498993          	addi	s3,s3,-124 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	46c080e7          	jalr	1132(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    8000275e:	589c                	lw	a5,48(s1)
    80002760:	01278d63          	beq	a5,s2,8000277a <kill+0x50>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	522080e7          	jalr	1314(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000276e:	30048493          	addi	s1,s1,768
    80002772:	ff3491e3          	bne	s1,s3,80002754 <kill+0x2a>
  }
  // no such pid
  return -1;
    80002776:	557d                	li	a0,-1
    80002778:	a829                	j	80002792 <kill+0x68>
      p->pending_signals = p->pending_signals | (1 << signum);
    8000277a:	4785                	li	a5,1
    8000277c:	0147973b          	sllw	a4,a5,s4
    80002780:	58dc                	lw	a5,52(s1)
    80002782:	8fd9                	or	a5,a5,a4
    80002784:	d8dc                	sw	a5,52(s1)
      release(&p->lock);
    80002786:	8526                	mv	a0,s1
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	500080e7          	jalr	1280(ra) # 80000c88 <release>
      return 0;
    80002790:	4501                	li	a0,0
}
    80002792:	70a2                	ld	ra,40(sp)
    80002794:	7402                	ld	s0,32(sp)
    80002796:	64e2                	ld	s1,24(sp)
    80002798:	6942                	ld	s2,16(sp)
    8000279a:	69a2                	ld	s3,8(sp)
    8000279c:	6a02                	ld	s4,0(sp)
    8000279e:	6145                	addi	sp,sp,48
    800027a0:	8082                	ret
    return -1;
    800027a2:	557d                	li	a0,-1
}
    800027a4:	8082                	ret

00000000800027a6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027a6:	7179                	addi	sp,sp,-48
    800027a8:	f406                	sd	ra,40(sp)
    800027aa:	f022                	sd	s0,32(sp)
    800027ac:	ec26                	sd	s1,24(sp)
    800027ae:	e84a                	sd	s2,16(sp)
    800027b0:	e44e                	sd	s3,8(sp)
    800027b2:	e052                	sd	s4,0(sp)
    800027b4:	1800                	addi	s0,sp,48
    800027b6:	84aa                	mv	s1,a0
    800027b8:	892e                	mv	s2,a1
    800027ba:	89b2                	mv	s3,a2
    800027bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	1e6080e7          	jalr	486(ra) # 800019a4 <myproc>
  if(user_dst){
    800027c6:	c095                	beqz	s1,800027ea <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800027c8:	86d2                	mv	a3,s4
    800027ca:	864e                	mv	a2,s3
    800027cc:	85ca                	mv	a1,s2
    800027ce:	1e853503          	ld	a0,488(a0)
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	e90080e7          	jalr	-368(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027da:	70a2                	ld	ra,40(sp)
    800027dc:	7402                	ld	s0,32(sp)
    800027de:	64e2                	ld	s1,24(sp)
    800027e0:	6942                	ld	s2,16(sp)
    800027e2:	69a2                	ld	s3,8(sp)
    800027e4:	6a02                	ld	s4,0(sp)
    800027e6:	6145                	addi	sp,sp,48
    800027e8:	8082                	ret
    memmove((char *)dst, src, len);
    800027ea:	000a061b          	sext.w	a2,s4
    800027ee:	85ce                	mv	a1,s3
    800027f0:	854a                	mv	a0,s2
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	54c080e7          	jalr	1356(ra) # 80000d3e <memmove>
    return 0;
    800027fa:	8526                	mv	a0,s1
    800027fc:	bff9                	j	800027da <either_copyout+0x34>

00000000800027fe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027fe:	7179                	addi	sp,sp,-48
    80002800:	f406                	sd	ra,40(sp)
    80002802:	f022                	sd	s0,32(sp)
    80002804:	ec26                	sd	s1,24(sp)
    80002806:	e84a                	sd	s2,16(sp)
    80002808:	e44e                	sd	s3,8(sp)
    8000280a:	e052                	sd	s4,0(sp)
    8000280c:	1800                	addi	s0,sp,48
    8000280e:	892a                	mv	s2,a0
    80002810:	84ae                	mv	s1,a1
    80002812:	89b2                	mv	s3,a2
    80002814:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	18e080e7          	jalr	398(ra) # 800019a4 <myproc>
  if(user_src){
    8000281e:	c095                	beqz	s1,80002842 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002820:	86d2                	mv	a3,s4
    80002822:	864e                	mv	a2,s3
    80002824:	85ca                	mv	a1,s2
    80002826:	1e853503          	ld	a0,488(a0)
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	ec4080e7          	jalr	-316(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002832:	70a2                	ld	ra,40(sp)
    80002834:	7402                	ld	s0,32(sp)
    80002836:	64e2                	ld	s1,24(sp)
    80002838:	6942                	ld	s2,16(sp)
    8000283a:	69a2                	ld	s3,8(sp)
    8000283c:	6a02                	ld	s4,0(sp)
    8000283e:	6145                	addi	sp,sp,48
    80002840:	8082                	ret
    memmove(dst, (char*)src, len);
    80002842:	000a061b          	sext.w	a2,s4
    80002846:	85ce                	mv	a1,s3
    80002848:	854a                	mv	a0,s2
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	4f4080e7          	jalr	1268(ra) # 80000d3e <memmove>
    return 0;
    80002852:	8526                	mv	a0,s1
    80002854:	bff9                	j	80002832 <either_copyin+0x34>

0000000080002856 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002856:	715d                	addi	sp,sp,-80
    80002858:	e486                	sd	ra,72(sp)
    8000285a:	e0a2                	sd	s0,64(sp)
    8000285c:	fc26                	sd	s1,56(sp)
    8000285e:	f84a                	sd	s2,48(sp)
    80002860:	f44e                	sd	s3,40(sp)
    80002862:	f052                	sd	s4,32(sp)
    80002864:	ec56                	sd	s5,24(sp)
    80002866:	e85a                	sd	s6,16(sp)
    80002868:	e45e                	sd	s7,8(sp)
    8000286a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	87c50513          	addi	a0,a0,-1924 # 800080e8 <digits+0xa8>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d00080e7          	jalr	-768(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000287c:	0000f497          	auipc	s1,0xf
    80002880:	14448493          	addi	s1,s1,324 # 800119c0 <proc+0x2f0>
    80002884:	0001b917          	auipc	s2,0x1b
    80002888:	13c90913          	addi	s2,s2,316 # 8001d9c0 <bcache+0x2d8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000288e:	00006997          	auipc	s3,0x6
    80002892:	a1a98993          	addi	s3,s3,-1510 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002896:	00006a97          	auipc	s5,0x6
    8000289a:	a1aa8a93          	addi	s5,s5,-1510 # 800082b0 <digits+0x270>
    printf("\n");
    8000289e:	00006a17          	auipc	s4,0x6
    800028a2:	84aa0a13          	addi	s4,s4,-1974 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a6:	00006b97          	auipc	s7,0x6
    800028aa:	a42b8b93          	addi	s7,s7,-1470 # 800082e8 <states.0>
    800028ae:	a00d                	j	800028d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b0:	d406a583          	lw	a1,-704(a3)
    800028b4:	8556                	mv	a0,s5
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cbe080e7          	jalr	-834(ra) # 80000574 <printf>
    printf("\n");
    800028be:	8552                	mv	a0,s4
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cb4080e7          	jalr	-844(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028c8:	30048493          	addi	s1,s1,768
    800028cc:	03248263          	beq	s1,s2,800028f0 <procdump+0x9a>
    if(p->state == UNUSED)
    800028d0:	86a6                	mv	a3,s1
    800028d2:	d284a783          	lw	a5,-728(s1)
    800028d6:	dbed                	beqz	a5,800028c8 <procdump+0x72>
      state = "???";
    800028d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028da:	fcfb6be3          	bltu	s6,a5,800028b0 <procdump+0x5a>
    800028de:	02079713          	slli	a4,a5,0x20
    800028e2:	01d75793          	srli	a5,a4,0x1d
    800028e6:	97de                	add	a5,a5,s7
    800028e8:	6390                	ld	a2,0(a5)
    800028ea:	f279                	bnez	a2,800028b0 <procdump+0x5a>
      state = "???";
    800028ec:	864e                	mv	a2,s3
    800028ee:	b7c9                	j	800028b0 <procdump+0x5a>
  }
}
    800028f0:	60a6                	ld	ra,72(sp)
    800028f2:	6406                	ld	s0,64(sp)
    800028f4:	74e2                	ld	s1,56(sp)
    800028f6:	7942                	ld	s2,48(sp)
    800028f8:	79a2                	ld	s3,40(sp)
    800028fa:	7a02                	ld	s4,32(sp)
    800028fc:	6ae2                	ld	s5,24(sp)
    800028fe:	6b42                	ld	s6,16(sp)
    80002900:	6ba2                	ld	s7,8(sp)
    80002902:	6161                	addi	sp,sp,80
    80002904:	8082                	ret

0000000080002906 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    80002906:	7179                	addi	sp,sp,-48
    80002908:	f406                	sd	ra,40(sp)
    8000290a:	f022                	sd	s0,32(sp)
    8000290c:	ec26                	sd	s1,24(sp)
    8000290e:	e84a                	sd	s2,16(sp)
    80002910:	e44e                	sd	s3,8(sp)
    80002912:	1800                	addi	s0,sp,48
    80002914:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	08e080e7          	jalr	142(ra) # 800019a4 <myproc>
    8000291e:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002920:	03852983          	lw	s3,56(a0)
  acquire(&p->lock);
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	29e080e7          	jalr	670(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    8000292c:	000207b7          	lui	a5,0x20
    80002930:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002934:	00f977b3          	and	a5,s2,a5
    80002938:	e385                	bnez	a5,80002958 <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    8000293a:	0324ac23          	sw	s2,56(s1)
  release(&p->lock);
    8000293e:	8526                	mv	a0,s1
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	348080e7          	jalr	840(ra) # 80000c88 <release>
  return old_mask;
}
    80002948:	854e                	mv	a0,s3
    8000294a:	70a2                	ld	ra,40(sp)
    8000294c:	7402                	ld	s0,32(sp)
    8000294e:	64e2                	ld	s1,24(sp)
    80002950:	6942                	ld	s2,16(sp)
    80002952:	69a2                	ld	s3,8(sp)
    80002954:	6145                	addi	sp,sp,48
    80002956:	8082                	ret
    release(&p->lock);
    80002958:	8526                	mv	a0,s1
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	32e080e7          	jalr	814(ra) # 80000c88 <release>
    return -1;
    80002962:	59fd                	li	s3,-1
    80002964:	b7d5                	j	80002948 <sigprocmask+0x42>

0000000080002966 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002966:	715d                	addi	sp,sp,-80
    80002968:	e486                	sd	ra,72(sp)
    8000296a:	e0a2                	sd	s0,64(sp)
    8000296c:	fc26                	sd	s1,56(sp)
    8000296e:	f84a                	sd	s2,48(sp)
    80002970:	f44e                	sd	s3,40(sp)
    80002972:	f052                	sd	s4,32(sp)
    80002974:	0880                	addi	s0,sp,80
    80002976:	84aa                	mv	s1,a0
    80002978:	89ae                	mv	s3,a1
    8000297a:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	028080e7          	jalr	40(ra) # 800019a4 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002984:	0004879b          	sext.w	a5,s1
    80002988:	477d                	li	a4,31
    8000298a:	0cf76763          	bltu	a4,a5,80002a58 <sigaction+0xf2>
    8000298e:	892a                	mv	s2,a0
    80002990:	37dd                	addiw	a5,a5,-9
    80002992:	9bdd                	andi	a5,a5,-9
    80002994:	2781                	sext.w	a5,a5
    80002996:	c3f9                	beqz	a5,80002a5c <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	22a080e7          	jalr	554(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    800029a0:	0c098063          	beqz	s3,80002a60 <sigaction+0xfa>
    800029a4:	46c1                	li	a3,16
    800029a6:	864e                	mv	a2,s3
    800029a8:	fc040593          	addi	a1,s0,-64
    800029ac:	1e893503          	ld	a0,488(s2)
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	d3e080e7          	jalr	-706(ra) # 800016ee <copyin>
    800029b8:	08054263          	bltz	a0,80002a3c <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    800029bc:	fc843783          	ld	a5,-56(s0)
    800029c0:	00020737          	lui	a4,0x20
    800029c4:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    800029c8:	8ff9                	and	a5,a5,a4
    800029ca:	e3c1                	bnez	a5,80002a4a <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    800029cc:	020a0c63          	beqz	s4,80002a04 <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    800029d0:	00848793          	addi	a5,s1,8
    800029d4:	078e                	slli	a5,a5,0x3
    800029d6:	97ca                	add	a5,a5,s2
    800029d8:	639c                	ld	a5,0(a5)
    800029da:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    800029de:	05048793          	addi	a5,s1,80
    800029e2:	078a                	slli	a5,a5,0x2
    800029e4:	97ca                	add	a5,a5,s2
    800029e6:	439c                	lw	a5,0(a5)
    800029e8:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    800029ec:	46c1                	li	a3,16
    800029ee:	fb040613          	addi	a2,s0,-80
    800029f2:	85d2                	mv	a1,s4
    800029f4:	1e893503          	ld	a0,488(s2)
    800029f8:	fffff097          	auipc	ra,0xfffff
    800029fc:	c6a080e7          	jalr	-918(ra) # 80001662 <copyout>
    80002a00:	08054c63          	bltz	a0,80002a98 <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002a04:	00848793          	addi	a5,s1,8
    80002a08:	078e                	slli	a5,a5,0x3
    80002a0a:	97ca                	add	a5,a5,s2
    80002a0c:	fc043703          	ld	a4,-64(s0)
    80002a10:	e398                	sd	a4,0(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002a12:	05048493          	addi	s1,s1,80
    80002a16:	048a                	slli	s1,s1,0x2
    80002a18:	94ca                	add	s1,s1,s2
    80002a1a:	fc842783          	lw	a5,-56(s0)
    80002a1e:	c09c                	sw	a5,0(s1)
  }

  release(&p->lock);
    80002a20:	854a                	mv	a0,s2
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	266080e7          	jalr	614(ra) # 80000c88 <release>
  return 0;
    80002a2a:	4501                	li	a0,0
}
    80002a2c:	60a6                	ld	ra,72(sp)
    80002a2e:	6406                	ld	s0,64(sp)
    80002a30:	74e2                	ld	s1,56(sp)
    80002a32:	7942                	ld	s2,48(sp)
    80002a34:	79a2                	ld	s3,40(sp)
    80002a36:	7a02                	ld	s4,32(sp)
    80002a38:	6161                	addi	sp,sp,80
    80002a3a:	8082                	ret
    release(&p->lock);
    80002a3c:	854a                	mv	a0,s2
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	24a080e7          	jalr	586(ra) # 80000c88 <release>
    return -1;
    80002a46:	557d                	li	a0,-1
    80002a48:	b7d5                	j	80002a2c <sigaction+0xc6>
    release(&p->lock);
    80002a4a:	854a                	mv	a0,s2
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	23c080e7          	jalr	572(ra) # 80000c88 <release>
    return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	bfd9                	j	80002a2c <sigaction+0xc6>
    return -1;
    80002a58:	557d                	li	a0,-1
    80002a5a:	bfc9                	j	80002a2c <sigaction+0xc6>
    80002a5c:	557d                	li	a0,-1
    80002a5e:	b7f9                	j	80002a2c <sigaction+0xc6>
  if (oldact) {
    80002a60:	fc0a00e3          	beqz	s4,80002a20 <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002a64:	00848793          	addi	a5,s1,8
    80002a68:	078e                	slli	a5,a5,0x3
    80002a6a:	97ca                	add	a5,a5,s2
    80002a6c:	639c                	ld	a5,0(a5)
    80002a6e:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002a72:	05048493          	addi	s1,s1,80
    80002a76:	048a                	slli	s1,s1,0x2
    80002a78:	94ca                	add	s1,s1,s2
    80002a7a:	409c                	lw	a5,0(s1)
    80002a7c:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002a80:	46c1                	li	a3,16
    80002a82:	fb040613          	addi	a2,s0,-80
    80002a86:	85d2                	mv	a1,s4
    80002a88:	1e893503          	ld	a0,488(s2)
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	bd6080e7          	jalr	-1066(ra) # 80001662 <copyout>
    80002a94:	f80556e3          	bgez	a0,80002a20 <sigaction+0xba>
      release(&p->lock);
    80002a98:	854a                	mv	a0,s2
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	1ee080e7          	jalr	494(ra) # 80000c88 <release>
      return -1;
    80002aa2:	557d                	li	a0,-1
    80002aa4:	b761                	j	80002a2c <sigaction+0xc6>

0000000080002aa6 <sigret>:

// ADDED Q2.1.5
void
sigret(void)
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	ef4080e7          	jalr	-268(ra) # 800019a4 <myproc>
    80002ab8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	108080e7          	jalr	264(ra) # 80000bc2 <acquire>
  memmove(p->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002ac2:	12000613          	li	a2,288
    80002ac6:	1c04b583          	ld	a1,448(s1)
    80002aca:	1f04b503          	ld	a0,496(s1)
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	270080e7          	jalr	624(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002ad6:	5cdc                	lw	a5,60(s1)
    80002ad8:	dc9c                	sw	a5,56(s1)
  p->handling_user_level_signal = 0;
    80002ada:	1c04a623          	sw	zero,460(s1)
  release(&p->lock);
    80002ade:	8526                	mv	a0,s1
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	1a8080e7          	jalr	424(ra) # 80000c88 <release>
}
    80002ae8:	60e2                	ld	ra,24(sp)
    80002aea:	6442                	ld	s0,16(sp)
    80002aec:	64a2                	ld	s1,8(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret

0000000080002af2 <swtch>:
    80002af2:	00153023          	sd	ra,0(a0)
    80002af6:	00253423          	sd	sp,8(a0)
    80002afa:	e900                	sd	s0,16(a0)
    80002afc:	ed04                	sd	s1,24(a0)
    80002afe:	03253023          	sd	s2,32(a0)
    80002b02:	03353423          	sd	s3,40(a0)
    80002b06:	03453823          	sd	s4,48(a0)
    80002b0a:	03553c23          	sd	s5,56(a0)
    80002b0e:	05653023          	sd	s6,64(a0)
    80002b12:	05753423          	sd	s7,72(a0)
    80002b16:	05853823          	sd	s8,80(a0)
    80002b1a:	05953c23          	sd	s9,88(a0)
    80002b1e:	07a53023          	sd	s10,96(a0)
    80002b22:	07b53423          	sd	s11,104(a0)
    80002b26:	0005b083          	ld	ra,0(a1)
    80002b2a:	0085b103          	ld	sp,8(a1)
    80002b2e:	6980                	ld	s0,16(a1)
    80002b30:	6d84                	ld	s1,24(a1)
    80002b32:	0205b903          	ld	s2,32(a1)
    80002b36:	0285b983          	ld	s3,40(a1)
    80002b3a:	0305ba03          	ld	s4,48(a1)
    80002b3e:	0385ba83          	ld	s5,56(a1)
    80002b42:	0405bb03          	ld	s6,64(a1)
    80002b46:	0485bb83          	ld	s7,72(a1)
    80002b4a:	0505bc03          	ld	s8,80(a1)
    80002b4e:	0585bc83          	ld	s9,88(a1)
    80002b52:	0605bd03          	ld	s10,96(a1)
    80002b56:	0685bd83          	ld	s11,104(a1)
    80002b5a:	8082                	ret

0000000080002b5c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b5c:	1141                	addi	sp,sp,-16
    80002b5e:	e406                	sd	ra,8(sp)
    80002b60:	e022                	sd	s0,0(sp)
    80002b62:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b64:	00005597          	auipc	a1,0x5
    80002b68:	7b458593          	addi	a1,a1,1972 # 80008318 <states.0+0x30>
    80002b6c:	0001b517          	auipc	a0,0x1b
    80002b70:	b6450513          	addi	a0,a0,-1180 # 8001d6d0 <tickslock>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	fbe080e7          	jalr	-66(ra) # 80000b32 <initlock>
}
    80002b7c:	60a2                	ld	ra,8(sp)
    80002b7e:	6402                	ld	s0,0(sp)
    80002b80:	0141                	addi	sp,sp,16
    80002b82:	8082                	ret

0000000080002b84 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b84:	1141                	addi	sp,sp,-16
    80002b86:	e422                	sd	s0,8(sp)
    80002b88:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b8a:	00003797          	auipc	a5,0x3
    80002b8e:	5c678793          	addi	a5,a5,1478 # 80006150 <kernelvec>
    80002b92:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b96:	6422                	ld	s0,8(sp)
    80002b98:	0141                	addi	sp,sp,16
    80002b9a:	8082                	ret

0000000080002b9c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	dfe080e7          	jalr	-514(ra) # 800019a4 <myproc>
    80002bae:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bb4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb6:	10079073          	csrw	sstatus,a5

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();
  handle_signals(); // ADDED Q2.4 
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	70c080e7          	jalr	1804(ra) # 800022c6 <handle_signals>
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bc2:	00004617          	auipc	a2,0x4
    80002bc6:	43e60613          	addi	a2,a2,1086 # 80007000 <_trampoline>
    80002bca:	00004697          	auipc	a3,0x4
    80002bce:	43668693          	addi	a3,a3,1078 # 80007000 <_trampoline>
    80002bd2:	8e91                	sub	a3,a3,a2
    80002bd4:	040007b7          	lui	a5,0x4000
    80002bd8:	17fd                	addi	a5,a5,-1
    80002bda:	07b2                	slli	a5,a5,0xc
    80002bdc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bde:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002be2:	1f04b703          	ld	a4,496(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002be6:	180026f3          	csrr	a3,satp
    80002bea:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bec:	1f04b703          	ld	a4,496(s1)
    80002bf0:	1d84b683          	ld	a3,472(s1)
    80002bf4:	6585                	lui	a1,0x1
    80002bf6:	96ae                	add	a3,a3,a1
    80002bf8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bfa:	1f04b703          	ld	a4,496(s1)
    80002bfe:	00000697          	auipc	a3,0x0
    80002c02:	14068693          	addi	a3,a3,320 # 80002d3e <usertrap>
    80002c06:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c08:	1f04b703          	ld	a4,496(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c0c:	8692                	mv	a3,tp
    80002c0e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c10:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c14:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c18:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c20:	1f04b703          	ld	a4,496(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c24:	6f18                	ld	a4,24(a4)
    80002c26:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c2a:	1e84b583          	ld	a1,488(s1)
    80002c2e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c30:	00004717          	auipc	a4,0x4
    80002c34:	46070713          	addi	a4,a4,1120 # 80007090 <userret>
    80002c38:	8f11                	sub	a4,a4,a2
    80002c3a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c3c:	577d                	li	a4,-1
    80002c3e:	177e                	slli	a4,a4,0x3f
    80002c40:	8dd9                	or	a1,a1,a4
    80002c42:	02000537          	lui	a0,0x2000
    80002c46:	157d                	addi	a0,a0,-1
    80002c48:	0536                	slli	a0,a0,0xd
    80002c4a:	9782                	jalr	a5

  //printf("usertrapret end\n");//TODO REMOVE
}
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	64a2                	ld	s1,8(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c60:	0001b497          	auipc	s1,0x1b
    80002c64:	a7048493          	addi	s1,s1,-1424 # 8001d6d0 <tickslock>
    80002c68:	8526                	mv	a0,s1
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	f58080e7          	jalr	-168(ra) # 80000bc2 <acquire>
  ticks++;
    80002c72:	00006517          	auipc	a0,0x6
    80002c76:	3be50513          	addi	a0,a0,958 # 80009030 <ticks>
    80002c7a:	411c                	lw	a5,0(a0)
    80002c7c:	2785                	addiw	a5,a5,1
    80002c7e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	900080e7          	jalr	-1792(ra) # 80002580 <wakeup>
  release(&tickslock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	ffe080e7          	jalr	-2(ra) # 80000c88 <release>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret

0000000080002c9c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002caa:	00074d63          	bltz	a4,80002cc4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cae:	57fd                	li	a5,-1
    80002cb0:	17fe                	slli	a5,a5,0x3f
    80002cb2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cb4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cb6:	06f70363          	beq	a4,a5,80002d1c <devintr+0x80>
  }
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	64a2                	ld	s1,8(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
     (scause & 0xff) == 9){
    80002cc4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cc8:	46a5                	li	a3,9
    80002cca:	fed792e3          	bne	a5,a3,80002cae <devintr+0x12>
    int irq = plic_claim();
    80002cce:	00003097          	auipc	ra,0x3
    80002cd2:	58a080e7          	jalr	1418(ra) # 80006258 <plic_claim>
    80002cd6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cd8:	47a9                	li	a5,10
    80002cda:	02f50763          	beq	a0,a5,80002d08 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cde:	4785                	li	a5,1
    80002ce0:	02f50963          	beq	a0,a5,80002d12 <devintr+0x76>
    return 1;
    80002ce4:	4505                	li	a0,1
    } else if(irq){
    80002ce6:	d8f1                	beqz	s1,80002cba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	63650513          	addi	a0,a0,1590 # 80008320 <states.0+0x38>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	882080e7          	jalr	-1918(ra) # 80000574 <printf>
      plic_complete(irq);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	00003097          	auipc	ra,0x3
    80002d00:	580080e7          	jalr	1408(ra) # 8000627c <plic_complete>
    return 1;
    80002d04:	4505                	li	a0,1
    80002d06:	bf55                	j	80002cba <devintr+0x1e>
      uartintr();
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	c7e080e7          	jalr	-898(ra) # 80000986 <uartintr>
    80002d10:	b7ed                	j	80002cfa <devintr+0x5e>
      virtio_disk_intr();
    80002d12:	00004097          	auipc	ra,0x4
    80002d16:	9fc080e7          	jalr	-1540(ra) # 8000670e <virtio_disk_intr>
    80002d1a:	b7c5                	j	80002cfa <devintr+0x5e>
    if(cpuid() == 0){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	c5c080e7          	jalr	-932(ra) # 80001978 <cpuid>
    80002d24:	c901                	beqz	a0,80002d34 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d26:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d2a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d2c:	14479073          	csrw	sip,a5
    return 2;
    80002d30:	4509                	li	a0,2
    80002d32:	b761                	j	80002cba <devintr+0x1e>
      clockintr();
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	f22080e7          	jalr	-222(ra) # 80002c56 <clockintr>
    80002d3c:	b7ed                	j	80002d26 <devintr+0x8a>

0000000080002d3e <usertrap>:
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d4e:	1007f793          	andi	a5,a5,256
    80002d52:	e3bd                	bnez	a5,80002db8 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d54:	00003797          	auipc	a5,0x3
    80002d58:	3fc78793          	addi	a5,a5,1020 # 80006150 <kernelvec>
    80002d5c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	c44080e7          	jalr	-956(ra) # 800019a4 <myproc>
    80002d68:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d6a:	1f053783          	ld	a5,496(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6e:	14102773          	csrr	a4,sepc
    80002d72:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d74:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d78:	47a1                	li	a5,8
    80002d7a:	04f71d63          	bne	a4,a5,80002dd4 <usertrap+0x96>
    if(p->killed)
    80002d7e:	551c                	lw	a5,40(a0)
    80002d80:	e7a1                	bnez	a5,80002dc8 <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002d82:	1f04b703          	ld	a4,496(s1)
    80002d86:	6f1c                	ld	a5,24(a4)
    80002d88:	0791                	addi	a5,a5,4
    80002d8a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d94:	10079073          	csrw	sstatus,a5
    syscall();
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	2f2080e7          	jalr	754(ra) # 8000308a <syscall>
  if(p->killed)
    80002da0:	549c                	lw	a5,40(s1)
    80002da2:	ebc1                	bnez	a5,80002e32 <usertrap+0xf4>
  usertrapret();
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	df8080e7          	jalr	-520(ra) # 80002b9c <usertrapret>
}
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	64a2                	ld	s1,8(sp)
    80002db2:	6902                	ld	s2,0(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret
    panic("usertrap: not from user mode");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	58850513          	addi	a0,a0,1416 # 80008340 <states.0+0x58>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	76a080e7          	jalr	1898(ra) # 8000052a <panic>
      exit(-1);
    80002dc8:	557d                	li	a0,-1
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	88a080e7          	jalr	-1910(ra) # 80002654 <exit>
    80002dd2:	bf45                	j	80002d82 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	ec8080e7          	jalr	-312(ra) # 80002c9c <devintr>
    80002ddc:	892a                	mv	s2,a0
    80002dde:	c501                	beqz	a0,80002de6 <usertrap+0xa8>
  if(p->killed)
    80002de0:	549c                	lw	a5,40(s1)
    80002de2:	c3a1                	beqz	a5,80002e22 <usertrap+0xe4>
    80002de4:	a815                	j	80002e18 <usertrap+0xda>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dea:	5890                	lw	a2,48(s1)
    80002dec:	00005517          	auipc	a0,0x5
    80002df0:	57450513          	addi	a0,a0,1396 # 80008360 <states.0+0x78>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	780080e7          	jalr	1920(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dfc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e00:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e04:	00005517          	auipc	a0,0x5
    80002e08:	58c50513          	addi	a0,a0,1420 # 80008390 <states.0+0xa8>
    80002e0c:	ffffd097          	auipc	ra,0xffffd
    80002e10:	768080e7          	jalr	1896(ra) # 80000574 <printf>
    p->killed = 1;
    80002e14:	4785                	li	a5,1
    80002e16:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e18:	557d                	li	a0,-1
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	83a080e7          	jalr	-1990(ra) # 80002654 <exit>
  if(which_dev == 2)
    80002e22:	4789                	li	a5,2
    80002e24:	f8f910e3          	bne	s2,a5,80002da4 <usertrap+0x66>
    yield();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	40e080e7          	jalr	1038(ra) # 80002236 <yield>
    80002e30:	bf95                	j	80002da4 <usertrap+0x66>
  int which_dev = 0;
    80002e32:	4901                	li	s2,0
    80002e34:	b7d5                	j	80002e18 <usertrap+0xda>

0000000080002e36 <kerneltrap>:
{
    80002e36:	7179                	addi	sp,sp,-48
    80002e38:	f406                	sd	ra,40(sp)
    80002e3a:	f022                	sd	s0,32(sp)
    80002e3c:	ec26                	sd	s1,24(sp)
    80002e3e:	e84a                	sd	s2,16(sp)
    80002e40:	e44e                	sd	s3,8(sp)
    80002e42:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e44:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e48:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e4c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e50:	1004f793          	andi	a5,s1,256
    80002e54:	cb85                	beqz	a5,80002e84 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e56:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e5a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e5c:	ef85                	bnez	a5,80002e94 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	e3e080e7          	jalr	-450(ra) # 80002c9c <devintr>
    80002e66:	cd1d                	beqz	a0,80002ea4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e68:	4789                	li	a5,2
    80002e6a:	06f50a63          	beq	a0,a5,80002ede <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e6e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e72:	10049073          	csrw	sstatus,s1
}
    80002e76:	70a2                	ld	ra,40(sp)
    80002e78:	7402                	ld	s0,32(sp)
    80002e7a:	64e2                	ld	s1,24(sp)
    80002e7c:	6942                	ld	s2,16(sp)
    80002e7e:	69a2                	ld	s3,8(sp)
    80002e80:	6145                	addi	sp,sp,48
    80002e82:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e84:	00005517          	auipc	a0,0x5
    80002e88:	52c50513          	addi	a0,a0,1324 # 800083b0 <states.0+0xc8>
    80002e8c:	ffffd097          	auipc	ra,0xffffd
    80002e90:	69e080e7          	jalr	1694(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	54450513          	addi	a0,a0,1348 # 800083d8 <states.0+0xf0>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	68e080e7          	jalr	1678(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002ea4:	85ce                	mv	a1,s3
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	55250513          	addi	a0,a0,1362 # 800083f8 <states.0+0x110>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6c6080e7          	jalr	1734(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ebe:	00005517          	auipc	a0,0x5
    80002ec2:	54a50513          	addi	a0,a0,1354 # 80008408 <states.0+0x120>
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002ece:	00005517          	auipc	a0,0x5
    80002ed2:	55250513          	addi	a0,a0,1362 # 80008420 <states.0+0x138>
    80002ed6:	ffffd097          	auipc	ra,0xffffd
    80002eda:	654080e7          	jalr	1620(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	ac6080e7          	jalr	-1338(ra) # 800019a4 <myproc>
    80002ee6:	d541                	beqz	a0,80002e6e <kerneltrap+0x38>
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	abc080e7          	jalr	-1348(ra) # 800019a4 <myproc>
    80002ef0:	4d18                	lw	a4,24(a0)
    80002ef2:	4791                	li	a5,4
    80002ef4:	f6f71de3          	bne	a4,a5,80002e6e <kerneltrap+0x38>
    yield();
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	33e080e7          	jalr	830(ra) # 80002236 <yield>
    80002f00:	b7bd                	j	80002e6e <kerneltrap+0x38>

0000000080002f02 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	e426                	sd	s1,8(sp)
    80002f0a:	1000                	addi	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	a96080e7          	jalr	-1386(ra) # 800019a4 <myproc>
  switch (n) {
    80002f16:	4795                	li	a5,5
    80002f18:	0497e763          	bltu	a5,s1,80002f66 <argraw+0x64>
    80002f1c:	048a                	slli	s1,s1,0x2
    80002f1e:	00005717          	auipc	a4,0x5
    80002f22:	53a70713          	addi	a4,a4,1338 # 80008458 <states.0+0x170>
    80002f26:	94ba                	add	s1,s1,a4
    80002f28:	409c                	lw	a5,0(s1)
    80002f2a:	97ba                	add	a5,a5,a4
    80002f2c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f2e:	1f053783          	ld	a5,496(a0)
    80002f32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	64a2                	ld	s1,8(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret
    return p->trapframe->a1;
    80002f3e:	1f053783          	ld	a5,496(a0)
    80002f42:	7fa8                	ld	a0,120(a5)
    80002f44:	bfc5                	j	80002f34 <argraw+0x32>
    return p->trapframe->a2;
    80002f46:	1f053783          	ld	a5,496(a0)
    80002f4a:	63c8                	ld	a0,128(a5)
    80002f4c:	b7e5                	j	80002f34 <argraw+0x32>
    return p->trapframe->a3;
    80002f4e:	1f053783          	ld	a5,496(a0)
    80002f52:	67c8                	ld	a0,136(a5)
    80002f54:	b7c5                	j	80002f34 <argraw+0x32>
    return p->trapframe->a4;
    80002f56:	1f053783          	ld	a5,496(a0)
    80002f5a:	6bc8                	ld	a0,144(a5)
    80002f5c:	bfe1                	j	80002f34 <argraw+0x32>
    return p->trapframe->a5;
    80002f5e:	1f053783          	ld	a5,496(a0)
    80002f62:	6fc8                	ld	a0,152(a5)
    80002f64:	bfc1                	j	80002f34 <argraw+0x32>
  panic("argraw");
    80002f66:	00005517          	auipc	a0,0x5
    80002f6a:	4ca50513          	addi	a0,a0,1226 # 80008430 <states.0+0x148>
    80002f6e:	ffffd097          	auipc	ra,0xffffd
    80002f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>

0000000080002f76 <fetchaddr>:
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	e426                	sd	s1,8(sp)
    80002f7e:	e04a                	sd	s2,0(sp)
    80002f80:	1000                	addi	s0,sp,32
    80002f82:	84aa                	mv	s1,a0
    80002f84:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	a1e080e7          	jalr	-1506(ra) # 800019a4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f8e:	1e053783          	ld	a5,480(a0)
    80002f92:	02f4f963          	bgeu	s1,a5,80002fc4 <fetchaddr+0x4e>
    80002f96:	00848713          	addi	a4,s1,8
    80002f9a:	02e7e763          	bltu	a5,a4,80002fc8 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f9e:	46a1                	li	a3,8
    80002fa0:	8626                	mv	a2,s1
    80002fa2:	85ca                	mv	a1,s2
    80002fa4:	1e853503          	ld	a0,488(a0)
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	746080e7          	jalr	1862(ra) # 800016ee <copyin>
    80002fb0:	00a03533          	snez	a0,a0
    80002fb4:	40a00533          	neg	a0,a0
}
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6902                	ld	s2,0(sp)
    80002fc0:	6105                	addi	sp,sp,32
    80002fc2:	8082                	ret
    return -1;
    80002fc4:	557d                	li	a0,-1
    80002fc6:	bfcd                	j	80002fb8 <fetchaddr+0x42>
    80002fc8:	557d                	li	a0,-1
    80002fca:	b7fd                	j	80002fb8 <fetchaddr+0x42>

0000000080002fcc <fetchstr>:
{
    80002fcc:	7179                	addi	sp,sp,-48
    80002fce:	f406                	sd	ra,40(sp)
    80002fd0:	f022                	sd	s0,32(sp)
    80002fd2:	ec26                	sd	s1,24(sp)
    80002fd4:	e84a                	sd	s2,16(sp)
    80002fd6:	e44e                	sd	s3,8(sp)
    80002fd8:	1800                	addi	s0,sp,48
    80002fda:	892a                	mv	s2,a0
    80002fdc:	84ae                	mv	s1,a1
    80002fde:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	9c4080e7          	jalr	-1596(ra) # 800019a4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fe8:	86ce                	mv	a3,s3
    80002fea:	864a                	mv	a2,s2
    80002fec:	85a6                	mv	a1,s1
    80002fee:	1e853503          	ld	a0,488(a0)
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	78a080e7          	jalr	1930(ra) # 8000177c <copyinstr>
  if(err < 0)
    80002ffa:	00054763          	bltz	a0,80003008 <fetchstr+0x3c>
  return strlen(buf);
    80002ffe:	8526                	mv	a0,s1
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	e66080e7          	jalr	-410(ra) # 80000e66 <strlen>
}
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6145                	addi	sp,sp,48
    80003014:	8082                	ret

0000000080003016 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003022:	00000097          	auipc	ra,0x0
    80003026:	ee0080e7          	jalr	-288(ra) # 80002f02 <argraw>
    8000302a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000302c:	4501                	li	a0,0
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	1000                	addi	s0,sp,32
    80003042:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003044:	00000097          	auipc	ra,0x0
    80003048:	ebe080e7          	jalr	-322(ra) # 80002f02 <argraw>
    8000304c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000304e:	4501                	li	a0,0
    80003050:	60e2                	ld	ra,24(sp)
    80003052:	6442                	ld	s0,16(sp)
    80003054:	64a2                	ld	s1,8(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret

000000008000305a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	e04a                	sd	s2,0(sp)
    80003064:	1000                	addi	s0,sp,32
    80003066:	84ae                	mv	s1,a1
    80003068:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000306a:	00000097          	auipc	ra,0x0
    8000306e:	e98080e7          	jalr	-360(ra) # 80002f02 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003072:	864a                	mv	a2,s2
    80003074:	85a6                	mv	a1,s1
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	f56080e7          	jalr	-170(ra) # 80002fcc <fetchstr>
}
    8000307e:	60e2                	ld	ra,24(sp)
    80003080:	6442                	ld	s0,16(sp)
    80003082:	64a2                	ld	s1,8(sp)
    80003084:	6902                	ld	s2,0(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <syscall>:
[SYS_sigret]   sys_sigret, // ADDED Q2.1.5
};

void
syscall(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	e04a                	sd	s2,0(sp)
    80003094:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	90e080e7          	jalr	-1778(ra) # 800019a4 <myproc>
    8000309e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030a0:	1f053903          	ld	s2,496(a0)
    800030a4:	0a893783          	ld	a5,168(s2)
    800030a8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030ac:	37fd                	addiw	a5,a5,-1
    800030ae:	475d                	li	a4,23
    800030b0:	00f76f63          	bltu	a4,a5,800030ce <syscall+0x44>
    800030b4:	00369713          	slli	a4,a3,0x3
    800030b8:	00005797          	auipc	a5,0x5
    800030bc:	3b878793          	addi	a5,a5,952 # 80008470 <syscalls>
    800030c0:	97ba                	add	a5,a5,a4
    800030c2:	639c                	ld	a5,0(a5)
    800030c4:	c789                	beqz	a5,800030ce <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030c6:	9782                	jalr	a5
    800030c8:	06a93823          	sd	a0,112(s2)
    800030cc:	a005                	j	800030ec <syscall+0x62>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030ce:	2f048613          	addi	a2,s1,752
    800030d2:	588c                	lw	a1,48(s1)
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	36450513          	addi	a0,a0,868 # 80008438 <states.0+0x150>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	498080e7          	jalr	1176(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030e4:	1f04b783          	ld	a5,496(s1)
    800030e8:	577d                	li	a4,-1
    800030ea:	fbb8                	sd	a4,112(a5)
  }
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6902                	ld	s2,0(sp)
    800030f4:	6105                	addi	sp,sp,32
    800030f6:	8082                	ret

00000000800030f8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030f8:	1101                	addi	sp,sp,-32
    800030fa:	ec06                	sd	ra,24(sp)
    800030fc:	e822                	sd	s0,16(sp)
    800030fe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003100:	fec40593          	addi	a1,s0,-20
    80003104:	4501                	li	a0,0
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	f10080e7          	jalr	-240(ra) # 80003016 <argint>
    return -1;
    8000310e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003110:	00054963          	bltz	a0,80003122 <sys_exit+0x2a>
  exit(n);
    80003114:	fec42503          	lw	a0,-20(s0)
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	53c080e7          	jalr	1340(ra) # 80002654 <exit>
  return 0;  // not reached
    80003120:	4781                	li	a5,0
}
    80003122:	853e                	mv	a0,a5
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000312c:	1141                	addi	sp,sp,-16
    8000312e:	e406                	sd	ra,8(sp)
    80003130:	e022                	sd	s0,0(sp)
    80003132:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	870080e7          	jalr	-1936(ra) # 800019a4 <myproc>
}
    8000313c:	5908                	lw	a0,48(a0)
    8000313e:	60a2                	ld	ra,8(sp)
    80003140:	6402                	ld	s0,0(sp)
    80003142:	0141                	addi	sp,sp,16
    80003144:	8082                	ret

0000000080003146 <sys_fork>:

uint64
sys_fork(void)
{
    80003146:	1141                	addi	sp,sp,-16
    80003148:	e406                	sd	ra,8(sp)
    8000314a:	e022                	sd	s0,0(sp)
    8000314c:	0800                	addi	s0,sp,16
  return fork();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	cae080e7          	jalr	-850(ra) # 80001dfc <fork>
}
    80003156:	60a2                	ld	ra,8(sp)
    80003158:	6402                	ld	s0,0(sp)
    8000315a:	0141                	addi	sp,sp,16
    8000315c:	8082                	ret

000000008000315e <sys_wait>:

uint64
sys_wait(void)
{
    8000315e:	1101                	addi	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003166:	fe840593          	addi	a1,s0,-24
    8000316a:	4501                	li	a0,0
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	ecc080e7          	jalr	-308(ra) # 80003038 <argaddr>
    80003174:	87aa                	mv	a5,a0
    return -1;
    80003176:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003178:	0007c863          	bltz	a5,80003188 <sys_wait+0x2a>
  return wait(p);
    8000317c:	fe843503          	ld	a0,-24(s0)
    80003180:	fffff097          	auipc	ra,0xfffff
    80003184:	2d6080e7          	jalr	726(ra) # 80002456 <wait>
}
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003190:	7179                	addi	sp,sp,-48
    80003192:	f406                	sd	ra,40(sp)
    80003194:	f022                	sd	s0,32(sp)
    80003196:	ec26                	sd	s1,24(sp)
    80003198:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000319a:	fdc40593          	addi	a1,s0,-36
    8000319e:	4501                	li	a0,0
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	e76080e7          	jalr	-394(ra) # 80003016 <argint>
    return -1;
    800031a8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800031aa:	02054063          	bltz	a0,800031ca <sys_sbrk+0x3a>
  addr = myproc()->sz;
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	7f6080e7          	jalr	2038(ra) # 800019a4 <myproc>
    800031b6:	1e052483          	lw	s1,480(a0)
  if(growproc(n) < 0)
    800031ba:	fdc42503          	lw	a0,-36(s0)
    800031be:	fffff097          	auipc	ra,0xfffff
    800031c2:	bc4080e7          	jalr	-1084(ra) # 80001d82 <growproc>
    800031c6:	00054863          	bltz	a0,800031d6 <sys_sbrk+0x46>
    return -1;
  return addr;
}
    800031ca:	8526                	mv	a0,s1
    800031cc:	70a2                	ld	ra,40(sp)
    800031ce:	7402                	ld	s0,32(sp)
    800031d0:	64e2                	ld	s1,24(sp)
    800031d2:	6145                	addi	sp,sp,48
    800031d4:	8082                	ret
    return -1;
    800031d6:	54fd                	li	s1,-1
    800031d8:	bfcd                	j	800031ca <sys_sbrk+0x3a>

00000000800031da <sys_sleep>:

uint64
sys_sleep(void)
{
    800031da:	7139                	addi	sp,sp,-64
    800031dc:	fc06                	sd	ra,56(sp)
    800031de:	f822                	sd	s0,48(sp)
    800031e0:	f426                	sd	s1,40(sp)
    800031e2:	f04a                	sd	s2,32(sp)
    800031e4:	ec4e                	sd	s3,24(sp)
    800031e6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031e8:	fcc40593          	addi	a1,s0,-52
    800031ec:	4501                	li	a0,0
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	e28080e7          	jalr	-472(ra) # 80003016 <argint>
    return -1;
    800031f6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031f8:	06054563          	bltz	a0,80003262 <sys_sleep+0x88>
  acquire(&tickslock);
    800031fc:	0001a517          	auipc	a0,0x1a
    80003200:	4d450513          	addi	a0,a0,1236 # 8001d6d0 <tickslock>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	9be080e7          	jalr	-1602(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000320c:	00006917          	auipc	s2,0x6
    80003210:	e2492903          	lw	s2,-476(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003214:	fcc42783          	lw	a5,-52(s0)
    80003218:	cf85                	beqz	a5,80003250 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000321a:	0001a997          	auipc	s3,0x1a
    8000321e:	4b698993          	addi	s3,s3,1206 # 8001d6d0 <tickslock>
    80003222:	00006497          	auipc	s1,0x6
    80003226:	e0e48493          	addi	s1,s1,-498 # 80009030 <ticks>
    if(myproc()->killed){
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	77a080e7          	jalr	1914(ra) # 800019a4 <myproc>
    80003232:	551c                	lw	a5,40(a0)
    80003234:	ef9d                	bnez	a5,80003272 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003236:	85ce                	mv	a1,s3
    80003238:	8526                	mv	a0,s1
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	1b8080e7          	jalr	440(ra) # 800023f2 <sleep>
  while(ticks - ticks0 < n){
    80003242:	409c                	lw	a5,0(s1)
    80003244:	412787bb          	subw	a5,a5,s2
    80003248:	fcc42703          	lw	a4,-52(s0)
    8000324c:	fce7efe3          	bltu	a5,a4,8000322a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003250:	0001a517          	auipc	a0,0x1a
    80003254:	48050513          	addi	a0,a0,1152 # 8001d6d0 <tickslock>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	a30080e7          	jalr	-1488(ra) # 80000c88 <release>
  return 0;
    80003260:	4781                	li	a5,0
}
    80003262:	853e                	mv	a0,a5
    80003264:	70e2                	ld	ra,56(sp)
    80003266:	7442                	ld	s0,48(sp)
    80003268:	74a2                	ld	s1,40(sp)
    8000326a:	7902                	ld	s2,32(sp)
    8000326c:	69e2                	ld	s3,24(sp)
    8000326e:	6121                	addi	sp,sp,64
    80003270:	8082                	ret
      release(&tickslock);
    80003272:	0001a517          	auipc	a0,0x1a
    80003276:	45e50513          	addi	a0,a0,1118 # 8001d6d0 <tickslock>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a0e080e7          	jalr	-1522(ra) # 80000c88 <release>
      return -1;
    80003282:	57fd                	li	a5,-1
    80003284:	bff9                	j	80003262 <sys_sleep+0x88>

0000000080003286 <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    80003286:	1101                	addi	sp,sp,-32
    80003288:	ec06                	sd	ra,24(sp)
    8000328a:	e822                	sd	s0,16(sp)
    8000328c:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    8000328e:	fec40593          	addi	a1,s0,-20
    80003292:	4501                	li	a0,0
    80003294:	00000097          	auipc	ra,0x0
    80003298:	d82080e7          	jalr	-638(ra) # 80003016 <argint>
    return -1;
    8000329c:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    8000329e:	02054563          	bltz	a0,800032c8 <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    800032a2:	fe840593          	addi	a1,s0,-24
    800032a6:	4505                	li	a0,1
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	d6e080e7          	jalr	-658(ra) # 80003016 <argint>
    return -1;
    800032b0:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    800032b2:	00054b63          	bltz	a0,800032c8 <sys_kill+0x42>

  return kill(pid, signum);
    800032b6:	fe842583          	lw	a1,-24(s0)
    800032ba:	fec42503          	lw	a0,-20(s0)
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	46c080e7          	jalr	1132(ra) # 8000272a <kill>
    800032c6:	87aa                	mv	a5,a0
}
    800032c8:	853e                	mv	a0,a5
    800032ca:	60e2                	ld	ra,24(sp)
    800032cc:	6442                	ld	s0,16(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret

00000000800032d2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	e426                	sd	s1,8(sp)
    800032da:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032dc:	0001a517          	auipc	a0,0x1a
    800032e0:	3f450513          	addi	a0,a0,1012 # 8001d6d0 <tickslock>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	8de080e7          	jalr	-1826(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800032ec:	00006497          	auipc	s1,0x6
    800032f0:	d444a483          	lw	s1,-700(s1) # 80009030 <ticks>
  release(&tickslock);
    800032f4:	0001a517          	auipc	a0,0x1a
    800032f8:	3dc50513          	addi	a0,a0,988 # 8001d6d0 <tickslock>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	98c080e7          	jalr	-1652(ra) # 80000c88 <release>
  return xticks;
}
    80003304:	02049513          	slli	a0,s1,0x20
    80003308:	9101                	srli	a0,a0,0x20
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    80003314:	1101                	addi	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    8000331c:	fec40593          	addi	a1,s0,-20
    80003320:	4501                	li	a0,0
    80003322:	00000097          	auipc	ra,0x0
    80003326:	cf4080e7          	jalr	-780(ra) # 80003016 <argint>
    8000332a:	87aa                	mv	a5,a0
    return -1;
    8000332c:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    8000332e:	0007ca63          	bltz	a5,80003342 <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    80003332:	fec42503          	lw	a0,-20(s0)
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	5d0080e7          	jalr	1488(ra) # 80002906 <sigprocmask>
    8000333e:	1502                	slli	a0,a0,0x20
    80003340:	9101                	srli	a0,a0,0x20
}
    80003342:	60e2                	ld	ra,24(sp)
    80003344:	6442                	ld	s0,16(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret

000000008000334a <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    8000334a:	7179                	addi	sp,sp,-48
    8000334c:	f406                	sd	ra,40(sp)
    8000334e:	f022                	sd	s0,32(sp)
    80003350:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    80003352:	fec40593          	addi	a1,s0,-20
    80003356:	4501                	li	a0,0
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	cbe080e7          	jalr	-834(ra) # 80003016 <argint>
    return -1;
    80003360:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80003362:	04054163          	bltz	a0,800033a4 <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    80003366:	fe040593          	addi	a1,s0,-32
    8000336a:	4505                	li	a0,1
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	ccc080e7          	jalr	-820(ra) # 80003038 <argaddr>
    return -1;
    80003374:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    80003376:	02054763          	bltz	a0,800033a4 <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    8000337a:	fd840593          	addi	a1,s0,-40
    8000337e:	4509                	li	a0,2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	cb8080e7          	jalr	-840(ra) # 80003038 <argaddr>
    return -1;
    80003388:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    8000338a:	00054d63          	bltz	a0,800033a4 <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    8000338e:	fd843603          	ld	a2,-40(s0)
    80003392:	fe043583          	ld	a1,-32(s0)
    80003396:	fec42503          	lw	a0,-20(s0)
    8000339a:	fffff097          	auipc	ra,0xfffff
    8000339e:	5cc080e7          	jalr	1484(ra) # 80002966 <sigaction>
    800033a2:	87aa                	mv	a5,a0
}
    800033a4:	853e                	mv	a0,a5
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	6145                	addi	sp,sp,48
    800033ac:	8082                	ret

00000000800033ae <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    800033ae:	1141                	addi	sp,sp,-16
    800033b0:	e406                	sd	ra,8(sp)
    800033b2:	e022                	sd	s0,0(sp)
    800033b4:	0800                	addi	s0,sp,16
  sigret();
    800033b6:	fffff097          	auipc	ra,0xfffff
    800033ba:	6f0080e7          	jalr	1776(ra) # 80002aa6 <sigret>
  return 0;
}
    800033be:	4501                	li	a0,0
    800033c0:	60a2                	ld	ra,8(sp)
    800033c2:	6402                	ld	s0,0(sp)
    800033c4:	0141                	addi	sp,sp,16
    800033c6:	8082                	ret

00000000800033c8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033c8:	7179                	addi	sp,sp,-48
    800033ca:	f406                	sd	ra,40(sp)
    800033cc:	f022                	sd	s0,32(sp)
    800033ce:	ec26                	sd	s1,24(sp)
    800033d0:	e84a                	sd	s2,16(sp)
    800033d2:	e44e                	sd	s3,8(sp)
    800033d4:	e052                	sd	s4,0(sp)
    800033d6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033d8:	00005597          	auipc	a1,0x5
    800033dc:	16058593          	addi	a1,a1,352 # 80008538 <syscalls+0xc8>
    800033e0:	0001a517          	auipc	a0,0x1a
    800033e4:	30850513          	addi	a0,a0,776 # 8001d6e8 <bcache>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	74a080e7          	jalr	1866(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033f0:	00022797          	auipc	a5,0x22
    800033f4:	2f878793          	addi	a5,a5,760 # 800256e8 <bcache+0x8000>
    800033f8:	00022717          	auipc	a4,0x22
    800033fc:	55870713          	addi	a4,a4,1368 # 80025950 <bcache+0x8268>
    80003400:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003404:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003408:	0001a497          	auipc	s1,0x1a
    8000340c:	2f848493          	addi	s1,s1,760 # 8001d700 <bcache+0x18>
    b->next = bcache.head.next;
    80003410:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003412:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003414:	00005a17          	auipc	s4,0x5
    80003418:	12ca0a13          	addi	s4,s4,300 # 80008540 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000341c:	2b893783          	ld	a5,696(s2)
    80003420:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003422:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003426:	85d2                	mv	a1,s4
    80003428:	01048513          	addi	a0,s1,16
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	4c2080e7          	jalr	1218(ra) # 800048ee <initsleeplock>
    bcache.head.next->prev = b;
    80003434:	2b893783          	ld	a5,696(s2)
    80003438:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000343a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000343e:	45848493          	addi	s1,s1,1112
    80003442:	fd349de3          	bne	s1,s3,8000341c <binit+0x54>
  }
}
    80003446:	70a2                	ld	ra,40(sp)
    80003448:	7402                	ld	s0,32(sp)
    8000344a:	64e2                	ld	s1,24(sp)
    8000344c:	6942                	ld	s2,16(sp)
    8000344e:	69a2                	ld	s3,8(sp)
    80003450:	6a02                	ld	s4,0(sp)
    80003452:	6145                	addi	sp,sp,48
    80003454:	8082                	ret

0000000080003456 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003456:	7179                	addi	sp,sp,-48
    80003458:	f406                	sd	ra,40(sp)
    8000345a:	f022                	sd	s0,32(sp)
    8000345c:	ec26                	sd	s1,24(sp)
    8000345e:	e84a                	sd	s2,16(sp)
    80003460:	e44e                	sd	s3,8(sp)
    80003462:	1800                	addi	s0,sp,48
    80003464:	892a                	mv	s2,a0
    80003466:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003468:	0001a517          	auipc	a0,0x1a
    8000346c:	28050513          	addi	a0,a0,640 # 8001d6e8 <bcache>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	752080e7          	jalr	1874(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003478:	00022497          	auipc	s1,0x22
    8000347c:	5284b483          	ld	s1,1320(s1) # 800259a0 <bcache+0x82b8>
    80003480:	00022797          	auipc	a5,0x22
    80003484:	4d078793          	addi	a5,a5,1232 # 80025950 <bcache+0x8268>
    80003488:	02f48f63          	beq	s1,a5,800034c6 <bread+0x70>
    8000348c:	873e                	mv	a4,a5
    8000348e:	a021                	j	80003496 <bread+0x40>
    80003490:	68a4                	ld	s1,80(s1)
    80003492:	02e48a63          	beq	s1,a4,800034c6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003496:	449c                	lw	a5,8(s1)
    80003498:	ff279ce3          	bne	a5,s2,80003490 <bread+0x3a>
    8000349c:	44dc                	lw	a5,12(s1)
    8000349e:	ff3799e3          	bne	a5,s3,80003490 <bread+0x3a>
      b->refcnt++;
    800034a2:	40bc                	lw	a5,64(s1)
    800034a4:	2785                	addiw	a5,a5,1
    800034a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034a8:	0001a517          	auipc	a0,0x1a
    800034ac:	24050513          	addi	a0,a0,576 # 8001d6e8 <bcache>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	7d8080e7          	jalr	2008(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    800034b8:	01048513          	addi	a0,s1,16
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	46c080e7          	jalr	1132(ra) # 80004928 <acquiresleep>
      return b;
    800034c4:	a8b9                	j	80003522 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c6:	00022497          	auipc	s1,0x22
    800034ca:	4d24b483          	ld	s1,1234(s1) # 80025998 <bcache+0x82b0>
    800034ce:	00022797          	auipc	a5,0x22
    800034d2:	48278793          	addi	a5,a5,1154 # 80025950 <bcache+0x8268>
    800034d6:	00f48863          	beq	s1,a5,800034e6 <bread+0x90>
    800034da:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034dc:	40bc                	lw	a5,64(s1)
    800034de:	cf81                	beqz	a5,800034f6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034e0:	64a4                	ld	s1,72(s1)
    800034e2:	fee49de3          	bne	s1,a4,800034dc <bread+0x86>
  panic("bget: no buffers");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	06250513          	addi	a0,a0,98 # 80008548 <syscalls+0xd8>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	03c080e7          	jalr	60(ra) # 8000052a <panic>
      b->dev = dev;
    800034f6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034fa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034fe:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003502:	4785                	li	a5,1
    80003504:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003506:	0001a517          	auipc	a0,0x1a
    8000350a:	1e250513          	addi	a0,a0,482 # 8001d6e8 <bcache>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	77a080e7          	jalr	1914(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003516:	01048513          	addi	a0,s1,16
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	40e080e7          	jalr	1038(ra) # 80004928 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003522:	409c                	lw	a5,0(s1)
    80003524:	cb89                	beqz	a5,80003536 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003526:	8526                	mv	a0,s1
    80003528:	70a2                	ld	ra,40(sp)
    8000352a:	7402                	ld	s0,32(sp)
    8000352c:	64e2                	ld	s1,24(sp)
    8000352e:	6942                	ld	s2,16(sp)
    80003530:	69a2                	ld	s3,8(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    virtio_disk_rw(b, 0);
    80003536:	4581                	li	a1,0
    80003538:	8526                	mv	a0,s1
    8000353a:	00003097          	auipc	ra,0x3
    8000353e:	f4c080e7          	jalr	-180(ra) # 80006486 <virtio_disk_rw>
    b->valid = 1;
    80003542:	4785                	li	a5,1
    80003544:	c09c                	sw	a5,0(s1)
  return b;
    80003546:	b7c5                	j	80003526 <bread+0xd0>

0000000080003548 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003548:	1101                	addi	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	e426                	sd	s1,8(sp)
    80003550:	1000                	addi	s0,sp,32
    80003552:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003554:	0541                	addi	a0,a0,16
    80003556:	00001097          	auipc	ra,0x1
    8000355a:	46c080e7          	jalr	1132(ra) # 800049c2 <holdingsleep>
    8000355e:	cd01                	beqz	a0,80003576 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003560:	4585                	li	a1,1
    80003562:	8526                	mv	a0,s1
    80003564:	00003097          	auipc	ra,0x3
    80003568:	f22080e7          	jalr	-222(ra) # 80006486 <virtio_disk_rw>
}
    8000356c:	60e2                	ld	ra,24(sp)
    8000356e:	6442                	ld	s0,16(sp)
    80003570:	64a2                	ld	s1,8(sp)
    80003572:	6105                	addi	sp,sp,32
    80003574:	8082                	ret
    panic("bwrite");
    80003576:	00005517          	auipc	a0,0x5
    8000357a:	fea50513          	addi	a0,a0,-22 # 80008560 <syscalls+0xf0>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	fac080e7          	jalr	-84(ra) # 8000052a <panic>

0000000080003586 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003586:	1101                	addi	sp,sp,-32
    80003588:	ec06                	sd	ra,24(sp)
    8000358a:	e822                	sd	s0,16(sp)
    8000358c:	e426                	sd	s1,8(sp)
    8000358e:	e04a                	sd	s2,0(sp)
    80003590:	1000                	addi	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003594:	01050913          	addi	s2,a0,16
    80003598:	854a                	mv	a0,s2
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	428080e7          	jalr	1064(ra) # 800049c2 <holdingsleep>
    800035a2:	c92d                	beqz	a0,80003614 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	3d8080e7          	jalr	984(ra) # 8000497e <releasesleep>

  acquire(&bcache.lock);
    800035ae:	0001a517          	auipc	a0,0x1a
    800035b2:	13a50513          	addi	a0,a0,314 # 8001d6e8 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	60c080e7          	jalr	1548(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800035be:	40bc                	lw	a5,64(s1)
    800035c0:	37fd                	addiw	a5,a5,-1
    800035c2:	0007871b          	sext.w	a4,a5
    800035c6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035c8:	eb05                	bnez	a4,800035f8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035ca:	68bc                	ld	a5,80(s1)
    800035cc:	64b8                	ld	a4,72(s1)
    800035ce:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035d0:	64bc                	ld	a5,72(s1)
    800035d2:	68b8                	ld	a4,80(s1)
    800035d4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035d6:	00022797          	auipc	a5,0x22
    800035da:	11278793          	addi	a5,a5,274 # 800256e8 <bcache+0x8000>
    800035de:	2b87b703          	ld	a4,696(a5)
    800035e2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035e4:	00022717          	auipc	a4,0x22
    800035e8:	36c70713          	addi	a4,a4,876 # 80025950 <bcache+0x8268>
    800035ec:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035ee:	2b87b703          	ld	a4,696(a5)
    800035f2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035f4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035f8:	0001a517          	auipc	a0,0x1a
    800035fc:	0f050513          	addi	a0,a0,240 # 8001d6e8 <bcache>
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	688080e7          	jalr	1672(ra) # 80000c88 <release>
}
    80003608:	60e2                	ld	ra,24(sp)
    8000360a:	6442                	ld	s0,16(sp)
    8000360c:	64a2                	ld	s1,8(sp)
    8000360e:	6902                	ld	s2,0(sp)
    80003610:	6105                	addi	sp,sp,32
    80003612:	8082                	ret
    panic("brelse");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	f5450513          	addi	a0,a0,-172 # 80008568 <syscalls+0xf8>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f0e080e7          	jalr	-242(ra) # 8000052a <panic>

0000000080003624 <bpin>:

void
bpin(struct buf *b) {
    80003624:	1101                	addi	sp,sp,-32
    80003626:	ec06                	sd	ra,24(sp)
    80003628:	e822                	sd	s0,16(sp)
    8000362a:	e426                	sd	s1,8(sp)
    8000362c:	1000                	addi	s0,sp,32
    8000362e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003630:	0001a517          	auipc	a0,0x1a
    80003634:	0b850513          	addi	a0,a0,184 # 8001d6e8 <bcache>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	58a080e7          	jalr	1418(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	2785                	addiw	a5,a5,1
    80003644:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003646:	0001a517          	auipc	a0,0x1a
    8000364a:	0a250513          	addi	a0,a0,162 # 8001d6e8 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	63a080e7          	jalr	1594(ra) # 80000c88 <release>
}
    80003656:	60e2                	ld	ra,24(sp)
    80003658:	6442                	ld	s0,16(sp)
    8000365a:	64a2                	ld	s1,8(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret

0000000080003660 <bunpin>:

void
bunpin(struct buf *b) {
    80003660:	1101                	addi	sp,sp,-32
    80003662:	ec06                	sd	ra,24(sp)
    80003664:	e822                	sd	s0,16(sp)
    80003666:	e426                	sd	s1,8(sp)
    80003668:	1000                	addi	s0,sp,32
    8000366a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000366c:	0001a517          	auipc	a0,0x1a
    80003670:	07c50513          	addi	a0,a0,124 # 8001d6e8 <bcache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	54e080e7          	jalr	1358(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000367c:	40bc                	lw	a5,64(s1)
    8000367e:	37fd                	addiw	a5,a5,-1
    80003680:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003682:	0001a517          	auipc	a0,0x1a
    80003686:	06650513          	addi	a0,a0,102 # 8001d6e8 <bcache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	5fe080e7          	jalr	1534(ra) # 80000c88 <release>
}
    80003692:	60e2                	ld	ra,24(sp)
    80003694:	6442                	ld	s0,16(sp)
    80003696:	64a2                	ld	s1,8(sp)
    80003698:	6105                	addi	sp,sp,32
    8000369a:	8082                	ret

000000008000369c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	e04a                	sd	s2,0(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036aa:	00d5d59b          	srliw	a1,a1,0xd
    800036ae:	00022797          	auipc	a5,0x22
    800036b2:	7167a783          	lw	a5,1814(a5) # 80025dc4 <sb+0x1c>
    800036b6:	9dbd                	addw	a1,a1,a5
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	d9e080e7          	jalr	-610(ra) # 80003456 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036c0:	0074f713          	andi	a4,s1,7
    800036c4:	4785                	li	a5,1
    800036c6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036ca:	14ce                	slli	s1,s1,0x33
    800036cc:	90d9                	srli	s1,s1,0x36
    800036ce:	00950733          	add	a4,a0,s1
    800036d2:	05874703          	lbu	a4,88(a4)
    800036d6:	00e7f6b3          	and	a3,a5,a4
    800036da:	c69d                	beqz	a3,80003708 <bfree+0x6c>
    800036dc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036de:	94aa                	add	s1,s1,a0
    800036e0:	fff7c793          	not	a5,a5
    800036e4:	8ff9                	and	a5,a5,a4
    800036e6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036ea:	00001097          	auipc	ra,0x1
    800036ee:	11e080e7          	jalr	286(ra) # 80004808 <log_write>
  brelse(bp);
    800036f2:	854a                	mv	a0,s2
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	e92080e7          	jalr	-366(ra) # 80003586 <brelse>
}
    800036fc:	60e2                	ld	ra,24(sp)
    800036fe:	6442                	ld	s0,16(sp)
    80003700:	64a2                	ld	s1,8(sp)
    80003702:	6902                	ld	s2,0(sp)
    80003704:	6105                	addi	sp,sp,32
    80003706:	8082                	ret
    panic("freeing free block");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	e6850513          	addi	a0,a0,-408 # 80008570 <syscalls+0x100>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e1a080e7          	jalr	-486(ra) # 8000052a <panic>

0000000080003718 <balloc>:
{
    80003718:	711d                	addi	sp,sp,-96
    8000371a:	ec86                	sd	ra,88(sp)
    8000371c:	e8a2                	sd	s0,80(sp)
    8000371e:	e4a6                	sd	s1,72(sp)
    80003720:	e0ca                	sd	s2,64(sp)
    80003722:	fc4e                	sd	s3,56(sp)
    80003724:	f852                	sd	s4,48(sp)
    80003726:	f456                	sd	s5,40(sp)
    80003728:	f05a                	sd	s6,32(sp)
    8000372a:	ec5e                	sd	s7,24(sp)
    8000372c:	e862                	sd	s8,16(sp)
    8000372e:	e466                	sd	s9,8(sp)
    80003730:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003732:	00022797          	auipc	a5,0x22
    80003736:	67a7a783          	lw	a5,1658(a5) # 80025dac <sb+0x4>
    8000373a:	cbd1                	beqz	a5,800037ce <balloc+0xb6>
    8000373c:	8baa                	mv	s7,a0
    8000373e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003740:	00022b17          	auipc	s6,0x22
    80003744:	668b0b13          	addi	s6,s6,1640 # 80025da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003748:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000374a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000374e:	6c89                	lui	s9,0x2
    80003750:	a831                	j	8000376c <balloc+0x54>
    brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	e32080e7          	jalr	-462(ra) # 80003586 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000375c:	015c87bb          	addw	a5,s9,s5
    80003760:	00078a9b          	sext.w	s5,a5
    80003764:	004b2703          	lw	a4,4(s6)
    80003768:	06eaf363          	bgeu	s5,a4,800037ce <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000376c:	41fad79b          	sraiw	a5,s5,0x1f
    80003770:	0137d79b          	srliw	a5,a5,0x13
    80003774:	015787bb          	addw	a5,a5,s5
    80003778:	40d7d79b          	sraiw	a5,a5,0xd
    8000377c:	01cb2583          	lw	a1,28(s6)
    80003780:	9dbd                	addw	a1,a1,a5
    80003782:	855e                	mv	a0,s7
    80003784:	00000097          	auipc	ra,0x0
    80003788:	cd2080e7          	jalr	-814(ra) # 80003456 <bread>
    8000378c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000378e:	004b2503          	lw	a0,4(s6)
    80003792:	000a849b          	sext.w	s1,s5
    80003796:	8662                	mv	a2,s8
    80003798:	faa4fde3          	bgeu	s1,a0,80003752 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000379c:	41f6579b          	sraiw	a5,a2,0x1f
    800037a0:	01d7d69b          	srliw	a3,a5,0x1d
    800037a4:	00c6873b          	addw	a4,a3,a2
    800037a8:	00777793          	andi	a5,a4,7
    800037ac:	9f95                	subw	a5,a5,a3
    800037ae:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037b2:	4037571b          	sraiw	a4,a4,0x3
    800037b6:	00e906b3          	add	a3,s2,a4
    800037ba:	0586c683          	lbu	a3,88(a3)
    800037be:	00d7f5b3          	and	a1,a5,a3
    800037c2:	cd91                	beqz	a1,800037de <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c4:	2605                	addiw	a2,a2,1
    800037c6:	2485                	addiw	s1,s1,1
    800037c8:	fd4618e3          	bne	a2,s4,80003798 <balloc+0x80>
    800037cc:	b759                	j	80003752 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037ce:	00005517          	auipc	a0,0x5
    800037d2:	dba50513          	addi	a0,a0,-582 # 80008588 <syscalls+0x118>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	d54080e7          	jalr	-684(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037de:	974a                	add	a4,a4,s2
    800037e0:	8fd5                	or	a5,a5,a3
    800037e2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	020080e7          	jalr	32(ra) # 80004808 <log_write>
        brelse(bp);
    800037f0:	854a                	mv	a0,s2
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	d94080e7          	jalr	-620(ra) # 80003586 <brelse>
  bp = bread(dev, bno);
    800037fa:	85a6                	mv	a1,s1
    800037fc:	855e                	mv	a0,s7
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	c58080e7          	jalr	-936(ra) # 80003456 <bread>
    80003806:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003808:	40000613          	li	a2,1024
    8000380c:	4581                	li	a1,0
    8000380e:	05850513          	addi	a0,a0,88
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	4d0080e7          	jalr	1232(ra) # 80000ce2 <memset>
  log_write(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	fec080e7          	jalr	-20(ra) # 80004808 <log_write>
  brelse(bp);
    80003824:	854a                	mv	a0,s2
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	d60080e7          	jalr	-672(ra) # 80003586 <brelse>
}
    8000382e:	8526                	mv	a0,s1
    80003830:	60e6                	ld	ra,88(sp)
    80003832:	6446                	ld	s0,80(sp)
    80003834:	64a6                	ld	s1,72(sp)
    80003836:	6906                	ld	s2,64(sp)
    80003838:	79e2                	ld	s3,56(sp)
    8000383a:	7a42                	ld	s4,48(sp)
    8000383c:	7aa2                	ld	s5,40(sp)
    8000383e:	7b02                	ld	s6,32(sp)
    80003840:	6be2                	ld	s7,24(sp)
    80003842:	6c42                	ld	s8,16(sp)
    80003844:	6ca2                	ld	s9,8(sp)
    80003846:	6125                	addi	sp,sp,96
    80003848:	8082                	ret

000000008000384a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000384a:	7179                	addi	sp,sp,-48
    8000384c:	f406                	sd	ra,40(sp)
    8000384e:	f022                	sd	s0,32(sp)
    80003850:	ec26                	sd	s1,24(sp)
    80003852:	e84a                	sd	s2,16(sp)
    80003854:	e44e                	sd	s3,8(sp)
    80003856:	e052                	sd	s4,0(sp)
    80003858:	1800                	addi	s0,sp,48
    8000385a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000385c:	47ad                	li	a5,11
    8000385e:	04b7fe63          	bgeu	a5,a1,800038ba <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003862:	ff45849b          	addiw	s1,a1,-12
    80003866:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000386a:	0ff00793          	li	a5,255
    8000386e:	0ae7e463          	bltu	a5,a4,80003916 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003872:	08052583          	lw	a1,128(a0)
    80003876:	c5b5                	beqz	a1,800038e2 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003878:	00092503          	lw	a0,0(s2)
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	bda080e7          	jalr	-1062(ra) # 80003456 <bread>
    80003884:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003886:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000388a:	02049713          	slli	a4,s1,0x20
    8000388e:	01e75593          	srli	a1,a4,0x1e
    80003892:	00b784b3          	add	s1,a5,a1
    80003896:	0004a983          	lw	s3,0(s1)
    8000389a:	04098e63          	beqz	s3,800038f6 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000389e:	8552                	mv	a0,s4
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	ce6080e7          	jalr	-794(ra) # 80003586 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038a8:	854e                	mv	a0,s3
    800038aa:	70a2                	ld	ra,40(sp)
    800038ac:	7402                	ld	s0,32(sp)
    800038ae:	64e2                	ld	s1,24(sp)
    800038b0:	6942                	ld	s2,16(sp)
    800038b2:	69a2                	ld	s3,8(sp)
    800038b4:	6a02                	ld	s4,0(sp)
    800038b6:	6145                	addi	sp,sp,48
    800038b8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038ba:	02059793          	slli	a5,a1,0x20
    800038be:	01e7d593          	srli	a1,a5,0x1e
    800038c2:	00b504b3          	add	s1,a0,a1
    800038c6:	0504a983          	lw	s3,80(s1)
    800038ca:	fc099fe3          	bnez	s3,800038a8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038ce:	4108                	lw	a0,0(a0)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	e48080e7          	jalr	-440(ra) # 80003718 <balloc>
    800038d8:	0005099b          	sext.w	s3,a0
    800038dc:	0534a823          	sw	s3,80(s1)
    800038e0:	b7e1                	j	800038a8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038e2:	4108                	lw	a0,0(a0)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	e34080e7          	jalr	-460(ra) # 80003718 <balloc>
    800038ec:	0005059b          	sext.w	a1,a0
    800038f0:	08b92023          	sw	a1,128(s2)
    800038f4:	b751                	j	80003878 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038f6:	00092503          	lw	a0,0(s2)
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	e1e080e7          	jalr	-482(ra) # 80003718 <balloc>
    80003902:	0005099b          	sext.w	s3,a0
    80003906:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000390a:	8552                	mv	a0,s4
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	efc080e7          	jalr	-260(ra) # 80004808 <log_write>
    80003914:	b769                	j	8000389e <bmap+0x54>
  panic("bmap: out of range");
    80003916:	00005517          	auipc	a0,0x5
    8000391a:	c8a50513          	addi	a0,a0,-886 # 800085a0 <syscalls+0x130>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	c0c080e7          	jalr	-1012(ra) # 8000052a <panic>

0000000080003926 <iget>:
{
    80003926:	7179                	addi	sp,sp,-48
    80003928:	f406                	sd	ra,40(sp)
    8000392a:	f022                	sd	s0,32(sp)
    8000392c:	ec26                	sd	s1,24(sp)
    8000392e:	e84a                	sd	s2,16(sp)
    80003930:	e44e                	sd	s3,8(sp)
    80003932:	e052                	sd	s4,0(sp)
    80003934:	1800                	addi	s0,sp,48
    80003936:	89aa                	mv	s3,a0
    80003938:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000393a:	00022517          	auipc	a0,0x22
    8000393e:	48e50513          	addi	a0,a0,1166 # 80025dc8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	280080e7          	jalr	640(ra) # 80000bc2 <acquire>
  empty = 0;
    8000394a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000394c:	00022497          	auipc	s1,0x22
    80003950:	49448493          	addi	s1,s1,1172 # 80025de0 <itable+0x18>
    80003954:	00024697          	auipc	a3,0x24
    80003958:	f1c68693          	addi	a3,a3,-228 # 80027870 <log>
    8000395c:	a039                	j	8000396a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000395e:	02090b63          	beqz	s2,80003994 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003962:	08848493          	addi	s1,s1,136
    80003966:	02d48a63          	beq	s1,a3,8000399a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000396a:	449c                	lw	a5,8(s1)
    8000396c:	fef059e3          	blez	a5,8000395e <iget+0x38>
    80003970:	4098                	lw	a4,0(s1)
    80003972:	ff3716e3          	bne	a4,s3,8000395e <iget+0x38>
    80003976:	40d8                	lw	a4,4(s1)
    80003978:	ff4713e3          	bne	a4,s4,8000395e <iget+0x38>
      ip->ref++;
    8000397c:	2785                	addiw	a5,a5,1
    8000397e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003980:	00022517          	auipc	a0,0x22
    80003984:	44850513          	addi	a0,a0,1096 # 80025dc8 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	300080e7          	jalr	768(ra) # 80000c88 <release>
      return ip;
    80003990:	8926                	mv	s2,s1
    80003992:	a03d                	j	800039c0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003994:	f7f9                	bnez	a5,80003962 <iget+0x3c>
    80003996:	8926                	mv	s2,s1
    80003998:	b7e9                	j	80003962 <iget+0x3c>
  if(empty == 0)
    8000399a:	02090c63          	beqz	s2,800039d2 <iget+0xac>
  ip->dev = dev;
    8000399e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039a2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039a6:	4785                	li	a5,1
    800039a8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039ac:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039b0:	00022517          	auipc	a0,0x22
    800039b4:	41850513          	addi	a0,a0,1048 # 80025dc8 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2d0080e7          	jalr	720(ra) # 80000c88 <release>
}
    800039c0:	854a                	mv	a0,s2
    800039c2:	70a2                	ld	ra,40(sp)
    800039c4:	7402                	ld	s0,32(sp)
    800039c6:	64e2                	ld	s1,24(sp)
    800039c8:	6942                	ld	s2,16(sp)
    800039ca:	69a2                	ld	s3,8(sp)
    800039cc:	6a02                	ld	s4,0(sp)
    800039ce:	6145                	addi	sp,sp,48
    800039d0:	8082                	ret
    panic("iget: no inodes");
    800039d2:	00005517          	auipc	a0,0x5
    800039d6:	be650513          	addi	a0,a0,-1050 # 800085b8 <syscalls+0x148>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	b50080e7          	jalr	-1200(ra) # 8000052a <panic>

00000000800039e2 <fsinit>:
fsinit(int dev) {
    800039e2:	7179                	addi	sp,sp,-48
    800039e4:	f406                	sd	ra,40(sp)
    800039e6:	f022                	sd	s0,32(sp)
    800039e8:	ec26                	sd	s1,24(sp)
    800039ea:	e84a                	sd	s2,16(sp)
    800039ec:	e44e                	sd	s3,8(sp)
    800039ee:	1800                	addi	s0,sp,48
    800039f0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039f2:	4585                	li	a1,1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	a62080e7          	jalr	-1438(ra) # 80003456 <bread>
    800039fc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039fe:	00022997          	auipc	s3,0x22
    80003a02:	3aa98993          	addi	s3,s3,938 # 80025da8 <sb>
    80003a06:	02000613          	li	a2,32
    80003a0a:	05850593          	addi	a1,a0,88
    80003a0e:	854e                	mv	a0,s3
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	32e080e7          	jalr	814(ra) # 80000d3e <memmove>
  brelse(bp);
    80003a18:	8526                	mv	a0,s1
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	b6c080e7          	jalr	-1172(ra) # 80003586 <brelse>
  if(sb.magic != FSMAGIC)
    80003a22:	0009a703          	lw	a4,0(s3)
    80003a26:	102037b7          	lui	a5,0x10203
    80003a2a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a2e:	02f71263          	bne	a4,a5,80003a52 <fsinit+0x70>
  initlog(dev, &sb);
    80003a32:	00022597          	auipc	a1,0x22
    80003a36:	37658593          	addi	a1,a1,886 # 80025da8 <sb>
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	b4e080e7          	jalr	-1202(ra) # 8000458a <initlog>
}
    80003a44:	70a2                	ld	ra,40(sp)
    80003a46:	7402                	ld	s0,32(sp)
    80003a48:	64e2                	ld	s1,24(sp)
    80003a4a:	6942                	ld	s2,16(sp)
    80003a4c:	69a2                	ld	s3,8(sp)
    80003a4e:	6145                	addi	sp,sp,48
    80003a50:	8082                	ret
    panic("invalid file system");
    80003a52:	00005517          	auipc	a0,0x5
    80003a56:	b7650513          	addi	a0,a0,-1162 # 800085c8 <syscalls+0x158>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	ad0080e7          	jalr	-1328(ra) # 8000052a <panic>

0000000080003a62 <iinit>:
{
    80003a62:	7179                	addi	sp,sp,-48
    80003a64:	f406                	sd	ra,40(sp)
    80003a66:	f022                	sd	s0,32(sp)
    80003a68:	ec26                	sd	s1,24(sp)
    80003a6a:	e84a                	sd	s2,16(sp)
    80003a6c:	e44e                	sd	s3,8(sp)
    80003a6e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a70:	00005597          	auipc	a1,0x5
    80003a74:	b7058593          	addi	a1,a1,-1168 # 800085e0 <syscalls+0x170>
    80003a78:	00022517          	auipc	a0,0x22
    80003a7c:	35050513          	addi	a0,a0,848 # 80025dc8 <itable>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	0b2080e7          	jalr	178(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a88:	00022497          	auipc	s1,0x22
    80003a8c:	36848493          	addi	s1,s1,872 # 80025df0 <itable+0x28>
    80003a90:	00024997          	auipc	s3,0x24
    80003a94:	df098993          	addi	s3,s3,-528 # 80027880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a98:	00005917          	auipc	s2,0x5
    80003a9c:	b5090913          	addi	s2,s2,-1200 # 800085e8 <syscalls+0x178>
    80003aa0:	85ca                	mv	a1,s2
    80003aa2:	8526                	mv	a0,s1
    80003aa4:	00001097          	auipc	ra,0x1
    80003aa8:	e4a080e7          	jalr	-438(ra) # 800048ee <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003aac:	08848493          	addi	s1,s1,136
    80003ab0:	ff3498e3          	bne	s1,s3,80003aa0 <iinit+0x3e>
}
    80003ab4:	70a2                	ld	ra,40(sp)
    80003ab6:	7402                	ld	s0,32(sp)
    80003ab8:	64e2                	ld	s1,24(sp)
    80003aba:	6942                	ld	s2,16(sp)
    80003abc:	69a2                	ld	s3,8(sp)
    80003abe:	6145                	addi	sp,sp,48
    80003ac0:	8082                	ret

0000000080003ac2 <ialloc>:
{
    80003ac2:	715d                	addi	sp,sp,-80
    80003ac4:	e486                	sd	ra,72(sp)
    80003ac6:	e0a2                	sd	s0,64(sp)
    80003ac8:	fc26                	sd	s1,56(sp)
    80003aca:	f84a                	sd	s2,48(sp)
    80003acc:	f44e                	sd	s3,40(sp)
    80003ace:	f052                	sd	s4,32(sp)
    80003ad0:	ec56                	sd	s5,24(sp)
    80003ad2:	e85a                	sd	s6,16(sp)
    80003ad4:	e45e                	sd	s7,8(sp)
    80003ad6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ad8:	00022717          	auipc	a4,0x22
    80003adc:	2dc72703          	lw	a4,732(a4) # 80025db4 <sb+0xc>
    80003ae0:	4785                	li	a5,1
    80003ae2:	04e7fa63          	bgeu	a5,a4,80003b36 <ialloc+0x74>
    80003ae6:	8aaa                	mv	s5,a0
    80003ae8:	8bae                	mv	s7,a1
    80003aea:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aec:	00022a17          	auipc	s4,0x22
    80003af0:	2bca0a13          	addi	s4,s4,700 # 80025da8 <sb>
    80003af4:	00048b1b          	sext.w	s6,s1
    80003af8:	0044d793          	srli	a5,s1,0x4
    80003afc:	018a2583          	lw	a1,24(s4)
    80003b00:	9dbd                	addw	a1,a1,a5
    80003b02:	8556                	mv	a0,s5
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	952080e7          	jalr	-1710(ra) # 80003456 <bread>
    80003b0c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b0e:	05850993          	addi	s3,a0,88
    80003b12:	00f4f793          	andi	a5,s1,15
    80003b16:	079a                	slli	a5,a5,0x6
    80003b18:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b1a:	00099783          	lh	a5,0(s3)
    80003b1e:	c785                	beqz	a5,80003b46 <ialloc+0x84>
    brelse(bp);
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	a66080e7          	jalr	-1434(ra) # 80003586 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b28:	0485                	addi	s1,s1,1
    80003b2a:	00ca2703          	lw	a4,12(s4)
    80003b2e:	0004879b          	sext.w	a5,s1
    80003b32:	fce7e1e3          	bltu	a5,a4,80003af4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	aba50513          	addi	a0,a0,-1350 # 800085f0 <syscalls+0x180>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	9ec080e7          	jalr	-1556(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003b46:	04000613          	li	a2,64
    80003b4a:	4581                	li	a1,0
    80003b4c:	854e                	mv	a0,s3
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	194080e7          	jalr	404(ra) # 80000ce2 <memset>
      dip->type = type;
    80003b56:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	cac080e7          	jalr	-852(ra) # 80004808 <log_write>
      brelse(bp);
    80003b64:	854a                	mv	a0,s2
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	a20080e7          	jalr	-1504(ra) # 80003586 <brelse>
      return iget(dev, inum);
    80003b6e:	85da                	mv	a1,s6
    80003b70:	8556                	mv	a0,s5
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	db4080e7          	jalr	-588(ra) # 80003926 <iget>
}
    80003b7a:	60a6                	ld	ra,72(sp)
    80003b7c:	6406                	ld	s0,64(sp)
    80003b7e:	74e2                	ld	s1,56(sp)
    80003b80:	7942                	ld	s2,48(sp)
    80003b82:	79a2                	ld	s3,40(sp)
    80003b84:	7a02                	ld	s4,32(sp)
    80003b86:	6ae2                	ld	s5,24(sp)
    80003b88:	6b42                	ld	s6,16(sp)
    80003b8a:	6ba2                	ld	s7,8(sp)
    80003b8c:	6161                	addi	sp,sp,80
    80003b8e:	8082                	ret

0000000080003b90 <iupdate>:
{
    80003b90:	1101                	addi	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	e04a                	sd	s2,0(sp)
    80003b9a:	1000                	addi	s0,sp,32
    80003b9c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b9e:	415c                	lw	a5,4(a0)
    80003ba0:	0047d79b          	srliw	a5,a5,0x4
    80003ba4:	00022597          	auipc	a1,0x22
    80003ba8:	21c5a583          	lw	a1,540(a1) # 80025dc0 <sb+0x18>
    80003bac:	9dbd                	addw	a1,a1,a5
    80003bae:	4108                	lw	a0,0(a0)
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	8a6080e7          	jalr	-1882(ra) # 80003456 <bread>
    80003bb8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bba:	05850793          	addi	a5,a0,88
    80003bbe:	40c8                	lw	a0,4(s1)
    80003bc0:	893d                	andi	a0,a0,15
    80003bc2:	051a                	slli	a0,a0,0x6
    80003bc4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bc6:	04449703          	lh	a4,68(s1)
    80003bca:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bce:	04649703          	lh	a4,70(s1)
    80003bd2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bd6:	04849703          	lh	a4,72(s1)
    80003bda:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bde:	04a49703          	lh	a4,74(s1)
    80003be2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003be6:	44f8                	lw	a4,76(s1)
    80003be8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bea:	03400613          	li	a2,52
    80003bee:	05048593          	addi	a1,s1,80
    80003bf2:	0531                	addi	a0,a0,12
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	14a080e7          	jalr	330(ra) # 80000d3e <memmove>
  log_write(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	c0a080e7          	jalr	-1014(ra) # 80004808 <log_write>
  brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	97e080e7          	jalr	-1666(ra) # 80003586 <brelse>
}
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6902                	ld	s2,0(sp)
    80003c18:	6105                	addi	sp,sp,32
    80003c1a:	8082                	ret

0000000080003c1c <idup>:
{
    80003c1c:	1101                	addi	sp,sp,-32
    80003c1e:	ec06                	sd	ra,24(sp)
    80003c20:	e822                	sd	s0,16(sp)
    80003c22:	e426                	sd	s1,8(sp)
    80003c24:	1000                	addi	s0,sp,32
    80003c26:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c28:	00022517          	auipc	a0,0x22
    80003c2c:	1a050513          	addi	a0,a0,416 # 80025dc8 <itable>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	f92080e7          	jalr	-110(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003c38:	449c                	lw	a5,8(s1)
    80003c3a:	2785                	addiw	a5,a5,1
    80003c3c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c3e:	00022517          	auipc	a0,0x22
    80003c42:	18a50513          	addi	a0,a0,394 # 80025dc8 <itable>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	042080e7          	jalr	66(ra) # 80000c88 <release>
}
    80003c4e:	8526                	mv	a0,s1
    80003c50:	60e2                	ld	ra,24(sp)
    80003c52:	6442                	ld	s0,16(sp)
    80003c54:	64a2                	ld	s1,8(sp)
    80003c56:	6105                	addi	sp,sp,32
    80003c58:	8082                	ret

0000000080003c5a <ilock>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	e04a                	sd	s2,0(sp)
    80003c64:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c66:	c115                	beqz	a0,80003c8a <ilock+0x30>
    80003c68:	84aa                	mv	s1,a0
    80003c6a:	451c                	lw	a5,8(a0)
    80003c6c:	00f05f63          	blez	a5,80003c8a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c70:	0541                	addi	a0,a0,16
    80003c72:	00001097          	auipc	ra,0x1
    80003c76:	cb6080e7          	jalr	-842(ra) # 80004928 <acquiresleep>
  if(ip->valid == 0){
    80003c7a:	40bc                	lw	a5,64(s1)
    80003c7c:	cf99                	beqz	a5,80003c9a <ilock+0x40>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6902                	ld	s2,0(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret
    panic("ilock");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	97e50513          	addi	a0,a0,-1666 # 80008608 <syscalls+0x198>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	898080e7          	jalr	-1896(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c9a:	40dc                	lw	a5,4(s1)
    80003c9c:	0047d79b          	srliw	a5,a5,0x4
    80003ca0:	00022597          	auipc	a1,0x22
    80003ca4:	1205a583          	lw	a1,288(a1) # 80025dc0 <sb+0x18>
    80003ca8:	9dbd                	addw	a1,a1,a5
    80003caa:	4088                	lw	a0,0(s1)
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	7aa080e7          	jalr	1962(ra) # 80003456 <bread>
    80003cb4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cb6:	05850593          	addi	a1,a0,88
    80003cba:	40dc                	lw	a5,4(s1)
    80003cbc:	8bbd                	andi	a5,a5,15
    80003cbe:	079a                	slli	a5,a5,0x6
    80003cc0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cc2:	00059783          	lh	a5,0(a1)
    80003cc6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cca:	00259783          	lh	a5,2(a1)
    80003cce:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cd2:	00459783          	lh	a5,4(a1)
    80003cd6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cda:	00659783          	lh	a5,6(a1)
    80003cde:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ce2:	459c                	lw	a5,8(a1)
    80003ce4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ce6:	03400613          	li	a2,52
    80003cea:	05b1                	addi	a1,a1,12
    80003cec:	05048513          	addi	a0,s1,80
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	04e080e7          	jalr	78(ra) # 80000d3e <memmove>
    brelse(bp);
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	88c080e7          	jalr	-1908(ra) # 80003586 <brelse>
    ip->valid = 1;
    80003d02:	4785                	li	a5,1
    80003d04:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d06:	04449783          	lh	a5,68(s1)
    80003d0a:	fbb5                	bnez	a5,80003c7e <ilock+0x24>
      panic("ilock: no type");
    80003d0c:	00005517          	auipc	a0,0x5
    80003d10:	90450513          	addi	a0,a0,-1788 # 80008610 <syscalls+0x1a0>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	816080e7          	jalr	-2026(ra) # 8000052a <panic>

0000000080003d1c <iunlock>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	e04a                	sd	s2,0(sp)
    80003d26:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d28:	c905                	beqz	a0,80003d58 <iunlock+0x3c>
    80003d2a:	84aa                	mv	s1,a0
    80003d2c:	01050913          	addi	s2,a0,16
    80003d30:	854a                	mv	a0,s2
    80003d32:	00001097          	auipc	ra,0x1
    80003d36:	c90080e7          	jalr	-880(ra) # 800049c2 <holdingsleep>
    80003d3a:	cd19                	beqz	a0,80003d58 <iunlock+0x3c>
    80003d3c:	449c                	lw	a5,8(s1)
    80003d3e:	00f05d63          	blez	a5,80003d58 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d42:	854a                	mv	a0,s2
    80003d44:	00001097          	auipc	ra,0x1
    80003d48:	c3a080e7          	jalr	-966(ra) # 8000497e <releasesleep>
}
    80003d4c:	60e2                	ld	ra,24(sp)
    80003d4e:	6442                	ld	s0,16(sp)
    80003d50:	64a2                	ld	s1,8(sp)
    80003d52:	6902                	ld	s2,0(sp)
    80003d54:	6105                	addi	sp,sp,32
    80003d56:	8082                	ret
    panic("iunlock");
    80003d58:	00005517          	auipc	a0,0x5
    80003d5c:	8c850513          	addi	a0,a0,-1848 # 80008620 <syscalls+0x1b0>
    80003d60:	ffffc097          	auipc	ra,0xffffc
    80003d64:	7ca080e7          	jalr	1994(ra) # 8000052a <panic>

0000000080003d68 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d68:	7179                	addi	sp,sp,-48
    80003d6a:	f406                	sd	ra,40(sp)
    80003d6c:	f022                	sd	s0,32(sp)
    80003d6e:	ec26                	sd	s1,24(sp)
    80003d70:	e84a                	sd	s2,16(sp)
    80003d72:	e44e                	sd	s3,8(sp)
    80003d74:	e052                	sd	s4,0(sp)
    80003d76:	1800                	addi	s0,sp,48
    80003d78:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d7a:	05050493          	addi	s1,a0,80
    80003d7e:	08050913          	addi	s2,a0,128
    80003d82:	a021                	j	80003d8a <itrunc+0x22>
    80003d84:	0491                	addi	s1,s1,4
    80003d86:	01248d63          	beq	s1,s2,80003da0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d8a:	408c                	lw	a1,0(s1)
    80003d8c:	dde5                	beqz	a1,80003d84 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d8e:	0009a503          	lw	a0,0(s3)
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	90a080e7          	jalr	-1782(ra) # 8000369c <bfree>
      ip->addrs[i] = 0;
    80003d9a:	0004a023          	sw	zero,0(s1)
    80003d9e:	b7dd                	j	80003d84 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003da0:	0809a583          	lw	a1,128(s3)
    80003da4:	e185                	bnez	a1,80003dc4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003da6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003daa:	854e                	mv	a0,s3
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	de4080e7          	jalr	-540(ra) # 80003b90 <iupdate>
}
    80003db4:	70a2                	ld	ra,40(sp)
    80003db6:	7402                	ld	s0,32(sp)
    80003db8:	64e2                	ld	s1,24(sp)
    80003dba:	6942                	ld	s2,16(sp)
    80003dbc:	69a2                	ld	s3,8(sp)
    80003dbe:	6a02                	ld	s4,0(sp)
    80003dc0:	6145                	addi	sp,sp,48
    80003dc2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dc4:	0009a503          	lw	a0,0(s3)
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	68e080e7          	jalr	1678(ra) # 80003456 <bread>
    80003dd0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dd2:	05850493          	addi	s1,a0,88
    80003dd6:	45850913          	addi	s2,a0,1112
    80003dda:	a021                	j	80003de2 <itrunc+0x7a>
    80003ddc:	0491                	addi	s1,s1,4
    80003dde:	01248b63          	beq	s1,s2,80003df4 <itrunc+0x8c>
      if(a[j])
    80003de2:	408c                	lw	a1,0(s1)
    80003de4:	dde5                	beqz	a1,80003ddc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003de6:	0009a503          	lw	a0,0(s3)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	8b2080e7          	jalr	-1870(ra) # 8000369c <bfree>
    80003df2:	b7ed                	j	80003ddc <itrunc+0x74>
    brelse(bp);
    80003df4:	8552                	mv	a0,s4
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	790080e7          	jalr	1936(ra) # 80003586 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dfe:	0809a583          	lw	a1,128(s3)
    80003e02:	0009a503          	lw	a0,0(s3)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	896080e7          	jalr	-1898(ra) # 8000369c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e0e:	0809a023          	sw	zero,128(s3)
    80003e12:	bf51                	j	80003da6 <itrunc+0x3e>

0000000080003e14 <iput>:
{
    80003e14:	1101                	addi	sp,sp,-32
    80003e16:	ec06                	sd	ra,24(sp)
    80003e18:	e822                	sd	s0,16(sp)
    80003e1a:	e426                	sd	s1,8(sp)
    80003e1c:	e04a                	sd	s2,0(sp)
    80003e1e:	1000                	addi	s0,sp,32
    80003e20:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e22:	00022517          	auipc	a0,0x22
    80003e26:	fa650513          	addi	a0,a0,-90 # 80025dc8 <itable>
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	d98080e7          	jalr	-616(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e32:	4498                	lw	a4,8(s1)
    80003e34:	4785                	li	a5,1
    80003e36:	02f70363          	beq	a4,a5,80003e5c <iput+0x48>
  ip->ref--;
    80003e3a:	449c                	lw	a5,8(s1)
    80003e3c:	37fd                	addiw	a5,a5,-1
    80003e3e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e40:	00022517          	auipc	a0,0x22
    80003e44:	f8850513          	addi	a0,a0,-120 # 80025dc8 <itable>
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	e40080e7          	jalr	-448(ra) # 80000c88 <release>
}
    80003e50:	60e2                	ld	ra,24(sp)
    80003e52:	6442                	ld	s0,16(sp)
    80003e54:	64a2                	ld	s1,8(sp)
    80003e56:	6902                	ld	s2,0(sp)
    80003e58:	6105                	addi	sp,sp,32
    80003e5a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e5c:	40bc                	lw	a5,64(s1)
    80003e5e:	dff1                	beqz	a5,80003e3a <iput+0x26>
    80003e60:	04a49783          	lh	a5,74(s1)
    80003e64:	fbf9                	bnez	a5,80003e3a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e66:	01048913          	addi	s2,s1,16
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00001097          	auipc	ra,0x1
    80003e70:	abc080e7          	jalr	-1348(ra) # 80004928 <acquiresleep>
    release(&itable.lock);
    80003e74:	00022517          	auipc	a0,0x22
    80003e78:	f5450513          	addi	a0,a0,-172 # 80025dc8 <itable>
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	e0c080e7          	jalr	-500(ra) # 80000c88 <release>
    itrunc(ip);
    80003e84:	8526                	mv	a0,s1
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	ee2080e7          	jalr	-286(ra) # 80003d68 <itrunc>
    ip->type = 0;
    80003e8e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e92:	8526                	mv	a0,s1
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	cfc080e7          	jalr	-772(ra) # 80003b90 <iupdate>
    ip->valid = 0;
    80003e9c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	00001097          	auipc	ra,0x1
    80003ea6:	adc080e7          	jalr	-1316(ra) # 8000497e <releasesleep>
    acquire(&itable.lock);
    80003eaa:	00022517          	auipc	a0,0x22
    80003eae:	f1e50513          	addi	a0,a0,-226 # 80025dc8 <itable>
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	d10080e7          	jalr	-752(ra) # 80000bc2 <acquire>
    80003eba:	b741                	j	80003e3a <iput+0x26>

0000000080003ebc <iunlockput>:
{
    80003ebc:	1101                	addi	sp,sp,-32
    80003ebe:	ec06                	sd	ra,24(sp)
    80003ec0:	e822                	sd	s0,16(sp)
    80003ec2:	e426                	sd	s1,8(sp)
    80003ec4:	1000                	addi	s0,sp,32
    80003ec6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	e54080e7          	jalr	-428(ra) # 80003d1c <iunlock>
  iput(ip);
    80003ed0:	8526                	mv	a0,s1
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	f42080e7          	jalr	-190(ra) # 80003e14 <iput>
}
    80003eda:	60e2                	ld	ra,24(sp)
    80003edc:	6442                	ld	s0,16(sp)
    80003ede:	64a2                	ld	s1,8(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ee4:	1141                	addi	sp,sp,-16
    80003ee6:	e422                	sd	s0,8(sp)
    80003ee8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eea:	411c                	lw	a5,0(a0)
    80003eec:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003eee:	415c                	lw	a5,4(a0)
    80003ef0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ef2:	04451783          	lh	a5,68(a0)
    80003ef6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003efa:	04a51783          	lh	a5,74(a0)
    80003efe:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f02:	04c56783          	lwu	a5,76(a0)
    80003f06:	e99c                	sd	a5,16(a1)
}
    80003f08:	6422                	ld	s0,8(sp)
    80003f0a:	0141                	addi	sp,sp,16
    80003f0c:	8082                	ret

0000000080003f0e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f0e:	457c                	lw	a5,76(a0)
    80003f10:	0ed7e963          	bltu	a5,a3,80004002 <readi+0xf4>
{
    80003f14:	7159                	addi	sp,sp,-112
    80003f16:	f486                	sd	ra,104(sp)
    80003f18:	f0a2                	sd	s0,96(sp)
    80003f1a:	eca6                	sd	s1,88(sp)
    80003f1c:	e8ca                	sd	s2,80(sp)
    80003f1e:	e4ce                	sd	s3,72(sp)
    80003f20:	e0d2                	sd	s4,64(sp)
    80003f22:	fc56                	sd	s5,56(sp)
    80003f24:	f85a                	sd	s6,48(sp)
    80003f26:	f45e                	sd	s7,40(sp)
    80003f28:	f062                	sd	s8,32(sp)
    80003f2a:	ec66                	sd	s9,24(sp)
    80003f2c:	e86a                	sd	s10,16(sp)
    80003f2e:	e46e                	sd	s11,8(sp)
    80003f30:	1880                	addi	s0,sp,112
    80003f32:	8baa                	mv	s7,a0
    80003f34:	8c2e                	mv	s8,a1
    80003f36:	8ab2                	mv	s5,a2
    80003f38:	84b6                	mv	s1,a3
    80003f3a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f3c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f3e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f40:	0ad76063          	bltu	a4,a3,80003fe0 <readi+0xd2>
  if(off + n > ip->size)
    80003f44:	00e7f463          	bgeu	a5,a4,80003f4c <readi+0x3e>
    n = ip->size - off;
    80003f48:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f4c:	0a0b0963          	beqz	s6,80003ffe <readi+0xf0>
    80003f50:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f52:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f56:	5cfd                	li	s9,-1
    80003f58:	a82d                	j	80003f92 <readi+0x84>
    80003f5a:	020a1d93          	slli	s11,s4,0x20
    80003f5e:	020ddd93          	srli	s11,s11,0x20
    80003f62:	05890793          	addi	a5,s2,88
    80003f66:	86ee                	mv	a3,s11
    80003f68:	963e                	add	a2,a2,a5
    80003f6a:	85d6                	mv	a1,s5
    80003f6c:	8562                	mv	a0,s8
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	838080e7          	jalr	-1992(ra) # 800027a6 <either_copyout>
    80003f76:	05950d63          	beq	a0,s9,80003fd0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	60a080e7          	jalr	1546(ra) # 80003586 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f84:	013a09bb          	addw	s3,s4,s3
    80003f88:	009a04bb          	addw	s1,s4,s1
    80003f8c:	9aee                	add	s5,s5,s11
    80003f8e:	0569f763          	bgeu	s3,s6,80003fdc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f92:	000ba903          	lw	s2,0(s7)
    80003f96:	00a4d59b          	srliw	a1,s1,0xa
    80003f9a:	855e                	mv	a0,s7
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	8ae080e7          	jalr	-1874(ra) # 8000384a <bmap>
    80003fa4:	0005059b          	sext.w	a1,a0
    80003fa8:	854a                	mv	a0,s2
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	4ac080e7          	jalr	1196(ra) # 80003456 <bread>
    80003fb2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fb4:	3ff4f613          	andi	a2,s1,1023
    80003fb8:	40cd07bb          	subw	a5,s10,a2
    80003fbc:	413b073b          	subw	a4,s6,s3
    80003fc0:	8a3e                	mv	s4,a5
    80003fc2:	2781                	sext.w	a5,a5
    80003fc4:	0007069b          	sext.w	a3,a4
    80003fc8:	f8f6f9e3          	bgeu	a3,a5,80003f5a <readi+0x4c>
    80003fcc:	8a3a                	mv	s4,a4
    80003fce:	b771                	j	80003f5a <readi+0x4c>
      brelse(bp);
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	5b4080e7          	jalr	1460(ra) # 80003586 <brelse>
      tot = -1;
    80003fda:	59fd                	li	s3,-1
  }
  return tot;
    80003fdc:	0009851b          	sext.w	a0,s3
}
    80003fe0:	70a6                	ld	ra,104(sp)
    80003fe2:	7406                	ld	s0,96(sp)
    80003fe4:	64e6                	ld	s1,88(sp)
    80003fe6:	6946                	ld	s2,80(sp)
    80003fe8:	69a6                	ld	s3,72(sp)
    80003fea:	6a06                	ld	s4,64(sp)
    80003fec:	7ae2                	ld	s5,56(sp)
    80003fee:	7b42                	ld	s6,48(sp)
    80003ff0:	7ba2                	ld	s7,40(sp)
    80003ff2:	7c02                	ld	s8,32(sp)
    80003ff4:	6ce2                	ld	s9,24(sp)
    80003ff6:	6d42                	ld	s10,16(sp)
    80003ff8:	6da2                	ld	s11,8(sp)
    80003ffa:	6165                	addi	sp,sp,112
    80003ffc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffe:	89da                	mv	s3,s6
    80004000:	bff1                	j	80003fdc <readi+0xce>
    return 0;
    80004002:	4501                	li	a0,0
}
    80004004:	8082                	ret

0000000080004006 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004006:	457c                	lw	a5,76(a0)
    80004008:	10d7e863          	bltu	a5,a3,80004118 <writei+0x112>
{
    8000400c:	7159                	addi	sp,sp,-112
    8000400e:	f486                	sd	ra,104(sp)
    80004010:	f0a2                	sd	s0,96(sp)
    80004012:	eca6                	sd	s1,88(sp)
    80004014:	e8ca                	sd	s2,80(sp)
    80004016:	e4ce                	sd	s3,72(sp)
    80004018:	e0d2                	sd	s4,64(sp)
    8000401a:	fc56                	sd	s5,56(sp)
    8000401c:	f85a                	sd	s6,48(sp)
    8000401e:	f45e                	sd	s7,40(sp)
    80004020:	f062                	sd	s8,32(sp)
    80004022:	ec66                	sd	s9,24(sp)
    80004024:	e86a                	sd	s10,16(sp)
    80004026:	e46e                	sd	s11,8(sp)
    80004028:	1880                	addi	s0,sp,112
    8000402a:	8b2a                	mv	s6,a0
    8000402c:	8c2e                	mv	s8,a1
    8000402e:	8ab2                	mv	s5,a2
    80004030:	8936                	mv	s2,a3
    80004032:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004034:	00e687bb          	addw	a5,a3,a4
    80004038:	0ed7e263          	bltu	a5,a3,8000411c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000403c:	00043737          	lui	a4,0x43
    80004040:	0ef76063          	bltu	a4,a5,80004120 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004044:	0c0b8863          	beqz	s7,80004114 <writei+0x10e>
    80004048:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000404a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000404e:	5cfd                	li	s9,-1
    80004050:	a091                	j	80004094 <writei+0x8e>
    80004052:	02099d93          	slli	s11,s3,0x20
    80004056:	020ddd93          	srli	s11,s11,0x20
    8000405a:	05848793          	addi	a5,s1,88
    8000405e:	86ee                	mv	a3,s11
    80004060:	8656                	mv	a2,s5
    80004062:	85e2                	mv	a1,s8
    80004064:	953e                	add	a0,a0,a5
    80004066:	ffffe097          	auipc	ra,0xffffe
    8000406a:	798080e7          	jalr	1944(ra) # 800027fe <either_copyin>
    8000406e:	07950263          	beq	a0,s9,800040d2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004072:	8526                	mv	a0,s1
    80004074:	00000097          	auipc	ra,0x0
    80004078:	794080e7          	jalr	1940(ra) # 80004808 <log_write>
    brelse(bp);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	508080e7          	jalr	1288(ra) # 80003586 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004086:	01498a3b          	addw	s4,s3,s4
    8000408a:	0129893b          	addw	s2,s3,s2
    8000408e:	9aee                	add	s5,s5,s11
    80004090:	057a7663          	bgeu	s4,s7,800040dc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004094:	000b2483          	lw	s1,0(s6)
    80004098:	00a9559b          	srliw	a1,s2,0xa
    8000409c:	855a                	mv	a0,s6
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	7ac080e7          	jalr	1964(ra) # 8000384a <bmap>
    800040a6:	0005059b          	sext.w	a1,a0
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	3aa080e7          	jalr	938(ra) # 80003456 <bread>
    800040b4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b6:	3ff97513          	andi	a0,s2,1023
    800040ba:	40ad07bb          	subw	a5,s10,a0
    800040be:	414b873b          	subw	a4,s7,s4
    800040c2:	89be                	mv	s3,a5
    800040c4:	2781                	sext.w	a5,a5
    800040c6:	0007069b          	sext.w	a3,a4
    800040ca:	f8f6f4e3          	bgeu	a3,a5,80004052 <writei+0x4c>
    800040ce:	89ba                	mv	s3,a4
    800040d0:	b749                	j	80004052 <writei+0x4c>
      brelse(bp);
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	4b2080e7          	jalr	1202(ra) # 80003586 <brelse>
  }

  if(off > ip->size)
    800040dc:	04cb2783          	lw	a5,76(s6)
    800040e0:	0127f463          	bgeu	a5,s2,800040e8 <writei+0xe2>
    ip->size = off;
    800040e4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040e8:	855a                	mv	a0,s6
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	aa6080e7          	jalr	-1370(ra) # 80003b90 <iupdate>

  return tot;
    800040f2:	000a051b          	sext.w	a0,s4
}
    800040f6:	70a6                	ld	ra,104(sp)
    800040f8:	7406                	ld	s0,96(sp)
    800040fa:	64e6                	ld	s1,88(sp)
    800040fc:	6946                	ld	s2,80(sp)
    800040fe:	69a6                	ld	s3,72(sp)
    80004100:	6a06                	ld	s4,64(sp)
    80004102:	7ae2                	ld	s5,56(sp)
    80004104:	7b42                	ld	s6,48(sp)
    80004106:	7ba2                	ld	s7,40(sp)
    80004108:	7c02                	ld	s8,32(sp)
    8000410a:	6ce2                	ld	s9,24(sp)
    8000410c:	6d42                	ld	s10,16(sp)
    8000410e:	6da2                	ld	s11,8(sp)
    80004110:	6165                	addi	sp,sp,112
    80004112:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004114:	8a5e                	mv	s4,s7
    80004116:	bfc9                	j	800040e8 <writei+0xe2>
    return -1;
    80004118:	557d                	li	a0,-1
}
    8000411a:	8082                	ret
    return -1;
    8000411c:	557d                	li	a0,-1
    8000411e:	bfe1                	j	800040f6 <writei+0xf0>
    return -1;
    80004120:	557d                	li	a0,-1
    80004122:	bfd1                	j	800040f6 <writei+0xf0>

0000000080004124 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004124:	1141                	addi	sp,sp,-16
    80004126:	e406                	sd	ra,8(sp)
    80004128:	e022                	sd	s0,0(sp)
    8000412a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	c8c080e7          	jalr	-884(ra) # 80000dba <strncmp>
}
    80004136:	60a2                	ld	ra,8(sp)
    80004138:	6402                	ld	s0,0(sp)
    8000413a:	0141                	addi	sp,sp,16
    8000413c:	8082                	ret

000000008000413e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000413e:	7139                	addi	sp,sp,-64
    80004140:	fc06                	sd	ra,56(sp)
    80004142:	f822                	sd	s0,48(sp)
    80004144:	f426                	sd	s1,40(sp)
    80004146:	f04a                	sd	s2,32(sp)
    80004148:	ec4e                	sd	s3,24(sp)
    8000414a:	e852                	sd	s4,16(sp)
    8000414c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000414e:	04451703          	lh	a4,68(a0)
    80004152:	4785                	li	a5,1
    80004154:	00f71a63          	bne	a4,a5,80004168 <dirlookup+0x2a>
    80004158:	892a                	mv	s2,a0
    8000415a:	89ae                	mv	s3,a1
    8000415c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000415e:	457c                	lw	a5,76(a0)
    80004160:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004162:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004164:	e79d                	bnez	a5,80004192 <dirlookup+0x54>
    80004166:	a8a5                	j	800041de <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004168:	00004517          	auipc	a0,0x4
    8000416c:	4c050513          	addi	a0,a0,1216 # 80008628 <syscalls+0x1b8>
    80004170:	ffffc097          	auipc	ra,0xffffc
    80004174:	3ba080e7          	jalr	954(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004178:	00004517          	auipc	a0,0x4
    8000417c:	4c850513          	addi	a0,a0,1224 # 80008640 <syscalls+0x1d0>
    80004180:	ffffc097          	auipc	ra,0xffffc
    80004184:	3aa080e7          	jalr	938(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004188:	24c1                	addiw	s1,s1,16
    8000418a:	04c92783          	lw	a5,76(s2)
    8000418e:	04f4f763          	bgeu	s1,a5,800041dc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004192:	4741                	li	a4,16
    80004194:	86a6                	mv	a3,s1
    80004196:	fc040613          	addi	a2,s0,-64
    8000419a:	4581                	li	a1,0
    8000419c:	854a                	mv	a0,s2
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	d70080e7          	jalr	-656(ra) # 80003f0e <readi>
    800041a6:	47c1                	li	a5,16
    800041a8:	fcf518e3          	bne	a0,a5,80004178 <dirlookup+0x3a>
    if(de.inum == 0)
    800041ac:	fc045783          	lhu	a5,-64(s0)
    800041b0:	dfe1                	beqz	a5,80004188 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041b2:	fc240593          	addi	a1,s0,-62
    800041b6:	854e                	mv	a0,s3
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	f6c080e7          	jalr	-148(ra) # 80004124 <namecmp>
    800041c0:	f561                	bnez	a0,80004188 <dirlookup+0x4a>
      if(poff)
    800041c2:	000a0463          	beqz	s4,800041ca <dirlookup+0x8c>
        *poff = off;
    800041c6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ca:	fc045583          	lhu	a1,-64(s0)
    800041ce:	00092503          	lw	a0,0(s2)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	754080e7          	jalr	1876(ra) # 80003926 <iget>
    800041da:	a011                	j	800041de <dirlookup+0xa0>
  return 0;
    800041dc:	4501                	li	a0,0
}
    800041de:	70e2                	ld	ra,56(sp)
    800041e0:	7442                	ld	s0,48(sp)
    800041e2:	74a2                	ld	s1,40(sp)
    800041e4:	7902                	ld	s2,32(sp)
    800041e6:	69e2                	ld	s3,24(sp)
    800041e8:	6a42                	ld	s4,16(sp)
    800041ea:	6121                	addi	sp,sp,64
    800041ec:	8082                	ret

00000000800041ee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041ee:	711d                	addi	sp,sp,-96
    800041f0:	ec86                	sd	ra,88(sp)
    800041f2:	e8a2                	sd	s0,80(sp)
    800041f4:	e4a6                	sd	s1,72(sp)
    800041f6:	e0ca                	sd	s2,64(sp)
    800041f8:	fc4e                	sd	s3,56(sp)
    800041fa:	f852                	sd	s4,48(sp)
    800041fc:	f456                	sd	s5,40(sp)
    800041fe:	f05a                	sd	s6,32(sp)
    80004200:	ec5e                	sd	s7,24(sp)
    80004202:	e862                	sd	s8,16(sp)
    80004204:	e466                	sd	s9,8(sp)
    80004206:	1080                	addi	s0,sp,96
    80004208:	84aa                	mv	s1,a0
    8000420a:	8aae                	mv	s5,a1
    8000420c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000420e:	00054703          	lbu	a4,0(a0)
    80004212:	02f00793          	li	a5,47
    80004216:	02f70363          	beq	a4,a5,8000423c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	78a080e7          	jalr	1930(ra) # 800019a4 <myproc>
    80004222:	2e853503          	ld	a0,744(a0)
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	9f6080e7          	jalr	-1546(ra) # 80003c1c <idup>
    8000422e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004230:	02f00913          	li	s2,47
  len = path - s;
    80004234:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004236:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004238:	4b85                	li	s7,1
    8000423a:	a865                	j	800042f2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000423c:	4585                	li	a1,1
    8000423e:	4505                	li	a0,1
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	6e6080e7          	jalr	1766(ra) # 80003926 <iget>
    80004248:	89aa                	mv	s3,a0
    8000424a:	b7dd                	j	80004230 <namex+0x42>
      iunlockput(ip);
    8000424c:	854e                	mv	a0,s3
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	c6e080e7          	jalr	-914(ra) # 80003ebc <iunlockput>
      return 0;
    80004256:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004258:	854e                	mv	a0,s3
    8000425a:	60e6                	ld	ra,88(sp)
    8000425c:	6446                	ld	s0,80(sp)
    8000425e:	64a6                	ld	s1,72(sp)
    80004260:	6906                	ld	s2,64(sp)
    80004262:	79e2                	ld	s3,56(sp)
    80004264:	7a42                	ld	s4,48(sp)
    80004266:	7aa2                	ld	s5,40(sp)
    80004268:	7b02                	ld	s6,32(sp)
    8000426a:	6be2                	ld	s7,24(sp)
    8000426c:	6c42                	ld	s8,16(sp)
    8000426e:	6ca2                	ld	s9,8(sp)
    80004270:	6125                	addi	sp,sp,96
    80004272:	8082                	ret
      iunlock(ip);
    80004274:	854e                	mv	a0,s3
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	aa6080e7          	jalr	-1370(ra) # 80003d1c <iunlock>
      return ip;
    8000427e:	bfe9                	j	80004258 <namex+0x6a>
      iunlockput(ip);
    80004280:	854e                	mv	a0,s3
    80004282:	00000097          	auipc	ra,0x0
    80004286:	c3a080e7          	jalr	-966(ra) # 80003ebc <iunlockput>
      return 0;
    8000428a:	89e6                	mv	s3,s9
    8000428c:	b7f1                	j	80004258 <namex+0x6a>
  len = path - s;
    8000428e:	40b48633          	sub	a2,s1,a1
    80004292:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004296:	099c5463          	bge	s8,s9,8000431e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000429a:	4639                	li	a2,14
    8000429c:	8552                	mv	a0,s4
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	aa0080e7          	jalr	-1376(ra) # 80000d3e <memmove>
  while(*path == '/')
    800042a6:	0004c783          	lbu	a5,0(s1)
    800042aa:	01279763          	bne	a5,s2,800042b8 <namex+0xca>
    path++;
    800042ae:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042b0:	0004c783          	lbu	a5,0(s1)
    800042b4:	ff278de3          	beq	a5,s2,800042ae <namex+0xc0>
    ilock(ip);
    800042b8:	854e                	mv	a0,s3
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	9a0080e7          	jalr	-1632(ra) # 80003c5a <ilock>
    if(ip->type != T_DIR){
    800042c2:	04499783          	lh	a5,68(s3)
    800042c6:	f97793e3          	bne	a5,s7,8000424c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ca:	000a8563          	beqz	s5,800042d4 <namex+0xe6>
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	d3cd                	beqz	a5,80004274 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042d4:	865a                	mv	a2,s6
    800042d6:	85d2                	mv	a1,s4
    800042d8:	854e                	mv	a0,s3
    800042da:	00000097          	auipc	ra,0x0
    800042de:	e64080e7          	jalr	-412(ra) # 8000413e <dirlookup>
    800042e2:	8caa                	mv	s9,a0
    800042e4:	dd51                	beqz	a0,80004280 <namex+0x92>
    iunlockput(ip);
    800042e6:	854e                	mv	a0,s3
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	bd4080e7          	jalr	-1068(ra) # 80003ebc <iunlockput>
    ip = next;
    800042f0:	89e6                	mv	s3,s9
  while(*path == '/')
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	05279763          	bne	a5,s2,80004344 <namex+0x156>
    path++;
    800042fa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042fc:	0004c783          	lbu	a5,0(s1)
    80004300:	ff278de3          	beq	a5,s2,800042fa <namex+0x10c>
  if(*path == 0)
    80004304:	c79d                	beqz	a5,80004332 <namex+0x144>
    path++;
    80004306:	85a6                	mv	a1,s1
  len = path - s;
    80004308:	8cda                	mv	s9,s6
    8000430a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000430c:	01278963          	beq	a5,s2,8000431e <namex+0x130>
    80004310:	dfbd                	beqz	a5,8000428e <namex+0xa0>
    path++;
    80004312:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004314:	0004c783          	lbu	a5,0(s1)
    80004318:	ff279ce3          	bne	a5,s2,80004310 <namex+0x122>
    8000431c:	bf8d                	j	8000428e <namex+0xa0>
    memmove(name, s, len);
    8000431e:	2601                	sext.w	a2,a2
    80004320:	8552                	mv	a0,s4
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	a1c080e7          	jalr	-1508(ra) # 80000d3e <memmove>
    name[len] = 0;
    8000432a:	9cd2                	add	s9,s9,s4
    8000432c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004330:	bf9d                	j	800042a6 <namex+0xb8>
  if(nameiparent){
    80004332:	f20a83e3          	beqz	s5,80004258 <namex+0x6a>
    iput(ip);
    80004336:	854e                	mv	a0,s3
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	adc080e7          	jalr	-1316(ra) # 80003e14 <iput>
    return 0;
    80004340:	4981                	li	s3,0
    80004342:	bf19                	j	80004258 <namex+0x6a>
  if(*path == 0)
    80004344:	d7fd                	beqz	a5,80004332 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004346:	0004c783          	lbu	a5,0(s1)
    8000434a:	85a6                	mv	a1,s1
    8000434c:	b7d1                	j	80004310 <namex+0x122>

000000008000434e <dirlink>:
{
    8000434e:	7139                	addi	sp,sp,-64
    80004350:	fc06                	sd	ra,56(sp)
    80004352:	f822                	sd	s0,48(sp)
    80004354:	f426                	sd	s1,40(sp)
    80004356:	f04a                	sd	s2,32(sp)
    80004358:	ec4e                	sd	s3,24(sp)
    8000435a:	e852                	sd	s4,16(sp)
    8000435c:	0080                	addi	s0,sp,64
    8000435e:	892a                	mv	s2,a0
    80004360:	8a2e                	mv	s4,a1
    80004362:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004364:	4601                	li	a2,0
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	dd8080e7          	jalr	-552(ra) # 8000413e <dirlookup>
    8000436e:	e93d                	bnez	a0,800043e4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004370:	04c92483          	lw	s1,76(s2)
    80004374:	c49d                	beqz	s1,800043a2 <dirlink+0x54>
    80004376:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004378:	4741                	li	a4,16
    8000437a:	86a6                	mv	a3,s1
    8000437c:	fc040613          	addi	a2,s0,-64
    80004380:	4581                	li	a1,0
    80004382:	854a                	mv	a0,s2
    80004384:	00000097          	auipc	ra,0x0
    80004388:	b8a080e7          	jalr	-1142(ra) # 80003f0e <readi>
    8000438c:	47c1                	li	a5,16
    8000438e:	06f51163          	bne	a0,a5,800043f0 <dirlink+0xa2>
    if(de.inum == 0)
    80004392:	fc045783          	lhu	a5,-64(s0)
    80004396:	c791                	beqz	a5,800043a2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004398:	24c1                	addiw	s1,s1,16
    8000439a:	04c92783          	lw	a5,76(s2)
    8000439e:	fcf4ede3          	bltu	s1,a5,80004378 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043a2:	4639                	li	a2,14
    800043a4:	85d2                	mv	a1,s4
    800043a6:	fc240513          	addi	a0,s0,-62
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	a4c080e7          	jalr	-1460(ra) # 80000df6 <strncpy>
  de.inum = inum;
    800043b2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b6:	4741                	li	a4,16
    800043b8:	86a6                	mv	a3,s1
    800043ba:	fc040613          	addi	a2,s0,-64
    800043be:	4581                	li	a1,0
    800043c0:	854a                	mv	a0,s2
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	c44080e7          	jalr	-956(ra) # 80004006 <writei>
    800043ca:	872a                	mv	a4,a0
    800043cc:	47c1                	li	a5,16
  return 0;
    800043ce:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043d0:	02f71863          	bne	a4,a5,80004400 <dirlink+0xb2>
}
    800043d4:	70e2                	ld	ra,56(sp)
    800043d6:	7442                	ld	s0,48(sp)
    800043d8:	74a2                	ld	s1,40(sp)
    800043da:	7902                	ld	s2,32(sp)
    800043dc:	69e2                	ld	s3,24(sp)
    800043de:	6a42                	ld	s4,16(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret
    iput(ip);
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	a30080e7          	jalr	-1488(ra) # 80003e14 <iput>
    return -1;
    800043ec:	557d                	li	a0,-1
    800043ee:	b7dd                	j	800043d4 <dirlink+0x86>
      panic("dirlink read");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	26050513          	addi	a0,a0,608 # 80008650 <syscalls+0x1e0>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	132080e7          	jalr	306(ra) # 8000052a <panic>
    panic("dirlink");
    80004400:	00004517          	auipc	a0,0x4
    80004404:	36050513          	addi	a0,a0,864 # 80008760 <syscalls+0x2f0>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	122080e7          	jalr	290(ra) # 8000052a <panic>

0000000080004410 <namei>:

struct inode*
namei(char *path)
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004418:	fe040613          	addi	a2,s0,-32
    8000441c:	4581                	li	a1,0
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	dd0080e7          	jalr	-560(ra) # 800041ee <namex>
}
    80004426:	60e2                	ld	ra,24(sp)
    80004428:	6442                	ld	s0,16(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000442e:	1141                	addi	sp,sp,-16
    80004430:	e406                	sd	ra,8(sp)
    80004432:	e022                	sd	s0,0(sp)
    80004434:	0800                	addi	s0,sp,16
    80004436:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004438:	4585                	li	a1,1
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	db4080e7          	jalr	-588(ra) # 800041ee <namex>
}
    80004442:	60a2                	ld	ra,8(sp)
    80004444:	6402                	ld	s0,0(sp)
    80004446:	0141                	addi	sp,sp,16
    80004448:	8082                	ret

000000008000444a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000444a:	1101                	addi	sp,sp,-32
    8000444c:	ec06                	sd	ra,24(sp)
    8000444e:	e822                	sd	s0,16(sp)
    80004450:	e426                	sd	s1,8(sp)
    80004452:	e04a                	sd	s2,0(sp)
    80004454:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004456:	00023917          	auipc	s2,0x23
    8000445a:	41a90913          	addi	s2,s2,1050 # 80027870 <log>
    8000445e:	01892583          	lw	a1,24(s2)
    80004462:	02892503          	lw	a0,40(s2)
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	ff0080e7          	jalr	-16(ra) # 80003456 <bread>
    8000446e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004470:	02c92683          	lw	a3,44(s2)
    80004474:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004476:	02d05863          	blez	a3,800044a6 <write_head+0x5c>
    8000447a:	00023797          	auipc	a5,0x23
    8000447e:	42678793          	addi	a5,a5,1062 # 800278a0 <log+0x30>
    80004482:	05c50713          	addi	a4,a0,92
    80004486:	36fd                	addiw	a3,a3,-1
    80004488:	02069613          	slli	a2,a3,0x20
    8000448c:	01e65693          	srli	a3,a2,0x1e
    80004490:	00023617          	auipc	a2,0x23
    80004494:	41460613          	addi	a2,a2,1044 # 800278a4 <log+0x34>
    80004498:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000449a:	4390                	lw	a2,0(a5)
    8000449c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000449e:	0791                	addi	a5,a5,4
    800044a0:	0711                	addi	a4,a4,4
    800044a2:	fed79ce3          	bne	a5,a3,8000449a <write_head+0x50>
  }
  bwrite(buf);
    800044a6:	8526                	mv	a0,s1
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	0a0080e7          	jalr	160(ra) # 80003548 <bwrite>
  brelse(buf);
    800044b0:	8526                	mv	a0,s1
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	0d4080e7          	jalr	212(ra) # 80003586 <brelse>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6902                	ld	s2,0(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044c6:	00023797          	auipc	a5,0x23
    800044ca:	3d67a783          	lw	a5,982(a5) # 8002789c <log+0x2c>
    800044ce:	0af05d63          	blez	a5,80004588 <install_trans+0xc2>
{
    800044d2:	7139                	addi	sp,sp,-64
    800044d4:	fc06                	sd	ra,56(sp)
    800044d6:	f822                	sd	s0,48(sp)
    800044d8:	f426                	sd	s1,40(sp)
    800044da:	f04a                	sd	s2,32(sp)
    800044dc:	ec4e                	sd	s3,24(sp)
    800044de:	e852                	sd	s4,16(sp)
    800044e0:	e456                	sd	s5,8(sp)
    800044e2:	e05a                	sd	s6,0(sp)
    800044e4:	0080                	addi	s0,sp,64
    800044e6:	8b2a                	mv	s6,a0
    800044e8:	00023a97          	auipc	s5,0x23
    800044ec:	3b8a8a93          	addi	s5,s5,952 # 800278a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044f2:	00023997          	auipc	s3,0x23
    800044f6:	37e98993          	addi	s3,s3,894 # 80027870 <log>
    800044fa:	a00d                	j	8000451c <install_trans+0x56>
    brelse(lbuf);
    800044fc:	854a                	mv	a0,s2
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	088080e7          	jalr	136(ra) # 80003586 <brelse>
    brelse(dbuf);
    80004506:	8526                	mv	a0,s1
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	07e080e7          	jalr	126(ra) # 80003586 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004510:	2a05                	addiw	s4,s4,1
    80004512:	0a91                	addi	s5,s5,4
    80004514:	02c9a783          	lw	a5,44(s3)
    80004518:	04fa5e63          	bge	s4,a5,80004574 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000451c:	0189a583          	lw	a1,24(s3)
    80004520:	014585bb          	addw	a1,a1,s4
    80004524:	2585                	addiw	a1,a1,1
    80004526:	0289a503          	lw	a0,40(s3)
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	f2c080e7          	jalr	-212(ra) # 80003456 <bread>
    80004532:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004534:	000aa583          	lw	a1,0(s5)
    80004538:	0289a503          	lw	a0,40(s3)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	f1a080e7          	jalr	-230(ra) # 80003456 <bread>
    80004544:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004546:	40000613          	li	a2,1024
    8000454a:	05890593          	addi	a1,s2,88
    8000454e:	05850513          	addi	a0,a0,88
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	7ec080e7          	jalr	2028(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	fec080e7          	jalr	-20(ra) # 80003548 <bwrite>
    if(recovering == 0)
    80004564:	f80b1ce3          	bnez	s6,800044fc <install_trans+0x36>
      bunpin(dbuf);
    80004568:	8526                	mv	a0,s1
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	0f6080e7          	jalr	246(ra) # 80003660 <bunpin>
    80004572:	b769                	j	800044fc <install_trans+0x36>
}
    80004574:	70e2                	ld	ra,56(sp)
    80004576:	7442                	ld	s0,48(sp)
    80004578:	74a2                	ld	s1,40(sp)
    8000457a:	7902                	ld	s2,32(sp)
    8000457c:	69e2                	ld	s3,24(sp)
    8000457e:	6a42                	ld	s4,16(sp)
    80004580:	6aa2                	ld	s5,8(sp)
    80004582:	6b02                	ld	s6,0(sp)
    80004584:	6121                	addi	sp,sp,64
    80004586:	8082                	ret
    80004588:	8082                	ret

000000008000458a <initlog>:
{
    8000458a:	7179                	addi	sp,sp,-48
    8000458c:	f406                	sd	ra,40(sp)
    8000458e:	f022                	sd	s0,32(sp)
    80004590:	ec26                	sd	s1,24(sp)
    80004592:	e84a                	sd	s2,16(sp)
    80004594:	e44e                	sd	s3,8(sp)
    80004596:	1800                	addi	s0,sp,48
    80004598:	892a                	mv	s2,a0
    8000459a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000459c:	00023497          	auipc	s1,0x23
    800045a0:	2d448493          	addi	s1,s1,724 # 80027870 <log>
    800045a4:	00004597          	auipc	a1,0x4
    800045a8:	0bc58593          	addi	a1,a1,188 # 80008660 <syscalls+0x1f0>
    800045ac:	8526                	mv	a0,s1
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	584080e7          	jalr	1412(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800045b6:	0149a583          	lw	a1,20(s3)
    800045ba:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045bc:	0109a783          	lw	a5,16(s3)
    800045c0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045c2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045c6:	854a                	mv	a0,s2
    800045c8:	fffff097          	auipc	ra,0xfffff
    800045cc:	e8e080e7          	jalr	-370(ra) # 80003456 <bread>
  log.lh.n = lh->n;
    800045d0:	4d34                	lw	a3,88(a0)
    800045d2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045d4:	02d05663          	blez	a3,80004600 <initlog+0x76>
    800045d8:	05c50793          	addi	a5,a0,92
    800045dc:	00023717          	auipc	a4,0x23
    800045e0:	2c470713          	addi	a4,a4,708 # 800278a0 <log+0x30>
    800045e4:	36fd                	addiw	a3,a3,-1
    800045e6:	02069613          	slli	a2,a3,0x20
    800045ea:	01e65693          	srli	a3,a2,0x1e
    800045ee:	06050613          	addi	a2,a0,96
    800045f2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045f4:	4390                	lw	a2,0(a5)
    800045f6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045f8:	0791                	addi	a5,a5,4
    800045fa:	0711                	addi	a4,a4,4
    800045fc:	fed79ce3          	bne	a5,a3,800045f4 <initlog+0x6a>
  brelse(buf);
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	f86080e7          	jalr	-122(ra) # 80003586 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004608:	4505                	li	a0,1
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	ebc080e7          	jalr	-324(ra) # 800044c6 <install_trans>
  log.lh.n = 0;
    80004612:	00023797          	auipc	a5,0x23
    80004616:	2807a523          	sw	zero,650(a5) # 8002789c <log+0x2c>
  write_head(); // clear the log
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	e30080e7          	jalr	-464(ra) # 8000444a <write_head>
}
    80004622:	70a2                	ld	ra,40(sp)
    80004624:	7402                	ld	s0,32(sp)
    80004626:	64e2                	ld	s1,24(sp)
    80004628:	6942                	ld	s2,16(sp)
    8000462a:	69a2                	ld	s3,8(sp)
    8000462c:	6145                	addi	sp,sp,48
    8000462e:	8082                	ret

0000000080004630 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004630:	1101                	addi	sp,sp,-32
    80004632:	ec06                	sd	ra,24(sp)
    80004634:	e822                	sd	s0,16(sp)
    80004636:	e426                	sd	s1,8(sp)
    80004638:	e04a                	sd	s2,0(sp)
    8000463a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000463c:	00023517          	auipc	a0,0x23
    80004640:	23450513          	addi	a0,a0,564 # 80027870 <log>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	57e080e7          	jalr	1406(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000464c:	00023497          	auipc	s1,0x23
    80004650:	22448493          	addi	s1,s1,548 # 80027870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004654:	4979                	li	s2,30
    80004656:	a039                	j	80004664 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004658:	85a6                	mv	a1,s1
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffe097          	auipc	ra,0xffffe
    80004660:	d96080e7          	jalr	-618(ra) # 800023f2 <sleep>
    if(log.committing){
    80004664:	50dc                	lw	a5,36(s1)
    80004666:	fbed                	bnez	a5,80004658 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004668:	509c                	lw	a5,32(s1)
    8000466a:	0017871b          	addiw	a4,a5,1
    8000466e:	0007069b          	sext.w	a3,a4
    80004672:	0027179b          	slliw	a5,a4,0x2
    80004676:	9fb9                	addw	a5,a5,a4
    80004678:	0017979b          	slliw	a5,a5,0x1
    8000467c:	54d8                	lw	a4,44(s1)
    8000467e:	9fb9                	addw	a5,a5,a4
    80004680:	00f95963          	bge	s2,a5,80004692 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004684:	85a6                	mv	a1,s1
    80004686:	8526                	mv	a0,s1
    80004688:	ffffe097          	auipc	ra,0xffffe
    8000468c:	d6a080e7          	jalr	-662(ra) # 800023f2 <sleep>
    80004690:	bfd1                	j	80004664 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004692:	00023517          	auipc	a0,0x23
    80004696:	1de50513          	addi	a0,a0,478 # 80027870 <log>
    8000469a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	5ec080e7          	jalr	1516(ra) # 80000c88 <release>
      break;
    }
  }
}
    800046a4:	60e2                	ld	ra,24(sp)
    800046a6:	6442                	ld	s0,16(sp)
    800046a8:	64a2                	ld	s1,8(sp)
    800046aa:	6902                	ld	s2,0(sp)
    800046ac:	6105                	addi	sp,sp,32
    800046ae:	8082                	ret

00000000800046b0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046b0:	7139                	addi	sp,sp,-64
    800046b2:	fc06                	sd	ra,56(sp)
    800046b4:	f822                	sd	s0,48(sp)
    800046b6:	f426                	sd	s1,40(sp)
    800046b8:	f04a                	sd	s2,32(sp)
    800046ba:	ec4e                	sd	s3,24(sp)
    800046bc:	e852                	sd	s4,16(sp)
    800046be:	e456                	sd	s5,8(sp)
    800046c0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046c2:	00023497          	auipc	s1,0x23
    800046c6:	1ae48493          	addi	s1,s1,430 # 80027870 <log>
    800046ca:	8526                	mv	a0,s1
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	4f6080e7          	jalr	1270(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800046d4:	509c                	lw	a5,32(s1)
    800046d6:	37fd                	addiw	a5,a5,-1
    800046d8:	0007891b          	sext.w	s2,a5
    800046dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046de:	50dc                	lw	a5,36(s1)
    800046e0:	e7b9                	bnez	a5,8000472e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046e2:	04091e63          	bnez	s2,8000473e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046e6:	00023497          	auipc	s1,0x23
    800046ea:	18a48493          	addi	s1,s1,394 # 80027870 <log>
    800046ee:	4785                	li	a5,1
    800046f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	594080e7          	jalr	1428(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046fc:	54dc                	lw	a5,44(s1)
    800046fe:	06f04763          	bgtz	a5,8000476c <end_op+0xbc>
    acquire(&log.lock);
    80004702:	00023497          	auipc	s1,0x23
    80004706:	16e48493          	addi	s1,s1,366 # 80027870 <log>
    8000470a:	8526                	mv	a0,s1
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	4b6080e7          	jalr	1206(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004714:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004718:	8526                	mv	a0,s1
    8000471a:	ffffe097          	auipc	ra,0xffffe
    8000471e:	e66080e7          	jalr	-410(ra) # 80002580 <wakeup>
    release(&log.lock);
    80004722:	8526                	mv	a0,s1
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	564080e7          	jalr	1380(ra) # 80000c88 <release>
}
    8000472c:	a03d                	j	8000475a <end_op+0xaa>
    panic("log.committing");
    8000472e:	00004517          	auipc	a0,0x4
    80004732:	f3a50513          	addi	a0,a0,-198 # 80008668 <syscalls+0x1f8>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	df4080e7          	jalr	-524(ra) # 8000052a <panic>
    wakeup(&log);
    8000473e:	00023497          	auipc	s1,0x23
    80004742:	13248493          	addi	s1,s1,306 # 80027870 <log>
    80004746:	8526                	mv	a0,s1
    80004748:	ffffe097          	auipc	ra,0xffffe
    8000474c:	e38080e7          	jalr	-456(ra) # 80002580 <wakeup>
  release(&log.lock);
    80004750:	8526                	mv	a0,s1
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	536080e7          	jalr	1334(ra) # 80000c88 <release>
}
    8000475a:	70e2                	ld	ra,56(sp)
    8000475c:	7442                	ld	s0,48(sp)
    8000475e:	74a2                	ld	s1,40(sp)
    80004760:	7902                	ld	s2,32(sp)
    80004762:	69e2                	ld	s3,24(sp)
    80004764:	6a42                	ld	s4,16(sp)
    80004766:	6aa2                	ld	s5,8(sp)
    80004768:	6121                	addi	sp,sp,64
    8000476a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476c:	00023a97          	auipc	s5,0x23
    80004770:	134a8a93          	addi	s5,s5,308 # 800278a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004774:	00023a17          	auipc	s4,0x23
    80004778:	0fca0a13          	addi	s4,s4,252 # 80027870 <log>
    8000477c:	018a2583          	lw	a1,24(s4)
    80004780:	012585bb          	addw	a1,a1,s2
    80004784:	2585                	addiw	a1,a1,1
    80004786:	028a2503          	lw	a0,40(s4)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	ccc080e7          	jalr	-820(ra) # 80003456 <bread>
    80004792:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004794:	000aa583          	lw	a1,0(s5)
    80004798:	028a2503          	lw	a0,40(s4)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	cba080e7          	jalr	-838(ra) # 80003456 <bread>
    800047a4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047a6:	40000613          	li	a2,1024
    800047aa:	05850593          	addi	a1,a0,88
    800047ae:	05848513          	addi	a0,s1,88
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	58c080e7          	jalr	1420(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    800047ba:	8526                	mv	a0,s1
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	d8c080e7          	jalr	-628(ra) # 80003548 <bwrite>
    brelse(from);
    800047c4:	854e                	mv	a0,s3
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	dc0080e7          	jalr	-576(ra) # 80003586 <brelse>
    brelse(to);
    800047ce:	8526                	mv	a0,s1
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	db6080e7          	jalr	-586(ra) # 80003586 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d8:	2905                	addiw	s2,s2,1
    800047da:	0a91                	addi	s5,s5,4
    800047dc:	02ca2783          	lw	a5,44(s4)
    800047e0:	f8f94ee3          	blt	s2,a5,8000477c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	c66080e7          	jalr	-922(ra) # 8000444a <write_head>
    install_trans(0); // Now install writes to home locations
    800047ec:	4501                	li	a0,0
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	cd8080e7          	jalr	-808(ra) # 800044c6 <install_trans>
    log.lh.n = 0;
    800047f6:	00023797          	auipc	a5,0x23
    800047fa:	0a07a323          	sw	zero,166(a5) # 8002789c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	c4c080e7          	jalr	-948(ra) # 8000444a <write_head>
    80004806:	bdf5                	j	80004702 <end_op+0x52>

0000000080004808 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004808:	1101                	addi	sp,sp,-32
    8000480a:	ec06                	sd	ra,24(sp)
    8000480c:	e822                	sd	s0,16(sp)
    8000480e:	e426                	sd	s1,8(sp)
    80004810:	e04a                	sd	s2,0(sp)
    80004812:	1000                	addi	s0,sp,32
    80004814:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004816:	00023917          	auipc	s2,0x23
    8000481a:	05a90913          	addi	s2,s2,90 # 80027870 <log>
    8000481e:	854a                	mv	a0,s2
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	3a2080e7          	jalr	930(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004828:	02c92603          	lw	a2,44(s2)
    8000482c:	47f5                	li	a5,29
    8000482e:	06c7c563          	blt	a5,a2,80004898 <log_write+0x90>
    80004832:	00023797          	auipc	a5,0x23
    80004836:	05a7a783          	lw	a5,90(a5) # 8002788c <log+0x1c>
    8000483a:	37fd                	addiw	a5,a5,-1
    8000483c:	04f65e63          	bge	a2,a5,80004898 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004840:	00023797          	auipc	a5,0x23
    80004844:	0507a783          	lw	a5,80(a5) # 80027890 <log+0x20>
    80004848:	06f05063          	blez	a5,800048a8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000484c:	4781                	li	a5,0
    8000484e:	06c05563          	blez	a2,800048b8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004852:	44cc                	lw	a1,12(s1)
    80004854:	00023717          	auipc	a4,0x23
    80004858:	04c70713          	addi	a4,a4,76 # 800278a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000485c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000485e:	4314                	lw	a3,0(a4)
    80004860:	04b68c63          	beq	a3,a1,800048b8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004864:	2785                	addiw	a5,a5,1
    80004866:	0711                	addi	a4,a4,4
    80004868:	fef61be3          	bne	a2,a5,8000485e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000486c:	0621                	addi	a2,a2,8
    8000486e:	060a                	slli	a2,a2,0x2
    80004870:	00023797          	auipc	a5,0x23
    80004874:	00078793          	mv	a5,a5
    80004878:	963e                	add	a2,a2,a5
    8000487a:	44dc                	lw	a5,12(s1)
    8000487c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000487e:	8526                	mv	a0,s1
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	da4080e7          	jalr	-604(ra) # 80003624 <bpin>
    log.lh.n++;
    80004888:	00023717          	auipc	a4,0x23
    8000488c:	fe870713          	addi	a4,a4,-24 # 80027870 <log>
    80004890:	575c                	lw	a5,44(a4)
    80004892:	2785                	addiw	a5,a5,1
    80004894:	d75c                	sw	a5,44(a4)
    80004896:	a835                	j	800048d2 <log_write+0xca>
    panic("too big a transaction");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	de050513          	addi	a0,a0,-544 # 80008678 <syscalls+0x208>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c8a080e7          	jalr	-886(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800048a8:	00004517          	auipc	a0,0x4
    800048ac:	de850513          	addi	a0,a0,-536 # 80008690 <syscalls+0x220>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	c7a080e7          	jalr	-902(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800048b8:	00878713          	addi	a4,a5,8 # 80027878 <log+0x8>
    800048bc:	00271693          	slli	a3,a4,0x2
    800048c0:	00023717          	auipc	a4,0x23
    800048c4:	fb070713          	addi	a4,a4,-80 # 80027870 <log>
    800048c8:	9736                	add	a4,a4,a3
    800048ca:	44d4                	lw	a3,12(s1)
    800048cc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048ce:	faf608e3          	beq	a2,a5,8000487e <log_write+0x76>
  }
  release(&log.lock);
    800048d2:	00023517          	auipc	a0,0x23
    800048d6:	f9e50513          	addi	a0,a0,-98 # 80027870 <log>
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	3ae080e7          	jalr	942(ra) # 80000c88 <release>
}
    800048e2:	60e2                	ld	ra,24(sp)
    800048e4:	6442                	ld	s0,16(sp)
    800048e6:	64a2                	ld	s1,8(sp)
    800048e8:	6902                	ld	s2,0(sp)
    800048ea:	6105                	addi	sp,sp,32
    800048ec:	8082                	ret

00000000800048ee <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048ee:	1101                	addi	sp,sp,-32
    800048f0:	ec06                	sd	ra,24(sp)
    800048f2:	e822                	sd	s0,16(sp)
    800048f4:	e426                	sd	s1,8(sp)
    800048f6:	e04a                	sd	s2,0(sp)
    800048f8:	1000                	addi	s0,sp,32
    800048fa:	84aa                	mv	s1,a0
    800048fc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048fe:	00004597          	auipc	a1,0x4
    80004902:	db258593          	addi	a1,a1,-590 # 800086b0 <syscalls+0x240>
    80004906:	0521                	addi	a0,a0,8
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	22a080e7          	jalr	554(ra) # 80000b32 <initlock>
  lk->name = name;
    80004910:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004914:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004918:	0204a423          	sw	zero,40(s1)
}
    8000491c:	60e2                	ld	ra,24(sp)
    8000491e:	6442                	ld	s0,16(sp)
    80004920:	64a2                	ld	s1,8(sp)
    80004922:	6902                	ld	s2,0(sp)
    80004924:	6105                	addi	sp,sp,32
    80004926:	8082                	ret

0000000080004928 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004928:	1101                	addi	sp,sp,-32
    8000492a:	ec06                	sd	ra,24(sp)
    8000492c:	e822                	sd	s0,16(sp)
    8000492e:	e426                	sd	s1,8(sp)
    80004930:	e04a                	sd	s2,0(sp)
    80004932:	1000                	addi	s0,sp,32
    80004934:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004936:	00850913          	addi	s2,a0,8
    8000493a:	854a                	mv	a0,s2
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	286080e7          	jalr	646(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004944:	409c                	lw	a5,0(s1)
    80004946:	cb89                	beqz	a5,80004958 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004948:	85ca                	mv	a1,s2
    8000494a:	8526                	mv	a0,s1
    8000494c:	ffffe097          	auipc	ra,0xffffe
    80004950:	aa6080e7          	jalr	-1370(ra) # 800023f2 <sleep>
  while (lk->locked) {
    80004954:	409c                	lw	a5,0(s1)
    80004956:	fbed                	bnez	a5,80004948 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004958:	4785                	li	a5,1
    8000495a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000495c:	ffffd097          	auipc	ra,0xffffd
    80004960:	048080e7          	jalr	72(ra) # 800019a4 <myproc>
    80004964:	591c                	lw	a5,48(a0)
    80004966:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004968:	854a                	mv	a0,s2
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	31e080e7          	jalr	798(ra) # 80000c88 <release>
}
    80004972:	60e2                	ld	ra,24(sp)
    80004974:	6442                	ld	s0,16(sp)
    80004976:	64a2                	ld	s1,8(sp)
    80004978:	6902                	ld	s2,0(sp)
    8000497a:	6105                	addi	sp,sp,32
    8000497c:	8082                	ret

000000008000497e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000497e:	1101                	addi	sp,sp,-32
    80004980:	ec06                	sd	ra,24(sp)
    80004982:	e822                	sd	s0,16(sp)
    80004984:	e426                	sd	s1,8(sp)
    80004986:	e04a                	sd	s2,0(sp)
    80004988:	1000                	addi	s0,sp,32
    8000498a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000498c:	00850913          	addi	s2,a0,8
    80004990:	854a                	mv	a0,s2
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	230080e7          	jalr	560(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000499a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000499e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049a2:	8526                	mv	a0,s1
    800049a4:	ffffe097          	auipc	ra,0xffffe
    800049a8:	bdc080e7          	jalr	-1060(ra) # 80002580 <wakeup>
  release(&lk->lk);
    800049ac:	854a                	mv	a0,s2
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	2da080e7          	jalr	730(ra) # 80000c88 <release>
}
    800049b6:	60e2                	ld	ra,24(sp)
    800049b8:	6442                	ld	s0,16(sp)
    800049ba:	64a2                	ld	s1,8(sp)
    800049bc:	6902                	ld	s2,0(sp)
    800049be:	6105                	addi	sp,sp,32
    800049c0:	8082                	ret

00000000800049c2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049c2:	7179                	addi	sp,sp,-48
    800049c4:	f406                	sd	ra,40(sp)
    800049c6:	f022                	sd	s0,32(sp)
    800049c8:	ec26                	sd	s1,24(sp)
    800049ca:	e84a                	sd	s2,16(sp)
    800049cc:	e44e                	sd	s3,8(sp)
    800049ce:	1800                	addi	s0,sp,48
    800049d0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049d2:	00850913          	addi	s2,a0,8
    800049d6:	854a                	mv	a0,s2
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	1ea080e7          	jalr	490(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049e0:	409c                	lw	a5,0(s1)
    800049e2:	ef99                	bnez	a5,80004a00 <holdingsleep+0x3e>
    800049e4:	4481                	li	s1,0
  release(&lk->lk);
    800049e6:	854a                	mv	a0,s2
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	2a0080e7          	jalr	672(ra) # 80000c88 <release>
  return r;
}
    800049f0:	8526                	mv	a0,s1
    800049f2:	70a2                	ld	ra,40(sp)
    800049f4:	7402                	ld	s0,32(sp)
    800049f6:	64e2                	ld	s1,24(sp)
    800049f8:	6942                	ld	s2,16(sp)
    800049fa:	69a2                	ld	s3,8(sp)
    800049fc:	6145                	addi	sp,sp,48
    800049fe:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a00:	0284a983          	lw	s3,40(s1)
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	fa0080e7          	jalr	-96(ra) # 800019a4 <myproc>
    80004a0c:	5904                	lw	s1,48(a0)
    80004a0e:	413484b3          	sub	s1,s1,s3
    80004a12:	0014b493          	seqz	s1,s1
    80004a16:	bfc1                	j	800049e6 <holdingsleep+0x24>

0000000080004a18 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a18:	1141                	addi	sp,sp,-16
    80004a1a:	e406                	sd	ra,8(sp)
    80004a1c:	e022                	sd	s0,0(sp)
    80004a1e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a20:	00004597          	auipc	a1,0x4
    80004a24:	ca058593          	addi	a1,a1,-864 # 800086c0 <syscalls+0x250>
    80004a28:	00023517          	auipc	a0,0x23
    80004a2c:	f9050513          	addi	a0,a0,-112 # 800279b8 <ftable>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	102080e7          	jalr	258(ra) # 80000b32 <initlock>
}
    80004a38:	60a2                	ld	ra,8(sp)
    80004a3a:	6402                	ld	s0,0(sp)
    80004a3c:	0141                	addi	sp,sp,16
    80004a3e:	8082                	ret

0000000080004a40 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a40:	1101                	addi	sp,sp,-32
    80004a42:	ec06                	sd	ra,24(sp)
    80004a44:	e822                	sd	s0,16(sp)
    80004a46:	e426                	sd	s1,8(sp)
    80004a48:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a4a:	00023517          	auipc	a0,0x23
    80004a4e:	f6e50513          	addi	a0,a0,-146 # 800279b8 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	170080e7          	jalr	368(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a5a:	00023497          	auipc	s1,0x23
    80004a5e:	f7648493          	addi	s1,s1,-138 # 800279d0 <ftable+0x18>
    80004a62:	00024717          	auipc	a4,0x24
    80004a66:	f0e70713          	addi	a4,a4,-242 # 80028970 <ftable+0xfb8>
    if(f->ref == 0){
    80004a6a:	40dc                	lw	a5,4(s1)
    80004a6c:	cf99                	beqz	a5,80004a8a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a6e:	02848493          	addi	s1,s1,40
    80004a72:	fee49ce3          	bne	s1,a4,80004a6a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a76:	00023517          	auipc	a0,0x23
    80004a7a:	f4250513          	addi	a0,a0,-190 # 800279b8 <ftable>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	20a080e7          	jalr	522(ra) # 80000c88 <release>
  return 0;
    80004a86:	4481                	li	s1,0
    80004a88:	a819                	j	80004a9e <filealloc+0x5e>
      f->ref = 1;
    80004a8a:	4785                	li	a5,1
    80004a8c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a8e:	00023517          	auipc	a0,0x23
    80004a92:	f2a50513          	addi	a0,a0,-214 # 800279b8 <ftable>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	1f2080e7          	jalr	498(ra) # 80000c88 <release>
}
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	60e2                	ld	ra,24(sp)
    80004aa2:	6442                	ld	s0,16(sp)
    80004aa4:	64a2                	ld	s1,8(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	1000                	addi	s0,sp,32
    80004ab4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ab6:	00023517          	auipc	a0,0x23
    80004aba:	f0250513          	addi	a0,a0,-254 # 800279b8 <ftable>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	104080e7          	jalr	260(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004ac6:	40dc                	lw	a5,4(s1)
    80004ac8:	02f05263          	blez	a5,80004aec <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004acc:	2785                	addiw	a5,a5,1
    80004ace:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ad0:	00023517          	auipc	a0,0x23
    80004ad4:	ee850513          	addi	a0,a0,-280 # 800279b8 <ftable>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	1b0080e7          	jalr	432(ra) # 80000c88 <release>
  return f;
}
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	60e2                	ld	ra,24(sp)
    80004ae4:	6442                	ld	s0,16(sp)
    80004ae6:	64a2                	ld	s1,8(sp)
    80004ae8:	6105                	addi	sp,sp,32
    80004aea:	8082                	ret
    panic("filedup");
    80004aec:	00004517          	auipc	a0,0x4
    80004af0:	bdc50513          	addi	a0,a0,-1060 # 800086c8 <syscalls+0x258>
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	a36080e7          	jalr	-1482(ra) # 8000052a <panic>

0000000080004afc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004afc:	7139                	addi	sp,sp,-64
    80004afe:	fc06                	sd	ra,56(sp)
    80004b00:	f822                	sd	s0,48(sp)
    80004b02:	f426                	sd	s1,40(sp)
    80004b04:	f04a                	sd	s2,32(sp)
    80004b06:	ec4e                	sd	s3,24(sp)
    80004b08:	e852                	sd	s4,16(sp)
    80004b0a:	e456                	sd	s5,8(sp)
    80004b0c:	0080                	addi	s0,sp,64
    80004b0e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b10:	00023517          	auipc	a0,0x23
    80004b14:	ea850513          	addi	a0,a0,-344 # 800279b8 <ftable>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	0aa080e7          	jalr	170(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004b20:	40dc                	lw	a5,4(s1)
    80004b22:	06f05163          	blez	a5,80004b84 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b26:	37fd                	addiw	a5,a5,-1
    80004b28:	0007871b          	sext.w	a4,a5
    80004b2c:	c0dc                	sw	a5,4(s1)
    80004b2e:	06e04363          	bgtz	a4,80004b94 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b32:	0004a903          	lw	s2,0(s1)
    80004b36:	0094ca83          	lbu	s5,9(s1)
    80004b3a:	0104ba03          	ld	s4,16(s1)
    80004b3e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b42:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b46:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b4a:	00023517          	auipc	a0,0x23
    80004b4e:	e6e50513          	addi	a0,a0,-402 # 800279b8 <ftable>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	136080e7          	jalr	310(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    80004b5a:	4785                	li	a5,1
    80004b5c:	04f90d63          	beq	s2,a5,80004bb6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b60:	3979                	addiw	s2,s2,-2
    80004b62:	4785                	li	a5,1
    80004b64:	0527e063          	bltu	a5,s2,80004ba4 <fileclose+0xa8>
    begin_op();
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	ac8080e7          	jalr	-1336(ra) # 80004630 <begin_op>
    iput(ff.ip);
    80004b70:	854e                	mv	a0,s3
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	2a2080e7          	jalr	674(ra) # 80003e14 <iput>
    end_op();
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	b36080e7          	jalr	-1226(ra) # 800046b0 <end_op>
    80004b82:	a00d                	j	80004ba4 <fileclose+0xa8>
    panic("fileclose");
    80004b84:	00004517          	auipc	a0,0x4
    80004b88:	b4c50513          	addi	a0,a0,-1204 # 800086d0 <syscalls+0x260>
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	99e080e7          	jalr	-1634(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004b94:	00023517          	auipc	a0,0x23
    80004b98:	e2450513          	addi	a0,a0,-476 # 800279b8 <ftable>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	0ec080e7          	jalr	236(ra) # 80000c88 <release>
  }
}
    80004ba4:	70e2                	ld	ra,56(sp)
    80004ba6:	7442                	ld	s0,48(sp)
    80004ba8:	74a2                	ld	s1,40(sp)
    80004baa:	7902                	ld	s2,32(sp)
    80004bac:	69e2                	ld	s3,24(sp)
    80004bae:	6a42                	ld	s4,16(sp)
    80004bb0:	6aa2                	ld	s5,8(sp)
    80004bb2:	6121                	addi	sp,sp,64
    80004bb4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bb6:	85d6                	mv	a1,s5
    80004bb8:	8552                	mv	a0,s4
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	34c080e7          	jalr	844(ra) # 80004f06 <pipeclose>
    80004bc2:	b7cd                	j	80004ba4 <fileclose+0xa8>

0000000080004bc4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bc4:	715d                	addi	sp,sp,-80
    80004bc6:	e486                	sd	ra,72(sp)
    80004bc8:	e0a2                	sd	s0,64(sp)
    80004bca:	fc26                	sd	s1,56(sp)
    80004bcc:	f84a                	sd	s2,48(sp)
    80004bce:	f44e                	sd	s3,40(sp)
    80004bd0:	0880                	addi	s0,sp,80
    80004bd2:	84aa                	mv	s1,a0
    80004bd4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bd6:	ffffd097          	auipc	ra,0xffffd
    80004bda:	dce080e7          	jalr	-562(ra) # 800019a4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bde:	409c                	lw	a5,0(s1)
    80004be0:	37f9                	addiw	a5,a5,-2
    80004be2:	4705                	li	a4,1
    80004be4:	04f76763          	bltu	a4,a5,80004c32 <filestat+0x6e>
    80004be8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bea:	6c88                	ld	a0,24(s1)
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	06e080e7          	jalr	110(ra) # 80003c5a <ilock>
    stati(f->ip, &st);
    80004bf4:	fb840593          	addi	a1,s0,-72
    80004bf8:	6c88                	ld	a0,24(s1)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	2ea080e7          	jalr	746(ra) # 80003ee4 <stati>
    iunlock(f->ip);
    80004c02:	6c88                	ld	a0,24(s1)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	118080e7          	jalr	280(ra) # 80003d1c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c0c:	46e1                	li	a3,24
    80004c0e:	fb840613          	addi	a2,s0,-72
    80004c12:	85ce                	mv	a1,s3
    80004c14:	1e893503          	ld	a0,488(s2)
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	a4a080e7          	jalr	-1462(ra) # 80001662 <copyout>
    80004c20:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c24:	60a6                	ld	ra,72(sp)
    80004c26:	6406                	ld	s0,64(sp)
    80004c28:	74e2                	ld	s1,56(sp)
    80004c2a:	7942                	ld	s2,48(sp)
    80004c2c:	79a2                	ld	s3,40(sp)
    80004c2e:	6161                	addi	sp,sp,80
    80004c30:	8082                	ret
  return -1;
    80004c32:	557d                	li	a0,-1
    80004c34:	bfc5                	j	80004c24 <filestat+0x60>

0000000080004c36 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c36:	7179                	addi	sp,sp,-48
    80004c38:	f406                	sd	ra,40(sp)
    80004c3a:	f022                	sd	s0,32(sp)
    80004c3c:	ec26                	sd	s1,24(sp)
    80004c3e:	e84a                	sd	s2,16(sp)
    80004c40:	e44e                	sd	s3,8(sp)
    80004c42:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c44:	00854783          	lbu	a5,8(a0)
    80004c48:	c3d5                	beqz	a5,80004cec <fileread+0xb6>
    80004c4a:	84aa                	mv	s1,a0
    80004c4c:	89ae                	mv	s3,a1
    80004c4e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c50:	411c                	lw	a5,0(a0)
    80004c52:	4705                	li	a4,1
    80004c54:	04e78963          	beq	a5,a4,80004ca6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c58:	470d                	li	a4,3
    80004c5a:	04e78d63          	beq	a5,a4,80004cb4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c5e:	4709                	li	a4,2
    80004c60:	06e79e63          	bne	a5,a4,80004cdc <fileread+0xa6>
    ilock(f->ip);
    80004c64:	6d08                	ld	a0,24(a0)
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	ff4080e7          	jalr	-12(ra) # 80003c5a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c6e:	874a                	mv	a4,s2
    80004c70:	5094                	lw	a3,32(s1)
    80004c72:	864e                	mv	a2,s3
    80004c74:	4585                	li	a1,1
    80004c76:	6c88                	ld	a0,24(s1)
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	296080e7          	jalr	662(ra) # 80003f0e <readi>
    80004c80:	892a                	mv	s2,a0
    80004c82:	00a05563          	blez	a0,80004c8c <fileread+0x56>
      f->off += r;
    80004c86:	509c                	lw	a5,32(s1)
    80004c88:	9fa9                	addw	a5,a5,a0
    80004c8a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c8c:	6c88                	ld	a0,24(s1)
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	08e080e7          	jalr	142(ra) # 80003d1c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c96:	854a                	mv	a0,s2
    80004c98:	70a2                	ld	ra,40(sp)
    80004c9a:	7402                	ld	s0,32(sp)
    80004c9c:	64e2                	ld	s1,24(sp)
    80004c9e:	6942                	ld	s2,16(sp)
    80004ca0:	69a2                	ld	s3,8(sp)
    80004ca2:	6145                	addi	sp,sp,48
    80004ca4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ca6:	6908                	ld	a0,16(a0)
    80004ca8:	00000097          	auipc	ra,0x0
    80004cac:	3c0080e7          	jalr	960(ra) # 80005068 <piperead>
    80004cb0:	892a                	mv	s2,a0
    80004cb2:	b7d5                	j	80004c96 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cb4:	02451783          	lh	a5,36(a0)
    80004cb8:	03079693          	slli	a3,a5,0x30
    80004cbc:	92c1                	srli	a3,a3,0x30
    80004cbe:	4725                	li	a4,9
    80004cc0:	02d76863          	bltu	a4,a3,80004cf0 <fileread+0xba>
    80004cc4:	0792                	slli	a5,a5,0x4
    80004cc6:	00023717          	auipc	a4,0x23
    80004cca:	c5270713          	addi	a4,a4,-942 # 80027918 <devsw>
    80004cce:	97ba                	add	a5,a5,a4
    80004cd0:	639c                	ld	a5,0(a5)
    80004cd2:	c38d                	beqz	a5,80004cf4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cd4:	4505                	li	a0,1
    80004cd6:	9782                	jalr	a5
    80004cd8:	892a                	mv	s2,a0
    80004cda:	bf75                	j	80004c96 <fileread+0x60>
    panic("fileread");
    80004cdc:	00004517          	auipc	a0,0x4
    80004ce0:	a0450513          	addi	a0,a0,-1532 # 800086e0 <syscalls+0x270>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	846080e7          	jalr	-1978(ra) # 8000052a <panic>
    return -1;
    80004cec:	597d                	li	s2,-1
    80004cee:	b765                	j	80004c96 <fileread+0x60>
      return -1;
    80004cf0:	597d                	li	s2,-1
    80004cf2:	b755                	j	80004c96 <fileread+0x60>
    80004cf4:	597d                	li	s2,-1
    80004cf6:	b745                	j	80004c96 <fileread+0x60>

0000000080004cf8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cf8:	715d                	addi	sp,sp,-80
    80004cfa:	e486                	sd	ra,72(sp)
    80004cfc:	e0a2                	sd	s0,64(sp)
    80004cfe:	fc26                	sd	s1,56(sp)
    80004d00:	f84a                	sd	s2,48(sp)
    80004d02:	f44e                	sd	s3,40(sp)
    80004d04:	f052                	sd	s4,32(sp)
    80004d06:	ec56                	sd	s5,24(sp)
    80004d08:	e85a                	sd	s6,16(sp)
    80004d0a:	e45e                	sd	s7,8(sp)
    80004d0c:	e062                	sd	s8,0(sp)
    80004d0e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d10:	00954783          	lbu	a5,9(a0)
    80004d14:	10078663          	beqz	a5,80004e20 <filewrite+0x128>
    80004d18:	892a                	mv	s2,a0
    80004d1a:	8aae                	mv	s5,a1
    80004d1c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d1e:	411c                	lw	a5,0(a0)
    80004d20:	4705                	li	a4,1
    80004d22:	02e78263          	beq	a5,a4,80004d46 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d26:	470d                	li	a4,3
    80004d28:	02e78663          	beq	a5,a4,80004d54 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d2c:	4709                	li	a4,2
    80004d2e:	0ee79163          	bne	a5,a4,80004e10 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d32:	0ac05d63          	blez	a2,80004dec <filewrite+0xf4>
    int i = 0;
    80004d36:	4981                	li	s3,0
    80004d38:	6b05                	lui	s6,0x1
    80004d3a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d3e:	6b85                	lui	s7,0x1
    80004d40:	c00b8b9b          	addiw	s7,s7,-1024
    80004d44:	a861                	j	80004ddc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d46:	6908                	ld	a0,16(a0)
    80004d48:	00000097          	auipc	ra,0x0
    80004d4c:	22e080e7          	jalr	558(ra) # 80004f76 <pipewrite>
    80004d50:	8a2a                	mv	s4,a0
    80004d52:	a045                	j	80004df2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d54:	02451783          	lh	a5,36(a0)
    80004d58:	03079693          	slli	a3,a5,0x30
    80004d5c:	92c1                	srli	a3,a3,0x30
    80004d5e:	4725                	li	a4,9
    80004d60:	0cd76263          	bltu	a4,a3,80004e24 <filewrite+0x12c>
    80004d64:	0792                	slli	a5,a5,0x4
    80004d66:	00023717          	auipc	a4,0x23
    80004d6a:	bb270713          	addi	a4,a4,-1102 # 80027918 <devsw>
    80004d6e:	97ba                	add	a5,a5,a4
    80004d70:	679c                	ld	a5,8(a5)
    80004d72:	cbdd                	beqz	a5,80004e28 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d74:	4505                	li	a0,1
    80004d76:	9782                	jalr	a5
    80004d78:	8a2a                	mv	s4,a0
    80004d7a:	a8a5                	j	80004df2 <filewrite+0xfa>
    80004d7c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	8b0080e7          	jalr	-1872(ra) # 80004630 <begin_op>
      ilock(f->ip);
    80004d88:	01893503          	ld	a0,24(s2)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	ece080e7          	jalr	-306(ra) # 80003c5a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d94:	8762                	mv	a4,s8
    80004d96:	02092683          	lw	a3,32(s2)
    80004d9a:	01598633          	add	a2,s3,s5
    80004d9e:	4585                	li	a1,1
    80004da0:	01893503          	ld	a0,24(s2)
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	262080e7          	jalr	610(ra) # 80004006 <writei>
    80004dac:	84aa                	mv	s1,a0
    80004dae:	00a05763          	blez	a0,80004dbc <filewrite+0xc4>
        f->off += r;
    80004db2:	02092783          	lw	a5,32(s2)
    80004db6:	9fa9                	addw	a5,a5,a0
    80004db8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dbc:	01893503          	ld	a0,24(s2)
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	f5c080e7          	jalr	-164(ra) # 80003d1c <iunlock>
      end_op();
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	8e8080e7          	jalr	-1816(ra) # 800046b0 <end_op>

      if(r != n1){
    80004dd0:	009c1f63          	bne	s8,s1,80004dee <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dd4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dd8:	0149db63          	bge	s3,s4,80004dee <filewrite+0xf6>
      int n1 = n - i;
    80004ddc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004de0:	84be                	mv	s1,a5
    80004de2:	2781                	sext.w	a5,a5
    80004de4:	f8fb5ce3          	bge	s6,a5,80004d7c <filewrite+0x84>
    80004de8:	84de                	mv	s1,s7
    80004dea:	bf49                	j	80004d7c <filewrite+0x84>
    int i = 0;
    80004dec:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dee:	013a1f63          	bne	s4,s3,80004e0c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004df2:	8552                	mv	a0,s4
    80004df4:	60a6                	ld	ra,72(sp)
    80004df6:	6406                	ld	s0,64(sp)
    80004df8:	74e2                	ld	s1,56(sp)
    80004dfa:	7942                	ld	s2,48(sp)
    80004dfc:	79a2                	ld	s3,40(sp)
    80004dfe:	7a02                	ld	s4,32(sp)
    80004e00:	6ae2                	ld	s5,24(sp)
    80004e02:	6b42                	ld	s6,16(sp)
    80004e04:	6ba2                	ld	s7,8(sp)
    80004e06:	6c02                	ld	s8,0(sp)
    80004e08:	6161                	addi	sp,sp,80
    80004e0a:	8082                	ret
    ret = (i == n ? n : -1);
    80004e0c:	5a7d                	li	s4,-1
    80004e0e:	b7d5                	j	80004df2 <filewrite+0xfa>
    panic("filewrite");
    80004e10:	00004517          	auipc	a0,0x4
    80004e14:	8e050513          	addi	a0,a0,-1824 # 800086f0 <syscalls+0x280>
    80004e18:	ffffb097          	auipc	ra,0xffffb
    80004e1c:	712080e7          	jalr	1810(ra) # 8000052a <panic>
    return -1;
    80004e20:	5a7d                	li	s4,-1
    80004e22:	bfc1                	j	80004df2 <filewrite+0xfa>
      return -1;
    80004e24:	5a7d                	li	s4,-1
    80004e26:	b7f1                	j	80004df2 <filewrite+0xfa>
    80004e28:	5a7d                	li	s4,-1
    80004e2a:	b7e1                	j	80004df2 <filewrite+0xfa>

0000000080004e2c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e2c:	7179                	addi	sp,sp,-48
    80004e2e:	f406                	sd	ra,40(sp)
    80004e30:	f022                	sd	s0,32(sp)
    80004e32:	ec26                	sd	s1,24(sp)
    80004e34:	e84a                	sd	s2,16(sp)
    80004e36:	e44e                	sd	s3,8(sp)
    80004e38:	e052                	sd	s4,0(sp)
    80004e3a:	1800                	addi	s0,sp,48
    80004e3c:	84aa                	mv	s1,a0
    80004e3e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e40:	0005b023          	sd	zero,0(a1)
    80004e44:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	bf8080e7          	jalr	-1032(ra) # 80004a40 <filealloc>
    80004e50:	e088                	sd	a0,0(s1)
    80004e52:	c551                	beqz	a0,80004ede <pipealloc+0xb2>
    80004e54:	00000097          	auipc	ra,0x0
    80004e58:	bec080e7          	jalr	-1044(ra) # 80004a40 <filealloc>
    80004e5c:	00aa3023          	sd	a0,0(s4)
    80004e60:	c92d                	beqz	a0,80004ed2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	c70080e7          	jalr	-912(ra) # 80000ad2 <kalloc>
    80004e6a:	892a                	mv	s2,a0
    80004e6c:	c125                	beqz	a0,80004ecc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e6e:	4985                	li	s3,1
    80004e70:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e74:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e78:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e7c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e80:	00004597          	auipc	a1,0x4
    80004e84:	88058593          	addi	a1,a1,-1920 # 80008700 <syscalls+0x290>
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	caa080e7          	jalr	-854(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004e90:	609c                	ld	a5,0(s1)
    80004e92:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e96:	609c                	ld	a5,0(s1)
    80004e98:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e9c:	609c                	ld	a5,0(s1)
    80004e9e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ea2:	609c                	ld	a5,0(s1)
    80004ea4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ea8:	000a3783          	ld	a5,0(s4)
    80004eac:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004eb0:	000a3783          	ld	a5,0(s4)
    80004eb4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004eb8:	000a3783          	ld	a5,0(s4)
    80004ebc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ec0:	000a3783          	ld	a5,0(s4)
    80004ec4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ec8:	4501                	li	a0,0
    80004eca:	a025                	j	80004ef2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ecc:	6088                	ld	a0,0(s1)
    80004ece:	e501                	bnez	a0,80004ed6 <pipealloc+0xaa>
    80004ed0:	a039                	j	80004ede <pipealloc+0xb2>
    80004ed2:	6088                	ld	a0,0(s1)
    80004ed4:	c51d                	beqz	a0,80004f02 <pipealloc+0xd6>
    fileclose(*f0);
    80004ed6:	00000097          	auipc	ra,0x0
    80004eda:	c26080e7          	jalr	-986(ra) # 80004afc <fileclose>
  if(*f1)
    80004ede:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ee2:	557d                	li	a0,-1
  if(*f1)
    80004ee4:	c799                	beqz	a5,80004ef2 <pipealloc+0xc6>
    fileclose(*f1);
    80004ee6:	853e                	mv	a0,a5
    80004ee8:	00000097          	auipc	ra,0x0
    80004eec:	c14080e7          	jalr	-1004(ra) # 80004afc <fileclose>
  return -1;
    80004ef0:	557d                	li	a0,-1
}
    80004ef2:	70a2                	ld	ra,40(sp)
    80004ef4:	7402                	ld	s0,32(sp)
    80004ef6:	64e2                	ld	s1,24(sp)
    80004ef8:	6942                	ld	s2,16(sp)
    80004efa:	69a2                	ld	s3,8(sp)
    80004efc:	6a02                	ld	s4,0(sp)
    80004efe:	6145                	addi	sp,sp,48
    80004f00:	8082                	ret
  return -1;
    80004f02:	557d                	li	a0,-1
    80004f04:	b7fd                	j	80004ef2 <pipealloc+0xc6>

0000000080004f06 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f06:	1101                	addi	sp,sp,-32
    80004f08:	ec06                	sd	ra,24(sp)
    80004f0a:	e822                	sd	s0,16(sp)
    80004f0c:	e426                	sd	s1,8(sp)
    80004f0e:	e04a                	sd	s2,0(sp)
    80004f10:	1000                	addi	s0,sp,32
    80004f12:	84aa                	mv	s1,a0
    80004f14:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	cac080e7          	jalr	-852(ra) # 80000bc2 <acquire>
  if(writable){
    80004f1e:	02090d63          	beqz	s2,80004f58 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f22:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f26:	21848513          	addi	a0,s1,536
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	656080e7          	jalr	1622(ra) # 80002580 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f32:	2204b783          	ld	a5,544(s1)
    80004f36:	eb95                	bnez	a5,80004f6a <pipeclose+0x64>
    release(&pi->lock);
    80004f38:	8526                	mv	a0,s1
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	d4e080e7          	jalr	-690(ra) # 80000c88 <release>
    kfree((char*)pi);
    80004f42:	8526                	mv	a0,s1
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	a92080e7          	jalr	-1390(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004f4c:	60e2                	ld	ra,24(sp)
    80004f4e:	6442                	ld	s0,16(sp)
    80004f50:	64a2                	ld	s1,8(sp)
    80004f52:	6902                	ld	s2,0(sp)
    80004f54:	6105                	addi	sp,sp,32
    80004f56:	8082                	ret
    pi->readopen = 0;
    80004f58:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f5c:	21c48513          	addi	a0,s1,540
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	620080e7          	jalr	1568(ra) # 80002580 <wakeup>
    80004f68:	b7e9                	j	80004f32 <pipeclose+0x2c>
    release(&pi->lock);
    80004f6a:	8526                	mv	a0,s1
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	d1c080e7          	jalr	-740(ra) # 80000c88 <release>
}
    80004f74:	bfe1                	j	80004f4c <pipeclose+0x46>

0000000080004f76 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f76:	711d                	addi	sp,sp,-96
    80004f78:	ec86                	sd	ra,88(sp)
    80004f7a:	e8a2                	sd	s0,80(sp)
    80004f7c:	e4a6                	sd	s1,72(sp)
    80004f7e:	e0ca                	sd	s2,64(sp)
    80004f80:	fc4e                	sd	s3,56(sp)
    80004f82:	f852                	sd	s4,48(sp)
    80004f84:	f456                	sd	s5,40(sp)
    80004f86:	f05a                	sd	s6,32(sp)
    80004f88:	ec5e                	sd	s7,24(sp)
    80004f8a:	e862                	sd	s8,16(sp)
    80004f8c:	1080                	addi	s0,sp,96
    80004f8e:	84aa                	mv	s1,a0
    80004f90:	8aae                	mv	s5,a1
    80004f92:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	a10080e7          	jalr	-1520(ra) # 800019a4 <myproc>
    80004f9c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	c22080e7          	jalr	-990(ra) # 80000bc2 <acquire>
  while(i < n){
    80004fa8:	0b405363          	blez	s4,8000504e <pipewrite+0xd8>
  int i = 0;
    80004fac:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fae:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fb0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fb4:	21c48b93          	addi	s7,s1,540
    80004fb8:	a089                	j	80004ffa <pipewrite+0x84>
      release(&pi->lock);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	ccc080e7          	jalr	-820(ra) # 80000c88 <release>
      return -1;
    80004fc4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	60e6                	ld	ra,88(sp)
    80004fca:	6446                	ld	s0,80(sp)
    80004fcc:	64a6                	ld	s1,72(sp)
    80004fce:	6906                	ld	s2,64(sp)
    80004fd0:	79e2                	ld	s3,56(sp)
    80004fd2:	7a42                	ld	s4,48(sp)
    80004fd4:	7aa2                	ld	s5,40(sp)
    80004fd6:	7b02                	ld	s6,32(sp)
    80004fd8:	6be2                	ld	s7,24(sp)
    80004fda:	6c42                	ld	s8,16(sp)
    80004fdc:	6125                	addi	sp,sp,96
    80004fde:	8082                	ret
      wakeup(&pi->nread);
    80004fe0:	8562                	mv	a0,s8
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	59e080e7          	jalr	1438(ra) # 80002580 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fea:	85a6                	mv	a1,s1
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	404080e7          	jalr	1028(ra) # 800023f2 <sleep>
  while(i < n){
    80004ff6:	05495d63          	bge	s2,s4,80005050 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ffa:	2204a783          	lw	a5,544(s1)
    80004ffe:	dfd5                	beqz	a5,80004fba <pipewrite+0x44>
    80005000:	0289a783          	lw	a5,40(s3)
    80005004:	fbdd                	bnez	a5,80004fba <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005006:	2184a783          	lw	a5,536(s1)
    8000500a:	21c4a703          	lw	a4,540(s1)
    8000500e:	2007879b          	addiw	a5,a5,512
    80005012:	fcf707e3          	beq	a4,a5,80004fe0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005016:	4685                	li	a3,1
    80005018:	01590633          	add	a2,s2,s5
    8000501c:	faf40593          	addi	a1,s0,-81
    80005020:	1e89b503          	ld	a0,488(s3)
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	6ca080e7          	jalr	1738(ra) # 800016ee <copyin>
    8000502c:	03650263          	beq	a0,s6,80005050 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005030:	21c4a783          	lw	a5,540(s1)
    80005034:	0017871b          	addiw	a4,a5,1
    80005038:	20e4ae23          	sw	a4,540(s1)
    8000503c:	1ff7f793          	andi	a5,a5,511
    80005040:	97a6                	add	a5,a5,s1
    80005042:	faf44703          	lbu	a4,-81(s0)
    80005046:	00e78c23          	sb	a4,24(a5)
      i++;
    8000504a:	2905                	addiw	s2,s2,1
    8000504c:	b76d                	j	80004ff6 <pipewrite+0x80>
  int i = 0;
    8000504e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005050:	21848513          	addi	a0,s1,536
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	52c080e7          	jalr	1324(ra) # 80002580 <wakeup>
  release(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c2a080e7          	jalr	-982(ra) # 80000c88 <release>
  return i;
    80005066:	b785                	j	80004fc6 <pipewrite+0x50>

0000000080005068 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005068:	715d                	addi	sp,sp,-80
    8000506a:	e486                	sd	ra,72(sp)
    8000506c:	e0a2                	sd	s0,64(sp)
    8000506e:	fc26                	sd	s1,56(sp)
    80005070:	f84a                	sd	s2,48(sp)
    80005072:	f44e                	sd	s3,40(sp)
    80005074:	f052                	sd	s4,32(sp)
    80005076:	ec56                	sd	s5,24(sp)
    80005078:	e85a                	sd	s6,16(sp)
    8000507a:	0880                	addi	s0,sp,80
    8000507c:	84aa                	mv	s1,a0
    8000507e:	892e                	mv	s2,a1
    80005080:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	922080e7          	jalr	-1758(ra) # 800019a4 <myproc>
    8000508a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000508c:	8526                	mv	a0,s1
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	b34080e7          	jalr	-1228(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005096:	2184a703          	lw	a4,536(s1)
    8000509a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000509e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a2:	02f71463          	bne	a4,a5,800050ca <piperead+0x62>
    800050a6:	2244a783          	lw	a5,548(s1)
    800050aa:	c385                	beqz	a5,800050ca <piperead+0x62>
    if(pr->killed){
    800050ac:	028a2783          	lw	a5,40(s4)
    800050b0:	ebc1                	bnez	a5,80005140 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050b2:	85a6                	mv	a1,s1
    800050b4:	854e                	mv	a0,s3
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	33c080e7          	jalr	828(ra) # 800023f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050be:	2184a703          	lw	a4,536(s1)
    800050c2:	21c4a783          	lw	a5,540(s1)
    800050c6:	fef700e3          	beq	a4,a5,800050a6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050cc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ce:	05505363          	blez	s5,80005114 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800050d2:	2184a783          	lw	a5,536(s1)
    800050d6:	21c4a703          	lw	a4,540(s1)
    800050da:	02f70d63          	beq	a4,a5,80005114 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050de:	0017871b          	addiw	a4,a5,1
    800050e2:	20e4ac23          	sw	a4,536(s1)
    800050e6:	1ff7f793          	andi	a5,a5,511
    800050ea:	97a6                	add	a5,a5,s1
    800050ec:	0187c783          	lbu	a5,24(a5)
    800050f0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050f4:	4685                	li	a3,1
    800050f6:	fbf40613          	addi	a2,s0,-65
    800050fa:	85ca                	mv	a1,s2
    800050fc:	1e8a3503          	ld	a0,488(s4)
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	562080e7          	jalr	1378(ra) # 80001662 <copyout>
    80005108:	01650663          	beq	a0,s6,80005114 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000510c:	2985                	addiw	s3,s3,1
    8000510e:	0905                	addi	s2,s2,1
    80005110:	fd3a91e3          	bne	s5,s3,800050d2 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005114:	21c48513          	addi	a0,s1,540
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	468080e7          	jalr	1128(ra) # 80002580 <wakeup>
  release(&pi->lock);
    80005120:	8526                	mv	a0,s1
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	b66080e7          	jalr	-1178(ra) # 80000c88 <release>
  return i;
}
    8000512a:	854e                	mv	a0,s3
    8000512c:	60a6                	ld	ra,72(sp)
    8000512e:	6406                	ld	s0,64(sp)
    80005130:	74e2                	ld	s1,56(sp)
    80005132:	7942                	ld	s2,48(sp)
    80005134:	79a2                	ld	s3,40(sp)
    80005136:	7a02                	ld	s4,32(sp)
    80005138:	6ae2                	ld	s5,24(sp)
    8000513a:	6b42                	ld	s6,16(sp)
    8000513c:	6161                	addi	sp,sp,80
    8000513e:	8082                	ret
      release(&pi->lock);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	b46080e7          	jalr	-1210(ra) # 80000c88 <release>
      return -1;
    8000514a:	59fd                	li	s3,-1
    8000514c:	bff9                	j	8000512a <piperead+0xc2>

000000008000514e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000514e:	de010113          	addi	sp,sp,-544
    80005152:	20113c23          	sd	ra,536(sp)
    80005156:	20813823          	sd	s0,528(sp)
    8000515a:	20913423          	sd	s1,520(sp)
    8000515e:	21213023          	sd	s2,512(sp)
    80005162:	ffce                	sd	s3,504(sp)
    80005164:	fbd2                	sd	s4,496(sp)
    80005166:	f7d6                	sd	s5,488(sp)
    80005168:	f3da                	sd	s6,480(sp)
    8000516a:	efde                	sd	s7,472(sp)
    8000516c:	ebe2                	sd	s8,464(sp)
    8000516e:	e7e6                	sd	s9,456(sp)
    80005170:	e3ea                	sd	s10,448(sp)
    80005172:	ff6e                	sd	s11,440(sp)
    80005174:	1400                	addi	s0,sp,544
    80005176:	892a                	mv	s2,a0
    80005178:	dea43423          	sd	a0,-536(s0)
    8000517c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	824080e7          	jalr	-2012(ra) # 800019a4 <myproc>
    80005188:	84aa                	mv	s1,a0

  begin_op();
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	4a6080e7          	jalr	1190(ra) # 80004630 <begin_op>

  if((ip = namei(path)) == 0){
    80005192:	854a                	mv	a0,s2
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	27c080e7          	jalr	636(ra) # 80004410 <namei>
    8000519c:	c93d                	beqz	a0,80005212 <exec+0xc4>
    8000519e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	aba080e7          	jalr	-1350(ra) # 80003c5a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051a8:	04000713          	li	a4,64
    800051ac:	4681                	li	a3,0
    800051ae:	e4840613          	addi	a2,s0,-440
    800051b2:	4581                	li	a1,0
    800051b4:	8556                	mv	a0,s5
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	d58080e7          	jalr	-680(ra) # 80003f0e <readi>
    800051be:	04000793          	li	a5,64
    800051c2:	00f51a63          	bne	a0,a5,800051d6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051c6:	e4842703          	lw	a4,-440(s0)
    800051ca:	464c47b7          	lui	a5,0x464c4
    800051ce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051d2:	04f70663          	beq	a4,a5,8000521e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051d6:	8556                	mv	a0,s5
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	ce4080e7          	jalr	-796(ra) # 80003ebc <iunlockput>
    end_op();
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	4d0080e7          	jalr	1232(ra) # 800046b0 <end_op>
  }
  return -1;
    800051e8:	557d                	li	a0,-1
}
    800051ea:	21813083          	ld	ra,536(sp)
    800051ee:	21013403          	ld	s0,528(sp)
    800051f2:	20813483          	ld	s1,520(sp)
    800051f6:	20013903          	ld	s2,512(sp)
    800051fa:	79fe                	ld	s3,504(sp)
    800051fc:	7a5e                	ld	s4,496(sp)
    800051fe:	7abe                	ld	s5,488(sp)
    80005200:	7b1e                	ld	s6,480(sp)
    80005202:	6bfe                	ld	s7,472(sp)
    80005204:	6c5e                	ld	s8,464(sp)
    80005206:	6cbe                	ld	s9,456(sp)
    80005208:	6d1e                	ld	s10,448(sp)
    8000520a:	7dfa                	ld	s11,440(sp)
    8000520c:	22010113          	addi	sp,sp,544
    80005210:	8082                	ret
    end_op();
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	49e080e7          	jalr	1182(ra) # 800046b0 <end_op>
    return -1;
    8000521a:	557d                	li	a0,-1
    8000521c:	b7f9                	j	800051ea <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffd097          	auipc	ra,0xffffd
    80005224:	848080e7          	jalr	-1976(ra) # 80001a68 <proc_pagetable>
    80005228:	8b2a                	mv	s6,a0
    8000522a:	d555                	beqz	a0,800051d6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000522c:	e6842783          	lw	a5,-408(s0)
    80005230:	e8045703          	lhu	a4,-384(s0)
    80005234:	c735                	beqz	a4,800052a0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005236:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005238:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000523c:	6a05                	lui	s4,0x1
    8000523e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005242:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005246:	6d85                	lui	s11,0x1
    80005248:	7d7d                	lui	s10,0xfffff
    8000524a:	acb9                	j	800054a8 <exec+0x35a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000524c:	00003517          	auipc	a0,0x3
    80005250:	4bc50513          	addi	a0,a0,1212 # 80008708 <syscalls+0x298>
    80005254:	ffffb097          	auipc	ra,0xffffb
    80005258:	2d6080e7          	jalr	726(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000525c:	874a                	mv	a4,s2
    8000525e:	009c86bb          	addw	a3,s9,s1
    80005262:	4581                	li	a1,0
    80005264:	8556                	mv	a0,s5
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	ca8080e7          	jalr	-856(ra) # 80003f0e <readi>
    8000526e:	2501                	sext.w	a0,a0
    80005270:	1ca91c63          	bne	s2,a0,80005448 <exec+0x2fa>
  for(i = 0; i < sz; i += PGSIZE){
    80005274:	009d84bb          	addw	s1,s11,s1
    80005278:	013d09bb          	addw	s3,s10,s3
    8000527c:	2174f663          	bgeu	s1,s7,80005488 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    80005280:	02049593          	slli	a1,s1,0x20
    80005284:	9181                	srli	a1,a1,0x20
    80005286:	95e2                	add	a1,a1,s8
    80005288:	855a                	mv	a0,s6
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	de6080e7          	jalr	-538(ra) # 80001070 <walkaddr>
    80005292:	862a                	mv	a2,a0
    if(pa == 0)
    80005294:	dd45                	beqz	a0,8000524c <exec+0xfe>
      n = PGSIZE;
    80005296:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005298:	fd49f2e3          	bgeu	s3,s4,8000525c <exec+0x10e>
      n = sz - i;
    8000529c:	894e                	mv	s2,s3
    8000529e:	bf7d                	j	8000525c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800052a0:	4481                	li	s1,0
  iunlockput(ip);
    800052a2:	8556                	mv	a0,s5
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	c18080e7          	jalr	-1000(ra) # 80003ebc <iunlockput>
  end_op();
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	404080e7          	jalr	1028(ra) # 800046b0 <end_op>
  p = myproc();
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	6f0080e7          	jalr	1776(ra) # 800019a4 <myproc>
    800052bc:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    800052be:	1e053d03          	ld	s10,480(a0)
  sz = PGROUNDUP(sz);
    800052c2:	6785                	lui	a5,0x1
    800052c4:	17fd                	addi	a5,a5,-1
    800052c6:	94be                	add	s1,s1,a5
    800052c8:	77fd                	lui	a5,0xfffff
    800052ca:	8fe5                	and	a5,a5,s1
    800052cc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052d0:	6609                	lui	a2,0x2
    800052d2:	963e                	add	a2,a2,a5
    800052d4:	85be                	mv	a1,a5
    800052d6:	855a                	mv	a0,s6
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	13a080e7          	jalr	314(ra) # 80001412 <uvmalloc>
    800052e0:	8baa                	mv	s7,a0
  ip = 0;
    800052e2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052e4:	16050263          	beqz	a0,80005448 <exec+0x2fa>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052e8:	75f9                	lui	a1,0xffffe
    800052ea:	95aa                	add	a1,a1,a0
    800052ec:	855a                	mv	a0,s6
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	342080e7          	jalr	834(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    800052f6:	7c7d                	lui	s8,0xfffff
    800052f8:	9c5e                	add	s8,s8,s7
  for(argc = 0; argv[argc]; argc++) {
    800052fa:	df043783          	ld	a5,-528(s0)
    800052fe:	6388                	ld	a0,0(a5)
    80005300:	c925                	beqz	a0,80005370 <exec+0x222>
    80005302:	e8840993          	addi	s3,s0,-376
    80005306:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000530a:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    8000530c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	b58080e7          	jalr	-1192(ra) # 80000e66 <strlen>
    80005316:	0015079b          	addiw	a5,a0,1
    8000531a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000531e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005322:	15896763          	bltu	s2,s8,80005470 <exec+0x322>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005326:	df043d83          	ld	s11,-528(s0)
    8000532a:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    8000532e:	8556                	mv	a0,s5
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	b36080e7          	jalr	-1226(ra) # 80000e66 <strlen>
    80005338:	0015069b          	addiw	a3,a0,1
    8000533c:	8656                	mv	a2,s5
    8000533e:	85ca                	mv	a1,s2
    80005340:	855a                	mv	a0,s6
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	320080e7          	jalr	800(ra) # 80001662 <copyout>
    8000534a:	12054763          	bltz	a0,80005478 <exec+0x32a>
    ustack[argc] = sp;
    8000534e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005352:	0485                	addi	s1,s1,1
    80005354:	008d8793          	addi	a5,s11,8
    80005358:	def43823          	sd	a5,-528(s0)
    8000535c:	008db503          	ld	a0,8(s11)
    80005360:	c911                	beqz	a0,80005374 <exec+0x226>
    if(argc >= MAXARG)
    80005362:	09a1                	addi	s3,s3,8
    80005364:	fb9995e3          	bne	s3,s9,8000530e <exec+0x1c0>
  sz = sz1;
    80005368:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    8000536c:	4a81                	li	s5,0
    8000536e:	a8e9                	j	80005448 <exec+0x2fa>
  sp = sz;
    80005370:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80005372:	4481                	li	s1,0
  ustack[argc] = 0;
    80005374:	00349793          	slli	a5,s1,0x3
    80005378:	f9040713          	addi	a4,s0,-112
    8000537c:	97ba                	add	a5,a5,a4
    8000537e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005382:	00148693          	addi	a3,s1,1
    80005386:	068e                	slli	a3,a3,0x3
    80005388:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000538c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005390:	01897663          	bgeu	s2,s8,8000539c <exec+0x24e>
  sz = sz1;
    80005394:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005398:	4a81                	li	s5,0
    8000539a:	a07d                	j	80005448 <exec+0x2fa>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000539c:	e8840613          	addi	a2,s0,-376
    800053a0:	85ca                	mv	a1,s2
    800053a2:	855a                	mv	a0,s6
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	2be080e7          	jalr	702(ra) # 80001662 <copyout>
    800053ac:	0c054a63          	bltz	a0,80005480 <exec+0x332>
  p->trapframe->a1 = sp;
    800053b0:	1f0a3783          	ld	a5,496(s4)
    800053b4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053b8:	de843783          	ld	a5,-536(s0)
    800053bc:	0007c703          	lbu	a4,0(a5)
    800053c0:	cf11                	beqz	a4,800053dc <exec+0x28e>
    800053c2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053c4:	02f00693          	li	a3,47
    800053c8:	a039                	j	800053d6 <exec+0x288>
      last = s+1;
    800053ca:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053ce:	0785                	addi	a5,a5,1
    800053d0:	fff7c703          	lbu	a4,-1(a5)
    800053d4:	c701                	beqz	a4,800053dc <exec+0x28e>
    if(*s == '/')
    800053d6:	fed71ce3          	bne	a4,a3,800053ce <exec+0x280>
    800053da:	bfc5                	j	800053ca <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800053dc:	4641                	li	a2,16
    800053de:	de843583          	ld	a1,-536(s0)
    800053e2:	2f0a0513          	addi	a0,s4,752
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	a4e080e7          	jalr	-1458(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    800053ee:	1e8a3503          	ld	a0,488(s4)
  p->pagetable = pagetable;
    800053f2:	1f6a3423          	sd	s6,488(s4)
  p->sz = sz;
    800053f6:	1f7a3023          	sd	s7,480(s4)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053fa:	1f0a3783          	ld	a5,496(s4)
    800053fe:	e6043703          	ld	a4,-416(s0)
    80005402:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005404:	1f0a3783          	ld	a5,496(s4)
    80005408:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000540c:	85ea                	mv	a1,s10
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	6f6080e7          	jalr	1782(ra) # 80001b04 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005416:	140a0793          	addi	a5,s4,320
    8000541a:	040a0a13          	addi	s4,s4,64
    8000541e:	863e                	mv	a2,a5
   if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005420:	4685                	li	a3,1
    80005422:	a039                	j	80005430 <exec+0x2e2>
     p->signal_handlers[signum] = SIG_DFL;
    80005424:	000a3023          	sd	zero,0(s4)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005428:	0791                	addi	a5,a5,4
    8000542a:	0a21                	addi	s4,s4,8
    8000542c:	01460963          	beq	a2,s4,8000543e <exec+0x2f0>
   p->signal_handlers_masks[signum] = 0;
    80005430:	0007a023          	sw	zero,0(a5)
   if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005434:	000a3703          	ld	a4,0(s4)
    80005438:	fed716e3          	bne	a4,a3,80005424 <exec+0x2d6>
    8000543c:	b7f5                	j	80005428 <exec+0x2da>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000543e:	0004851b          	sext.w	a0,s1
    80005442:	b365                	j	800051ea <exec+0x9c>
    80005444:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005448:	df843583          	ld	a1,-520(s0)
    8000544c:	855a                	mv	a0,s6
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	6b6080e7          	jalr	1718(ra) # 80001b04 <proc_freepagetable>
  if(ip){
    80005456:	d80a90e3          	bnez	s5,800051d6 <exec+0x88>
  return -1;
    8000545a:	557d                	li	a0,-1
    8000545c:	b379                	j	800051ea <exec+0x9c>
    8000545e:	de943c23          	sd	s1,-520(s0)
    80005462:	b7dd                	j	80005448 <exec+0x2fa>
    80005464:	de943c23          	sd	s1,-520(s0)
    80005468:	b7c5                	j	80005448 <exec+0x2fa>
    8000546a:	de943c23          	sd	s1,-520(s0)
    8000546e:	bfe9                	j	80005448 <exec+0x2fa>
  sz = sz1;
    80005470:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005474:	4a81                	li	s5,0
    80005476:	bfc9                	j	80005448 <exec+0x2fa>
  sz = sz1;
    80005478:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    8000547c:	4a81                	li	s5,0
    8000547e:	b7e9                	j	80005448 <exec+0x2fa>
  sz = sz1;
    80005480:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005484:	4a81                	li	s5,0
    80005486:	b7c9                	j	80005448 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005488:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000548c:	e0843783          	ld	a5,-504(s0)
    80005490:	0017869b          	addiw	a3,a5,1
    80005494:	e0d43423          	sd	a3,-504(s0)
    80005498:	e0043783          	ld	a5,-512(s0)
    8000549c:	0387879b          	addiw	a5,a5,56
    800054a0:	e8045703          	lhu	a4,-384(s0)
    800054a4:	dee6dfe3          	bge	a3,a4,800052a2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054a8:	2781                	sext.w	a5,a5
    800054aa:	e0f43023          	sd	a5,-512(s0)
    800054ae:	03800713          	li	a4,56
    800054b2:	86be                	mv	a3,a5
    800054b4:	e1040613          	addi	a2,s0,-496
    800054b8:	4581                	li	a1,0
    800054ba:	8556                	mv	a0,s5
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	a52080e7          	jalr	-1454(ra) # 80003f0e <readi>
    800054c4:	03800793          	li	a5,56
    800054c8:	f6f51ee3          	bne	a0,a5,80005444 <exec+0x2f6>
    if(ph.type != ELF_PROG_LOAD)
    800054cc:	e1042783          	lw	a5,-496(s0)
    800054d0:	4705                	li	a4,1
    800054d2:	fae79de3          	bne	a5,a4,8000548c <exec+0x33e>
    if(ph.memsz < ph.filesz)
    800054d6:	e3843603          	ld	a2,-456(s0)
    800054da:	e3043783          	ld	a5,-464(s0)
    800054de:	f8f660e3          	bltu	a2,a5,8000545e <exec+0x310>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054e2:	e2043783          	ld	a5,-480(s0)
    800054e6:	963e                	add	a2,a2,a5
    800054e8:	f6f66ee3          	bltu	a2,a5,80005464 <exec+0x316>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054ec:	85a6                	mv	a1,s1
    800054ee:	855a                	mv	a0,s6
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	f22080e7          	jalr	-222(ra) # 80001412 <uvmalloc>
    800054f8:	dea43c23          	sd	a0,-520(s0)
    800054fc:	d53d                	beqz	a0,8000546a <exec+0x31c>
    if(ph.vaddr % PGSIZE != 0)
    800054fe:	e2043c03          	ld	s8,-480(s0)
    80005502:	de043783          	ld	a5,-544(s0)
    80005506:	00fc77b3          	and	a5,s8,a5
    8000550a:	ff9d                	bnez	a5,80005448 <exec+0x2fa>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000550c:	e1842c83          	lw	s9,-488(s0)
    80005510:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005514:	f60b8ae3          	beqz	s7,80005488 <exec+0x33a>
    80005518:	89de                	mv	s3,s7
    8000551a:	4481                	li	s1,0
    8000551c:	b395                	j	80005280 <exec+0x132>

000000008000551e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000551e:	7179                	addi	sp,sp,-48
    80005520:	f406                	sd	ra,40(sp)
    80005522:	f022                	sd	s0,32(sp)
    80005524:	ec26                	sd	s1,24(sp)
    80005526:	e84a                	sd	s2,16(sp)
    80005528:	1800                	addi	s0,sp,48
    8000552a:	892e                	mv	s2,a1
    8000552c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000552e:	fdc40593          	addi	a1,s0,-36
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	ae4080e7          	jalr	-1308(ra) # 80003016 <argint>
    8000553a:	04054063          	bltz	a0,8000557a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000553e:	fdc42703          	lw	a4,-36(s0)
    80005542:	47bd                	li	a5,15
    80005544:	02e7ed63          	bltu	a5,a4,8000557e <argfd+0x60>
    80005548:	ffffc097          	auipc	ra,0xffffc
    8000554c:	45c080e7          	jalr	1116(ra) # 800019a4 <myproc>
    80005550:	fdc42703          	lw	a4,-36(s0)
    80005554:	04c70793          	addi	a5,a4,76
    80005558:	078e                	slli	a5,a5,0x3
    8000555a:	953e                	add	a0,a0,a5
    8000555c:	651c                	ld	a5,8(a0)
    8000555e:	c395                	beqz	a5,80005582 <argfd+0x64>
    return -1;
  if(pfd)
    80005560:	00090463          	beqz	s2,80005568 <argfd+0x4a>
    *pfd = fd;
    80005564:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005568:	4501                	li	a0,0
  if(pf)
    8000556a:	c091                	beqz	s1,8000556e <argfd+0x50>
    *pf = f;
    8000556c:	e09c                	sd	a5,0(s1)
}
    8000556e:	70a2                	ld	ra,40(sp)
    80005570:	7402                	ld	s0,32(sp)
    80005572:	64e2                	ld	s1,24(sp)
    80005574:	6942                	ld	s2,16(sp)
    80005576:	6145                	addi	sp,sp,48
    80005578:	8082                	ret
    return -1;
    8000557a:	557d                	li	a0,-1
    8000557c:	bfcd                	j	8000556e <argfd+0x50>
    return -1;
    8000557e:	557d                	li	a0,-1
    80005580:	b7fd                	j	8000556e <argfd+0x50>
    80005582:	557d                	li	a0,-1
    80005584:	b7ed                	j	8000556e <argfd+0x50>

0000000080005586 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005586:	1101                	addi	sp,sp,-32
    80005588:	ec06                	sd	ra,24(sp)
    8000558a:	e822                	sd	s0,16(sp)
    8000558c:	e426                	sd	s1,8(sp)
    8000558e:	1000                	addi	s0,sp,32
    80005590:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005592:	ffffc097          	auipc	ra,0xffffc
    80005596:	412080e7          	jalr	1042(ra) # 800019a4 <myproc>
    8000559a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000559c:	26850793          	addi	a5,a0,616
    800055a0:	4501                	li	a0,0
    800055a2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055a4:	6398                	ld	a4,0(a5)
    800055a6:	cb19                	beqz	a4,800055bc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055a8:	2505                	addiw	a0,a0,1
    800055aa:	07a1                	addi	a5,a5,8
    800055ac:	fed51ce3          	bne	a0,a3,800055a4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055b0:	557d                	li	a0,-1
}
    800055b2:	60e2                	ld	ra,24(sp)
    800055b4:	6442                	ld	s0,16(sp)
    800055b6:	64a2                	ld	s1,8(sp)
    800055b8:	6105                	addi	sp,sp,32
    800055ba:	8082                	ret
      p->ofile[fd] = f;
    800055bc:	04c50793          	addi	a5,a0,76
    800055c0:	078e                	slli	a5,a5,0x3
    800055c2:	963e                	add	a2,a2,a5
    800055c4:	e604                	sd	s1,8(a2)
      return fd;
    800055c6:	b7f5                	j	800055b2 <fdalloc+0x2c>

00000000800055c8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055c8:	715d                	addi	sp,sp,-80
    800055ca:	e486                	sd	ra,72(sp)
    800055cc:	e0a2                	sd	s0,64(sp)
    800055ce:	fc26                	sd	s1,56(sp)
    800055d0:	f84a                	sd	s2,48(sp)
    800055d2:	f44e                	sd	s3,40(sp)
    800055d4:	f052                	sd	s4,32(sp)
    800055d6:	ec56                	sd	s5,24(sp)
    800055d8:	0880                	addi	s0,sp,80
    800055da:	89ae                	mv	s3,a1
    800055dc:	8ab2                	mv	s5,a2
    800055de:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055e0:	fb040593          	addi	a1,s0,-80
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	e4a080e7          	jalr	-438(ra) # 8000442e <nameiparent>
    800055ec:	892a                	mv	s2,a0
    800055ee:	12050e63          	beqz	a0,8000572a <create+0x162>
    return 0;

  ilock(dp);
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	668080e7          	jalr	1640(ra) # 80003c5a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055fa:	4601                	li	a2,0
    800055fc:	fb040593          	addi	a1,s0,-80
    80005600:	854a                	mv	a0,s2
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	b3c080e7          	jalr	-1220(ra) # 8000413e <dirlookup>
    8000560a:	84aa                	mv	s1,a0
    8000560c:	c921                	beqz	a0,8000565c <create+0x94>
    iunlockput(dp);
    8000560e:	854a                	mv	a0,s2
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	8ac080e7          	jalr	-1876(ra) # 80003ebc <iunlockput>
    ilock(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	640080e7          	jalr	1600(ra) # 80003c5a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005622:	2981                	sext.w	s3,s3
    80005624:	4789                	li	a5,2
    80005626:	02f99463          	bne	s3,a5,8000564e <create+0x86>
    8000562a:	0444d783          	lhu	a5,68(s1)
    8000562e:	37f9                	addiw	a5,a5,-2
    80005630:	17c2                	slli	a5,a5,0x30
    80005632:	93c1                	srli	a5,a5,0x30
    80005634:	4705                	li	a4,1
    80005636:	00f76c63          	bltu	a4,a5,8000564e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000563a:	8526                	mv	a0,s1
    8000563c:	60a6                	ld	ra,72(sp)
    8000563e:	6406                	ld	s0,64(sp)
    80005640:	74e2                	ld	s1,56(sp)
    80005642:	7942                	ld	s2,48(sp)
    80005644:	79a2                	ld	s3,40(sp)
    80005646:	7a02                	ld	s4,32(sp)
    80005648:	6ae2                	ld	s5,24(sp)
    8000564a:	6161                	addi	sp,sp,80
    8000564c:	8082                	ret
    iunlockput(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	86c080e7          	jalr	-1940(ra) # 80003ebc <iunlockput>
    return 0;
    80005658:	4481                	li	s1,0
    8000565a:	b7c5                	j	8000563a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000565c:	85ce                	mv	a1,s3
    8000565e:	00092503          	lw	a0,0(s2)
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	460080e7          	jalr	1120(ra) # 80003ac2 <ialloc>
    8000566a:	84aa                	mv	s1,a0
    8000566c:	c521                	beqz	a0,800056b4 <create+0xec>
  ilock(ip);
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	5ec080e7          	jalr	1516(ra) # 80003c5a <ilock>
  ip->major = major;
    80005676:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000567a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000567e:	4a05                	li	s4,1
    80005680:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	50a080e7          	jalr	1290(ra) # 80003b90 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000568e:	2981                	sext.w	s3,s3
    80005690:	03498a63          	beq	s3,s4,800056c4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005694:	40d0                	lw	a2,4(s1)
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	854a                	mv	a0,s2
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	cb2080e7          	jalr	-846(ra) # 8000434e <dirlink>
    800056a4:	06054b63          	bltz	a0,8000571a <create+0x152>
  iunlockput(dp);
    800056a8:	854a                	mv	a0,s2
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	812080e7          	jalr	-2030(ra) # 80003ebc <iunlockput>
  return ip;
    800056b2:	b761                	j	8000563a <create+0x72>
    panic("create: ialloc");
    800056b4:	00003517          	auipc	a0,0x3
    800056b8:	07450513          	addi	a0,a0,116 # 80008728 <syscalls+0x2b8>
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	e6e080e7          	jalr	-402(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800056c4:	04a95783          	lhu	a5,74(s2)
    800056c8:	2785                	addiw	a5,a5,1
    800056ca:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	4c0080e7          	jalr	1216(ra) # 80003b90 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056d8:	40d0                	lw	a2,4(s1)
    800056da:	00003597          	auipc	a1,0x3
    800056de:	05e58593          	addi	a1,a1,94 # 80008738 <syscalls+0x2c8>
    800056e2:	8526                	mv	a0,s1
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	c6a080e7          	jalr	-918(ra) # 8000434e <dirlink>
    800056ec:	00054f63          	bltz	a0,8000570a <create+0x142>
    800056f0:	00492603          	lw	a2,4(s2)
    800056f4:	00003597          	auipc	a1,0x3
    800056f8:	04c58593          	addi	a1,a1,76 # 80008740 <syscalls+0x2d0>
    800056fc:	8526                	mv	a0,s1
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	c50080e7          	jalr	-944(ra) # 8000434e <dirlink>
    80005706:	f80557e3          	bgez	a0,80005694 <create+0xcc>
      panic("create dots");
    8000570a:	00003517          	auipc	a0,0x3
    8000570e:	03e50513          	addi	a0,a0,62 # 80008748 <syscalls+0x2d8>
    80005712:	ffffb097          	auipc	ra,0xffffb
    80005716:	e18080e7          	jalr	-488(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000571a:	00003517          	auipc	a0,0x3
    8000571e:	03e50513          	addi	a0,a0,62 # 80008758 <syscalls+0x2e8>
    80005722:	ffffb097          	auipc	ra,0xffffb
    80005726:	e08080e7          	jalr	-504(ra) # 8000052a <panic>
    return 0;
    8000572a:	84aa                	mv	s1,a0
    8000572c:	b739                	j	8000563a <create+0x72>

000000008000572e <sys_dup>:
{
    8000572e:	7179                	addi	sp,sp,-48
    80005730:	f406                	sd	ra,40(sp)
    80005732:	f022                	sd	s0,32(sp)
    80005734:	ec26                	sd	s1,24(sp)
    80005736:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005738:	fd840613          	addi	a2,s0,-40
    8000573c:	4581                	li	a1,0
    8000573e:	4501                	li	a0,0
    80005740:	00000097          	auipc	ra,0x0
    80005744:	dde080e7          	jalr	-546(ra) # 8000551e <argfd>
    return -1;
    80005748:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000574a:	02054363          	bltz	a0,80005770 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000574e:	fd843503          	ld	a0,-40(s0)
    80005752:	00000097          	auipc	ra,0x0
    80005756:	e34080e7          	jalr	-460(ra) # 80005586 <fdalloc>
    8000575a:	84aa                	mv	s1,a0
    return -1;
    8000575c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000575e:	00054963          	bltz	a0,80005770 <sys_dup+0x42>
  filedup(f);
    80005762:	fd843503          	ld	a0,-40(s0)
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	344080e7          	jalr	836(ra) # 80004aaa <filedup>
  return fd;
    8000576e:	87a6                	mv	a5,s1
}
    80005770:	853e                	mv	a0,a5
    80005772:	70a2                	ld	ra,40(sp)
    80005774:	7402                	ld	s0,32(sp)
    80005776:	64e2                	ld	s1,24(sp)
    80005778:	6145                	addi	sp,sp,48
    8000577a:	8082                	ret

000000008000577c <sys_read>:
{
    8000577c:	7179                	addi	sp,sp,-48
    8000577e:	f406                	sd	ra,40(sp)
    80005780:	f022                	sd	s0,32(sp)
    80005782:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005784:	fe840613          	addi	a2,s0,-24
    80005788:	4581                	li	a1,0
    8000578a:	4501                	li	a0,0
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	d92080e7          	jalr	-622(ra) # 8000551e <argfd>
    return -1;
    80005794:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005796:	04054163          	bltz	a0,800057d8 <sys_read+0x5c>
    8000579a:	fe440593          	addi	a1,s0,-28
    8000579e:	4509                	li	a0,2
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	876080e7          	jalr	-1930(ra) # 80003016 <argint>
    return -1;
    800057a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057aa:	02054763          	bltz	a0,800057d8 <sys_read+0x5c>
    800057ae:	fd840593          	addi	a1,s0,-40
    800057b2:	4505                	li	a0,1
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	884080e7          	jalr	-1916(ra) # 80003038 <argaddr>
    return -1;
    800057bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057be:	00054d63          	bltz	a0,800057d8 <sys_read+0x5c>
  return fileread(f, p, n);
    800057c2:	fe442603          	lw	a2,-28(s0)
    800057c6:	fd843583          	ld	a1,-40(s0)
    800057ca:	fe843503          	ld	a0,-24(s0)
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	468080e7          	jalr	1128(ra) # 80004c36 <fileread>
    800057d6:	87aa                	mv	a5,a0
}
    800057d8:	853e                	mv	a0,a5
    800057da:	70a2                	ld	ra,40(sp)
    800057dc:	7402                	ld	s0,32(sp)
    800057de:	6145                	addi	sp,sp,48
    800057e0:	8082                	ret

00000000800057e2 <sys_write>:
{
    800057e2:	7179                	addi	sp,sp,-48
    800057e4:	f406                	sd	ra,40(sp)
    800057e6:	f022                	sd	s0,32(sp)
    800057e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ea:	fe840613          	addi	a2,s0,-24
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	d2c080e7          	jalr	-724(ra) # 8000551e <argfd>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fc:	04054163          	bltz	a0,8000583e <sys_write+0x5c>
    80005800:	fe440593          	addi	a1,s0,-28
    80005804:	4509                	li	a0,2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	810080e7          	jalr	-2032(ra) # 80003016 <argint>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005810:	02054763          	bltz	a0,8000583e <sys_write+0x5c>
    80005814:	fd840593          	addi	a1,s0,-40
    80005818:	4505                	li	a0,1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	81e080e7          	jalr	-2018(ra) # 80003038 <argaddr>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005824:	00054d63          	bltz	a0,8000583e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005828:	fe442603          	lw	a2,-28(s0)
    8000582c:	fd843583          	ld	a1,-40(s0)
    80005830:	fe843503          	ld	a0,-24(s0)
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	4c4080e7          	jalr	1220(ra) # 80004cf8 <filewrite>
    8000583c:	87aa                	mv	a5,a0
}
    8000583e:	853e                	mv	a0,a5
    80005840:	70a2                	ld	ra,40(sp)
    80005842:	7402                	ld	s0,32(sp)
    80005844:	6145                	addi	sp,sp,48
    80005846:	8082                	ret

0000000080005848 <sys_close>:
{
    80005848:	1101                	addi	sp,sp,-32
    8000584a:	ec06                	sd	ra,24(sp)
    8000584c:	e822                	sd	s0,16(sp)
    8000584e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005850:	fe040613          	addi	a2,s0,-32
    80005854:	fec40593          	addi	a1,s0,-20
    80005858:	4501                	li	a0,0
    8000585a:	00000097          	auipc	ra,0x0
    8000585e:	cc4080e7          	jalr	-828(ra) # 8000551e <argfd>
    return -1;
    80005862:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005864:	02054563          	bltz	a0,8000588e <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005868:	ffffc097          	auipc	ra,0xffffc
    8000586c:	13c080e7          	jalr	316(ra) # 800019a4 <myproc>
    80005870:	fec42783          	lw	a5,-20(s0)
    80005874:	04c78793          	addi	a5,a5,76
    80005878:	078e                	slli	a5,a5,0x3
    8000587a:	97aa                	add	a5,a5,a0
    8000587c:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005880:	fe043503          	ld	a0,-32(s0)
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	278080e7          	jalr	632(ra) # 80004afc <fileclose>
  return 0;
    8000588c:	4781                	li	a5,0
}
    8000588e:	853e                	mv	a0,a5
    80005890:	60e2                	ld	ra,24(sp)
    80005892:	6442                	ld	s0,16(sp)
    80005894:	6105                	addi	sp,sp,32
    80005896:	8082                	ret

0000000080005898 <sys_fstat>:
{
    80005898:	1101                	addi	sp,sp,-32
    8000589a:	ec06                	sd	ra,24(sp)
    8000589c:	e822                	sd	s0,16(sp)
    8000589e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a0:	fe840613          	addi	a2,s0,-24
    800058a4:	4581                	li	a1,0
    800058a6:	4501                	li	a0,0
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	c76080e7          	jalr	-906(ra) # 8000551e <argfd>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058b2:	02054563          	bltz	a0,800058dc <sys_fstat+0x44>
    800058b6:	fe040593          	addi	a1,s0,-32
    800058ba:	4505                	li	a0,1
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	77c080e7          	jalr	1916(ra) # 80003038 <argaddr>
    return -1;
    800058c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058c6:	00054b63          	bltz	a0,800058dc <sys_fstat+0x44>
  return filestat(f, st);
    800058ca:	fe043583          	ld	a1,-32(s0)
    800058ce:	fe843503          	ld	a0,-24(s0)
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	2f2080e7          	jalr	754(ra) # 80004bc4 <filestat>
    800058da:	87aa                	mv	a5,a0
}
    800058dc:	853e                	mv	a0,a5
    800058de:	60e2                	ld	ra,24(sp)
    800058e0:	6442                	ld	s0,16(sp)
    800058e2:	6105                	addi	sp,sp,32
    800058e4:	8082                	ret

00000000800058e6 <sys_link>:
{
    800058e6:	7169                	addi	sp,sp,-304
    800058e8:	f606                	sd	ra,296(sp)
    800058ea:	f222                	sd	s0,288(sp)
    800058ec:	ee26                	sd	s1,280(sp)
    800058ee:	ea4a                	sd	s2,272(sp)
    800058f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f2:	08000613          	li	a2,128
    800058f6:	ed040593          	addi	a1,s0,-304
    800058fa:	4501                	li	a0,0
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	75e080e7          	jalr	1886(ra) # 8000305a <argstr>
    return -1;
    80005904:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005906:	10054e63          	bltz	a0,80005a22 <sys_link+0x13c>
    8000590a:	08000613          	li	a2,128
    8000590e:	f5040593          	addi	a1,s0,-176
    80005912:	4505                	li	a0,1
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	746080e7          	jalr	1862(ra) # 8000305a <argstr>
    return -1;
    8000591c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000591e:	10054263          	bltz	a0,80005a22 <sys_link+0x13c>
  begin_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	d0e080e7          	jalr	-754(ra) # 80004630 <begin_op>
  if((ip = namei(old)) == 0){
    8000592a:	ed040513          	addi	a0,s0,-304
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	ae2080e7          	jalr	-1310(ra) # 80004410 <namei>
    80005936:	84aa                	mv	s1,a0
    80005938:	c551                	beqz	a0,800059c4 <sys_link+0xde>
  ilock(ip);
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	320080e7          	jalr	800(ra) # 80003c5a <ilock>
  if(ip->type == T_DIR){
    80005942:	04449703          	lh	a4,68(s1)
    80005946:	4785                	li	a5,1
    80005948:	08f70463          	beq	a4,a5,800059d0 <sys_link+0xea>
  ip->nlink++;
    8000594c:	04a4d783          	lhu	a5,74(s1)
    80005950:	2785                	addiw	a5,a5,1
    80005952:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005956:	8526                	mv	a0,s1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	238080e7          	jalr	568(ra) # 80003b90 <iupdate>
  iunlock(ip);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	3ba080e7          	jalr	954(ra) # 80003d1c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000596a:	fd040593          	addi	a1,s0,-48
    8000596e:	f5040513          	addi	a0,s0,-176
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	abc080e7          	jalr	-1348(ra) # 8000442e <nameiparent>
    8000597a:	892a                	mv	s2,a0
    8000597c:	c935                	beqz	a0,800059f0 <sys_link+0x10a>
  ilock(dp);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	2dc080e7          	jalr	732(ra) # 80003c5a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005986:	00092703          	lw	a4,0(s2)
    8000598a:	409c                	lw	a5,0(s1)
    8000598c:	04f71d63          	bne	a4,a5,800059e6 <sys_link+0x100>
    80005990:	40d0                	lw	a2,4(s1)
    80005992:	fd040593          	addi	a1,s0,-48
    80005996:	854a                	mv	a0,s2
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	9b6080e7          	jalr	-1610(ra) # 8000434e <dirlink>
    800059a0:	04054363          	bltz	a0,800059e6 <sys_link+0x100>
  iunlockput(dp);
    800059a4:	854a                	mv	a0,s2
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	516080e7          	jalr	1302(ra) # 80003ebc <iunlockput>
  iput(ip);
    800059ae:	8526                	mv	a0,s1
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	464080e7          	jalr	1124(ra) # 80003e14 <iput>
  end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	cf8080e7          	jalr	-776(ra) # 800046b0 <end_op>
  return 0;
    800059c0:	4781                	li	a5,0
    800059c2:	a085                	j	80005a22 <sys_link+0x13c>
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	cec080e7          	jalr	-788(ra) # 800046b0 <end_op>
    return -1;
    800059cc:	57fd                	li	a5,-1
    800059ce:	a891                	j	80005a22 <sys_link+0x13c>
    iunlockput(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	4ea080e7          	jalr	1258(ra) # 80003ebc <iunlockput>
    end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	cd6080e7          	jalr	-810(ra) # 800046b0 <end_op>
    return -1;
    800059e2:	57fd                	li	a5,-1
    800059e4:	a83d                	j	80005a22 <sys_link+0x13c>
    iunlockput(dp);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	4d4080e7          	jalr	1236(ra) # 80003ebc <iunlockput>
  ilock(ip);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	268080e7          	jalr	616(ra) # 80003c5a <ilock>
  ip->nlink--;
    800059fa:	04a4d783          	lhu	a5,74(s1)
    800059fe:	37fd                	addiw	a5,a5,-1
    80005a00:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	18a080e7          	jalr	394(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	4ac080e7          	jalr	1196(ra) # 80003ebc <iunlockput>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	c98080e7          	jalr	-872(ra) # 800046b0 <end_op>
  return -1;
    80005a20:	57fd                	li	a5,-1
}
    80005a22:	853e                	mv	a0,a5
    80005a24:	70b2                	ld	ra,296(sp)
    80005a26:	7412                	ld	s0,288(sp)
    80005a28:	64f2                	ld	s1,280(sp)
    80005a2a:	6952                	ld	s2,272(sp)
    80005a2c:	6155                	addi	sp,sp,304
    80005a2e:	8082                	ret

0000000080005a30 <sys_unlink>:
{
    80005a30:	7151                	addi	sp,sp,-240
    80005a32:	f586                	sd	ra,232(sp)
    80005a34:	f1a2                	sd	s0,224(sp)
    80005a36:	eda6                	sd	s1,216(sp)
    80005a38:	e9ca                	sd	s2,208(sp)
    80005a3a:	e5ce                	sd	s3,200(sp)
    80005a3c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a3e:	08000613          	li	a2,128
    80005a42:	f3040593          	addi	a1,s0,-208
    80005a46:	4501                	li	a0,0
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	612080e7          	jalr	1554(ra) # 8000305a <argstr>
    80005a50:	18054163          	bltz	a0,80005bd2 <sys_unlink+0x1a2>
  begin_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	bdc080e7          	jalr	-1060(ra) # 80004630 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a5c:	fb040593          	addi	a1,s0,-80
    80005a60:	f3040513          	addi	a0,s0,-208
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	9ca080e7          	jalr	-1590(ra) # 8000442e <nameiparent>
    80005a6c:	84aa                	mv	s1,a0
    80005a6e:	c979                	beqz	a0,80005b44 <sys_unlink+0x114>
  ilock(dp);
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	1ea080e7          	jalr	490(ra) # 80003c5a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a78:	00003597          	auipc	a1,0x3
    80005a7c:	cc058593          	addi	a1,a1,-832 # 80008738 <syscalls+0x2c8>
    80005a80:	fb040513          	addi	a0,s0,-80
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	6a0080e7          	jalr	1696(ra) # 80004124 <namecmp>
    80005a8c:	14050a63          	beqz	a0,80005be0 <sys_unlink+0x1b0>
    80005a90:	00003597          	auipc	a1,0x3
    80005a94:	cb058593          	addi	a1,a1,-848 # 80008740 <syscalls+0x2d0>
    80005a98:	fb040513          	addi	a0,s0,-80
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	688080e7          	jalr	1672(ra) # 80004124 <namecmp>
    80005aa4:	12050e63          	beqz	a0,80005be0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aa8:	f2c40613          	addi	a2,s0,-212
    80005aac:	fb040593          	addi	a1,s0,-80
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	68c080e7          	jalr	1676(ra) # 8000413e <dirlookup>
    80005aba:	892a                	mv	s2,a0
    80005abc:	12050263          	beqz	a0,80005be0 <sys_unlink+0x1b0>
  ilock(ip);
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	19a080e7          	jalr	410(ra) # 80003c5a <ilock>
  if(ip->nlink < 1)
    80005ac8:	04a91783          	lh	a5,74(s2)
    80005acc:	08f05263          	blez	a5,80005b50 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ad0:	04491703          	lh	a4,68(s2)
    80005ad4:	4785                	li	a5,1
    80005ad6:	08f70563          	beq	a4,a5,80005b60 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ada:	4641                	li	a2,16
    80005adc:	4581                	li	a1,0
    80005ade:	fc040513          	addi	a0,s0,-64
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	200080e7          	jalr	512(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aea:	4741                	li	a4,16
    80005aec:	f2c42683          	lw	a3,-212(s0)
    80005af0:	fc040613          	addi	a2,s0,-64
    80005af4:	4581                	li	a1,0
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	50e080e7          	jalr	1294(ra) # 80004006 <writei>
    80005b00:	47c1                	li	a5,16
    80005b02:	0af51563          	bne	a0,a5,80005bac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b06:	04491703          	lh	a4,68(s2)
    80005b0a:	4785                	li	a5,1
    80005b0c:	0af70863          	beq	a4,a5,80005bbc <sys_unlink+0x18c>
  iunlockput(dp);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	3aa080e7          	jalr	938(ra) # 80003ebc <iunlockput>
  ip->nlink--;
    80005b1a:	04a95783          	lhu	a5,74(s2)
    80005b1e:	37fd                	addiw	a5,a5,-1
    80005b20:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b24:	854a                	mv	a0,s2
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	06a080e7          	jalr	106(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    80005b2e:	854a                	mv	a0,s2
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	38c080e7          	jalr	908(ra) # 80003ebc <iunlockput>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	b78080e7          	jalr	-1160(ra) # 800046b0 <end_op>
  return 0;
    80005b40:	4501                	li	a0,0
    80005b42:	a84d                	j	80005bf4 <sys_unlink+0x1c4>
    end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	b6c080e7          	jalr	-1172(ra) # 800046b0 <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	a05d                	j	80005bf4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b50:	00003517          	auipc	a0,0x3
    80005b54:	c1850513          	addi	a0,a0,-1000 # 80008768 <syscalls+0x2f8>
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	9d2080e7          	jalr	-1582(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b60:	04c92703          	lw	a4,76(s2)
    80005b64:	02000793          	li	a5,32
    80005b68:	f6e7f9e3          	bgeu	a5,a4,80005ada <sys_unlink+0xaa>
    80005b6c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b70:	4741                	li	a4,16
    80005b72:	86ce                	mv	a3,s3
    80005b74:	f1840613          	addi	a2,s0,-232
    80005b78:	4581                	li	a1,0
    80005b7a:	854a                	mv	a0,s2
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	392080e7          	jalr	914(ra) # 80003f0e <readi>
    80005b84:	47c1                	li	a5,16
    80005b86:	00f51b63          	bne	a0,a5,80005b9c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b8a:	f1845783          	lhu	a5,-232(s0)
    80005b8e:	e7a1                	bnez	a5,80005bd6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b90:	29c1                	addiw	s3,s3,16
    80005b92:	04c92783          	lw	a5,76(s2)
    80005b96:	fcf9ede3          	bltu	s3,a5,80005b70 <sys_unlink+0x140>
    80005b9a:	b781                	j	80005ada <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b9c:	00003517          	auipc	a0,0x3
    80005ba0:	be450513          	addi	a0,a0,-1052 # 80008780 <syscalls+0x310>
    80005ba4:	ffffb097          	auipc	ra,0xffffb
    80005ba8:	986080e7          	jalr	-1658(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005bac:	00003517          	auipc	a0,0x3
    80005bb0:	bec50513          	addi	a0,a0,-1044 # 80008798 <syscalls+0x328>
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	976080e7          	jalr	-1674(ra) # 8000052a <panic>
    dp->nlink--;
    80005bbc:	04a4d783          	lhu	a5,74(s1)
    80005bc0:	37fd                	addiw	a5,a5,-1
    80005bc2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bc6:	8526                	mv	a0,s1
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	fc8080e7          	jalr	-56(ra) # 80003b90 <iupdate>
    80005bd0:	b781                	j	80005b10 <sys_unlink+0xe0>
    return -1;
    80005bd2:	557d                	li	a0,-1
    80005bd4:	a005                	j	80005bf4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bd6:	854a                	mv	a0,s2
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	2e4080e7          	jalr	740(ra) # 80003ebc <iunlockput>
  iunlockput(dp);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	2da080e7          	jalr	730(ra) # 80003ebc <iunlockput>
  end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	ac6080e7          	jalr	-1338(ra) # 800046b0 <end_op>
  return -1;
    80005bf2:	557d                	li	a0,-1
}
    80005bf4:	70ae                	ld	ra,232(sp)
    80005bf6:	740e                	ld	s0,224(sp)
    80005bf8:	64ee                	ld	s1,216(sp)
    80005bfa:	694e                	ld	s2,208(sp)
    80005bfc:	69ae                	ld	s3,200(sp)
    80005bfe:	616d                	addi	sp,sp,240
    80005c00:	8082                	ret

0000000080005c02 <sys_open>:

uint64
sys_open(void)
{
    80005c02:	7131                	addi	sp,sp,-192
    80005c04:	fd06                	sd	ra,184(sp)
    80005c06:	f922                	sd	s0,176(sp)
    80005c08:	f526                	sd	s1,168(sp)
    80005c0a:	f14a                	sd	s2,160(sp)
    80005c0c:	ed4e                	sd	s3,152(sp)
    80005c0e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c10:	08000613          	li	a2,128
    80005c14:	f5040593          	addi	a1,s0,-176
    80005c18:	4501                	li	a0,0
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	440080e7          	jalr	1088(ra) # 8000305a <argstr>
    return -1;
    80005c22:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c24:	0c054163          	bltz	a0,80005ce6 <sys_open+0xe4>
    80005c28:	f4c40593          	addi	a1,s0,-180
    80005c2c:	4505                	li	a0,1
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	3e8080e7          	jalr	1000(ra) # 80003016 <argint>
    80005c36:	0a054863          	bltz	a0,80005ce6 <sys_open+0xe4>

  begin_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	9f6080e7          	jalr	-1546(ra) # 80004630 <begin_op>

  if(omode & O_CREATE){
    80005c42:	f4c42783          	lw	a5,-180(s0)
    80005c46:	2007f793          	andi	a5,a5,512
    80005c4a:	cbdd                	beqz	a5,80005d00 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c4c:	4681                	li	a3,0
    80005c4e:	4601                	li	a2,0
    80005c50:	4589                	li	a1,2
    80005c52:	f5040513          	addi	a0,s0,-176
    80005c56:	00000097          	auipc	ra,0x0
    80005c5a:	972080e7          	jalr	-1678(ra) # 800055c8 <create>
    80005c5e:	892a                	mv	s2,a0
    if(ip == 0){
    80005c60:	c959                	beqz	a0,80005cf6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c62:	04491703          	lh	a4,68(s2)
    80005c66:	478d                	li	a5,3
    80005c68:	00f71763          	bne	a4,a5,80005c76 <sys_open+0x74>
    80005c6c:	04695703          	lhu	a4,70(s2)
    80005c70:	47a5                	li	a5,9
    80005c72:	0ce7ec63          	bltu	a5,a4,80005d4a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	dca080e7          	jalr	-566(ra) # 80004a40 <filealloc>
    80005c7e:	89aa                	mv	s3,a0
    80005c80:	10050263          	beqz	a0,80005d84 <sys_open+0x182>
    80005c84:	00000097          	auipc	ra,0x0
    80005c88:	902080e7          	jalr	-1790(ra) # 80005586 <fdalloc>
    80005c8c:	84aa                	mv	s1,a0
    80005c8e:	0e054663          	bltz	a0,80005d7a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c92:	04491703          	lh	a4,68(s2)
    80005c96:	478d                	li	a5,3
    80005c98:	0cf70463          	beq	a4,a5,80005d60 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c9c:	4789                	li	a5,2
    80005c9e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ca2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ca6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005caa:	f4c42783          	lw	a5,-180(s0)
    80005cae:	0017c713          	xori	a4,a5,1
    80005cb2:	8b05                	andi	a4,a4,1
    80005cb4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cb8:	0037f713          	andi	a4,a5,3
    80005cbc:	00e03733          	snez	a4,a4
    80005cc0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cc4:	4007f793          	andi	a5,a5,1024
    80005cc8:	c791                	beqz	a5,80005cd4 <sys_open+0xd2>
    80005cca:	04491703          	lh	a4,68(s2)
    80005cce:	4789                	li	a5,2
    80005cd0:	08f70f63          	beq	a4,a5,80005d6e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cd4:	854a                	mv	a0,s2
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	046080e7          	jalr	70(ra) # 80003d1c <iunlock>
  end_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	9d2080e7          	jalr	-1582(ra) # 800046b0 <end_op>

  return fd;
}
    80005ce6:	8526                	mv	a0,s1
    80005ce8:	70ea                	ld	ra,184(sp)
    80005cea:	744a                	ld	s0,176(sp)
    80005cec:	74aa                	ld	s1,168(sp)
    80005cee:	790a                	ld	s2,160(sp)
    80005cf0:	69ea                	ld	s3,152(sp)
    80005cf2:	6129                	addi	sp,sp,192
    80005cf4:	8082                	ret
      end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	9ba080e7          	jalr	-1606(ra) # 800046b0 <end_op>
      return -1;
    80005cfe:	b7e5                	j	80005ce6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d00:	f5040513          	addi	a0,s0,-176
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	70c080e7          	jalr	1804(ra) # 80004410 <namei>
    80005d0c:	892a                	mv	s2,a0
    80005d0e:	c905                	beqz	a0,80005d3e <sys_open+0x13c>
    ilock(ip);
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	f4a080e7          	jalr	-182(ra) # 80003c5a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d18:	04491703          	lh	a4,68(s2)
    80005d1c:	4785                	li	a5,1
    80005d1e:	f4f712e3          	bne	a4,a5,80005c62 <sys_open+0x60>
    80005d22:	f4c42783          	lw	a5,-180(s0)
    80005d26:	dba1                	beqz	a5,80005c76 <sys_open+0x74>
      iunlockput(ip);
    80005d28:	854a                	mv	a0,s2
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	192080e7          	jalr	402(ra) # 80003ebc <iunlockput>
      end_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	97e080e7          	jalr	-1666(ra) # 800046b0 <end_op>
      return -1;
    80005d3a:	54fd                	li	s1,-1
    80005d3c:	b76d                	j	80005ce6 <sys_open+0xe4>
      end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	972080e7          	jalr	-1678(ra) # 800046b0 <end_op>
      return -1;
    80005d46:	54fd                	li	s1,-1
    80005d48:	bf79                	j	80005ce6 <sys_open+0xe4>
    iunlockput(ip);
    80005d4a:	854a                	mv	a0,s2
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	170080e7          	jalr	368(ra) # 80003ebc <iunlockput>
    end_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	95c080e7          	jalr	-1700(ra) # 800046b0 <end_op>
    return -1;
    80005d5c:	54fd                	li	s1,-1
    80005d5e:	b761                	j	80005ce6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d60:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d64:	04691783          	lh	a5,70(s2)
    80005d68:	02f99223          	sh	a5,36(s3)
    80005d6c:	bf2d                	j	80005ca6 <sys_open+0xa4>
    itrunc(ip);
    80005d6e:	854a                	mv	a0,s2
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	ff8080e7          	jalr	-8(ra) # 80003d68 <itrunc>
    80005d78:	bfb1                	j	80005cd4 <sys_open+0xd2>
      fileclose(f);
    80005d7a:	854e                	mv	a0,s3
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	d80080e7          	jalr	-640(ra) # 80004afc <fileclose>
    iunlockput(ip);
    80005d84:	854a                	mv	a0,s2
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	136080e7          	jalr	310(ra) # 80003ebc <iunlockput>
    end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	922080e7          	jalr	-1758(ra) # 800046b0 <end_op>
    return -1;
    80005d96:	54fd                	li	s1,-1
    80005d98:	b7b9                	j	80005ce6 <sys_open+0xe4>

0000000080005d9a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d9a:	7175                	addi	sp,sp,-144
    80005d9c:	e506                	sd	ra,136(sp)
    80005d9e:	e122                	sd	s0,128(sp)
    80005da0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	88e080e7          	jalr	-1906(ra) # 80004630 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005daa:	08000613          	li	a2,128
    80005dae:	f7040593          	addi	a1,s0,-144
    80005db2:	4501                	li	a0,0
    80005db4:	ffffd097          	auipc	ra,0xffffd
    80005db8:	2a6080e7          	jalr	678(ra) # 8000305a <argstr>
    80005dbc:	02054963          	bltz	a0,80005dee <sys_mkdir+0x54>
    80005dc0:	4681                	li	a3,0
    80005dc2:	4601                	li	a2,0
    80005dc4:	4585                	li	a1,1
    80005dc6:	f7040513          	addi	a0,s0,-144
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	7fe080e7          	jalr	2046(ra) # 800055c8 <create>
    80005dd2:	cd11                	beqz	a0,80005dee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	0e8080e7          	jalr	232(ra) # 80003ebc <iunlockput>
  end_op();
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	8d4080e7          	jalr	-1836(ra) # 800046b0 <end_op>
  return 0;
    80005de4:	4501                	li	a0,0
}
    80005de6:	60aa                	ld	ra,136(sp)
    80005de8:	640a                	ld	s0,128(sp)
    80005dea:	6149                	addi	sp,sp,144
    80005dec:	8082                	ret
    end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	8c2080e7          	jalr	-1854(ra) # 800046b0 <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
    80005df8:	b7fd                	j	80005de6 <sys_mkdir+0x4c>

0000000080005dfa <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dfa:	7135                	addi	sp,sp,-160
    80005dfc:	ed06                	sd	ra,152(sp)
    80005dfe:	e922                	sd	s0,144(sp)
    80005e00:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	82e080e7          	jalr	-2002(ra) # 80004630 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e0a:	08000613          	li	a2,128
    80005e0e:	f7040593          	addi	a1,s0,-144
    80005e12:	4501                	li	a0,0
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	246080e7          	jalr	582(ra) # 8000305a <argstr>
    80005e1c:	04054a63          	bltz	a0,80005e70 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e20:	f6c40593          	addi	a1,s0,-148
    80005e24:	4505                	li	a0,1
    80005e26:	ffffd097          	auipc	ra,0xffffd
    80005e2a:	1f0080e7          	jalr	496(ra) # 80003016 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e2e:	04054163          	bltz	a0,80005e70 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e32:	f6840593          	addi	a1,s0,-152
    80005e36:	4509                	li	a0,2
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	1de080e7          	jalr	478(ra) # 80003016 <argint>
     argint(1, &major) < 0 ||
    80005e40:	02054863          	bltz	a0,80005e70 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e44:	f6841683          	lh	a3,-152(s0)
    80005e48:	f6c41603          	lh	a2,-148(s0)
    80005e4c:	458d                	li	a1,3
    80005e4e:	f7040513          	addi	a0,s0,-144
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	776080e7          	jalr	1910(ra) # 800055c8 <create>
     argint(2, &minor) < 0 ||
    80005e5a:	c919                	beqz	a0,80005e70 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	060080e7          	jalr	96(ra) # 80003ebc <iunlockput>
  end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	84c080e7          	jalr	-1972(ra) # 800046b0 <end_op>
  return 0;
    80005e6c:	4501                	li	a0,0
    80005e6e:	a031                	j	80005e7a <sys_mknod+0x80>
    end_op();
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	840080e7          	jalr	-1984(ra) # 800046b0 <end_op>
    return -1;
    80005e78:	557d                	li	a0,-1
}
    80005e7a:	60ea                	ld	ra,152(sp)
    80005e7c:	644a                	ld	s0,144(sp)
    80005e7e:	610d                	addi	sp,sp,160
    80005e80:	8082                	ret

0000000080005e82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e82:	7135                	addi	sp,sp,-160
    80005e84:	ed06                	sd	ra,152(sp)
    80005e86:	e922                	sd	s0,144(sp)
    80005e88:	e526                	sd	s1,136(sp)
    80005e8a:	e14a                	sd	s2,128(sp)
    80005e8c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e8e:	ffffc097          	auipc	ra,0xffffc
    80005e92:	b16080e7          	jalr	-1258(ra) # 800019a4 <myproc>
    80005e96:	892a                	mv	s2,a0
  
  begin_op();
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	798080e7          	jalr	1944(ra) # 80004630 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ea0:	08000613          	li	a2,128
    80005ea4:	f6040593          	addi	a1,s0,-160
    80005ea8:	4501                	li	a0,0
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	1b0080e7          	jalr	432(ra) # 8000305a <argstr>
    80005eb2:	04054b63          	bltz	a0,80005f08 <sys_chdir+0x86>
    80005eb6:	f6040513          	addi	a0,s0,-160
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	556080e7          	jalr	1366(ra) # 80004410 <namei>
    80005ec2:	84aa                	mv	s1,a0
    80005ec4:	c131                	beqz	a0,80005f08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	d94080e7          	jalr	-620(ra) # 80003c5a <ilock>
  if(ip->type != T_DIR){
    80005ece:	04449703          	lh	a4,68(s1)
    80005ed2:	4785                	li	a5,1
    80005ed4:	04f71063          	bne	a4,a5,80005f14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ed8:	8526                	mv	a0,s1
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	e42080e7          	jalr	-446(ra) # 80003d1c <iunlock>
  iput(p->cwd);
    80005ee2:	2e893503          	ld	a0,744(s2)
    80005ee6:	ffffe097          	auipc	ra,0xffffe
    80005eea:	f2e080e7          	jalr	-210(ra) # 80003e14 <iput>
  end_op();
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	7c2080e7          	jalr	1986(ra) # 800046b0 <end_op>
  p->cwd = ip;
    80005ef6:	2e993423          	sd	s1,744(s2)
  return 0;
    80005efa:	4501                	li	a0,0
}
    80005efc:	60ea                	ld	ra,152(sp)
    80005efe:	644a                	ld	s0,144(sp)
    80005f00:	64aa                	ld	s1,136(sp)
    80005f02:	690a                	ld	s2,128(sp)
    80005f04:	610d                	addi	sp,sp,160
    80005f06:	8082                	ret
    end_op();
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	7a8080e7          	jalr	1960(ra) # 800046b0 <end_op>
    return -1;
    80005f10:	557d                	li	a0,-1
    80005f12:	b7ed                	j	80005efc <sys_chdir+0x7a>
    iunlockput(ip);
    80005f14:	8526                	mv	a0,s1
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	fa6080e7          	jalr	-90(ra) # 80003ebc <iunlockput>
    end_op();
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	792080e7          	jalr	1938(ra) # 800046b0 <end_op>
    return -1;
    80005f26:	557d                	li	a0,-1
    80005f28:	bfd1                	j	80005efc <sys_chdir+0x7a>

0000000080005f2a <sys_exec>:

uint64
sys_exec(void)
{
    80005f2a:	7145                	addi	sp,sp,-464
    80005f2c:	e786                	sd	ra,456(sp)
    80005f2e:	e3a2                	sd	s0,448(sp)
    80005f30:	ff26                	sd	s1,440(sp)
    80005f32:	fb4a                	sd	s2,432(sp)
    80005f34:	f74e                	sd	s3,424(sp)
    80005f36:	f352                	sd	s4,416(sp)
    80005f38:	ef56                	sd	s5,408(sp)
    80005f3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f3c:	08000613          	li	a2,128
    80005f40:	f4040593          	addi	a1,s0,-192
    80005f44:	4501                	li	a0,0
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	114080e7          	jalr	276(ra) # 8000305a <argstr>
    return -1;
    80005f4e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f50:	0c054a63          	bltz	a0,80006024 <sys_exec+0xfa>
    80005f54:	e3840593          	addi	a1,s0,-456
    80005f58:	4505                	li	a0,1
    80005f5a:	ffffd097          	auipc	ra,0xffffd
    80005f5e:	0de080e7          	jalr	222(ra) # 80003038 <argaddr>
    80005f62:	0c054163          	bltz	a0,80006024 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f66:	10000613          	li	a2,256
    80005f6a:	4581                	li	a1,0
    80005f6c:	e4040513          	addi	a0,s0,-448
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	d72080e7          	jalr	-654(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f7c:	89a6                	mv	s3,s1
    80005f7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f80:	02000a13          	li	s4,32
    80005f84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f88:	00391793          	slli	a5,s2,0x3
    80005f8c:	e3040593          	addi	a1,s0,-464
    80005f90:	e3843503          	ld	a0,-456(s0)
    80005f94:	953e                	add	a0,a0,a5
    80005f96:	ffffd097          	auipc	ra,0xffffd
    80005f9a:	fe0080e7          	jalr	-32(ra) # 80002f76 <fetchaddr>
    80005f9e:	02054a63          	bltz	a0,80005fd2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fa2:	e3043783          	ld	a5,-464(s0)
    80005fa6:	c3b9                	beqz	a5,80005fec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fa8:	ffffb097          	auipc	ra,0xffffb
    80005fac:	b2a080e7          	jalr	-1238(ra) # 80000ad2 <kalloc>
    80005fb0:	85aa                	mv	a1,a0
    80005fb2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fb6:	cd11                	beqz	a0,80005fd2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fb8:	6605                	lui	a2,0x1
    80005fba:	e3043503          	ld	a0,-464(s0)
    80005fbe:	ffffd097          	auipc	ra,0xffffd
    80005fc2:	00e080e7          	jalr	14(ra) # 80002fcc <fetchstr>
    80005fc6:	00054663          	bltz	a0,80005fd2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fca:	0905                	addi	s2,s2,1
    80005fcc:	09a1                	addi	s3,s3,8
    80005fce:	fb491be3          	bne	s2,s4,80005f84 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd2:	10048913          	addi	s2,s1,256
    80005fd6:	6088                	ld	a0,0(s1)
    80005fd8:	c529                	beqz	a0,80006022 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	9fc080e7          	jalr	-1540(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe2:	04a1                	addi	s1,s1,8
    80005fe4:	ff2499e3          	bne	s1,s2,80005fd6 <sys_exec+0xac>
  return -1;
    80005fe8:	597d                	li	s2,-1
    80005fea:	a82d                	j	80006024 <sys_exec+0xfa>
      argv[i] = 0;
    80005fec:	0a8e                	slli	s5,s5,0x3
    80005fee:	fc040793          	addi	a5,s0,-64
    80005ff2:	9abe                	add	s5,s5,a5
    80005ff4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ff8:	e4040593          	addi	a1,s0,-448
    80005ffc:	f4040513          	addi	a0,s0,-192
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	14e080e7          	jalr	334(ra) # 8000514e <exec>
    80006008:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600a:	10048993          	addi	s3,s1,256
    8000600e:	6088                	ld	a0,0(s1)
    80006010:	c911                	beqz	a0,80006024 <sys_exec+0xfa>
    kfree(argv[i]);
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	9c4080e7          	jalr	-1596(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601a:	04a1                	addi	s1,s1,8
    8000601c:	ff3499e3          	bne	s1,s3,8000600e <sys_exec+0xe4>
    80006020:	a011                	j	80006024 <sys_exec+0xfa>
  return -1;
    80006022:	597d                	li	s2,-1
}
    80006024:	854a                	mv	a0,s2
    80006026:	60be                	ld	ra,456(sp)
    80006028:	641e                	ld	s0,448(sp)
    8000602a:	74fa                	ld	s1,440(sp)
    8000602c:	795a                	ld	s2,432(sp)
    8000602e:	79ba                	ld	s3,424(sp)
    80006030:	7a1a                	ld	s4,416(sp)
    80006032:	6afa                	ld	s5,408(sp)
    80006034:	6179                	addi	sp,sp,464
    80006036:	8082                	ret

0000000080006038 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006038:	7139                	addi	sp,sp,-64
    8000603a:	fc06                	sd	ra,56(sp)
    8000603c:	f822                	sd	s0,48(sp)
    8000603e:	f426                	sd	s1,40(sp)
    80006040:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	962080e7          	jalr	-1694(ra) # 800019a4 <myproc>
    8000604a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000604c:	fd840593          	addi	a1,s0,-40
    80006050:	4501                	li	a0,0
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	fe6080e7          	jalr	-26(ra) # 80003038 <argaddr>
    return -1;
    8000605a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000605c:	0e054463          	bltz	a0,80006144 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    80006060:	fc840593          	addi	a1,s0,-56
    80006064:	fd040513          	addi	a0,s0,-48
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	dc4080e7          	jalr	-572(ra) # 80004e2c <pipealloc>
    return -1;
    80006070:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006072:	0c054963          	bltz	a0,80006144 <sys_pipe+0x10c>
  fd0 = -1;
    80006076:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000607a:	fd043503          	ld	a0,-48(s0)
    8000607e:	fffff097          	auipc	ra,0xfffff
    80006082:	508080e7          	jalr	1288(ra) # 80005586 <fdalloc>
    80006086:	fca42223          	sw	a0,-60(s0)
    8000608a:	0a054063          	bltz	a0,8000612a <sys_pipe+0xf2>
    8000608e:	fc843503          	ld	a0,-56(s0)
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	4f4080e7          	jalr	1268(ra) # 80005586 <fdalloc>
    8000609a:	fca42023          	sw	a0,-64(s0)
    8000609e:	06054c63          	bltz	a0,80006116 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060a2:	4691                	li	a3,4
    800060a4:	fc440613          	addi	a2,s0,-60
    800060a8:	fd843583          	ld	a1,-40(s0)
    800060ac:	1e84b503          	ld	a0,488(s1)
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	5b2080e7          	jalr	1458(ra) # 80001662 <copyout>
    800060b8:	02054163          	bltz	a0,800060da <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060bc:	4691                	li	a3,4
    800060be:	fc040613          	addi	a2,s0,-64
    800060c2:	fd843583          	ld	a1,-40(s0)
    800060c6:	0591                	addi	a1,a1,4
    800060c8:	1e84b503          	ld	a0,488(s1)
    800060cc:	ffffb097          	auipc	ra,0xffffb
    800060d0:	596080e7          	jalr	1430(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060d4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d6:	06055763          	bgez	a0,80006144 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    800060da:	fc442783          	lw	a5,-60(s0)
    800060de:	04c78793          	addi	a5,a5,76
    800060e2:	078e                	slli	a5,a5,0x3
    800060e4:	97a6                	add	a5,a5,s1
    800060e6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800060ea:	fc042503          	lw	a0,-64(s0)
    800060ee:	04c50513          	addi	a0,a0,76
    800060f2:	050e                	slli	a0,a0,0x3
    800060f4:	9526                	add	a0,a0,s1
    800060f6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800060fa:	fd043503          	ld	a0,-48(s0)
    800060fe:	fffff097          	auipc	ra,0xfffff
    80006102:	9fe080e7          	jalr	-1538(ra) # 80004afc <fileclose>
    fileclose(wf);
    80006106:	fc843503          	ld	a0,-56(s0)
    8000610a:	fffff097          	auipc	ra,0xfffff
    8000610e:	9f2080e7          	jalr	-1550(ra) # 80004afc <fileclose>
    return -1;
    80006112:	57fd                	li	a5,-1
    80006114:	a805                	j	80006144 <sys_pipe+0x10c>
    if(fd0 >= 0)
    80006116:	fc442783          	lw	a5,-60(s0)
    8000611a:	0007c863          	bltz	a5,8000612a <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    8000611e:	04c78513          	addi	a0,a5,76
    80006122:	050e                	slli	a0,a0,0x3
    80006124:	9526                	add	a0,a0,s1
    80006126:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000612a:	fd043503          	ld	a0,-48(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	9ce080e7          	jalr	-1586(ra) # 80004afc <fileclose>
    fileclose(wf);
    80006136:	fc843503          	ld	a0,-56(s0)
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	9c2080e7          	jalr	-1598(ra) # 80004afc <fileclose>
    return -1;
    80006142:	57fd                	li	a5,-1
}
    80006144:	853e                	mv	a0,a5
    80006146:	70e2                	ld	ra,56(sp)
    80006148:	7442                	ld	s0,48(sp)
    8000614a:	74a2                	ld	s1,40(sp)
    8000614c:	6121                	addi	sp,sp,64
    8000614e:	8082                	ret

0000000080006150 <kernelvec>:
    80006150:	7111                	addi	sp,sp,-256
    80006152:	e006                	sd	ra,0(sp)
    80006154:	e40a                	sd	sp,8(sp)
    80006156:	e80e                	sd	gp,16(sp)
    80006158:	ec12                	sd	tp,24(sp)
    8000615a:	f016                	sd	t0,32(sp)
    8000615c:	f41a                	sd	t1,40(sp)
    8000615e:	f81e                	sd	t2,48(sp)
    80006160:	fc22                	sd	s0,56(sp)
    80006162:	e0a6                	sd	s1,64(sp)
    80006164:	e4aa                	sd	a0,72(sp)
    80006166:	e8ae                	sd	a1,80(sp)
    80006168:	ecb2                	sd	a2,88(sp)
    8000616a:	f0b6                	sd	a3,96(sp)
    8000616c:	f4ba                	sd	a4,104(sp)
    8000616e:	f8be                	sd	a5,112(sp)
    80006170:	fcc2                	sd	a6,120(sp)
    80006172:	e146                	sd	a7,128(sp)
    80006174:	e54a                	sd	s2,136(sp)
    80006176:	e94e                	sd	s3,144(sp)
    80006178:	ed52                	sd	s4,152(sp)
    8000617a:	f156                	sd	s5,160(sp)
    8000617c:	f55a                	sd	s6,168(sp)
    8000617e:	f95e                	sd	s7,176(sp)
    80006180:	fd62                	sd	s8,184(sp)
    80006182:	e1e6                	sd	s9,192(sp)
    80006184:	e5ea                	sd	s10,200(sp)
    80006186:	e9ee                	sd	s11,208(sp)
    80006188:	edf2                	sd	t3,216(sp)
    8000618a:	f1f6                	sd	t4,224(sp)
    8000618c:	f5fa                	sd	t5,232(sp)
    8000618e:	f9fe                	sd	t6,240(sp)
    80006190:	ca7fc0ef          	jal	ra,80002e36 <kerneltrap>
    80006194:	6082                	ld	ra,0(sp)
    80006196:	6122                	ld	sp,8(sp)
    80006198:	61c2                	ld	gp,16(sp)
    8000619a:	7282                	ld	t0,32(sp)
    8000619c:	7322                	ld	t1,40(sp)
    8000619e:	73c2                	ld	t2,48(sp)
    800061a0:	7462                	ld	s0,56(sp)
    800061a2:	6486                	ld	s1,64(sp)
    800061a4:	6526                	ld	a0,72(sp)
    800061a6:	65c6                	ld	a1,80(sp)
    800061a8:	6666                	ld	a2,88(sp)
    800061aa:	7686                	ld	a3,96(sp)
    800061ac:	7726                	ld	a4,104(sp)
    800061ae:	77c6                	ld	a5,112(sp)
    800061b0:	7866                	ld	a6,120(sp)
    800061b2:	688a                	ld	a7,128(sp)
    800061b4:	692a                	ld	s2,136(sp)
    800061b6:	69ca                	ld	s3,144(sp)
    800061b8:	6a6a                	ld	s4,152(sp)
    800061ba:	7a8a                	ld	s5,160(sp)
    800061bc:	7b2a                	ld	s6,168(sp)
    800061be:	7bca                	ld	s7,176(sp)
    800061c0:	7c6a                	ld	s8,184(sp)
    800061c2:	6c8e                	ld	s9,192(sp)
    800061c4:	6d2e                	ld	s10,200(sp)
    800061c6:	6dce                	ld	s11,208(sp)
    800061c8:	6e6e                	ld	t3,216(sp)
    800061ca:	7e8e                	ld	t4,224(sp)
    800061cc:	7f2e                	ld	t5,232(sp)
    800061ce:	7fce                	ld	t6,240(sp)
    800061d0:	6111                	addi	sp,sp,256
    800061d2:	10200073          	sret
    800061d6:	00000013          	nop
    800061da:	00000013          	nop
    800061de:	0001                	nop

00000000800061e0 <timervec>:
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	e10c                	sd	a1,0(a0)
    800061e6:	e510                	sd	a2,8(a0)
    800061e8:	e914                	sd	a3,16(a0)
    800061ea:	6d0c                	ld	a1,24(a0)
    800061ec:	7110                	ld	a2,32(a0)
    800061ee:	6194                	ld	a3,0(a1)
    800061f0:	96b2                	add	a3,a3,a2
    800061f2:	e194                	sd	a3,0(a1)
    800061f4:	4589                	li	a1,2
    800061f6:	14459073          	csrw	sip,a1
    800061fa:	6914                	ld	a3,16(a0)
    800061fc:	6510                	ld	a2,8(a0)
    800061fe:	610c                	ld	a1,0(a0)
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	30200073          	mret
	...

000000008000620a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000620a:	1141                	addi	sp,sp,-16
    8000620c:	e422                	sd	s0,8(sp)
    8000620e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006210:	0c0007b7          	lui	a5,0xc000
    80006214:	4705                	li	a4,1
    80006216:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006218:	c3d8                	sw	a4,4(a5)
}
    8000621a:	6422                	ld	s0,8(sp)
    8000621c:	0141                	addi	sp,sp,16
    8000621e:	8082                	ret

0000000080006220 <plicinithart>:

void
plicinithart(void)
{
    80006220:	1141                	addi	sp,sp,-16
    80006222:	e406                	sd	ra,8(sp)
    80006224:	e022                	sd	s0,0(sp)
    80006226:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	750080e7          	jalr	1872(ra) # 80001978 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006230:	0085171b          	slliw	a4,a0,0x8
    80006234:	0c0027b7          	lui	a5,0xc002
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	40200713          	li	a4,1026
    8000623e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006242:	00d5151b          	slliw	a0,a0,0xd
    80006246:	0c2017b7          	lui	a5,0xc201
    8000624a:	953e                	add	a0,a0,a5
    8000624c:	00052023          	sw	zero,0(a0)
}
    80006250:	60a2                	ld	ra,8(sp)
    80006252:	6402                	ld	s0,0(sp)
    80006254:	0141                	addi	sp,sp,16
    80006256:	8082                	ret

0000000080006258 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006258:	1141                	addi	sp,sp,-16
    8000625a:	e406                	sd	ra,8(sp)
    8000625c:	e022                	sd	s0,0(sp)
    8000625e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	718080e7          	jalr	1816(ra) # 80001978 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006268:	00d5179b          	slliw	a5,a0,0xd
    8000626c:	0c201537          	lui	a0,0xc201
    80006270:	953e                	add	a0,a0,a5
  return irq;
}
    80006272:	4148                	lw	a0,4(a0)
    80006274:	60a2                	ld	ra,8(sp)
    80006276:	6402                	ld	s0,0(sp)
    80006278:	0141                	addi	sp,sp,16
    8000627a:	8082                	ret

000000008000627c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	1000                	addi	s0,sp,32
    80006286:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006288:	ffffb097          	auipc	ra,0xffffb
    8000628c:	6f0080e7          	jalr	1776(ra) # 80001978 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006290:	00d5151b          	slliw	a0,a0,0xd
    80006294:	0c2017b7          	lui	a5,0xc201
    80006298:	97aa                	add	a5,a5,a0
    8000629a:	c3c4                	sw	s1,4(a5)
}
    8000629c:	60e2                	ld	ra,24(sp)
    8000629e:	6442                	ld	s0,16(sp)
    800062a0:	64a2                	ld	s1,8(sp)
    800062a2:	6105                	addi	sp,sp,32
    800062a4:	8082                	ret

00000000800062a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062a6:	1141                	addi	sp,sp,-16
    800062a8:	e406                	sd	ra,8(sp)
    800062aa:	e022                	sd	s0,0(sp)
    800062ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ae:	479d                	li	a5,7
    800062b0:	06a7c963          	blt	a5,a0,80006322 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062b4:	00023797          	auipc	a5,0x23
    800062b8:	d4c78793          	addi	a5,a5,-692 # 80029000 <disk>
    800062bc:	00a78733          	add	a4,a5,a0
    800062c0:	6789                	lui	a5,0x2
    800062c2:	97ba                	add	a5,a5,a4
    800062c4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062c8:	e7ad                	bnez	a5,80006332 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ca:	00451793          	slli	a5,a0,0x4
    800062ce:	00025717          	auipc	a4,0x25
    800062d2:	d3270713          	addi	a4,a4,-718 # 8002b000 <disk+0x2000>
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062de:	6314                	ld	a3,0(a4)
    800062e0:	96be                	add	a3,a3,a5
    800062e2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062e6:	6314                	ld	a3,0(a4)
    800062e8:	96be                	add	a3,a3,a5
    800062ea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062ee:	6318                	ld	a4,0(a4)
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062f6:	00023797          	auipc	a5,0x23
    800062fa:	d0a78793          	addi	a5,a5,-758 # 80029000 <disk>
    800062fe:	97aa                	add	a5,a5,a0
    80006300:	6509                	lui	a0,0x2
    80006302:	953e                	add	a0,a0,a5
    80006304:	4785                	li	a5,1
    80006306:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000630a:	00025517          	auipc	a0,0x25
    8000630e:	d0e50513          	addi	a0,a0,-754 # 8002b018 <disk+0x2018>
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	26e080e7          	jalr	622(ra) # 80002580 <wakeup>
}
    8000631a:	60a2                	ld	ra,8(sp)
    8000631c:	6402                	ld	s0,0(sp)
    8000631e:	0141                	addi	sp,sp,16
    80006320:	8082                	ret
    panic("free_desc 1");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	48650513          	addi	a0,a0,1158 # 800087a8 <syscalls+0x338>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	200080e7          	jalr	512(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	48650513          	addi	a0,a0,1158 # 800087b8 <syscalls+0x348>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	1f0080e7          	jalr	496(ra) # 8000052a <panic>

0000000080006342 <virtio_disk_init>:
{
    80006342:	1101                	addi	sp,sp,-32
    80006344:	ec06                	sd	ra,24(sp)
    80006346:	e822                	sd	s0,16(sp)
    80006348:	e426                	sd	s1,8(sp)
    8000634a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000634c:	00002597          	auipc	a1,0x2
    80006350:	47c58593          	addi	a1,a1,1148 # 800087c8 <syscalls+0x358>
    80006354:	00025517          	auipc	a0,0x25
    80006358:	dd450513          	addi	a0,a0,-556 # 8002b128 <disk+0x2128>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	7d6080e7          	jalr	2006(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006364:	100017b7          	lui	a5,0x10001
    80006368:	4398                	lw	a4,0(a5)
    8000636a:	2701                	sext.w	a4,a4
    8000636c:	747277b7          	lui	a5,0x74727
    80006370:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006374:	0ef71163          	bne	a4,a5,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	43dc                	lw	a5,4(a5)
    8000637e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006380:	4705                	li	a4,1
    80006382:	0ce79a63          	bne	a5,a4,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006386:	100017b7          	lui	a5,0x10001
    8000638a:	479c                	lw	a5,8(a5)
    8000638c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000638e:	4709                	li	a4,2
    80006390:	0ce79363          	bne	a5,a4,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006394:	100017b7          	lui	a5,0x10001
    80006398:	47d8                	lw	a4,12(a5)
    8000639a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000639c:	554d47b7          	lui	a5,0x554d4
    800063a0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063a4:	0af71963          	bne	a4,a5,80006456 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a8:	100017b7          	lui	a5,0x10001
    800063ac:	4705                	li	a4,1
    800063ae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b0:	470d                	li	a4,3
    800063b2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063b4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063b6:	c7ffe737          	lui	a4,0xc7ffe
    800063ba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd275f>
    800063be:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063c0:	2701                	sext.w	a4,a4
    800063c2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c4:	472d                	li	a4,11
    800063c6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c8:	473d                	li	a4,15
    800063ca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063cc:	6705                	lui	a4,0x1
    800063ce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063d4:	5bdc                	lw	a5,52(a5)
    800063d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063d8:	c7d9                	beqz	a5,80006466 <virtio_disk_init+0x124>
  if(max < NUM)
    800063da:	471d                	li	a4,7
    800063dc:	08f77d63          	bgeu	a4,a5,80006476 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063e0:	100014b7          	lui	s1,0x10001
    800063e4:	47a1                	li	a5,8
    800063e6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063e8:	6609                	lui	a2,0x2
    800063ea:	4581                	li	a1,0
    800063ec:	00023517          	auipc	a0,0x23
    800063f0:	c1450513          	addi	a0,a0,-1004 # 80029000 <disk>
    800063f4:	ffffb097          	auipc	ra,0xffffb
    800063f8:	8ee080e7          	jalr	-1810(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063fc:	00023717          	auipc	a4,0x23
    80006400:	c0470713          	addi	a4,a4,-1020 # 80029000 <disk>
    80006404:	00c75793          	srli	a5,a4,0xc
    80006408:	2781                	sext.w	a5,a5
    8000640a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000640c:	00025797          	auipc	a5,0x25
    80006410:	bf478793          	addi	a5,a5,-1036 # 8002b000 <disk+0x2000>
    80006414:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006416:	00023717          	auipc	a4,0x23
    8000641a:	c6a70713          	addi	a4,a4,-918 # 80029080 <disk+0x80>
    8000641e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006420:	00024717          	auipc	a4,0x24
    80006424:	be070713          	addi	a4,a4,-1056 # 8002a000 <disk+0x1000>
    80006428:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000642a:	4705                	li	a4,1
    8000642c:	00e78c23          	sb	a4,24(a5)
    80006430:	00e78ca3          	sb	a4,25(a5)
    80006434:	00e78d23          	sb	a4,26(a5)
    80006438:	00e78da3          	sb	a4,27(a5)
    8000643c:	00e78e23          	sb	a4,28(a5)
    80006440:	00e78ea3          	sb	a4,29(a5)
    80006444:	00e78f23          	sb	a4,30(a5)
    80006448:	00e78fa3          	sb	a4,31(a5)
}
    8000644c:	60e2                	ld	ra,24(sp)
    8000644e:	6442                	ld	s0,16(sp)
    80006450:	64a2                	ld	s1,8(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
    panic("could not find virtio disk");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	38250513          	addi	a0,a0,898 # 800087d8 <syscalls+0x368>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0cc080e7          	jalr	204(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	39250513          	addi	a0,a0,914 # 800087f8 <syscalls+0x388>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0bc080e7          	jalr	188(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	3a250513          	addi	a0,a0,930 # 80008818 <syscalls+0x3a8>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0ac080e7          	jalr	172(ra) # 8000052a <panic>

0000000080006486 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006486:	7119                	addi	sp,sp,-128
    80006488:	fc86                	sd	ra,120(sp)
    8000648a:	f8a2                	sd	s0,112(sp)
    8000648c:	f4a6                	sd	s1,104(sp)
    8000648e:	f0ca                	sd	s2,96(sp)
    80006490:	ecce                	sd	s3,88(sp)
    80006492:	e8d2                	sd	s4,80(sp)
    80006494:	e4d6                	sd	s5,72(sp)
    80006496:	e0da                	sd	s6,64(sp)
    80006498:	fc5e                	sd	s7,56(sp)
    8000649a:	f862                	sd	s8,48(sp)
    8000649c:	f466                	sd	s9,40(sp)
    8000649e:	f06a                	sd	s10,32(sp)
    800064a0:	ec6e                	sd	s11,24(sp)
    800064a2:	0100                	addi	s0,sp,128
    800064a4:	8aaa                	mv	s5,a0
    800064a6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064a8:	00c52c83          	lw	s9,12(a0)
    800064ac:	001c9c9b          	slliw	s9,s9,0x1
    800064b0:	1c82                	slli	s9,s9,0x20
    800064b2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064b6:	00025517          	auipc	a0,0x25
    800064ba:	c7250513          	addi	a0,a0,-910 # 8002b128 <disk+0x2128>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	704080e7          	jalr	1796(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    800064c6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064c8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064ca:	00023c17          	auipc	s8,0x23
    800064ce:	b36c0c13          	addi	s8,s8,-1226 # 80029000 <disk>
    800064d2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800064d4:	4b0d                	li	s6,3
    800064d6:	a0ad                	j	80006540 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800064d8:	00fc0733          	add	a4,s8,a5
    800064dc:	975e                	add	a4,a4,s7
    800064de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800064e4:	0207c563          	bltz	a5,8000650e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064e8:	2905                	addiw	s2,s2,1
    800064ea:	0611                	addi	a2,a2,4
    800064ec:	19690d63          	beq	s2,s6,80006686 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800064f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800064f2:	00025717          	auipc	a4,0x25
    800064f6:	b2670713          	addi	a4,a4,-1242 # 8002b018 <disk+0x2018>
    800064fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800064fc:	00074683          	lbu	a3,0(a4)
    80006500:	fee1                	bnez	a3,800064d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006502:	2785                	addiw	a5,a5,1
    80006504:	0705                	addi	a4,a4,1
    80006506:	fe979be3          	bne	a5,s1,800064fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000650a:	57fd                	li	a5,-1
    8000650c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000650e:	01205d63          	blez	s2,80006528 <virtio_disk_rw+0xa2>
    80006512:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006514:	000a2503          	lw	a0,0(s4)
    80006518:	00000097          	auipc	ra,0x0
    8000651c:	d8e080e7          	jalr	-626(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006520:	2d85                	addiw	s11,s11,1
    80006522:	0a11                	addi	s4,s4,4
    80006524:	ffb918e3          	bne	s2,s11,80006514 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006528:	00025597          	auipc	a1,0x25
    8000652c:	c0058593          	addi	a1,a1,-1024 # 8002b128 <disk+0x2128>
    80006530:	00025517          	auipc	a0,0x25
    80006534:	ae850513          	addi	a0,a0,-1304 # 8002b018 <disk+0x2018>
    80006538:	ffffc097          	auipc	ra,0xffffc
    8000653c:	eba080e7          	jalr	-326(ra) # 800023f2 <sleep>
  for(int i = 0; i < 3; i++){
    80006540:	f8040a13          	addi	s4,s0,-128
{
    80006544:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006546:	894e                	mv	s2,s3
    80006548:	b765                	j	800064f0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000654a:	00025697          	auipc	a3,0x25
    8000654e:	ab66b683          	ld	a3,-1354(a3) # 8002b000 <disk+0x2000>
    80006552:	96ba                	add	a3,a3,a4
    80006554:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006558:	00023817          	auipc	a6,0x23
    8000655c:	aa880813          	addi	a6,a6,-1368 # 80029000 <disk>
    80006560:	00025697          	auipc	a3,0x25
    80006564:	aa068693          	addi	a3,a3,-1376 # 8002b000 <disk+0x2000>
    80006568:	6290                	ld	a2,0(a3)
    8000656a:	963a                	add	a2,a2,a4
    8000656c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006570:	0015e593          	ori	a1,a1,1
    80006574:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006578:	f8842603          	lw	a2,-120(s0)
    8000657c:	628c                	ld	a1,0(a3)
    8000657e:	972e                	add	a4,a4,a1
    80006580:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006584:	20050593          	addi	a1,a0,512
    80006588:	0592                	slli	a1,a1,0x4
    8000658a:	95c2                	add	a1,a1,a6
    8000658c:	577d                	li	a4,-1
    8000658e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006592:	00461713          	slli	a4,a2,0x4
    80006596:	6290                	ld	a2,0(a3)
    80006598:	963a                	add	a2,a2,a4
    8000659a:	03078793          	addi	a5,a5,48
    8000659e:	97c2                	add	a5,a5,a6
    800065a0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800065a2:	629c                	ld	a5,0(a3)
    800065a4:	97ba                	add	a5,a5,a4
    800065a6:	4605                	li	a2,1
    800065a8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065aa:	629c                	ld	a5,0(a3)
    800065ac:	97ba                	add	a5,a5,a4
    800065ae:	4809                	li	a6,2
    800065b0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065b4:	629c                	ld	a5,0(a3)
    800065b6:	973e                	add	a4,a4,a5
    800065b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065bc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800065c0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065c4:	6698                	ld	a4,8(a3)
    800065c6:	00275783          	lhu	a5,2(a4)
    800065ca:	8b9d                	andi	a5,a5,7
    800065cc:	0786                	slli	a5,a5,0x1
    800065ce:	97ba                	add	a5,a5,a4
    800065d0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800065d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065d8:	6698                	ld	a4,8(a3)
    800065da:	00275783          	lhu	a5,2(a4)
    800065de:	2785                	addiw	a5,a5,1
    800065e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065e8:	100017b7          	lui	a5,0x10001
    800065ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065f0:	004aa783          	lw	a5,4(s5)
    800065f4:	02c79163          	bne	a5,a2,80006616 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800065f8:	00025917          	auipc	s2,0x25
    800065fc:	b3090913          	addi	s2,s2,-1232 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    80006600:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006602:	85ca                	mv	a1,s2
    80006604:	8556                	mv	a0,s5
    80006606:	ffffc097          	auipc	ra,0xffffc
    8000660a:	dec080e7          	jalr	-532(ra) # 800023f2 <sleep>
  while(b->disk == 1) {
    8000660e:	004aa783          	lw	a5,4(s5)
    80006612:	fe9788e3          	beq	a5,s1,80006602 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006616:	f8042903          	lw	s2,-128(s0)
    8000661a:	20090793          	addi	a5,s2,512
    8000661e:	00479713          	slli	a4,a5,0x4
    80006622:	00023797          	auipc	a5,0x23
    80006626:	9de78793          	addi	a5,a5,-1570 # 80029000 <disk>
    8000662a:	97ba                	add	a5,a5,a4
    8000662c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006630:	00025997          	auipc	s3,0x25
    80006634:	9d098993          	addi	s3,s3,-1584 # 8002b000 <disk+0x2000>
    80006638:	00491713          	slli	a4,s2,0x4
    8000663c:	0009b783          	ld	a5,0(s3)
    80006640:	97ba                	add	a5,a5,a4
    80006642:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006646:	854a                	mv	a0,s2
    80006648:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000664c:	00000097          	auipc	ra,0x0
    80006650:	c5a080e7          	jalr	-934(ra) # 800062a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006654:	8885                	andi	s1,s1,1
    80006656:	f0ed                	bnez	s1,80006638 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006658:	00025517          	auipc	a0,0x25
    8000665c:	ad050513          	addi	a0,a0,-1328 # 8002b128 <disk+0x2128>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	628080e7          	jalr	1576(ra) # 80000c88 <release>
}
    80006668:	70e6                	ld	ra,120(sp)
    8000666a:	7446                	ld	s0,112(sp)
    8000666c:	74a6                	ld	s1,104(sp)
    8000666e:	7906                	ld	s2,96(sp)
    80006670:	69e6                	ld	s3,88(sp)
    80006672:	6a46                	ld	s4,80(sp)
    80006674:	6aa6                	ld	s5,72(sp)
    80006676:	6b06                	ld	s6,64(sp)
    80006678:	7be2                	ld	s7,56(sp)
    8000667a:	7c42                	ld	s8,48(sp)
    8000667c:	7ca2                	ld	s9,40(sp)
    8000667e:	7d02                	ld	s10,32(sp)
    80006680:	6de2                	ld	s11,24(sp)
    80006682:	6109                	addi	sp,sp,128
    80006684:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006686:	f8042503          	lw	a0,-128(s0)
    8000668a:	20050793          	addi	a5,a0,512
    8000668e:	0792                	slli	a5,a5,0x4
  if(write)
    80006690:	00023817          	auipc	a6,0x23
    80006694:	97080813          	addi	a6,a6,-1680 # 80029000 <disk>
    80006698:	00f80733          	add	a4,a6,a5
    8000669c:	01a036b3          	snez	a3,s10
    800066a0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800066a4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066a8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066ac:	7679                	lui	a2,0xffffe
    800066ae:	963e                	add	a2,a2,a5
    800066b0:	00025697          	auipc	a3,0x25
    800066b4:	95068693          	addi	a3,a3,-1712 # 8002b000 <disk+0x2000>
    800066b8:	6298                	ld	a4,0(a3)
    800066ba:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066bc:	0a878593          	addi	a1,a5,168
    800066c0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066c2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066c4:	6298                	ld	a4,0(a3)
    800066c6:	9732                	add	a4,a4,a2
    800066c8:	45c1                	li	a1,16
    800066ca:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066cc:	6298                	ld	a4,0(a3)
    800066ce:	9732                	add	a4,a4,a2
    800066d0:	4585                	li	a1,1
    800066d2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066d6:	f8442703          	lw	a4,-124(s0)
    800066da:	628c                	ld	a1,0(a3)
    800066dc:	962e                	add	a2,a2,a1
    800066de:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd200e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800066e2:	0712                	slli	a4,a4,0x4
    800066e4:	6290                	ld	a2,0(a3)
    800066e6:	963a                	add	a2,a2,a4
    800066e8:	058a8593          	addi	a1,s5,88
    800066ec:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800066ee:	6294                	ld	a3,0(a3)
    800066f0:	96ba                	add	a3,a3,a4
    800066f2:	40000613          	li	a2,1024
    800066f6:	c690                	sw	a2,8(a3)
  if(write)
    800066f8:	e40d19e3          	bnez	s10,8000654a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066fc:	00025697          	auipc	a3,0x25
    80006700:	9046b683          	ld	a3,-1788(a3) # 8002b000 <disk+0x2000>
    80006704:	96ba                	add	a3,a3,a4
    80006706:	4609                	li	a2,2
    80006708:	00c69623          	sh	a2,12(a3)
    8000670c:	b5b1                	j	80006558 <virtio_disk_rw+0xd2>

000000008000670e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000670e:	1101                	addi	sp,sp,-32
    80006710:	ec06                	sd	ra,24(sp)
    80006712:	e822                	sd	s0,16(sp)
    80006714:	e426                	sd	s1,8(sp)
    80006716:	e04a                	sd	s2,0(sp)
    80006718:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000671a:	00025517          	auipc	a0,0x25
    8000671e:	a0e50513          	addi	a0,a0,-1522 # 8002b128 <disk+0x2128>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	4a0080e7          	jalr	1184(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000672a:	10001737          	lui	a4,0x10001
    8000672e:	533c                	lw	a5,96(a4)
    80006730:	8b8d                	andi	a5,a5,3
    80006732:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006734:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006738:	00025797          	auipc	a5,0x25
    8000673c:	8c878793          	addi	a5,a5,-1848 # 8002b000 <disk+0x2000>
    80006740:	6b94                	ld	a3,16(a5)
    80006742:	0207d703          	lhu	a4,32(a5)
    80006746:	0026d783          	lhu	a5,2(a3)
    8000674a:	06f70163          	beq	a4,a5,800067ac <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000674e:	00023917          	auipc	s2,0x23
    80006752:	8b290913          	addi	s2,s2,-1870 # 80029000 <disk>
    80006756:	00025497          	auipc	s1,0x25
    8000675a:	8aa48493          	addi	s1,s1,-1878 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    8000675e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006762:	6898                	ld	a4,16(s1)
    80006764:	0204d783          	lhu	a5,32(s1)
    80006768:	8b9d                	andi	a5,a5,7
    8000676a:	078e                	slli	a5,a5,0x3
    8000676c:	97ba                	add	a5,a5,a4
    8000676e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006770:	20078713          	addi	a4,a5,512
    80006774:	0712                	slli	a4,a4,0x4
    80006776:	974a                	add	a4,a4,s2
    80006778:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000677c:	e731                	bnez	a4,800067c8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000677e:	20078793          	addi	a5,a5,512
    80006782:	0792                	slli	a5,a5,0x4
    80006784:	97ca                	add	a5,a5,s2
    80006786:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006788:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000678c:	ffffc097          	auipc	ra,0xffffc
    80006790:	df4080e7          	jalr	-524(ra) # 80002580 <wakeup>

    disk.used_idx += 1;
    80006794:	0204d783          	lhu	a5,32(s1)
    80006798:	2785                	addiw	a5,a5,1
    8000679a:	17c2                	slli	a5,a5,0x30
    8000679c:	93c1                	srli	a5,a5,0x30
    8000679e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067a2:	6898                	ld	a4,16(s1)
    800067a4:	00275703          	lhu	a4,2(a4)
    800067a8:	faf71be3          	bne	a4,a5,8000675e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ac:	00025517          	auipc	a0,0x25
    800067b0:	97c50513          	addi	a0,a0,-1668 # 8002b128 <disk+0x2128>
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	4d4080e7          	jalr	1236(ra) # 80000c88 <release>
}
    800067bc:	60e2                	ld	ra,24(sp)
    800067be:	6442                	ld	s0,16(sp)
    800067c0:	64a2                	ld	s1,8(sp)
    800067c2:	6902                	ld	s2,0(sp)
    800067c4:	6105                	addi	sp,sp,32
    800067c6:	8082                	ret
      panic("virtio_disk_intr status");
    800067c8:	00002517          	auipc	a0,0x2
    800067cc:	07050513          	addi	a0,a0,112 # 80008838 <syscalls+0x3c8>
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	d5a080e7          	jalr	-678(ra) # 8000052a <panic>
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
