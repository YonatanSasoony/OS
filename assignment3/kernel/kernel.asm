
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
    80000122:	0d4080e7          	jalr	212(ra) # 800021f2 <either_copyin>
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
    800001c6:	e34080e7          	jalr	-460(ra) # 80001ff6 <sleep>
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
    80000202:	f9e080e7          	jalr	-98(ra) # 8000219c <either_copyout>
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
    800002e2:	f6a080e7          	jalr	-150(ra) # 80002248 <procdump>
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
    80000436:	c28080e7          	jalr	-984(ra) # 8000205a <wakeup>
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
    8000087e:	00001097          	auipc	ra,0x1
    80000882:	7dc080e7          	jalr	2012(ra) # 8000205a <wakeup>
    
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
    8000090e:	6ec080e7          	jalr	1772(ra) # 80001ff6 <sleep>
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
    80000eb6:	040080e7          	jalr	64(ra) # 80002ef2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	bd6080e7          	jalr	-1066(ra) # 80006a90 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	f82080e7          	jalr	-126(ra) # 80001e44 <scheduler>
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
    80000f2e:	fa0080e7          	jalr	-96(ra) # 80002eca <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	fc0080e7          	jalr	-64(ra) # 80002ef2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	b40080e7          	jalr	-1216(ra) # 80006a7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	b4e080e7          	jalr	-1202(ra) # 80006a90 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	720080e7          	jalr	1824(ra) # 8000366a <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	db2080e7          	jalr	-590(ra) # 80003d04 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	072080e7          	jalr	114(ra) # 80004fcc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	c50080e7          	jalr	-944(ra) # 80006bb2 <virtio_disk_init>
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
    80001428:	69c080e7          	jalr	1692(ra) # 80002ac0 <remove_page_from_ram>
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
    80001492:	7fe080e7          	jalr	2046(ra) # 80002c8c <insert_page_to_ram>
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
    80001a28:	0cc7a783          	lw	a5,204(a5) # 80009af0 <first.1>
    80001a2c:	eb89                	bnez	a5,80001a3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2e:	00001097          	auipc	ra,0x1
    80001a32:	4dc080e7          	jalr	1244(ra) # 80002f0a <usertrapret>
}
    80001a36:	60a2                	ld	ra,8(sp)
    80001a38:	6402                	ld	s0,0(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret
    first = 0;
    80001a3e:	00008797          	auipc	a5,0x8
    80001a42:	0a07a923          	sw	zero,178(a5) # 80009af0 <first.1>
    fsinit(ROOTDEV);
    80001a46:	4505                	li	a0,1
    80001a48:	00002097          	auipc	ra,0x2
    80001a4c:	23c080e7          	jalr	572(ra) # 80003c84 <fsinit>
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
    80001a74:	08478793          	addi	a5,a5,132 # 80009af4 <nextpid>
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
    80001cd0:	e3458593          	addi	a1,a1,-460 # 80009b00 <initcode>
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
    80001d0e:	9a8080e7          	jalr	-1624(ra) # 800046b2 <namei>
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

0000000080001da2 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001da2:	c559                	beqz	a0,80001e30 <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001da4:	7139                	addi	sp,sp,-64
    80001da6:	fc06                	sd	ra,56(sp)
    80001da8:	f822                	sd	s0,48(sp)
    80001daa:	f426                	sd	s1,40(sp)
    80001dac:	f04a                	sd	s2,32(sp)
    80001dae:	ec4e                	sd	s3,24(sp)
    80001db0:	e852                	sd	s4,16(sp)
    80001db2:	e456                	sd	s5,8(sp)
    80001db4:	0080                	addi	s0,sp,64
    80001db6:	89aa                	mv	s3,a0
    80001db8:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001dba:	16853783          	ld	a5,360(a0)
    80001dbe:	cbbd                	beqz	a5,80001e34 <copy_swapFile+0x92>
    80001dc0:	cda5                	beqz	a1,80001e38 <copy_swapFile+0x96>
    80001dc2:	1685b783          	ld	a5,360(a1)
    80001dc6:	cbbd                	beqz	a5,80001e3c <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	d0a080e7          	jalr	-758(ra) # 80000ad2 <kalloc>
    80001dd0:	892a                	mv	s2,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_PSYC_PAGES]; disk_pg++) {
    80001dd2:	27098493          	addi	s1,s3,624
    80001dd6:	37098a13          	addi	s4,s3,880
    80001dda:	a021                	j	80001de2 <copy_swapFile+0x40>
    80001ddc:	04c1                	addi	s1,s1,16
    80001dde:	029a0a63          	beq	s4,s1,80001e12 <copy_swapFile+0x70>
    if(!disk_pg->used) {
    80001de2:	44dc                	lw	a5,12(s1)
    80001de4:	dfe5                	beqz	a5,80001ddc <copy_swapFile+0x3a>
    if (readFromSwapFile(src, buffer, disk_pg->offset, total_size) < 0) {
    80001de6:	66c1                	lui	a3,0x10
    80001de8:	4490                	lw	a2,8(s1)
    80001dea:	85ca                	mv	a1,s2
    80001dec:	854e                	mv	a0,s3
    80001dee:	00003097          	auipc	ra,0x3
    80001df2:	bec080e7          	jalr	-1044(ra) # 800049da <readFromSwapFile>
    80001df6:	04054563          	bltz	a0,80001e40 <copy_swapFile+0x9e>
    if (writeToSwapFile(dst, buffer, disk_pg->offset, total_size) < 0) {
    80001dfa:	66c1                	lui	a3,0x10
    80001dfc:	4490                	lw	a2,8(s1)
    80001dfe:	85ca                	mv	a1,s2
    80001e00:	8556                	mv	a0,s5
    80001e02:	00003097          	auipc	ra,0x3
    80001e06:	bb4080e7          	jalr	-1100(ra) # 800049b6 <writeToSwapFile>
    80001e0a:	fc0559e3          	bgez	a0,80001ddc <copy_swapFile+0x3a>
      return -1;
    80001e0e:	557d                	li	a0,-1
    80001e10:	a039                	j	80001e1e <copy_swapFile+0x7c>
  kfree(buffer);
    80001e12:	854a                	mv	a0,s2
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	bc2080e7          	jalr	-1086(ra) # 800009d6 <kfree>
  return 0;
    80001e1c:	4501                	li	a0,0
}
    80001e1e:	70e2                	ld	ra,56(sp)
    80001e20:	7442                	ld	s0,48(sp)
    80001e22:	74a2                	ld	s1,40(sp)
    80001e24:	7902                	ld	s2,32(sp)
    80001e26:	69e2                	ld	s3,24(sp)
    80001e28:	6a42                	ld	s4,16(sp)
    80001e2a:	6aa2                	ld	s5,8(sp)
    80001e2c:	6121                	addi	sp,sp,64
    80001e2e:	8082                	ret
    return -1;
    80001e30:	557d                	li	a0,-1
}
    80001e32:	8082                	ret
    return -1;
    80001e34:	557d                	li	a0,-1
    80001e36:	b7e5                	j	80001e1e <copy_swapFile+0x7c>
    80001e38:	557d                	li	a0,-1
    80001e3a:	b7d5                	j	80001e1e <copy_swapFile+0x7c>
    80001e3c:	557d                	li	a0,-1
    80001e3e:	b7c5                	j	80001e1e <copy_swapFile+0x7c>
      return -1;
    80001e40:	557d                	li	a0,-1
    80001e42:	bff1                	j	80001e1e <copy_swapFile+0x7c>

0000000080001e44 <scheduler>:
{
    80001e44:	7139                	addi	sp,sp,-64
    80001e46:	fc06                	sd	ra,56(sp)
    80001e48:	f822                	sd	s0,48(sp)
    80001e4a:	f426                	sd	s1,40(sp)
    80001e4c:	f04a                	sd	s2,32(sp)
    80001e4e:	ec4e                	sd	s3,24(sp)
    80001e50:	e852                	sd	s4,16(sp)
    80001e52:	e456                	sd	s5,8(sp)
    80001e54:	e05a                	sd	s6,0(sp)
    80001e56:	0080                	addi	s0,sp,64
    80001e58:	8792                	mv	a5,tp
  int id = r_tp();
    80001e5a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e5c:	00779a93          	slli	s5,a5,0x7
    80001e60:	00010717          	auipc	a4,0x10
    80001e64:	44070713          	addi	a4,a4,1088 # 800122a0 <pid_lock>
    80001e68:	9756                	add	a4,a4,s5
    80001e6a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001e6e:	00010717          	auipc	a4,0x10
    80001e72:	46a70713          	addi	a4,a4,1130 # 800122d8 <cpus+0x8>
    80001e76:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001e78:	498d                	li	s3,3
        p->state = RUNNING;
    80001e7a:	4b11                	li	s6,4
        c->proc = p;
    80001e7c:	079e                	slli	a5,a5,0x7
    80001e7e:	00010a17          	auipc	s4,0x10
    80001e82:	422a0a13          	addi	s4,s4,1058 # 800122a0 <pid_lock>
    80001e86:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e88:	0001e917          	auipc	s2,0x1e
    80001e8c:	64890913          	addi	s2,s2,1608 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e98:	10079073          	csrw	sstatus,a5
    80001e9c:	00011497          	auipc	s1,0x11
    80001ea0:	83448493          	addi	s1,s1,-1996 # 800126d0 <proc>
    80001ea4:	a811                	j	80001eb8 <scheduler+0x74>
      release(&p->lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	dce080e7          	jalr	-562(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eb0:	37848493          	addi	s1,s1,888
    80001eb4:	fd248ee3          	beq	s1,s2,80001e90 <scheduler+0x4c>
      acquire(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	d08080e7          	jalr	-760(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001ec2:	4c9c                	lw	a5,24(s1)
    80001ec4:	ff3791e3          	bne	a5,s3,80001ea6 <scheduler+0x62>
        p->state = RUNNING;
    80001ec8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001ecc:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ed0:	06048593          	addi	a1,s1,96
    80001ed4:	8556                	mv	a0,s5
    80001ed6:	00001097          	auipc	ra,0x1
    80001eda:	f8a080e7          	jalr	-118(ra) # 80002e60 <swtch>
        c->proc = 0;
    80001ede:	020a3823          	sd	zero,48(s4)
    80001ee2:	b7d1                	j	80001ea6 <scheduler+0x62>

0000000080001ee4 <sched>:
{
    80001ee4:	7179                	addi	sp,sp,-48
    80001ee6:	f406                	sd	ra,40(sp)
    80001ee8:	f022                	sd	s0,32(sp)
    80001eea:	ec26                	sd	s1,24(sp)
    80001eec:	e84a                	sd	s2,16(sp)
    80001eee:	e44e                	sd	s3,8(sp)
    80001ef0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	ae2080e7          	jalr	-1310(ra) # 800019d4 <myproc>
    80001efa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	c4c080e7          	jalr	-948(ra) # 80000b48 <holding>
    80001f04:	c93d                	beqz	a0,80001f7a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f06:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f08:	2781                	sext.w	a5,a5
    80001f0a:	079e                	slli	a5,a5,0x7
    80001f0c:	00010717          	auipc	a4,0x10
    80001f10:	39470713          	addi	a4,a4,916 # 800122a0 <pid_lock>
    80001f14:	97ba                	add	a5,a5,a4
    80001f16:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f1a:	4785                	li	a5,1
    80001f1c:	06f71763          	bne	a4,a5,80001f8a <sched+0xa6>
  if(p->state == RUNNING)
    80001f20:	4c98                	lw	a4,24(s1)
    80001f22:	4791                	li	a5,4
    80001f24:	06f70b63          	beq	a4,a5,80001f9a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f2c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f2e:	efb5                	bnez	a5,80001faa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f30:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f32:	00010917          	auipc	s2,0x10
    80001f36:	36e90913          	addi	s2,s2,878 # 800122a0 <pid_lock>
    80001f3a:	2781                	sext.w	a5,a5
    80001f3c:	079e                	slli	a5,a5,0x7
    80001f3e:	97ca                	add	a5,a5,s2
    80001f40:	0ac7a983          	lw	s3,172(a5)
    80001f44:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f46:	2781                	sext.w	a5,a5
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	00010597          	auipc	a1,0x10
    80001f4e:	38e58593          	addi	a1,a1,910 # 800122d8 <cpus+0x8>
    80001f52:	95be                	add	a1,a1,a5
    80001f54:	06048513          	addi	a0,s1,96
    80001f58:	00001097          	auipc	ra,0x1
    80001f5c:	f08080e7          	jalr	-248(ra) # 80002e60 <swtch>
    80001f60:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	97ca                	add	a5,a5,s2
    80001f68:	0b37a623          	sw	s3,172(a5)
}
    80001f6c:	70a2                	ld	ra,40(sp)
    80001f6e:	7402                	ld	s0,32(sp)
    80001f70:	64e2                	ld	s1,24(sp)
    80001f72:	6942                	ld	s2,16(sp)
    80001f74:	69a2                	ld	s3,8(sp)
    80001f76:	6145                	addi	sp,sp,48
    80001f78:	8082                	ret
    panic("sched p->lock");
    80001f7a:	00007517          	auipc	a0,0x7
    80001f7e:	28650513          	addi	a0,a0,646 # 80009200 <digits+0x1c0>
    80001f82:	ffffe097          	auipc	ra,0xffffe
    80001f86:	5a8080e7          	jalr	1448(ra) # 8000052a <panic>
    panic("sched locks");
    80001f8a:	00007517          	auipc	a0,0x7
    80001f8e:	28650513          	addi	a0,a0,646 # 80009210 <digits+0x1d0>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	598080e7          	jalr	1432(ra) # 8000052a <panic>
    panic("sched running");
    80001f9a:	00007517          	auipc	a0,0x7
    80001f9e:	28650513          	addi	a0,a0,646 # 80009220 <digits+0x1e0>
    80001fa2:	ffffe097          	auipc	ra,0xffffe
    80001fa6:	588080e7          	jalr	1416(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001faa:	00007517          	auipc	a0,0x7
    80001fae:	28650513          	addi	a0,a0,646 # 80009230 <digits+0x1f0>
    80001fb2:	ffffe097          	auipc	ra,0xffffe
    80001fb6:	578080e7          	jalr	1400(ra) # 8000052a <panic>

0000000080001fba <yield>:
{
    80001fba:	1101                	addi	sp,sp,-32
    80001fbc:	ec06                	sd	ra,24(sp)
    80001fbe:	e822                	sd	s0,16(sp)
    80001fc0:	e426                	sd	s1,8(sp)
    80001fc2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	a10080e7          	jalr	-1520(ra) # 800019d4 <myproc>
    80001fcc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	bf4080e7          	jalr	-1036(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80001fd6:	478d                	li	a5,3
    80001fd8:	cc9c                	sw	a5,24(s1)
  sched();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	f0a080e7          	jalr	-246(ra) # 80001ee4 <sched>
  release(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	c92080e7          	jalr	-878(ra) # 80000c76 <release>
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6105                	addi	sp,sp,32
    80001ff4:	8082                	ret

0000000080001ff6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ff6:	7179                	addi	sp,sp,-48
    80001ff8:	f406                	sd	ra,40(sp)
    80001ffa:	f022                	sd	s0,32(sp)
    80001ffc:	ec26                	sd	s1,24(sp)
    80001ffe:	e84a                	sd	s2,16(sp)
    80002000:	e44e                	sd	s3,8(sp)
    80002002:	1800                	addi	s0,sp,48
    80002004:	89aa                	mv	s3,a0
    80002006:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	9cc080e7          	jalr	-1588(ra) # 800019d4 <myproc>
    80002010:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	bb0080e7          	jalr	-1104(ra) # 80000bc2 <acquire>
  release(lk);
    8000201a:	854a                	mv	a0,s2
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c5a080e7          	jalr	-934(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002024:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002028:	4789                	li	a5,2
    8000202a:	cc9c                	sw	a5,24(s1)

  sched();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	eb8080e7          	jalr	-328(ra) # 80001ee4 <sched>

  // Tidy up.
  p->chan = 0;
    80002034:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c3c080e7          	jalr	-964(ra) # 80000c76 <release>
  acquire(lk);
    80002042:	854a                	mv	a0,s2
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	b7e080e7          	jalr	-1154(ra) # 80000bc2 <acquire>
}
    8000204c:	70a2                	ld	ra,40(sp)
    8000204e:	7402                	ld	s0,32(sp)
    80002050:	64e2                	ld	s1,24(sp)
    80002052:	6942                	ld	s2,16(sp)
    80002054:	69a2                	ld	s3,8(sp)
    80002056:	6145                	addi	sp,sp,48
    80002058:	8082                	ret

000000008000205a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000205a:	7139                	addi	sp,sp,-64
    8000205c:	fc06                	sd	ra,56(sp)
    8000205e:	f822                	sd	s0,48(sp)
    80002060:	f426                	sd	s1,40(sp)
    80002062:	f04a                	sd	s2,32(sp)
    80002064:	ec4e                	sd	s3,24(sp)
    80002066:	e852                	sd	s4,16(sp)
    80002068:	e456                	sd	s5,8(sp)
    8000206a:	0080                	addi	s0,sp,64
    8000206c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000206e:	00010497          	auipc	s1,0x10
    80002072:	66248493          	addi	s1,s1,1634 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002076:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002078:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000207a:	0001e917          	auipc	s2,0x1e
    8000207e:	45690913          	addi	s2,s2,1110 # 800204d0 <tickslock>
    80002082:	a811                	j	80002096 <wakeup+0x3c>
      }
      release(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	bf0080e7          	jalr	-1040(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000208e:	37848493          	addi	s1,s1,888
    80002092:	03248663          	beq	s1,s2,800020be <wakeup+0x64>
    if(p != myproc()){
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	93e080e7          	jalr	-1730(ra) # 800019d4 <myproc>
    8000209e:	fea488e3          	beq	s1,a0,8000208e <wakeup+0x34>
      acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b1e080e7          	jalr	-1250(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	fd379be3          	bne	a5,s3,80002084 <wakeup+0x2a>
    800020b2:	709c                	ld	a5,32(s1)
    800020b4:	fd4798e3          	bne	a5,s4,80002084 <wakeup+0x2a>
        p->state = RUNNABLE;
    800020b8:	0154ac23          	sw	s5,24(s1)
    800020bc:	b7e1                	j	80002084 <wakeup+0x2a>
    }
  }
}
    800020be:	70e2                	ld	ra,56(sp)
    800020c0:	7442                	ld	s0,48(sp)
    800020c2:	74a2                	ld	s1,40(sp)
    800020c4:	7902                	ld	s2,32(sp)
    800020c6:	69e2                	ld	s3,24(sp)
    800020c8:	6a42                	ld	s4,16(sp)
    800020ca:	6aa2                	ld	s5,8(sp)
    800020cc:	6121                	addi	sp,sp,64
    800020ce:	8082                	ret

00000000800020d0 <reparent>:
{
    800020d0:	7179                	addi	sp,sp,-48
    800020d2:	f406                	sd	ra,40(sp)
    800020d4:	f022                	sd	s0,32(sp)
    800020d6:	ec26                	sd	s1,24(sp)
    800020d8:	e84a                	sd	s2,16(sp)
    800020da:	e44e                	sd	s3,8(sp)
    800020dc:	e052                	sd	s4,0(sp)
    800020de:	1800                	addi	s0,sp,48
    800020e0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020e2:	00010497          	auipc	s1,0x10
    800020e6:	5ee48493          	addi	s1,s1,1518 # 800126d0 <proc>
      pp->parent = initproc;
    800020ea:	00008a17          	auipc	s4,0x8
    800020ee:	f3ea0a13          	addi	s4,s4,-194 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020f2:	0001e997          	auipc	s3,0x1e
    800020f6:	3de98993          	addi	s3,s3,990 # 800204d0 <tickslock>
    800020fa:	a029                	j	80002104 <reparent+0x34>
    800020fc:	37848493          	addi	s1,s1,888
    80002100:	01348d63          	beq	s1,s3,8000211a <reparent+0x4a>
    if(pp->parent == p){
    80002104:	7c9c                	ld	a5,56(s1)
    80002106:	ff279be3          	bne	a5,s2,800020fc <reparent+0x2c>
      pp->parent = initproc;
    8000210a:	000a3503          	ld	a0,0(s4)
    8000210e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002110:	00000097          	auipc	ra,0x0
    80002114:	f4a080e7          	jalr	-182(ra) # 8000205a <wakeup>
    80002118:	b7d5                	j	800020fc <reparent+0x2c>
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6a02                	ld	s4,0(sp)
    80002126:	6145                	addi	sp,sp,48
    80002128:	8082                	ret

000000008000212a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000212a:	7179                	addi	sp,sp,-48
    8000212c:	f406                	sd	ra,40(sp)
    8000212e:	f022                	sd	s0,32(sp)
    80002130:	ec26                	sd	s1,24(sp)
    80002132:	e84a                	sd	s2,16(sp)
    80002134:	e44e                	sd	s3,8(sp)
    80002136:	1800                	addi	s0,sp,48
    80002138:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000213a:	00010497          	auipc	s1,0x10
    8000213e:	59648493          	addi	s1,s1,1430 # 800126d0 <proc>
    80002142:	0001e997          	auipc	s3,0x1e
    80002146:	38e98993          	addi	s3,s3,910 # 800204d0 <tickslock>
    acquire(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a76080e7          	jalr	-1418(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002154:	589c                	lw	a5,48(s1)
    80002156:	01278d63          	beq	a5,s2,80002170 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b1a080e7          	jalr	-1254(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002164:	37848493          	addi	s1,s1,888
    80002168:	ff3491e3          	bne	s1,s3,8000214a <kill+0x20>
  }
  return -1;
    8000216c:	557d                	li	a0,-1
    8000216e:	a829                	j	80002188 <kill+0x5e>
      p->killed = 1;
    80002170:	4785                	li	a5,1
    80002172:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002174:	4c98                	lw	a4,24(s1)
    80002176:	4789                	li	a5,2
    80002178:	00f70f63          	beq	a4,a5,80002196 <kill+0x6c>
      release(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	af8080e7          	jalr	-1288(ra) # 80000c76 <release>
      return 0;
    80002186:	4501                	li	a0,0
}
    80002188:	70a2                	ld	ra,40(sp)
    8000218a:	7402                	ld	s0,32(sp)
    8000218c:	64e2                	ld	s1,24(sp)
    8000218e:	6942                	ld	s2,16(sp)
    80002190:	69a2                	ld	s3,8(sp)
    80002192:	6145                	addi	sp,sp,48
    80002194:	8082                	ret
        p->state = RUNNABLE;
    80002196:	478d                	li	a5,3
    80002198:	cc9c                	sw	a5,24(s1)
    8000219a:	b7cd                	j	8000217c <kill+0x52>

000000008000219c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	84aa                	mv	s1,a0
    800021ae:	892e                	mv	s2,a1
    800021b0:	89b2                	mv	s3,a2
    800021b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	820080e7          	jalr	-2016(ra) # 800019d4 <myproc>
  if(user_dst){
    800021bc:	c08d                	beqz	s1,800021de <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800021be:	86d2                	mv	a3,s4
    800021c0:	864e                	mv	a2,s3
    800021c2:	85ca                	mv	a1,s2
    800021c4:	6928                	ld	a0,80(a0)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	4ce080e7          	jalr	1230(ra) # 80001694 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800021ce:	70a2                	ld	ra,40(sp)
    800021d0:	7402                	ld	s0,32(sp)
    800021d2:	64e2                	ld	s1,24(sp)
    800021d4:	6942                	ld	s2,16(sp)
    800021d6:	69a2                	ld	s3,8(sp)
    800021d8:	6a02                	ld	s4,0(sp)
    800021da:	6145                	addi	sp,sp,48
    800021dc:	8082                	ret
    memmove((char *)dst, src, len);
    800021de:	000a061b          	sext.w	a2,s4
    800021e2:	85ce                	mv	a1,s3
    800021e4:	854a                	mv	a0,s2
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	b34080e7          	jalr	-1228(ra) # 80000d1a <memmove>
    return 0;
    800021ee:	8526                	mv	a0,s1
    800021f0:	bff9                	j	800021ce <either_copyout+0x32>

00000000800021f2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	e052                	sd	s4,0(sp)
    80002200:	1800                	addi	s0,sp,48
    80002202:	892a                	mv	s2,a0
    80002204:	84ae                	mv	s1,a1
    80002206:	89b2                	mv	s3,a2
    80002208:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	7ca080e7          	jalr	1994(ra) # 800019d4 <myproc>
  if(user_src){
    80002212:	c08d                	beqz	s1,80002234 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002214:	86d2                	mv	a3,s4
    80002216:	864e                	mv	a2,s3
    80002218:	85ca                	mv	a1,s2
    8000221a:	6928                	ld	a0,80(a0)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	504080e7          	jalr	1284(ra) # 80001720 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002224:	70a2                	ld	ra,40(sp)
    80002226:	7402                	ld	s0,32(sp)
    80002228:	64e2                	ld	s1,24(sp)
    8000222a:	6942                	ld	s2,16(sp)
    8000222c:	69a2                	ld	s3,8(sp)
    8000222e:	6a02                	ld	s4,0(sp)
    80002230:	6145                	addi	sp,sp,48
    80002232:	8082                	ret
    memmove(dst, (char*)src, len);
    80002234:	000a061b          	sext.w	a2,s4
    80002238:	85ce                	mv	a1,s3
    8000223a:	854a                	mv	a0,s2
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	ade080e7          	jalr	-1314(ra) # 80000d1a <memmove>
    return 0;
    80002244:	8526                	mv	a0,s1
    80002246:	bff9                	j	80002224 <either_copyin+0x32>

0000000080002248 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002248:	715d                	addi	sp,sp,-80
    8000224a:	e486                	sd	ra,72(sp)
    8000224c:	e0a2                	sd	s0,64(sp)
    8000224e:	fc26                	sd	s1,56(sp)
    80002250:	f84a                	sd	s2,48(sp)
    80002252:	f44e                	sd	s3,40(sp)
    80002254:	f052                	sd	s4,32(sp)
    80002256:	ec56                	sd	s5,24(sp)
    80002258:	e85a                	sd	s6,16(sp)
    8000225a:	e45e                	sd	s7,8(sp)
    8000225c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000225e:	00007517          	auipc	a0,0x7
    80002262:	e6a50513          	addi	a0,a0,-406 # 800090c8 <digits+0x88>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	30e080e7          	jalr	782(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	00010497          	auipc	s1,0x10
    80002272:	5ba48493          	addi	s1,s1,1466 # 80012828 <proc+0x158>
    80002276:	0001e917          	auipc	s2,0x1e
    8000227a:	3b290913          	addi	s2,s2,946 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000227e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002280:	00007997          	auipc	s3,0x7
    80002284:	fc898993          	addi	s3,s3,-56 # 80009248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    80002288:	00007a97          	auipc	s5,0x7
    8000228c:	fc8a8a93          	addi	s5,s5,-56 # 80009250 <digits+0x210>
    printf("\n");
    80002290:	00007a17          	auipc	s4,0x7
    80002294:	e38a0a13          	addi	s4,s4,-456 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002298:	00007b97          	auipc	s7,0x7
    8000229c:	2d0b8b93          	addi	s7,s7,720 # 80009568 <states.0>
    800022a0:	a00d                	j	800022c2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800022a2:	ed86a583          	lw	a1,-296(a3) # fed8 <_entry-0x7fff0128>
    800022a6:	8556                	mv	a0,s5
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	2cc080e7          	jalr	716(ra) # 80000574 <printf>
    printf("\n");
    800022b0:	8552                	mv	a0,s4
    800022b2:	ffffe097          	auipc	ra,0xffffe
    800022b6:	2c2080e7          	jalr	706(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ba:	37848493          	addi	s1,s1,888
    800022be:	03248263          	beq	s1,s2,800022e2 <procdump+0x9a>
    if(p->state == UNUSED)
    800022c2:	86a6                	mv	a3,s1
    800022c4:	ec04a783          	lw	a5,-320(s1)
    800022c8:	dbed                	beqz	a5,800022ba <procdump+0x72>
      state = "???";
    800022ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022cc:	fcfb6be3          	bltu	s6,a5,800022a2 <procdump+0x5a>
    800022d0:	02079713          	slli	a4,a5,0x20
    800022d4:	01d75793          	srli	a5,a4,0x1d
    800022d8:	97de                	add	a5,a5,s7
    800022da:	6390                	ld	a2,0(a5)
    800022dc:	f279                	bnez	a2,800022a2 <procdump+0x5a>
      state = "???";
    800022de:	864e                	mv	a2,s3
    800022e0:	b7c9                	j	800022a2 <procdump+0x5a>
  }
}
    800022e2:	60a6                	ld	ra,72(sp)
    800022e4:	6406                	ld	s0,64(sp)
    800022e6:	74e2                	ld	s1,56(sp)
    800022e8:	7942                	ld	s2,48(sp)
    800022ea:	79a2                	ld	s3,40(sp)
    800022ec:	7a02                	ld	s4,32(sp)
    800022ee:	6ae2                	ld	s5,24(sp)
    800022f0:	6b42                	ld	s6,16(sp)
    800022f2:	6ba2                	ld	s7,8(sp)
    800022f4:	6161                	addi	sp,sp,80
    800022f6:	8082                	ret

00000000800022f8 <init_metadata>:

// ADDED Q1 - p->lock must bot be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    800022f8:	1101                	addi	sp,sp,-32
    800022fa:	ec06                	sd	ra,24(sp)
    800022fc:	e822                	sd	s0,16(sp)
    800022fe:	e426                	sd	s1,8(sp)
    80002300:	1000                	addi	s0,sp,32
    80002302:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002304:	16853783          	ld	a5,360(a0)
    80002308:	cf95                	beqz	a5,80002344 <init_metadata+0x4c>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000230a:	17048793          	addi	a5,s1,368
{
    8000230e:	4701                	li	a4,0
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002310:	6605                	lui	a2,0x1
    80002312:	66c1                	lui	a3,0x10
    p->ram_pages[i].va = 0;
    80002314:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002318:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    8000231c:	0007a623          	sw	zero,12(a5)
    
    p->disk_pages[i].va = 0;
    80002320:	1007b023          	sd	zero,256(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    80002324:	10e7a423          	sw	a4,264(a5)
    p->disk_pages[i].used = 0;
    80002328:	1007a623          	sw	zero,268(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000232c:	07c1                	addi	a5,a5,16
    8000232e:	9f31                	addw	a4,a4,a2
    80002330:	fed712e3          	bne	a4,a3,80002314 <init_metadata+0x1c>
  }
  p->scfifo_index = 0; // ADDED Q2
    80002334:	3604a823          	sw	zero,880(s1)
  return 0;
    80002338:	4501                	li	a0,0
}
    8000233a:	60e2                	ld	ra,24(sp)
    8000233c:	6442                	ld	s0,16(sp)
    8000233e:	64a2                	ld	s1,8(sp)
    80002340:	6105                	addi	sp,sp,32
    80002342:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002344:	00002097          	auipc	ra,0x2
    80002348:	5c2080e7          	jalr	1474(ra) # 80004906 <createSwapFile>
    8000234c:	fa055fe3          	bgez	a0,8000230a <init_metadata+0x12>
    return -1;
    80002350:	557d                	li	a0,-1
    80002352:	b7e5                	j	8000233a <init_metadata+0x42>

0000000080002354 <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    80002354:	1101                	addi	sp,sp,-32
    80002356:	ec06                	sd	ra,24(sp)
    80002358:	e822                	sd	s0,16(sp)
    8000235a:	e426                	sd	s1,8(sp)
    8000235c:	1000                	addi	s0,sp,32
    8000235e:	84aa                	mv	s1,a0
    if (removeSwapFile(p) < 0) {
    80002360:	00002097          	auipc	ra,0x2
    80002364:	3fe080e7          	jalr	1022(ra) # 8000475e <removeSwapFile>
    80002368:	02054e63          	bltz	a0,800023a4 <free_metadata+0x50>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    8000236c:	1604b423          	sd	zero,360(s1)

    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002370:	17048793          	addi	a5,s1,368
    80002374:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    80002378:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    8000237c:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    80002380:	0007a623          	sw	zero,12(a5)

      p->disk_pages[i].va = 0;
    80002384:	1007b023          	sd	zero,256(a5)
      p->disk_pages[i].offset = 0;
    80002388:	1007a423          	sw	zero,264(a5)
      p->disk_pages[i].used = 0;
    8000238c:	1007a623          	sw	zero,268(a5)
    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002390:	07c1                	addi	a5,a5,16
    80002392:	fee793e3          	bne	a5,a4,80002378 <free_metadata+0x24>
    }
    p->scfifo_index = 0; // ADDED Q2
    80002396:	3604a823          	sw	zero,880(s1)
}
    8000239a:	60e2                	ld	ra,24(sp)
    8000239c:	6442                	ld	s0,16(sp)
    8000239e:	64a2                	ld	s1,8(sp)
    800023a0:	6105                	addi	sp,sp,32
    800023a2:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    800023a4:	00007517          	auipc	a0,0x7
    800023a8:	ebc50513          	addi	a0,a0,-324 # 80009260 <digits+0x220>
    800023ac:	ffffe097          	auipc	ra,0xffffe
    800023b0:	17e080e7          	jalr	382(ra) # 8000052a <panic>

00000000800023b4 <fork>:
{
    800023b4:	7139                	addi	sp,sp,-64
    800023b6:	fc06                	sd	ra,56(sp)
    800023b8:	f822                	sd	s0,48(sp)
    800023ba:	f426                	sd	s1,40(sp)
    800023bc:	f04a                	sd	s2,32(sp)
    800023be:	ec4e                	sd	s3,24(sp)
    800023c0:	e852                	sd	s4,16(sp)
    800023c2:	e456                	sd	s5,8(sp)
    800023c4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	60e080e7          	jalr	1550(ra) # 800019d4 <myproc>
    800023ce:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	80e080e7          	jalr	-2034(ra) # 80001bde <allocproc>
    800023d8:	1c050663          	beqz	a0,800025a4 <fork+0x1f0>
    800023dc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800023de:	048ab603          	ld	a2,72(s5)
    800023e2:	692c                	ld	a1,80(a0)
    800023e4:	050ab503          	ld	a0,80(s5)
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	1a2080e7          	jalr	418(ra) # 8000158a <uvmcopy>
    800023f0:	04054863          	bltz	a0,80002440 <fork+0x8c>
  np->sz = p->sz;
    800023f4:	048ab783          	ld	a5,72(s5)
    800023f8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800023fc:	058ab683          	ld	a3,88(s5)
    80002400:	87b6                	mv	a5,a3
    80002402:	0589b703          	ld	a4,88(s3)
    80002406:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    8000240a:	0007b803          	ld	a6,0(a5)
    8000240e:	6788                	ld	a0,8(a5)
    80002410:	6b8c                	ld	a1,16(a5)
    80002412:	6f90                	ld	a2,24(a5)
    80002414:	01073023          	sd	a6,0(a4)
    80002418:	e708                	sd	a0,8(a4)
    8000241a:	eb0c                	sd	a1,16(a4)
    8000241c:	ef10                	sd	a2,24(a4)
    8000241e:	02078793          	addi	a5,a5,32
    80002422:	02070713          	addi	a4,a4,32
    80002426:	fed792e3          	bne	a5,a3,8000240a <fork+0x56>
  np->trapframe->a0 = 0;
    8000242a:	0589b783          	ld	a5,88(s3)
    8000242e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002432:	0d0a8493          	addi	s1,s5,208
    80002436:	0d098913          	addi	s2,s3,208
    8000243a:	150a8a13          	addi	s4,s5,336
    8000243e:	a00d                	j	80002460 <fork+0xac>
    freeproc(np);
    80002440:	854e                	mv	a0,s3
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	744080e7          	jalr	1860(ra) # 80001b86 <freeproc>
    release(&np->lock);
    8000244a:	854e                	mv	a0,s3
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	82a080e7          	jalr	-2006(ra) # 80000c76 <release>
    return -1;
    80002454:	54fd                	li	s1,-1
    80002456:	a8f1                	j	80002532 <fork+0x17e>
  for(i = 0; i < NOFILE; i++)
    80002458:	04a1                	addi	s1,s1,8
    8000245a:	0921                	addi	s2,s2,8
    8000245c:	01448b63          	beq	s1,s4,80002472 <fork+0xbe>
    if(p->ofile[i])
    80002460:	6088                	ld	a0,0(s1)
    80002462:	d97d                	beqz	a0,80002458 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002464:	00003097          	auipc	ra,0x3
    80002468:	bfa080e7          	jalr	-1030(ra) # 8000505e <filedup>
    8000246c:	00a93023          	sd	a0,0(s2)
    80002470:	b7e5                	j	80002458 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002472:	150ab503          	ld	a0,336(s5)
    80002476:	00002097          	auipc	ra,0x2
    8000247a:	a48080e7          	jalr	-1464(ra) # 80003ebe <idup>
    8000247e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002482:	4641                	li	a2,16
    80002484:	158a8593          	addi	a1,s5,344
    80002488:	15898513          	addi	a0,s3,344
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	984080e7          	jalr	-1660(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002494:	0309a483          	lw	s1,48(s3)
  if (relevant_metadata_proc(np)) {
    80002498:	fff4871b          	addiw	a4,s1,-1
    8000249c:	4785                	li	a5,1
    8000249e:	0ae7e463          	bltu	a5,a4,80002546 <fork+0x192>
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    800024a2:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    800024a6:	37fd                	addiw	a5,a5,-1
    800024a8:	4705                	li	a4,1
    800024aa:	04f77263          	bgeu	a4,a5,800024ee <fork+0x13a>
    if (copy_swapFile(p, np) < 0) {
    800024ae:	85ce                	mv	a1,s3
    800024b0:	8556                	mv	a0,s5
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	8f0080e7          	jalr	-1808(ra) # 80001da2 <copy_swapFile>
    800024ba:	0c054463          	bltz	a0,80002582 <fork+0x1ce>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    800024be:	10000613          	li	a2,256
    800024c2:	170a8593          	addi	a1,s5,368
    800024c6:	17098513          	addi	a0,s3,368
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	850080e7          	jalr	-1968(ra) # 80000d1a <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    800024d2:	10000613          	li	a2,256
    800024d6:	270a8593          	addi	a1,s5,624
    800024da:	27098513          	addi	a0,s3,624
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	83c080e7          	jalr	-1988(ra) # 80000d1a <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    800024e6:	370aa783          	lw	a5,880(s5)
    800024ea:	36f9a823          	sw	a5,880(s3)
  release(&np->lock);
    800024ee:	854e                	mv	a0,s3
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	786080e7          	jalr	1926(ra) # 80000c76 <release>
  acquire(&wait_lock);
    800024f8:	00010917          	auipc	s2,0x10
    800024fc:	dc090913          	addi	s2,s2,-576 # 800122b8 <wait_lock>
    80002500:	854a                	mv	a0,s2
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	6c0080e7          	jalr	1728(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000250a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000250e:	854a                	mv	a0,s2
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	766080e7          	jalr	1894(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002518:	854e                	mv	a0,s3
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	6a8080e7          	jalr	1704(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002522:	478d                	li	a5,3
    80002524:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002528:	854e                	mv	a0,s3
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	74c080e7          	jalr	1868(ra) # 80000c76 <release>
}
    80002532:	8526                	mv	a0,s1
    80002534:	70e2                	ld	ra,56(sp)
    80002536:	7442                	ld	s0,48(sp)
    80002538:	74a2                	ld	s1,40(sp)
    8000253a:	7902                	ld	s2,32(sp)
    8000253c:	69e2                	ld	s3,24(sp)
    8000253e:	6a42                	ld	s4,16(sp)
    80002540:	6aa2                	ld	s5,8(sp)
    80002542:	6121                	addi	sp,sp,64
    80002544:	8082                	ret
    release(&np->lock);
    80002546:	854e                	mv	a0,s3
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	72e080e7          	jalr	1838(ra) # 80000c76 <release>
    if (init_metadata(np) < 0) {
    80002550:	854e                	mv	a0,s3
    80002552:	00000097          	auipc	ra,0x0
    80002556:	da6080e7          	jalr	-602(ra) # 800022f8 <init_metadata>
    8000255a:	00054863          	bltz	a0,8000256a <fork+0x1b6>
    acquire(&np->lock);
    8000255e:	854e                	mv	a0,s3
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	662080e7          	jalr	1634(ra) # 80000bc2 <acquire>
    80002568:	bf2d                	j	800024a2 <fork+0xee>
      freeproc(np);
    8000256a:	854e                	mv	a0,s3
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	61a080e7          	jalr	1562(ra) # 80001b86 <freeproc>
      release(&np->lock);
    80002574:	854e                	mv	a0,s3
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	700080e7          	jalr	1792(ra) # 80000c76 <release>
      return -1;
    8000257e:	54fd                	li	s1,-1
    80002580:	bf4d                	j	80002532 <fork+0x17e>
      freeproc(np);
    80002582:	854e                	mv	a0,s3
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	602080e7          	jalr	1538(ra) # 80001b86 <freeproc>
      release(&np->lock);
    8000258c:	854e                	mv	a0,s3
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6e8080e7          	jalr	1768(ra) # 80000c76 <release>
      free_metadata(np);
    80002596:	854e                	mv	a0,s3
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	dbc080e7          	jalr	-580(ra) # 80002354 <free_metadata>
      return -1;
    800025a0:	54fd                	li	s1,-1
    800025a2:	bf41                	j	80002532 <fork+0x17e>
    return -1;
    800025a4:	54fd                	li	s1,-1
    800025a6:	b771                	j	80002532 <fork+0x17e>

00000000800025a8 <exit>:
{
    800025a8:	7179                	addi	sp,sp,-48
    800025aa:	f406                	sd	ra,40(sp)
    800025ac:	f022                	sd	s0,32(sp)
    800025ae:	ec26                	sd	s1,24(sp)
    800025b0:	e84a                	sd	s2,16(sp)
    800025b2:	e44e                	sd	s3,8(sp)
    800025b4:	e052                	sd	s4,0(sp)
    800025b6:	1800                	addi	s0,sp,48
    800025b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	41a080e7          	jalr	1050(ra) # 800019d4 <myproc>
    800025c2:	89aa                	mv	s3,a0
  if(p == initproc)
    800025c4:	00008797          	auipc	a5,0x8
    800025c8:	a647b783          	ld	a5,-1436(a5) # 8000a028 <initproc>
    800025cc:	0d050493          	addi	s1,a0,208
    800025d0:	15050913          	addi	s2,a0,336
    800025d4:	02a79363          	bne	a5,a0,800025fa <exit+0x52>
    panic("init exiting");
    800025d8:	00007517          	auipc	a0,0x7
    800025dc:	cb050513          	addi	a0,a0,-848 # 80009288 <digits+0x248>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	f4a080e7          	jalr	-182(ra) # 8000052a <panic>
      fileclose(f);
    800025e8:	00003097          	auipc	ra,0x3
    800025ec:	ac8080e7          	jalr	-1336(ra) # 800050b0 <fileclose>
      p->ofile[fd] = 0;
    800025f0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025f4:	04a1                	addi	s1,s1,8
    800025f6:	01248563          	beq	s1,s2,80002600 <exit+0x58>
    if(p->ofile[fd]){
    800025fa:	6088                	ld	a0,0(s1)
    800025fc:	f575                	bnez	a0,800025e8 <exit+0x40>
    800025fe:	bfdd                	j	800025f4 <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002600:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    80002604:	37fd                	addiw	a5,a5,-1
    80002606:	4705                	li	a4,1
    80002608:	08f76163          	bltu	a4,a5,8000268a <exit+0xe2>
  begin_op();
    8000260c:	00002097          	auipc	ra,0x2
    80002610:	5d8080e7          	jalr	1496(ra) # 80004be4 <begin_op>
  iput(p->cwd);
    80002614:	1509b503          	ld	a0,336(s3)
    80002618:	00002097          	auipc	ra,0x2
    8000261c:	a9e080e7          	jalr	-1378(ra) # 800040b6 <iput>
  end_op();
    80002620:	00002097          	auipc	ra,0x2
    80002624:	644080e7          	jalr	1604(ra) # 80004c64 <end_op>
  p->cwd = 0;
    80002628:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000262c:	00010497          	auipc	s1,0x10
    80002630:	c8c48493          	addi	s1,s1,-884 # 800122b8 <wait_lock>
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	58c080e7          	jalr	1420(ra) # 80000bc2 <acquire>
  reparent(p);
    8000263e:	854e                	mv	a0,s3
    80002640:	00000097          	auipc	ra,0x0
    80002644:	a90080e7          	jalr	-1392(ra) # 800020d0 <reparent>
  wakeup(p->parent);
    80002648:	0389b503          	ld	a0,56(s3)
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	a0e080e7          	jalr	-1522(ra) # 8000205a <wakeup>
  acquire(&p->lock);
    80002654:	854e                	mv	a0,s3
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	56c080e7          	jalr	1388(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000265e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002662:	4795                	li	a5,5
    80002664:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	60c080e7          	jalr	1548(ra) # 80000c76 <release>
  sched();
    80002672:	00000097          	auipc	ra,0x0
    80002676:	872080e7          	jalr	-1934(ra) # 80001ee4 <sched>
  panic("zombie exit");
    8000267a:	00007517          	auipc	a0,0x7
    8000267e:	c1e50513          	addi	a0,a0,-994 # 80009298 <digits+0x258>
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	ea8080e7          	jalr	-344(ra) # 8000052a <panic>
    free_metadata(p);
    8000268a:	854e                	mv	a0,s3
    8000268c:	00000097          	auipc	ra,0x0
    80002690:	cc8080e7          	jalr	-824(ra) # 80002354 <free_metadata>
    80002694:	bfa5                	j	8000260c <exit+0x64>

0000000080002696 <wait>:
{
    80002696:	715d                	addi	sp,sp,-80
    80002698:	e486                	sd	ra,72(sp)
    8000269a:	e0a2                	sd	s0,64(sp)
    8000269c:	fc26                	sd	s1,56(sp)
    8000269e:	f84a                	sd	s2,48(sp)
    800026a0:	f44e                	sd	s3,40(sp)
    800026a2:	f052                	sd	s4,32(sp)
    800026a4:	ec56                	sd	s5,24(sp)
    800026a6:	e85a                	sd	s6,16(sp)
    800026a8:	e45e                	sd	s7,8(sp)
    800026aa:	e062                	sd	s8,0(sp)
    800026ac:	0880                	addi	s0,sp,80
    800026ae:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	324080e7          	jalr	804(ra) # 800019d4 <myproc>
    800026b8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026ba:	00010517          	auipc	a0,0x10
    800026be:	bfe50513          	addi	a0,a0,-1026 # 800122b8 <wait_lock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	500080e7          	jalr	1280(ra) # 80000bc2 <acquire>
    havekids = 0;
    800026ca:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026cc:	4a15                	li	s4,5
        havekids = 1;
    800026ce:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800026d0:	0001e997          	auipc	s3,0x1e
    800026d4:	e0098993          	addi	s3,s3,-512 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026d8:	00010c17          	auipc	s8,0x10
    800026dc:	be0c0c13          	addi	s8,s8,-1056 # 800122b8 <wait_lock>
    havekids = 0;
    800026e0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026e2:	00010497          	auipc	s1,0x10
    800026e6:	fee48493          	addi	s1,s1,-18 # 800126d0 <proc>
    800026ea:	a059                	j	80002770 <wait+0xda>
          pid = np->pid;
    800026ec:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026f0:	000b0e63          	beqz	s6,8000270c <wait+0x76>
    800026f4:	4691                	li	a3,4
    800026f6:	02c48613          	addi	a2,s1,44
    800026fa:	85da                	mv	a1,s6
    800026fc:	05093503          	ld	a0,80(s2)
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	f94080e7          	jalr	-108(ra) # 80001694 <copyout>
    80002708:	02054b63          	bltz	a0,8000273e <wait+0xa8>
          freeproc(np);
    8000270c:	8526                	mv	a0,s1
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	478080e7          	jalr	1144(ra) # 80001b86 <freeproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002716:	03092783          	lw	a5,48(s2)
         if (relevant_metadata_proc(p)) {
    8000271a:	37fd                	addiw	a5,a5,-1
    8000271c:	4705                	li	a4,1
    8000271e:	02f76f63          	bltu	a4,a5,8000275c <wait+0xc6>
          release(&np->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	552080e7          	jalr	1362(ra) # 80000c76 <release>
          release(&wait_lock);
    8000272c:	00010517          	auipc	a0,0x10
    80002730:	b8c50513          	addi	a0,a0,-1140 # 800122b8 <wait_lock>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	542080e7          	jalr	1346(ra) # 80000c76 <release>
          return pid;
    8000273c:	a88d                	j	800027ae <wait+0x118>
            release(&np->lock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	536080e7          	jalr	1334(ra) # 80000c76 <release>
            release(&wait_lock);
    80002748:	00010517          	auipc	a0,0x10
    8000274c:	b7050513          	addi	a0,a0,-1168 # 800122b8 <wait_lock>
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	526080e7          	jalr	1318(ra) # 80000c76 <release>
            return -1;
    80002758:	59fd                	li	s3,-1
    8000275a:	a891                	j	800027ae <wait+0x118>
           free_metadata(np);
    8000275c:	8526                	mv	a0,s1
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	bf6080e7          	jalr	-1034(ra) # 80002354 <free_metadata>
    80002766:	bf75                	j	80002722 <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    80002768:	37848493          	addi	s1,s1,888
    8000276c:	03348463          	beq	s1,s3,80002794 <wait+0xfe>
      if(np->parent == p){
    80002770:	7c9c                	ld	a5,56(s1)
    80002772:	ff279be3          	bne	a5,s2,80002768 <wait+0xd2>
        acquire(&np->lock);
    80002776:	8526                	mv	a0,s1
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	44a080e7          	jalr	1098(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002780:	4c9c                	lw	a5,24(s1)
    80002782:	f74785e3          	beq	a5,s4,800026ec <wait+0x56>
        release(&np->lock);
    80002786:	8526                	mv	a0,s1
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	4ee080e7          	jalr	1262(ra) # 80000c76 <release>
        havekids = 1;
    80002790:	8756                	mv	a4,s5
    80002792:	bfd9                	j	80002768 <wait+0xd2>
    if(!havekids || p->killed){
    80002794:	c701                	beqz	a4,8000279c <wait+0x106>
    80002796:	02892783          	lw	a5,40(s2)
    8000279a:	c79d                	beqz	a5,800027c8 <wait+0x132>
      release(&wait_lock);
    8000279c:	00010517          	auipc	a0,0x10
    800027a0:	b1c50513          	addi	a0,a0,-1252 # 800122b8 <wait_lock>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4d2080e7          	jalr	1234(ra) # 80000c76 <release>
      return -1;
    800027ac:	59fd                	li	s3,-1
}
    800027ae:	854e                	mv	a0,s3
    800027b0:	60a6                	ld	ra,72(sp)
    800027b2:	6406                	ld	s0,64(sp)
    800027b4:	74e2                	ld	s1,56(sp)
    800027b6:	7942                	ld	s2,48(sp)
    800027b8:	79a2                	ld	s3,40(sp)
    800027ba:	7a02                	ld	s4,32(sp)
    800027bc:	6ae2                	ld	s5,24(sp)
    800027be:	6b42                	ld	s6,16(sp)
    800027c0:	6ba2                	ld	s7,8(sp)
    800027c2:	6c02                	ld	s8,0(sp)
    800027c4:	6161                	addi	sp,sp,80
    800027c6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027c8:	85e2                	mv	a1,s8
    800027ca:	854a                	mv	a0,s2
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	82a080e7          	jalr	-2006(ra) # 80001ff6 <sleep>
    havekids = 0;
    800027d4:	b731                	j	800026e0 <wait+0x4a>

00000000800027d6 <get_free_page_in_disk>:
{
    800027d6:	1141                	addi	sp,sp,-16
    800027d8:	e406                	sd	ra,8(sp)
    800027da:	e022                	sd	s0,0(sp)
    800027dc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1f6080e7          	jalr	502(ra) # 800019d4 <myproc>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    800027e6:	27050793          	addi	a5,a0,624
  int index = 0;
    800027ea:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    800027ec:	46c1                	li	a3,16
    if (!disk_pg->used) {
    800027ee:	47d8                	lw	a4,12(a5)
    800027f0:	c711                	beqz	a4,800027fc <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    800027f2:	07c1                	addi	a5,a5,16
    800027f4:	2505                	addiw	a0,a0,1
    800027f6:	fed51ce3          	bne	a0,a3,800027ee <get_free_page_in_disk+0x18>
  return -1;
    800027fa:	557d                	li	a0,-1
}
    800027fc:	60a2                	ld	ra,8(sp)
    800027fe:	6402                	ld	s0,0(sp)
    80002800:	0141                	addi	sp,sp,16
    80002802:	8082                	ret

0000000080002804 <swapout>:
{
    80002804:	7139                	addi	sp,sp,-64
    80002806:	fc06                	sd	ra,56(sp)
    80002808:	f822                	sd	s0,48(sp)
    8000280a:	f426                	sd	s1,40(sp)
    8000280c:	f04a                	sd	s2,32(sp)
    8000280e:	ec4e                	sd	s3,24(sp)
    80002810:	e852                	sd	s4,16(sp)
    80002812:	e456                	sd	s5,8(sp)
    80002814:	0080                	addi	s0,sp,64
    80002816:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	1bc080e7          	jalr	444(ra) # 800019d4 <myproc>
  if (ram_pg_index < 0 || ram_pg_index > MAX_PSYC_PAGES) {
    80002820:	0004871b          	sext.w	a4,s1
    80002824:	47c1                	li	a5,16
    80002826:	0ae7e363          	bltu	a5,a4,800028cc <swapout+0xc8>
    8000282a:	8a2a                	mv	s4,a0
  if (!ram_pg_to_swap->used) {
    8000282c:	0492                	slli	s1,s1,0x4
    8000282e:	94aa                	add	s1,s1,a0
    80002830:	17c4a783          	lw	a5,380(s1)
    80002834:	c7c5                	beqz	a5,800028dc <swapout+0xd8>
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    80002836:	4601                	li	a2,0
    80002838:	1704b583          	ld	a1,368(s1)
    8000283c:	6928                	ld	a0,80(a0)
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	768080e7          	jalr	1896(ra) # 80000fa6 <walk>
    80002846:	89aa                	mv	s3,a0
    80002848:	c155                	beqz	a0,800028ec <swapout+0xe8>
  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    8000284a:	611c                	ld	a5,0(a0)
    8000284c:	2017f793          	andi	a5,a5,513
    80002850:	4705                	li	a4,1
    80002852:	0ae79563          	bne	a5,a4,800028fc <swapout+0xf8>
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	f80080e7          	jalr	-128(ra) # 800027d6 <get_free_page_in_disk>
    8000285e:	0a054763          	bltz	a0,8000290c <swapout+0x108>
  uint64 pa = PTE2PA(*pte);
    80002862:	0009ba83          	ld	s5,0(s3)
    80002866:	00aada93          	srli	s5,s5,0xa
    8000286a:	0ab2                	slli	s5,s5,0xc
    8000286c:	00451913          	slli	s2,a0,0x4
    80002870:	9952                	add	s2,s2,s4
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    80002872:	6685                	lui	a3,0x1
    80002874:	27892603          	lw	a2,632(s2)
    80002878:	85d6                	mv	a1,s5
    8000287a:	8552                	mv	a0,s4
    8000287c:	00002097          	auipc	ra,0x2
    80002880:	13a080e7          	jalr	314(ra) # 800049b6 <writeToSwapFile>
    80002884:	08054c63          	bltz	a0,8000291c <swapout+0x118>
  disk_pg_to_store->used = 1;
    80002888:	4785                	li	a5,1
    8000288a:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    8000288e:	1704b783          	ld	a5,368(s1)
    80002892:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    80002896:	8556                	mv	a0,s5
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	13e080e7          	jalr	318(ra) # 800009d6 <kfree>
  ram_pg_to_swap->va = 0;
    800028a0:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    800028a4:	1604ae23          	sw	zero,380(s1)
  *pte = *pte & ~PTE_V;
    800028a8:	0009b783          	ld	a5,0(s3)
    800028ac:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    800028ae:	2007e793          	ori	a5,a5,512
    800028b2:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    800028b6:	12000073          	sfence.vma
}
    800028ba:	70e2                	ld	ra,56(sp)
    800028bc:	7442                	ld	s0,48(sp)
    800028be:	74a2                	ld	s1,40(sp)
    800028c0:	7902                	ld	s2,32(sp)
    800028c2:	69e2                	ld	s3,24(sp)
    800028c4:	6a42                	ld	s4,16(sp)
    800028c6:	6aa2                	ld	s5,8(sp)
    800028c8:	6121                	addi	sp,sp,64
    800028ca:	8082                	ret
    panic("swapout: ram page index out of bounds");
    800028cc:	00007517          	auipc	a0,0x7
    800028d0:	9dc50513          	addi	a0,a0,-1572 # 800092a8 <digits+0x268>
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	c56080e7          	jalr	-938(ra) # 8000052a <panic>
    panic("swapout: page unused");
    800028dc:	00007517          	auipc	a0,0x7
    800028e0:	9f450513          	addi	a0,a0,-1548 # 800092d0 <digits+0x290>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c46080e7          	jalr	-954(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    800028ec:	00007517          	auipc	a0,0x7
    800028f0:	9fc50513          	addi	a0,a0,-1540 # 800092e8 <digits+0x2a8>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c36080e7          	jalr	-970(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    800028fc:	00007517          	auipc	a0,0x7
    80002900:	a0450513          	addi	a0,a0,-1532 # 80009300 <digits+0x2c0>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c26080e7          	jalr	-986(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    8000290c:	00007517          	auipc	a0,0x7
    80002910:	a1450513          	addi	a0,a0,-1516 # 80009320 <digits+0x2e0>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c16080e7          	jalr	-1002(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    8000291c:	00007517          	auipc	a0,0x7
    80002920:	a1c50513          	addi	a0,a0,-1508 # 80009338 <digits+0x2f8>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c06080e7          	jalr	-1018(ra) # 8000052a <panic>

000000008000292c <swapin>:
{
    8000292c:	7139                	addi	sp,sp,-64
    8000292e:	fc06                	sd	ra,56(sp)
    80002930:	f822                	sd	s0,48(sp)
    80002932:	f426                	sd	s1,40(sp)
    80002934:	f04a                	sd	s2,32(sp)
    80002936:	ec4e                	sd	s3,24(sp)
    80002938:	e852                	sd	s4,16(sp)
    8000293a:	e456                	sd	s5,8(sp)
    8000293c:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index > MAX_PSYC_PAGES) {
    8000293e:	47c1                	li	a5,16
    80002940:	0aa7ed63          	bltu	a5,a0,800029fa <swapin+0xce>
    80002944:	89ae                	mv	s3,a1
    80002946:	892a                	mv	s2,a0
  if (ram_index < 0 || ram_index > MAX_PSYC_PAGES) {
    80002948:	0005879b          	sext.w	a5,a1
    8000294c:	4741                	li	a4,16
    8000294e:	0af76e63          	bltu	a4,a5,80002a0a <swapin+0xde>
  struct proc *p = myproc();
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	082080e7          	jalr	130(ra) # 800019d4 <myproc>
    8000295a:	8aaa                	mv	s5,a0
  if (!disk_pg->used) {
    8000295c:	0912                	slli	s2,s2,0x4
    8000295e:	992a                	add	s2,s2,a0
    80002960:	27c92783          	lw	a5,636(s2)
    80002964:	cbdd                	beqz	a5,80002a1a <swapin+0xee>
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    80002966:	4601                	li	a2,0
    80002968:	27093583          	ld	a1,624(s2)
    8000296c:	6928                	ld	a0,80(a0)
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	638080e7          	jalr	1592(ra) # 80000fa6 <walk>
    80002976:	8a2a                	mv	s4,a0
    80002978:	c94d                	beqz	a0,80002a2a <swapin+0xfe>
  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    8000297a:	611c                	ld	a5,0(a0)
    8000297c:	2017f793          	andi	a5,a5,513
    80002980:	20000713          	li	a4,512
    80002984:	0ae79b63          	bne	a5,a4,80002a3a <swapin+0x10e>
  if (ram_pg->used) {
    80002988:	0992                	slli	s3,s3,0x4
    8000298a:	99d6                	add	s3,s3,s5
    8000298c:	17c9a783          	lw	a5,380(s3)
    80002990:	efcd                	bnez	a5,80002a4a <swapin+0x11e>
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	140080e7          	jalr	320(ra) # 80000ad2 <kalloc>
    8000299a:	84aa                	mv	s1,a0
    8000299c:	cd5d                	beqz	a0,80002a5a <swapin+0x12e>
  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    8000299e:	6685                	lui	a3,0x1
    800029a0:	27892603          	lw	a2,632(s2)
    800029a4:	85aa                	mv	a1,a0
    800029a6:	8556                	mv	a0,s5
    800029a8:	00002097          	auipc	ra,0x2
    800029ac:	032080e7          	jalr	50(ra) # 800049da <readFromSwapFile>
    800029b0:	0a054d63          	bltz	a0,80002a6a <swapin+0x13e>
  ram_pg->used = 1;
    800029b4:	4785                	li	a5,1
    800029b6:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    800029ba:	27093783          	ld	a5,624(s2)
    800029be:	16f9b823          	sd	a5,368(s3)
    ram_pg->age = 0;
    800029c2:	1609ac23          	sw	zero,376(s3)
  disk_pg->va = 0;
    800029c6:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    800029ca:	26092e23          	sw	zero,636(s2)
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    800029ce:	80b1                	srli	s1,s1,0xc
    800029d0:	04aa                	slli	s1,s1,0xa
    800029d2:	000a3783          	ld	a5,0(s4)
    800029d6:	1ff7f793          	andi	a5,a5,511
    800029da:	8cdd                	or	s1,s1,a5
    800029dc:	0014e493          	ori	s1,s1,1
    800029e0:	009a3023          	sd	s1,0(s4)
    800029e4:	12000073          	sfence.vma
}
    800029e8:	70e2                	ld	ra,56(sp)
    800029ea:	7442                	ld	s0,48(sp)
    800029ec:	74a2                	ld	s1,40(sp)
    800029ee:	7902                	ld	s2,32(sp)
    800029f0:	69e2                	ld	s3,24(sp)
    800029f2:	6a42                	ld	s4,16(sp)
    800029f4:	6aa2                	ld	s5,8(sp)
    800029f6:	6121                	addi	sp,sp,64
    800029f8:	8082                	ret
    panic("swapin: disk index out of bounds");
    800029fa:	00007517          	auipc	a0,0x7
    800029fe:	96650513          	addi	a0,a0,-1690 # 80009360 <digits+0x320>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b28080e7          	jalr	-1240(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002a0a:	00007517          	auipc	a0,0x7
    80002a0e:	97e50513          	addi	a0,a0,-1666 # 80009388 <digits+0x348>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b18080e7          	jalr	-1256(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002a1a:	00007517          	auipc	a0,0x7
    80002a1e:	98e50513          	addi	a0,a0,-1650 # 800093a8 <digits+0x368>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b08080e7          	jalr	-1272(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002a2a:	00007517          	auipc	a0,0x7
    80002a2e:	99650513          	addi	a0,a0,-1642 # 800093c0 <digits+0x380>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	af8080e7          	jalr	-1288(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002a3a:	00007517          	auipc	a0,0x7
    80002a3e:	99e50513          	addi	a0,a0,-1634 # 800093d8 <digits+0x398>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	ae8080e7          	jalr	-1304(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002a4a:	00007517          	auipc	a0,0x7
    80002a4e:	9ae50513          	addi	a0,a0,-1618 # 800093f8 <digits+0x3b8>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	ad8080e7          	jalr	-1320(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002a5a:	00007517          	auipc	a0,0x7
    80002a5e:	9b650513          	addi	a0,a0,-1610 # 80009410 <digits+0x3d0>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	ac8080e7          	jalr	-1336(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002a6a:	00007517          	auipc	a0,0x7
    80002a6e:	9ce50513          	addi	a0,a0,-1586 # 80009438 <digits+0x3f8>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ab8080e7          	jalr	-1352(ra) # 8000052a <panic>

0000000080002a7a <get_unused_ram_index>:
{
    80002a7a:	1141                	addi	sp,sp,-16
    80002a7c:	e422                	sd	s0,8(sp)
    80002a7e:	0800                	addi	s0,sp,16
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a80:	17c50793          	addi	a5,a0,380
    80002a84:	4501                	li	a0,0
    80002a86:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002a88:	4398                	lw	a4,0(a5)
    80002a8a:	c711                	beqz	a4,80002a96 <get_unused_ram_index+0x1c>
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a8c:	2505                	addiw	a0,a0,1
    80002a8e:	07c1                	addi	a5,a5,16
    80002a90:	fed51ce3          	bne	a0,a3,80002a88 <get_unused_ram_index+0xe>
  return -1;
    80002a94:	557d                	li	a0,-1
}
    80002a96:	6422                	ld	s0,8(sp)
    80002a98:	0141                	addi	sp,sp,16
    80002a9a:	8082                	ret

0000000080002a9c <get_disk_page_index>:
{
    80002a9c:	1141                	addi	sp,sp,-16
    80002a9e:	e422                	sd	s0,8(sp)
    80002aa0:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002aa2:	27050793          	addi	a5,a0,624
    80002aa6:	4501                	li	a0,0
    80002aa8:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002aaa:	6398                	ld	a4,0(a5)
    80002aac:	00b70763          	beq	a4,a1,80002aba <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002ab0:	2505                	addiw	a0,a0,1
    80002ab2:	07c1                	addi	a5,a5,16
    80002ab4:	fed51be3          	bne	a0,a3,80002aaa <get_disk_page_index+0xe>
  return -1;
    80002ab8:	557d                	li	a0,-1
}
    80002aba:	6422                	ld	s0,8(sp)
    80002abc:	0141                	addi	sp,sp,16
    80002abe:	8082                	ret

0000000080002ac0 <remove_page_from_ram>:
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	f08080e7          	jalr	-248(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002ad4:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002ad6:	37fd                	addiw	a5,a5,-1
    80002ad8:	4705                	li	a4,1
    80002ada:	02f77863          	bgeu	a4,a5,80002b0a <remove_page_from_ram+0x4a>
    80002ade:	17050793          	addi	a5,a0,368
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002ae2:	4701                	li	a4,0
    80002ae4:	4641                	li	a2,16
    80002ae6:	a029                	j	80002af0 <remove_page_from_ram+0x30>
    80002ae8:	2705                	addiw	a4,a4,1
    80002aea:	07c1                	addi	a5,a5,16
    80002aec:	02c70463          	beq	a4,a2,80002b14 <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002af0:	6394                	ld	a3,0(a5)
    80002af2:	fe969be3          	bne	a3,s1,80002ae8 <remove_page_from_ram+0x28>
    80002af6:	47d4                	lw	a3,12(a5)
    80002af8:	dae5                	beqz	a3,80002ae8 <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002afa:	0712                	slli	a4,a4,0x4
    80002afc:	972a                	add	a4,a4,a0
    80002afe:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002b02:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002b06:	16072c23          	sw	zero,376(a4)
}
    80002b0a:	60e2                	ld	ra,24(sp)
    80002b0c:	6442                	ld	s0,16(sp)
    80002b0e:	64a2                	ld	s1,8(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret
  panic("remove_page_from_ram failed");
    80002b14:	00007517          	auipc	a0,0x7
    80002b18:	94450513          	addi	a0,a0,-1724 # 80009458 <digits+0x418>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a0e080e7          	jalr	-1522(ra) # 8000052a <panic>

0000000080002b24 <nfua>:
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e406                	sd	ra,8(sp)
    80002b28:	e022                	sd	s0,0(sp)
    80002b2a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	ea8080e7          	jalr	-344(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b34:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002b38:	567d                	li	a2,-1
  int min_index = 0;
    80002b3a:	4501                	li	a0,0
  int i = 0;
    80002b3c:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b3e:	45c1                	li	a1,16
    80002b40:	a029                	j	80002b4a <nfua+0x26>
    80002b42:	0741                	addi	a4,a4,16
    80002b44:	2785                	addiw	a5,a5,1
    80002b46:	00b78863          	beq	a5,a1,80002b56 <nfua+0x32>
    if(ram_pg->age < min_age){
    80002b4a:	4714                	lw	a3,8(a4)
    80002b4c:	fec6fbe3          	bgeu	a3,a2,80002b42 <nfua+0x1e>
      min_age = ram_pg->age;
    80002b50:	8636                	mv	a2,a3
    if(ram_pg->age < min_age){
    80002b52:	853e                	mv	a0,a5
    80002b54:	b7fd                	j	80002b42 <nfua+0x1e>
}
    80002b56:	60a2                	ld	ra,8(sp)
    80002b58:	6402                	ld	s0,0(sp)
    80002b5a:	0141                	addi	sp,sp,16
    80002b5c:	8082                	ret

0000000080002b5e <count_ones>:
{
    80002b5e:	1141                	addi	sp,sp,-16
    80002b60:	e422                	sd	s0,8(sp)
    80002b62:	0800                	addi	s0,sp,16
  while(num > 0){
    80002b64:	c105                	beqz	a0,80002b84 <count_ones+0x26>
    80002b66:	87aa                	mv	a5,a0
  int count = 0;
    80002b68:	4501                	li	a0,0
  while(num > 0){
    80002b6a:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002b6c:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002b70:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002b72:	0007871b          	sext.w	a4,a5
    80002b76:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002b7a:	fee6e9e3          	bltu	a3,a4,80002b6c <count_ones+0xe>
}
    80002b7e:	6422                	ld	s0,8(sp)
    80002b80:	0141                	addi	sp,sp,16
    80002b82:	8082                	ret
  int count = 0;
    80002b84:	4501                	li	a0,0
    80002b86:	bfe5                	j	80002b7e <count_ones+0x20>

0000000080002b88 <lapa>:
{
    80002b88:	715d                	addi	sp,sp,-80
    80002b8a:	e486                	sd	ra,72(sp)
    80002b8c:	e0a2                	sd	s0,64(sp)
    80002b8e:	fc26                	sd	s1,56(sp)
    80002b90:	f84a                	sd	s2,48(sp)
    80002b92:	f44e                	sd	s3,40(sp)
    80002b94:	f052                	sd	s4,32(sp)
    80002b96:	ec56                	sd	s5,24(sp)
    80002b98:	e85a                	sd	s6,16(sp)
    80002b9a:	e45e                	sd	s7,8(sp)
    80002b9c:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e36080e7          	jalr	-458(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002ba6:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002baa:	5afd                	li	s5,-1
  int min_index = 0;
    80002bac:	4b81                	li	s7,0
  int i = 0;
    80002bae:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bb0:	4b41                	li	s6,16
    80002bb2:	a039                	j	80002bc0 <lapa+0x38>
      min_age = ram_pg->age;
    80002bb4:	8ad2                	mv	s5,s4
    80002bb6:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bb8:	09c1                	addi	s3,s3,16
    80002bba:	2905                	addiw	s2,s2,1
    80002bbc:	03690863          	beq	s2,s6,80002bec <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002bc0:	0089aa03          	lw	s4,8(s3)
    80002bc4:	8552                	mv	a0,s4
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	f98080e7          	jalr	-104(ra) # 80002b5e <count_ones>
    80002bce:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002bd0:	8556                	mv	a0,s5
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	f8c080e7          	jalr	-116(ra) # 80002b5e <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002bda:	fca4cde3          	blt	s1,a0,80002bb4 <lapa+0x2c>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002bde:	fca49de3          	bne	s1,a0,80002bb8 <lapa+0x30>
    80002be2:	fd5a7be3          	bgeu	s4,s5,80002bb8 <lapa+0x30>
      min_age = ram_pg->age;
    80002be6:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002be8:	8bca                	mv	s7,s2
    80002bea:	b7f9                	j	80002bb8 <lapa+0x30>
}
    80002bec:	855e                	mv	a0,s7
    80002bee:	60a6                	ld	ra,72(sp)
    80002bf0:	6406                	ld	s0,64(sp)
    80002bf2:	74e2                	ld	s1,56(sp)
    80002bf4:	7942                	ld	s2,48(sp)
    80002bf6:	79a2                	ld	s3,40(sp)
    80002bf8:	7a02                	ld	s4,32(sp)
    80002bfa:	6ae2                	ld	s5,24(sp)
    80002bfc:	6b42                	ld	s6,16(sp)
    80002bfe:	6ba2                	ld	s7,8(sp)
    80002c00:	6161                	addi	sp,sp,80
    80002c02:	8082                	ret

0000000080002c04 <scfifo>:
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	dc4080e7          	jalr	-572(ra) # 800019d4 <myproc>
    80002c18:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002c1a:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002c1e:	01748793          	addi	a5,s1,23
    80002c22:	0792                	slli	a5,a5,0x4
    80002c24:	97ca                	add	a5,a5,s2
    80002c26:	4601                	li	a2,0
    80002c28:	638c                	ld	a1,0(a5)
    80002c2a:	05093503          	ld	a0,80(s2)
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	378080e7          	jalr	888(ra) # 80000fa6 <walk>
    80002c36:	c10d                	beqz	a0,80002c58 <scfifo+0x54>
    if(*pte & PTE_A){
    80002c38:	611c                	ld	a5,0(a0)
    80002c3a:	0407f713          	andi	a4,a5,64
    80002c3e:	c70d                	beqz	a4,80002c68 <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002c40:	fbf7f793          	andi	a5,a5,-65
    80002c44:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002c46:	2485                	addiw	s1,s1,1
    80002c48:	41f4d79b          	sraiw	a5,s1,0x1f
    80002c4c:	01c7d79b          	srliw	a5,a5,0x1c
    80002c50:	9cbd                	addw	s1,s1,a5
    80002c52:	88bd                	andi	s1,s1,15
    80002c54:	9c9d                	subw	s1,s1,a5
  while(1){
    80002c56:	b7e1                	j	80002c1e <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002c58:	00007517          	auipc	a0,0x7
    80002c5c:	82050513          	addi	a0,a0,-2016 # 80009478 <digits+0x438>
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	8ca080e7          	jalr	-1846(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002c68:	0014879b          	addiw	a5,s1,1
    80002c6c:	41f7d71b          	sraiw	a4,a5,0x1f
    80002c70:	01c7571b          	srliw	a4,a4,0x1c
    80002c74:	9fb9                	addw	a5,a5,a4
    80002c76:	8bbd                	andi	a5,a5,15
    80002c78:	9f99                	subw	a5,a5,a4
    80002c7a:	36f92823          	sw	a5,880(s2)
}
    80002c7e:	8526                	mv	a0,s1
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	64a2                	ld	s1,8(sp)
    80002c86:	6902                	ld	s2,0(sp)
    80002c88:	6105                	addi	sp,sp,32
    80002c8a:	8082                	ret

0000000080002c8c <insert_page_to_ram>:
{
    80002c8c:	7179                	addi	sp,sp,-48
    80002c8e:	f406                	sd	ra,40(sp)
    80002c90:	f022                	sd	s0,32(sp)
    80002c92:	ec26                	sd	s1,24(sp)
    80002c94:	e84a                	sd	s2,16(sp)
    80002c96:	e44e                	sd	s3,8(sp)
    80002c98:	1800                	addi	s0,sp,48
    80002c9a:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d38080e7          	jalr	-712(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002ca4:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002ca6:	37fd                	addiw	a5,a5,-1
    80002ca8:	4705                	li	a4,1
    80002caa:	02f77363          	bgeu	a4,a5,80002cd0 <insert_page_to_ram+0x44>
    80002cae:	84aa                	mv	s1,a0
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	dca080e7          	jalr	-566(ra) # 80002a7a <get_unused_ram_index>
    80002cb8:	892a                	mv	s2,a0
    80002cba:	02054263          	bltz	a0,80002cde <insert_page_to_ram+0x52>
  ram_pg->va = va;
    80002cbe:	0912                	slli	s2,s2,0x4
    80002cc0:	94ca                	add	s1,s1,s2
    80002cc2:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002cc6:	4785                	li	a5,1
    80002cc8:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002ccc:	1604ac23          	sw	zero,376(s1)
}
    80002cd0:	70a2                	ld	ra,40(sp)
    80002cd2:	7402                	ld	s0,32(sp)
    80002cd4:	64e2                	ld	s1,24(sp)
    80002cd6:	6942                	ld	s2,16(sp)
    80002cd8:	69a2                	ld	s3,8(sp)
    80002cda:	6145                	addi	sp,sp,48
    80002cdc:	8082                	ret
    return scfifo();
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	f26080e7          	jalr	-218(ra) # 80002c04 <scfifo>
    80002ce6:	892a                	mv	s2,a0
    swapout(ram_pg_index_to_swap);
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	b1c080e7          	jalr	-1252(ra) # 80002804 <swapout>
    unused_ram_pg_index = ram_pg_index_to_swap;
    80002cf0:	b7f9                	j	80002cbe <insert_page_to_ram+0x32>

0000000080002cf2 <handle_page_fault>:
{
    80002cf2:	7179                	addi	sp,sp,-48
    80002cf4:	f406                	sd	ra,40(sp)
    80002cf6:	f022                	sd	s0,32(sp)
    80002cf8:	ec26                	sd	s1,24(sp)
    80002cfa:	e84a                	sd	s2,16(sp)
    80002cfc:	e44e                	sd	s3,8(sp)
    80002cfe:	1800                	addi	s0,sp,48
    80002d00:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	cd2080e7          	jalr	-814(ra) # 800019d4 <myproc>
    80002d0a:	84aa                	mv	s1,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002d0c:	4601                	li	a2,0
    80002d0e:	85ce                	mv	a1,s3
    80002d10:	6928                	ld	a0,80(a0)
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	294080e7          	jalr	660(ra) # 80000fa6 <walk>
    80002d1a:	c531                	beqz	a0,80002d66 <handle_page_fault+0x74>
  if(*pte & PTE_V){
    80002d1c:	611c                	ld	a5,0(a0)
    80002d1e:	0017f713          	andi	a4,a5,1
    80002d22:	eb31                	bnez	a4,80002d76 <handle_page_fault+0x84>
  if(!(*pte & PTE_PG)) {
    80002d24:	2007f793          	andi	a5,a5,512
    80002d28:	cfb9                	beqz	a5,80002d86 <handle_page_fault+0x94>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	d4e080e7          	jalr	-690(ra) # 80002a7a <get_unused_ram_index>
    80002d34:	892a                	mv	s2,a0
    80002d36:	06054063          	bltz	a0,80002d96 <handle_page_fault+0xa4>
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002d3a:	75fd                	lui	a1,0xfffff
    80002d3c:	00b9f5b3          	and	a1,s3,a1
    80002d40:	8526                	mv	a0,s1
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	d5a080e7          	jalr	-678(ra) # 80002a9c <get_disk_page_index>
    80002d4a:	06054063          	bltz	a0,80002daa <handle_page_fault+0xb8>
  swapin(target_idx, unused_ram_pg_index);
    80002d4e:	85ca                	mv	a1,s2
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	bdc080e7          	jalr	-1060(ra) # 8000292c <swapin>
}
    80002d58:	70a2                	ld	ra,40(sp)
    80002d5a:	7402                	ld	s0,32(sp)
    80002d5c:	64e2                	ld	s1,24(sp)
    80002d5e:	6942                	ld	s2,16(sp)
    80002d60:	69a2                	ld	s3,8(sp)
    80002d62:	6145                	addi	sp,sp,48
    80002d64:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002d66:	00006517          	auipc	a0,0x6
    80002d6a:	72a50513          	addi	a0,a0,1834 # 80009490 <digits+0x450>
    80002d6e:	ffffd097          	auipc	ra,0xffffd
    80002d72:	7bc080e7          	jalr	1980(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002d76:	00006517          	auipc	a0,0x6
    80002d7a:	73a50513          	addi	a0,a0,1850 # 800094b0 <digits+0x470>
    80002d7e:	ffffd097          	auipc	ra,0xffffd
    80002d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002d86:	00006517          	auipc	a0,0x6
    80002d8a:	74a50513          	addi	a0,a0,1866 # 800094d0 <digits+0x490>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	79c080e7          	jalr	1948(ra) # 8000052a <panic>
    return scfifo();
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	e6e080e7          	jalr	-402(ra) # 80002c04 <scfifo>
    80002d9e:	892a                	mv	s2,a0
      swapout(ram_pg_index_to_swap); 
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	a64080e7          	jalr	-1436(ra) # 80002804 <swapout>
      unused_ram_pg_index = ram_pg_index_to_swap;
    80002da8:	bf49                	j	80002d3a <handle_page_fault+0x48>
    panic("handle_page_fault: get_disk_page_index failed");
    80002daa:	00006517          	auipc	a0,0x6
    80002dae:	74650513          	addi	a0,a0,1862 # 800094f0 <digits+0x4b0>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	778080e7          	jalr	1912(ra) # 8000052a <panic>

0000000080002dba <index_page_to_swap>:
{
    80002dba:	1141                	addi	sp,sp,-16
    80002dbc:	e406                	sd	ra,8(sp)
    80002dbe:	e022                	sd	s0,0(sp)
    80002dc0:	0800                	addi	s0,sp,16
    return scfifo();
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	e42080e7          	jalr	-446(ra) # 80002c04 <scfifo>
}
    80002dca:	60a2                	ld	ra,8(sp)
    80002dcc:	6402                	ld	s0,0(sp)
    80002dce:	0141                	addi	sp,sp,16
    80002dd0:	8082                	ret

0000000080002dd2 <maintain_age>:
void maintain_age(struct proc *p){
    80002dd2:	7179                	addi	sp,sp,-48
    80002dd4:	f406                	sd	ra,40(sp)
    80002dd6:	f022                	sd	s0,32(sp)
    80002dd8:	ec26                	sd	s1,24(sp)
    80002dda:	e84a                	sd	s2,16(sp)
    80002ddc:	e44e                	sd	s3,8(sp)
    80002dde:	e052                	sd	s4,0(sp)
    80002de0:	1800                	addi	s0,sp,48
    80002de2:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002de4:	17050493          	addi	s1,a0,368
    80002de8:	27050993          	addi	s3,a0,624
      ram_pg->age = ram_pg->age | (1 << 31);
    80002dec:	80000a37          	lui	s4,0x80000
    80002df0:	a821                	j	80002e08 <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002df2:	00006517          	auipc	a0,0x6
    80002df6:	72e50513          	addi	a0,a0,1838 # 80009520 <digits+0x4e0>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	730080e7          	jalr	1840(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002e02:	04c1                	addi	s1,s1,16
    80002e04:	02998b63          	beq	s3,s1,80002e3a <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002e08:	4601                	li	a2,0
    80002e0a:	608c                	ld	a1,0(s1)
    80002e0c:	05093503          	ld	a0,80(s2)
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	196080e7          	jalr	406(ra) # 80000fa6 <walk>
    80002e18:	dd69                	beqz	a0,80002df2 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002e1a:	449c                	lw	a5,8(s1)
    80002e1c:	0017d79b          	srliw	a5,a5,0x1
    80002e20:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002e22:	6118                	ld	a4,0(a0)
    80002e24:	04077713          	andi	a4,a4,64
    80002e28:	df69                	beqz	a4,80002e02 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002e2a:	0147e7b3          	or	a5,a5,s4
    80002e2e:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002e30:	611c                	ld	a5,0(a0)
    80002e32:	fbf7f793          	andi	a5,a5,-65
    80002e36:	e11c                	sd	a5,0(a0)
    80002e38:	b7e9                	j	80002e02 <maintain_age+0x30>
}
    80002e3a:	70a2                	ld	ra,40(sp)
    80002e3c:	7402                	ld	s0,32(sp)
    80002e3e:	64e2                	ld	s1,24(sp)
    80002e40:	6942                	ld	s2,16(sp)
    80002e42:	69a2                	ld	s3,8(sp)
    80002e44:	6a02                	ld	s4,0(sp)
    80002e46:	6145                	addi	sp,sp,48
    80002e48:	8082                	ret

0000000080002e4a <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80002e4a:	1141                	addi	sp,sp,-16
    80002e4c:	e422                	sd	s0,8(sp)
    80002e4e:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002e50:	591c                	lw	a5,48(a0)
    80002e52:	37fd                	addiw	a5,a5,-1
    80002e54:	4505                	li	a0,1
    80002e56:	00f53533          	sltu	a0,a0,a5
    80002e5a:	6422                	ld	s0,8(sp)
    80002e5c:	0141                	addi	sp,sp,16
    80002e5e:	8082                	ret

0000000080002e60 <swtch>:
    80002e60:	00153023          	sd	ra,0(a0)
    80002e64:	00253423          	sd	sp,8(a0)
    80002e68:	e900                	sd	s0,16(a0)
    80002e6a:	ed04                	sd	s1,24(a0)
    80002e6c:	03253023          	sd	s2,32(a0)
    80002e70:	03353423          	sd	s3,40(a0)
    80002e74:	03453823          	sd	s4,48(a0)
    80002e78:	03553c23          	sd	s5,56(a0)
    80002e7c:	05653023          	sd	s6,64(a0)
    80002e80:	05753423          	sd	s7,72(a0)
    80002e84:	05853823          	sd	s8,80(a0)
    80002e88:	05953c23          	sd	s9,88(a0)
    80002e8c:	07a53023          	sd	s10,96(a0)
    80002e90:	07b53423          	sd	s11,104(a0)
    80002e94:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002e98:	0085b103          	ld	sp,8(a1)
    80002e9c:	6980                	ld	s0,16(a1)
    80002e9e:	6d84                	ld	s1,24(a1)
    80002ea0:	0205b903          	ld	s2,32(a1)
    80002ea4:	0285b983          	ld	s3,40(a1)
    80002ea8:	0305ba03          	ld	s4,48(a1)
    80002eac:	0385ba83          	ld	s5,56(a1)
    80002eb0:	0405bb03          	ld	s6,64(a1)
    80002eb4:	0485bb83          	ld	s7,72(a1)
    80002eb8:	0505bc03          	ld	s8,80(a1)
    80002ebc:	0585bc83          	ld	s9,88(a1)
    80002ec0:	0605bd03          	ld	s10,96(a1)
    80002ec4:	0685bd83          	ld	s11,104(a1)
    80002ec8:	8082                	ret

0000000080002eca <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002eca:	1141                	addi	sp,sp,-16
    80002ecc:	e406                	sd	ra,8(sp)
    80002ece:	e022                	sd	s0,0(sp)
    80002ed0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ed2:	00006597          	auipc	a1,0x6
    80002ed6:	6c658593          	addi	a1,a1,1734 # 80009598 <states.0+0x30>
    80002eda:	0001d517          	auipc	a0,0x1d
    80002ede:	5f650513          	addi	a0,a0,1526 # 800204d0 <tickslock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	c50080e7          	jalr	-944(ra) # 80000b32 <initlock>
}
    80002eea:	60a2                	ld	ra,8(sp)
    80002eec:	6402                	ld	s0,0(sp)
    80002eee:	0141                	addi	sp,sp,16
    80002ef0:	8082                	ret

0000000080002ef2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ef2:	1141                	addi	sp,sp,-16
    80002ef4:	e422                	sd	s0,8(sp)
    80002ef6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ef8:	00004797          	auipc	a5,0x4
    80002efc:	ac878793          	addi	a5,a5,-1336 # 800069c0 <kernelvec>
    80002f00:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f04:	6422                	ld	s0,8(sp)
    80002f06:	0141                	addi	sp,sp,16
    80002f08:	8082                	ret

0000000080002f0a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f0a:	1141                	addi	sp,sp,-16
    80002f0c:	e406                	sd	ra,8(sp)
    80002f0e:	e022                	sd	s0,0(sp)
    80002f10:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	ac2080e7          	jalr	-1342(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f20:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f24:	00005617          	auipc	a2,0x5
    80002f28:	0dc60613          	addi	a2,a2,220 # 80008000 <_trampoline>
    80002f2c:	00005697          	auipc	a3,0x5
    80002f30:	0d468693          	addi	a3,a3,212 # 80008000 <_trampoline>
    80002f34:	8e91                	sub	a3,a3,a2
    80002f36:	040007b7          	lui	a5,0x4000
    80002f3a:	17fd                	addi	a5,a5,-1
    80002f3c:	07b2                	slli	a5,a5,0xc
    80002f3e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f40:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f44:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f46:	180026f3          	csrr	a3,satp
    80002f4a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f4c:	6d38                	ld	a4,88(a0)
    80002f4e:	6134                	ld	a3,64(a0)
    80002f50:	6585                	lui	a1,0x1
    80002f52:	96ae                	add	a3,a3,a1
    80002f54:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f56:	6d38                	ld	a4,88(a0)
    80002f58:	00000697          	auipc	a3,0x0
    80002f5c:	13868693          	addi	a3,a3,312 # 80003090 <usertrap>
    80002f60:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f62:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f64:	8692                	mv	a3,tp
    80002f66:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f68:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f6c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f70:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f74:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f78:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f7a:	6f18                	ld	a4,24(a4)
    80002f7c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f80:	692c                	ld	a1,80(a0)
    80002f82:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f84:	00005717          	auipc	a4,0x5
    80002f88:	10c70713          	addi	a4,a4,268 # 80008090 <userret>
    80002f8c:	8f11                	sub	a4,a4,a2
    80002f8e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f90:	577d                	li	a4,-1
    80002f92:	177e                	slli	a4,a4,0x3f
    80002f94:	8dd9                	or	a1,a1,a4
    80002f96:	02000537          	lui	a0,0x2000
    80002f9a:	157d                	addi	a0,a0,-1
    80002f9c:	0536                	slli	a0,a0,0xd
    80002f9e:	9782                	jalr	a5
}
    80002fa0:	60a2                	ld	ra,8(sp)
    80002fa2:	6402                	ld	s0,0(sp)
    80002fa4:	0141                	addi	sp,sp,16
    80002fa6:	8082                	ret

0000000080002fa8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	e426                	sd	s1,8(sp)
    80002fb0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002fb2:	0001d497          	auipc	s1,0x1d
    80002fb6:	51e48493          	addi	s1,s1,1310 # 800204d0 <tickslock>
    80002fba:	8526                	mv	a0,s1
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	c06080e7          	jalr	-1018(ra) # 80000bc2 <acquire>
  ticks++;
    80002fc4:	00007517          	auipc	a0,0x7
    80002fc8:	06c50513          	addi	a0,a0,108 # 8000a030 <ticks>
    80002fcc:	411c                	lw	a5,0(a0)
    80002fce:	2785                	addiw	a5,a5,1
    80002fd0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	088080e7          	jalr	136(ra) # 8000205a <wakeup>
  release(&tickslock);
    80002fda:	8526                	mv	a0,s1
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c9a080e7          	jalr	-870(ra) # 80000c76 <release>
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6105                	addi	sp,sp,32
    80002fec:	8082                	ret

0000000080002fee <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002fee:	1101                	addi	sp,sp,-32
    80002ff0:	ec06                	sd	ra,24(sp)
    80002ff2:	e822                	sd	s0,16(sp)
    80002ff4:	e426                	sd	s1,8(sp)
    80002ff6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ff8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ffc:	00074d63          	bltz	a4,80003016 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003000:	57fd                	li	a5,-1
    80003002:	17fe                	slli	a5,a5,0x3f
    80003004:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003006:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003008:	06f70363          	beq	a4,a5,8000306e <devintr+0x80>
  }
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret
     (scause & 0xff) == 9){
    80003016:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000301a:	46a5                	li	a3,9
    8000301c:	fed792e3          	bne	a5,a3,80003000 <devintr+0x12>
    int irq = plic_claim();
    80003020:	00004097          	auipc	ra,0x4
    80003024:	aa8080e7          	jalr	-1368(ra) # 80006ac8 <plic_claim>
    80003028:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000302a:	47a9                	li	a5,10
    8000302c:	02f50763          	beq	a0,a5,8000305a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003030:	4785                	li	a5,1
    80003032:	02f50963          	beq	a0,a5,80003064 <devintr+0x76>
    return 1;
    80003036:	4505                	li	a0,1
    } else if(irq){
    80003038:	d8f1                	beqz	s1,8000300c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000303a:	85a6                	mv	a1,s1
    8000303c:	00006517          	auipc	a0,0x6
    80003040:	56450513          	addi	a0,a0,1380 # 800095a0 <states.0+0x38>
    80003044:	ffffd097          	auipc	ra,0xffffd
    80003048:	530080e7          	jalr	1328(ra) # 80000574 <printf>
      plic_complete(irq);
    8000304c:	8526                	mv	a0,s1
    8000304e:	00004097          	auipc	ra,0x4
    80003052:	a9e080e7          	jalr	-1378(ra) # 80006aec <plic_complete>
    return 1;
    80003056:	4505                	li	a0,1
    80003058:	bf55                	j	8000300c <devintr+0x1e>
      uartintr();
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	92c080e7          	jalr	-1748(ra) # 80000986 <uartintr>
    80003062:	b7ed                	j	8000304c <devintr+0x5e>
      virtio_disk_intr();
    80003064:	00004097          	auipc	ra,0x4
    80003068:	f1a080e7          	jalr	-230(ra) # 80006f7e <virtio_disk_intr>
    8000306c:	b7c5                	j	8000304c <devintr+0x5e>
    if(cpuid() == 0){
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	93a080e7          	jalr	-1734(ra) # 800019a8 <cpuid>
    80003076:	c901                	beqz	a0,80003086 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003078:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000307c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000307e:	14479073          	csrw	sip,a5
    return 2;
    80003082:	4509                	li	a0,2
    80003084:	b761                	j	8000300c <devintr+0x1e>
      clockintr();
    80003086:	00000097          	auipc	ra,0x0
    8000308a:	f22080e7          	jalr	-222(ra) # 80002fa8 <clockintr>
    8000308e:	b7ed                	j	80003078 <devintr+0x8a>

0000000080003090 <usertrap>:
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	e04a                	sd	s2,0(sp)
    8000309a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000309c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030a0:	1007f793          	andi	a5,a5,256
    800030a4:	e3ad                	bnez	a5,80003106 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030a6:	00004797          	auipc	a5,0x4
    800030aa:	91a78793          	addi	a5,a5,-1766 # 800069c0 <kernelvec>
    800030ae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	922080e7          	jalr	-1758(ra) # 800019d4 <myproc>
    800030ba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030bc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030be:	14102773          	csrr	a4,sepc
    800030c2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030c4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030c8:	47a1                	li	a5,8
    800030ca:	04f71c63          	bne	a4,a5,80003122 <usertrap+0x92>
    if(p->killed)
    800030ce:	551c                	lw	a5,40(a0)
    800030d0:	e3b9                	bnez	a5,80003116 <usertrap+0x86>
    p->trapframe->epc += 4;
    800030d2:	6cb8                	ld	a4,88(s1)
    800030d4:	6f1c                	ld	a5,24(a4)
    800030d6:	0791                	addi	a5,a5,4
    800030d8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030de:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030e2:	10079073          	csrw	sstatus,a5
    syscall();
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	318080e7          	jalr	792(ra) # 800033fe <syscall>
  if(p->killed)
    800030ee:	549c                	lw	a5,40(s1)
    800030f0:	ebc5                	bnez	a5,800031a0 <usertrap+0x110>
  usertrapret();
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	e18080e7          	jalr	-488(ra) # 80002f0a <usertrapret>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	64a2                	ld	s1,8(sp)
    80003100:	6902                	ld	s2,0(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret
    panic("usertrap: not from user mode");
    80003106:	00006517          	auipc	a0,0x6
    8000310a:	4ba50513          	addi	a0,a0,1210 # 800095c0 <states.0+0x58>
    8000310e:	ffffd097          	auipc	ra,0xffffd
    80003112:	41c080e7          	jalr	1052(ra) # 8000052a <panic>
      exit(-1);
    80003116:	557d                	li	a0,-1
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	490080e7          	jalr	1168(ra) # 800025a8 <exit>
    80003120:	bf4d                	j	800030d2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003122:	00000097          	auipc	ra,0x0
    80003126:	ecc080e7          	jalr	-308(ra) # 80002fee <devintr>
    8000312a:	892a                	mv	s2,a0
    8000312c:	c501                	beqz	a0,80003134 <usertrap+0xa4>
  if(p->killed)
    8000312e:	549c                	lw	a5,40(s1)
    80003130:	cfb5                	beqz	a5,800031ac <usertrap+0x11c>
    80003132:	a885                	j	800031a2 <usertrap+0x112>
  } else if (relevant_metadata_proc(p) && 
    80003134:	8526                	mv	a0,s1
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	d14080e7          	jalr	-748(ra) # 80002e4a <relevant_metadata_proc>
    8000313e:	c105                	beqz	a0,8000315e <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003140:	14202773          	csrr	a4,scause
    80003144:	47b1                	li	a5,12
    80003146:	04f70663          	beq	a4,a5,80003192 <usertrap+0x102>
    8000314a:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    8000314e:	47b5                	li	a5,13
    80003150:	04f70163          	beq	a4,a5,80003192 <usertrap+0x102>
    80003154:	14202773          	csrr	a4,scause
    80003158:	47bd                	li	a5,15
    8000315a:	02f70c63          	beq	a4,a5,80003192 <usertrap+0x102>
    8000315e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003162:	5890                	lw	a2,48(s1)
    80003164:	00006517          	auipc	a0,0x6
    80003168:	47c50513          	addi	a0,a0,1148 # 800095e0 <states.0+0x78>
    8000316c:	ffffd097          	auipc	ra,0xffffd
    80003170:	408080e7          	jalr	1032(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003174:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003178:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000317c:	00006517          	auipc	a0,0x6
    80003180:	49450513          	addi	a0,a0,1172 # 80009610 <states.0+0xa8>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	3f0080e7          	jalr	1008(ra) # 80000574 <printf>
    p->killed = 1;
    8000318c:	4785                	li	a5,1
    8000318e:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003190:	a809                	j	800031a2 <usertrap+0x112>
    80003192:	14302573          	csrr	a0,stval
      handle_page_fault(va);  
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	b5c080e7          	jalr	-1188(ra) # 80002cf2 <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    8000319e:	bf81                	j	800030ee <usertrap+0x5e>
  if(p->killed)
    800031a0:	4901                	li	s2,0
    exit(-1);
    800031a2:	557d                	li	a0,-1
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	404080e7          	jalr	1028(ra) # 800025a8 <exit>
  if(which_dev == 2)
    800031ac:	4789                	li	a5,2
    800031ae:	f4f912e3          	bne	s2,a5,800030f2 <usertrap+0x62>
    yield();
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	e08080e7          	jalr	-504(ra) # 80001fba <yield>
    800031ba:	bf25                	j	800030f2 <usertrap+0x62>

00000000800031bc <kerneltrap>:
{
    800031bc:	7179                	addi	sp,sp,-48
    800031be:	f406                	sd	ra,40(sp)
    800031c0:	f022                	sd	s0,32(sp)
    800031c2:	ec26                	sd	s1,24(sp)
    800031c4:	e84a                	sd	s2,16(sp)
    800031c6:	e44e                	sd	s3,8(sp)
    800031c8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ca:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031ce:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031d2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031d6:	1004f793          	andi	a5,s1,256
    800031da:	cb85                	beqz	a5,8000320a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031e0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031e2:	ef85                	bnez	a5,8000321a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e0a080e7          	jalr	-502(ra) # 80002fee <devintr>
    800031ec:	cd1d                	beqz	a0,8000322a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031ee:	4789                	li	a5,2
    800031f0:	06f50a63          	beq	a0,a5,80003264 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031f4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031f8:	10049073          	csrw	sstatus,s1
}
    800031fc:	70a2                	ld	ra,40(sp)
    800031fe:	7402                	ld	s0,32(sp)
    80003200:	64e2                	ld	s1,24(sp)
    80003202:	6942                	ld	s2,16(sp)
    80003204:	69a2                	ld	s3,8(sp)
    80003206:	6145                	addi	sp,sp,48
    80003208:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000320a:	00006517          	auipc	a0,0x6
    8000320e:	42650513          	addi	a0,a0,1062 # 80009630 <states.0+0xc8>
    80003212:	ffffd097          	auipc	ra,0xffffd
    80003216:	318080e7          	jalr	792(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000321a:	00006517          	auipc	a0,0x6
    8000321e:	43e50513          	addi	a0,a0,1086 # 80009658 <states.0+0xf0>
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	308080e7          	jalr	776(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000322a:	85ce                	mv	a1,s3
    8000322c:	00006517          	auipc	a0,0x6
    80003230:	44c50513          	addi	a0,a0,1100 # 80009678 <states.0+0x110>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	340080e7          	jalr	832(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000323c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003240:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003244:	00006517          	auipc	a0,0x6
    80003248:	44450513          	addi	a0,a0,1092 # 80009688 <states.0+0x120>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	328080e7          	jalr	808(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003254:	00006517          	auipc	a0,0x6
    80003258:	44c50513          	addi	a0,a0,1100 # 800096a0 <states.0+0x138>
    8000325c:	ffffd097          	auipc	ra,0xffffd
    80003260:	2ce080e7          	jalr	718(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	770080e7          	jalr	1904(ra) # 800019d4 <myproc>
    8000326c:	d541                	beqz	a0,800031f4 <kerneltrap+0x38>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	766080e7          	jalr	1894(ra) # 800019d4 <myproc>
    80003276:	4d18                	lw	a4,24(a0)
    80003278:	4791                	li	a5,4
    8000327a:	f6f71de3          	bne	a4,a5,800031f4 <kerneltrap+0x38>
    yield();
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	d3c080e7          	jalr	-708(ra) # 80001fba <yield>
    80003286:	b7bd                	j	800031f4 <kerneltrap+0x38>

0000000080003288 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	e426                	sd	s1,8(sp)
    80003290:	1000                	addi	s0,sp,32
    80003292:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	740080e7          	jalr	1856(ra) # 800019d4 <myproc>
  switch (n) {
    8000329c:	4795                	li	a5,5
    8000329e:	0497e163          	bltu	a5,s1,800032e0 <argraw+0x58>
    800032a2:	048a                	slli	s1,s1,0x2
    800032a4:	00006717          	auipc	a4,0x6
    800032a8:	43470713          	addi	a4,a4,1076 # 800096d8 <states.0+0x170>
    800032ac:	94ba                	add	s1,s1,a4
    800032ae:	409c                	lw	a5,0(s1)
    800032b0:	97ba                	add	a5,a5,a4
    800032b2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032b4:	6d3c                	ld	a5,88(a0)
    800032b6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032b8:	60e2                	ld	ra,24(sp)
    800032ba:	6442                	ld	s0,16(sp)
    800032bc:	64a2                	ld	s1,8(sp)
    800032be:	6105                	addi	sp,sp,32
    800032c0:	8082                	ret
    return p->trapframe->a1;
    800032c2:	6d3c                	ld	a5,88(a0)
    800032c4:	7fa8                	ld	a0,120(a5)
    800032c6:	bfcd                	j	800032b8 <argraw+0x30>
    return p->trapframe->a2;
    800032c8:	6d3c                	ld	a5,88(a0)
    800032ca:	63c8                	ld	a0,128(a5)
    800032cc:	b7f5                	j	800032b8 <argraw+0x30>
    return p->trapframe->a3;
    800032ce:	6d3c                	ld	a5,88(a0)
    800032d0:	67c8                	ld	a0,136(a5)
    800032d2:	b7dd                	j	800032b8 <argraw+0x30>
    return p->trapframe->a4;
    800032d4:	6d3c                	ld	a5,88(a0)
    800032d6:	6bc8                	ld	a0,144(a5)
    800032d8:	b7c5                	j	800032b8 <argraw+0x30>
    return p->trapframe->a5;
    800032da:	6d3c                	ld	a5,88(a0)
    800032dc:	6fc8                	ld	a0,152(a5)
    800032de:	bfe9                	j	800032b8 <argraw+0x30>
  panic("argraw");
    800032e0:	00006517          	auipc	a0,0x6
    800032e4:	3d050513          	addi	a0,a0,976 # 800096b0 <states.0+0x148>
    800032e8:	ffffd097          	auipc	ra,0xffffd
    800032ec:	242080e7          	jalr	578(ra) # 8000052a <panic>

00000000800032f0 <fetchaddr>:
{
    800032f0:	1101                	addi	sp,sp,-32
    800032f2:	ec06                	sd	ra,24(sp)
    800032f4:	e822                	sd	s0,16(sp)
    800032f6:	e426                	sd	s1,8(sp)
    800032f8:	e04a                	sd	s2,0(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84aa                	mv	s1,a0
    800032fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	6d4080e7          	jalr	1748(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003308:	653c                	ld	a5,72(a0)
    8000330a:	02f4f863          	bgeu	s1,a5,8000333a <fetchaddr+0x4a>
    8000330e:	00848713          	addi	a4,s1,8
    80003312:	02e7e663          	bltu	a5,a4,8000333e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003316:	46a1                	li	a3,8
    80003318:	8626                	mv	a2,s1
    8000331a:	85ca                	mv	a1,s2
    8000331c:	6928                	ld	a0,80(a0)
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	402080e7          	jalr	1026(ra) # 80001720 <copyin>
    80003326:	00a03533          	snez	a0,a0
    8000332a:	40a00533          	neg	a0,a0
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6902                	ld	s2,0(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret
    return -1;
    8000333a:	557d                	li	a0,-1
    8000333c:	bfcd                	j	8000332e <fetchaddr+0x3e>
    8000333e:	557d                	li	a0,-1
    80003340:	b7fd                	j	8000332e <fetchaddr+0x3e>

0000000080003342 <fetchstr>:
{
    80003342:	7179                	addi	sp,sp,-48
    80003344:	f406                	sd	ra,40(sp)
    80003346:	f022                	sd	s0,32(sp)
    80003348:	ec26                	sd	s1,24(sp)
    8000334a:	e84a                	sd	s2,16(sp)
    8000334c:	e44e                	sd	s3,8(sp)
    8000334e:	1800                	addi	s0,sp,48
    80003350:	892a                	mv	s2,a0
    80003352:	84ae                	mv	s1,a1
    80003354:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	67e080e7          	jalr	1662(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000335e:	86ce                	mv	a3,s3
    80003360:	864a                	mv	a2,s2
    80003362:	85a6                	mv	a1,s1
    80003364:	6928                	ld	a0,80(a0)
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	448080e7          	jalr	1096(ra) # 800017ae <copyinstr>
  if(err < 0)
    8000336e:	00054763          	bltz	a0,8000337c <fetchstr+0x3a>
  return strlen(buf);
    80003372:	8526                	mv	a0,s1
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	ace080e7          	jalr	-1330(ra) # 80000e42 <strlen>
}
    8000337c:	70a2                	ld	ra,40(sp)
    8000337e:	7402                	ld	s0,32(sp)
    80003380:	64e2                	ld	s1,24(sp)
    80003382:	6942                	ld	s2,16(sp)
    80003384:	69a2                	ld	s3,8(sp)
    80003386:	6145                	addi	sp,sp,48
    80003388:	8082                	ret

000000008000338a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	e426                	sd	s1,8(sp)
    80003392:	1000                	addi	s0,sp,32
    80003394:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	ef2080e7          	jalr	-270(ra) # 80003288 <argraw>
    8000339e:	c088                	sw	a0,0(s1)
  return 0;
}
    800033a0:	4501                	li	a0,0
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	64a2                	ld	s1,8(sp)
    800033a8:	6105                	addi	sp,sp,32
    800033aa:	8082                	ret

00000000800033ac <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033ac:	1101                	addi	sp,sp,-32
    800033ae:	ec06                	sd	ra,24(sp)
    800033b0:	e822                	sd	s0,16(sp)
    800033b2:	e426                	sd	s1,8(sp)
    800033b4:	1000                	addi	s0,sp,32
    800033b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	ed0080e7          	jalr	-304(ra) # 80003288 <argraw>
    800033c0:	e088                	sd	a0,0(s1)
  return 0;
}
    800033c2:	4501                	li	a0,0
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	64a2                	ld	s1,8(sp)
    800033ca:	6105                	addi	sp,sp,32
    800033cc:	8082                	ret

00000000800033ce <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033ce:	1101                	addi	sp,sp,-32
    800033d0:	ec06                	sd	ra,24(sp)
    800033d2:	e822                	sd	s0,16(sp)
    800033d4:	e426                	sd	s1,8(sp)
    800033d6:	e04a                	sd	s2,0(sp)
    800033d8:	1000                	addi	s0,sp,32
    800033da:	84ae                	mv	s1,a1
    800033dc:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	eaa080e7          	jalr	-342(ra) # 80003288 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033e6:	864a                	mv	a2,s2
    800033e8:	85a6                	mv	a1,s1
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	f58080e7          	jalr	-168(ra) # 80003342 <fetchstr>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	64a2                	ld	s1,8(sp)
    800033f8:	6902                	ld	s2,0(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret

00000000800033fe <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800033fe:	1101                	addi	sp,sp,-32
    80003400:	ec06                	sd	ra,24(sp)
    80003402:	e822                	sd	s0,16(sp)
    80003404:	e426                	sd	s1,8(sp)
    80003406:	e04a                	sd	s2,0(sp)
    80003408:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	5ca080e7          	jalr	1482(ra) # 800019d4 <myproc>
    80003412:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003414:	05853903          	ld	s2,88(a0)
    80003418:	0a893783          	ld	a5,168(s2)
    8000341c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003420:	37fd                	addiw	a5,a5,-1
    80003422:	4751                	li	a4,20
    80003424:	00f76f63          	bltu	a4,a5,80003442 <syscall+0x44>
    80003428:	00369713          	slli	a4,a3,0x3
    8000342c:	00006797          	auipc	a5,0x6
    80003430:	2c478793          	addi	a5,a5,708 # 800096f0 <syscalls>
    80003434:	97ba                	add	a5,a5,a4
    80003436:	639c                	ld	a5,0(a5)
    80003438:	c789                	beqz	a5,80003442 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000343a:	9782                	jalr	a5
    8000343c:	06a93823          	sd	a0,112(s2)
    80003440:	a839                	j	8000345e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003442:	15848613          	addi	a2,s1,344
    80003446:	588c                	lw	a1,48(s1)
    80003448:	00006517          	auipc	a0,0x6
    8000344c:	27050513          	addi	a0,a0,624 # 800096b8 <states.0+0x150>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	124080e7          	jalr	292(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003458:	6cbc                	ld	a5,88(s1)
    8000345a:	577d                	li	a4,-1
    8000345c:	fbb8                	sd	a4,112(a5)
  }
}
    8000345e:	60e2                	ld	ra,24(sp)
    80003460:	6442                	ld	s0,16(sp)
    80003462:	64a2                	ld	s1,8(sp)
    80003464:	6902                	ld	s2,0(sp)
    80003466:	6105                	addi	sp,sp,32
    80003468:	8082                	ret

000000008000346a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000346a:	1101                	addi	sp,sp,-32
    8000346c:	ec06                	sd	ra,24(sp)
    8000346e:	e822                	sd	s0,16(sp)
    80003470:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003472:	fec40593          	addi	a1,s0,-20
    80003476:	4501                	li	a0,0
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	f12080e7          	jalr	-238(ra) # 8000338a <argint>
    return -1;
    80003480:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003482:	00054963          	bltz	a0,80003494 <sys_exit+0x2a>
  exit(n);
    80003486:	fec42503          	lw	a0,-20(s0)
    8000348a:	fffff097          	auipc	ra,0xfffff
    8000348e:	11e080e7          	jalr	286(ra) # 800025a8 <exit>
  return 0;  // not reached
    80003492:	4781                	li	a5,0
}
    80003494:	853e                	mv	a0,a5
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	6105                	addi	sp,sp,32
    8000349c:	8082                	ret

000000008000349e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000349e:	1141                	addi	sp,sp,-16
    800034a0:	e406                	sd	ra,8(sp)
    800034a2:	e022                	sd	s0,0(sp)
    800034a4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034a6:	ffffe097          	auipc	ra,0xffffe
    800034aa:	52e080e7          	jalr	1326(ra) # 800019d4 <myproc>
}
    800034ae:	5908                	lw	a0,48(a0)
    800034b0:	60a2                	ld	ra,8(sp)
    800034b2:	6402                	ld	s0,0(sp)
    800034b4:	0141                	addi	sp,sp,16
    800034b6:	8082                	ret

00000000800034b8 <sys_fork>:

uint64
sys_fork(void)
{
    800034b8:	1141                	addi	sp,sp,-16
    800034ba:	e406                	sd	ra,8(sp)
    800034bc:	e022                	sd	s0,0(sp)
    800034be:	0800                	addi	s0,sp,16
  return fork();
    800034c0:	fffff097          	auipc	ra,0xfffff
    800034c4:	ef4080e7          	jalr	-268(ra) # 800023b4 <fork>
}
    800034c8:	60a2                	ld	ra,8(sp)
    800034ca:	6402                	ld	s0,0(sp)
    800034cc:	0141                	addi	sp,sp,16
    800034ce:	8082                	ret

00000000800034d0 <sys_wait>:

uint64
sys_wait(void)
{
    800034d0:	1101                	addi	sp,sp,-32
    800034d2:	ec06                	sd	ra,24(sp)
    800034d4:	e822                	sd	s0,16(sp)
    800034d6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034d8:	fe840593          	addi	a1,s0,-24
    800034dc:	4501                	li	a0,0
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	ece080e7          	jalr	-306(ra) # 800033ac <argaddr>
    800034e6:	87aa                	mv	a5,a0
    return -1;
    800034e8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800034ea:	0007c863          	bltz	a5,800034fa <sys_wait+0x2a>
  return wait(p);
    800034ee:	fe843503          	ld	a0,-24(s0)
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	1a4080e7          	jalr	420(ra) # 80002696 <wait>
}
    800034fa:	60e2                	ld	ra,24(sp)
    800034fc:	6442                	ld	s0,16(sp)
    800034fe:	6105                	addi	sp,sp,32
    80003500:	8082                	ret

0000000080003502 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000350c:	fdc40593          	addi	a1,s0,-36
    80003510:	4501                	li	a0,0
    80003512:	00000097          	auipc	ra,0x0
    80003516:	e78080e7          	jalr	-392(ra) # 8000338a <argint>
    return -1;
    8000351a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000351c:	00054f63          	bltz	a0,8000353a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	4b4080e7          	jalr	1204(ra) # 800019d4 <myproc>
    80003528:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000352a:	fdc42503          	lw	a0,-36(s0)
    8000352e:	fffff097          	auipc	ra,0xfffff
    80003532:	800080e7          	jalr	-2048(ra) # 80001d2e <growproc>
    80003536:	00054863          	bltz	a0,80003546 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000353a:	8526                	mv	a0,s1
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
    return -1;
    80003546:	54fd                	li	s1,-1
    80003548:	bfcd                	j	8000353a <sys_sbrk+0x38>

000000008000354a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000354a:	7139                	addi	sp,sp,-64
    8000354c:	fc06                	sd	ra,56(sp)
    8000354e:	f822                	sd	s0,48(sp)
    80003550:	f426                	sd	s1,40(sp)
    80003552:	f04a                	sd	s2,32(sp)
    80003554:	ec4e                	sd	s3,24(sp)
    80003556:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003558:	fcc40593          	addi	a1,s0,-52
    8000355c:	4501                	li	a0,0
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	e2c080e7          	jalr	-468(ra) # 8000338a <argint>
    return -1;
    80003566:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003568:	06054563          	bltz	a0,800035d2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000356c:	0001d517          	auipc	a0,0x1d
    80003570:	f6450513          	addi	a0,a0,-156 # 800204d0 <tickslock>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	64e080e7          	jalr	1614(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000357c:	00007917          	auipc	s2,0x7
    80003580:	ab492903          	lw	s2,-1356(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003584:	fcc42783          	lw	a5,-52(s0)
    80003588:	cf85                	beqz	a5,800035c0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000358a:	0001d997          	auipc	s3,0x1d
    8000358e:	f4698993          	addi	s3,s3,-186 # 800204d0 <tickslock>
    80003592:	00007497          	auipc	s1,0x7
    80003596:	a9e48493          	addi	s1,s1,-1378 # 8000a030 <ticks>
    if(myproc()->killed){
    8000359a:	ffffe097          	auipc	ra,0xffffe
    8000359e:	43a080e7          	jalr	1082(ra) # 800019d4 <myproc>
    800035a2:	551c                	lw	a5,40(a0)
    800035a4:	ef9d                	bnez	a5,800035e2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035a6:	85ce                	mv	a1,s3
    800035a8:	8526                	mv	a0,s1
    800035aa:	fffff097          	auipc	ra,0xfffff
    800035ae:	a4c080e7          	jalr	-1460(ra) # 80001ff6 <sleep>
  while(ticks - ticks0 < n){
    800035b2:	409c                	lw	a5,0(s1)
    800035b4:	412787bb          	subw	a5,a5,s2
    800035b8:	fcc42703          	lw	a4,-52(s0)
    800035bc:	fce7efe3          	bltu	a5,a4,8000359a <sys_sleep+0x50>
  }
  release(&tickslock);
    800035c0:	0001d517          	auipc	a0,0x1d
    800035c4:	f1050513          	addi	a0,a0,-240 # 800204d0 <tickslock>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	6ae080e7          	jalr	1710(ra) # 80000c76 <release>
  return 0;
    800035d0:	4781                	li	a5,0
}
    800035d2:	853e                	mv	a0,a5
    800035d4:	70e2                	ld	ra,56(sp)
    800035d6:	7442                	ld	s0,48(sp)
    800035d8:	74a2                	ld	s1,40(sp)
    800035da:	7902                	ld	s2,32(sp)
    800035dc:	69e2                	ld	s3,24(sp)
    800035de:	6121                	addi	sp,sp,64
    800035e0:	8082                	ret
      release(&tickslock);
    800035e2:	0001d517          	auipc	a0,0x1d
    800035e6:	eee50513          	addi	a0,a0,-274 # 800204d0 <tickslock>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	68c080e7          	jalr	1676(ra) # 80000c76 <release>
      return -1;
    800035f2:	57fd                	li	a5,-1
    800035f4:	bff9                	j	800035d2 <sys_sleep+0x88>

00000000800035f6 <sys_kill>:

uint64
sys_kill(void)
{
    800035f6:	1101                	addi	sp,sp,-32
    800035f8:	ec06                	sd	ra,24(sp)
    800035fa:	e822                	sd	s0,16(sp)
    800035fc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800035fe:	fec40593          	addi	a1,s0,-20
    80003602:	4501                	li	a0,0
    80003604:	00000097          	auipc	ra,0x0
    80003608:	d86080e7          	jalr	-634(ra) # 8000338a <argint>
    8000360c:	87aa                	mv	a5,a0
    return -1;
    8000360e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003610:	0007c863          	bltz	a5,80003620 <sys_kill+0x2a>
  return kill(pid);
    80003614:	fec42503          	lw	a0,-20(s0)
    80003618:	fffff097          	auipc	ra,0xfffff
    8000361c:	b12080e7          	jalr	-1262(ra) # 8000212a <kill>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	6105                	addi	sp,sp,32
    80003626:	8082                	ret

0000000080003628 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003628:	1101                	addi	sp,sp,-32
    8000362a:	ec06                	sd	ra,24(sp)
    8000362c:	e822                	sd	s0,16(sp)
    8000362e:	e426                	sd	s1,8(sp)
    80003630:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003632:	0001d517          	auipc	a0,0x1d
    80003636:	e9e50513          	addi	a0,a0,-354 # 800204d0 <tickslock>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	588080e7          	jalr	1416(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003642:	00007497          	auipc	s1,0x7
    80003646:	9ee4a483          	lw	s1,-1554(s1) # 8000a030 <ticks>
  release(&tickslock);
    8000364a:	0001d517          	auipc	a0,0x1d
    8000364e:	e8650513          	addi	a0,a0,-378 # 800204d0 <tickslock>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	624080e7          	jalr	1572(ra) # 80000c76 <release>
  return xticks;
}
    8000365a:	02049513          	slli	a0,s1,0x20
    8000365e:	9101                	srli	a0,a0,0x20
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret

000000008000366a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000366a:	7179                	addi	sp,sp,-48
    8000366c:	f406                	sd	ra,40(sp)
    8000366e:	f022                	sd	s0,32(sp)
    80003670:	ec26                	sd	s1,24(sp)
    80003672:	e84a                	sd	s2,16(sp)
    80003674:	e44e                	sd	s3,8(sp)
    80003676:	e052                	sd	s4,0(sp)
    80003678:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000367a:	00006597          	auipc	a1,0x6
    8000367e:	12658593          	addi	a1,a1,294 # 800097a0 <syscalls+0xb0>
    80003682:	0001d517          	auipc	a0,0x1d
    80003686:	e6650513          	addi	a0,a0,-410 # 800204e8 <bcache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	4a8080e7          	jalr	1192(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003692:	00025797          	auipc	a5,0x25
    80003696:	e5678793          	addi	a5,a5,-426 # 800284e8 <bcache+0x8000>
    8000369a:	00025717          	auipc	a4,0x25
    8000369e:	0b670713          	addi	a4,a4,182 # 80028750 <bcache+0x8268>
    800036a2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036a6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036aa:	0001d497          	auipc	s1,0x1d
    800036ae:	e5648493          	addi	s1,s1,-426 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    800036b2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036b4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036b6:	00006a17          	auipc	s4,0x6
    800036ba:	0f2a0a13          	addi	s4,s4,242 # 800097a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800036be:	2b893783          	ld	a5,696(s2)
    800036c2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036c4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036c8:	85d2                	mv	a1,s4
    800036ca:	01048513          	addi	a0,s1,16
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	7d4080e7          	jalr	2004(ra) # 80004ea2 <initsleeplock>
    bcache.head.next->prev = b;
    800036d6:	2b893783          	ld	a5,696(s2)
    800036da:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036dc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036e0:	45848493          	addi	s1,s1,1112
    800036e4:	fd349de3          	bne	s1,s3,800036be <binit+0x54>
  }
}
    800036e8:	70a2                	ld	ra,40(sp)
    800036ea:	7402                	ld	s0,32(sp)
    800036ec:	64e2                	ld	s1,24(sp)
    800036ee:	6942                	ld	s2,16(sp)
    800036f0:	69a2                	ld	s3,8(sp)
    800036f2:	6a02                	ld	s4,0(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret

00000000800036f8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036f8:	7179                	addi	sp,sp,-48
    800036fa:	f406                	sd	ra,40(sp)
    800036fc:	f022                	sd	s0,32(sp)
    800036fe:	ec26                	sd	s1,24(sp)
    80003700:	e84a                	sd	s2,16(sp)
    80003702:	e44e                	sd	s3,8(sp)
    80003704:	1800                	addi	s0,sp,48
    80003706:	892a                	mv	s2,a0
    80003708:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000370a:	0001d517          	auipc	a0,0x1d
    8000370e:	dde50513          	addi	a0,a0,-546 # 800204e8 <bcache>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	4b0080e7          	jalr	1200(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000371a:	00025497          	auipc	s1,0x25
    8000371e:	0864b483          	ld	s1,134(s1) # 800287a0 <bcache+0x82b8>
    80003722:	00025797          	auipc	a5,0x25
    80003726:	02e78793          	addi	a5,a5,46 # 80028750 <bcache+0x8268>
    8000372a:	02f48f63          	beq	s1,a5,80003768 <bread+0x70>
    8000372e:	873e                	mv	a4,a5
    80003730:	a021                	j	80003738 <bread+0x40>
    80003732:	68a4                	ld	s1,80(s1)
    80003734:	02e48a63          	beq	s1,a4,80003768 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003738:	449c                	lw	a5,8(s1)
    8000373a:	ff279ce3          	bne	a5,s2,80003732 <bread+0x3a>
    8000373e:	44dc                	lw	a5,12(s1)
    80003740:	ff3799e3          	bne	a5,s3,80003732 <bread+0x3a>
      b->refcnt++;
    80003744:	40bc                	lw	a5,64(s1)
    80003746:	2785                	addiw	a5,a5,1
    80003748:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000374a:	0001d517          	auipc	a0,0x1d
    8000374e:	d9e50513          	addi	a0,a0,-610 # 800204e8 <bcache>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	524080e7          	jalr	1316(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000375a:	01048513          	addi	a0,s1,16
    8000375e:	00001097          	auipc	ra,0x1
    80003762:	77e080e7          	jalr	1918(ra) # 80004edc <acquiresleep>
      return b;
    80003766:	a8b9                	j	800037c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003768:	00025497          	auipc	s1,0x25
    8000376c:	0304b483          	ld	s1,48(s1) # 80028798 <bcache+0x82b0>
    80003770:	00025797          	auipc	a5,0x25
    80003774:	fe078793          	addi	a5,a5,-32 # 80028750 <bcache+0x8268>
    80003778:	00f48863          	beq	s1,a5,80003788 <bread+0x90>
    8000377c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000377e:	40bc                	lw	a5,64(s1)
    80003780:	cf81                	beqz	a5,80003798 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003782:	64a4                	ld	s1,72(s1)
    80003784:	fee49de3          	bne	s1,a4,8000377e <bread+0x86>
  panic("bget: no buffers");
    80003788:	00006517          	auipc	a0,0x6
    8000378c:	02850513          	addi	a0,a0,40 # 800097b0 <syscalls+0xc0>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	d9a080e7          	jalr	-614(ra) # 8000052a <panic>
      b->dev = dev;
    80003798:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000379c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800037a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037a4:	4785                	li	a5,1
    800037a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037a8:	0001d517          	auipc	a0,0x1d
    800037ac:	d4050513          	addi	a0,a0,-704 # 800204e8 <bcache>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	4c6080e7          	jalr	1222(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800037b8:	01048513          	addi	a0,s1,16
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	720080e7          	jalr	1824(ra) # 80004edc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037c4:	409c                	lw	a5,0(s1)
    800037c6:	cb89                	beqz	a5,800037d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037c8:	8526                	mv	a0,s1
    800037ca:	70a2                	ld	ra,40(sp)
    800037cc:	7402                	ld	s0,32(sp)
    800037ce:	64e2                	ld	s1,24(sp)
    800037d0:	6942                	ld	s2,16(sp)
    800037d2:	69a2                	ld	s3,8(sp)
    800037d4:	6145                	addi	sp,sp,48
    800037d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800037d8:	4581                	li	a1,0
    800037da:	8526                	mv	a0,s1
    800037dc:	00003097          	auipc	ra,0x3
    800037e0:	51a080e7          	jalr	1306(ra) # 80006cf6 <virtio_disk_rw>
    b->valid = 1;
    800037e4:	4785                	li	a5,1
    800037e6:	c09c                	sw	a5,0(s1)
  return b;
    800037e8:	b7c5                	j	800037c8 <bread+0xd0>

00000000800037ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	1000                	addi	s0,sp,32
    800037f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037f6:	0541                	addi	a0,a0,16
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	77e080e7          	jalr	1918(ra) # 80004f76 <holdingsleep>
    80003800:	cd01                	beqz	a0,80003818 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003802:	4585                	li	a1,1
    80003804:	8526                	mv	a0,s1
    80003806:	00003097          	auipc	ra,0x3
    8000380a:	4f0080e7          	jalr	1264(ra) # 80006cf6 <virtio_disk_rw>
}
    8000380e:	60e2                	ld	ra,24(sp)
    80003810:	6442                	ld	s0,16(sp)
    80003812:	64a2                	ld	s1,8(sp)
    80003814:	6105                	addi	sp,sp,32
    80003816:	8082                	ret
    panic("bwrite");
    80003818:	00006517          	auipc	a0,0x6
    8000381c:	fb050513          	addi	a0,a0,-80 # 800097c8 <syscalls+0xd8>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	d0a080e7          	jalr	-758(ra) # 8000052a <panic>

0000000080003828 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	e426                	sd	s1,8(sp)
    80003830:	e04a                	sd	s2,0(sp)
    80003832:	1000                	addi	s0,sp,32
    80003834:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003836:	01050913          	addi	s2,a0,16
    8000383a:	854a                	mv	a0,s2
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	73a080e7          	jalr	1850(ra) # 80004f76 <holdingsleep>
    80003844:	c92d                	beqz	a0,800038b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003846:	854a                	mv	a0,s2
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	6ea080e7          	jalr	1770(ra) # 80004f32 <releasesleep>

  acquire(&bcache.lock);
    80003850:	0001d517          	auipc	a0,0x1d
    80003854:	c9850513          	addi	a0,a0,-872 # 800204e8 <bcache>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	36a080e7          	jalr	874(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003860:	40bc                	lw	a5,64(s1)
    80003862:	37fd                	addiw	a5,a5,-1
    80003864:	0007871b          	sext.w	a4,a5
    80003868:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000386a:	eb05                	bnez	a4,8000389a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000386c:	68bc                	ld	a5,80(s1)
    8000386e:	64b8                	ld	a4,72(s1)
    80003870:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003872:	64bc                	ld	a5,72(s1)
    80003874:	68b8                	ld	a4,80(s1)
    80003876:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003878:	00025797          	auipc	a5,0x25
    8000387c:	c7078793          	addi	a5,a5,-912 # 800284e8 <bcache+0x8000>
    80003880:	2b87b703          	ld	a4,696(a5)
    80003884:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003886:	00025717          	auipc	a4,0x25
    8000388a:	eca70713          	addi	a4,a4,-310 # 80028750 <bcache+0x8268>
    8000388e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003890:	2b87b703          	ld	a4,696(a5)
    80003894:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003896:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000389a:	0001d517          	auipc	a0,0x1d
    8000389e:	c4e50513          	addi	a0,a0,-946 # 800204e8 <bcache>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	3d4080e7          	jalr	980(ra) # 80000c76 <release>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret
    panic("brelse");
    800038b6:	00006517          	auipc	a0,0x6
    800038ba:	f1a50513          	addi	a0,a0,-230 # 800097d0 <syscalls+0xe0>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c6c080e7          	jalr	-916(ra) # 8000052a <panic>

00000000800038c6 <bpin>:

void
bpin(struct buf *b) {
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d2:	0001d517          	auipc	a0,0x1d
    800038d6:	c1650513          	addi	a0,a0,-1002 # 800204e8 <bcache>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	2e8080e7          	jalr	744(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	2785                	addiw	a5,a5,1
    800038e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038e8:	0001d517          	auipc	a0,0x1d
    800038ec:	c0050513          	addi	a0,a0,-1024 # 800204e8 <bcache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	386080e7          	jalr	902(ra) # 80000c76 <release>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <bunpin>:

void
bunpin(struct buf *b) {
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	1000                	addi	s0,sp,32
    8000390c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000390e:	0001d517          	auipc	a0,0x1d
    80003912:	bda50513          	addi	a0,a0,-1062 # 800204e8 <bcache>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	2ac080e7          	jalr	684(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000391e:	40bc                	lw	a5,64(s1)
    80003920:	37fd                	addiw	a5,a5,-1
    80003922:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003924:	0001d517          	auipc	a0,0x1d
    80003928:	bc450513          	addi	a0,a0,-1084 # 800204e8 <bcache>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	34a080e7          	jalr	842(ra) # 80000c76 <release>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret

000000008000393e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000393e:	1101                	addi	sp,sp,-32
    80003940:	ec06                	sd	ra,24(sp)
    80003942:	e822                	sd	s0,16(sp)
    80003944:	e426                	sd	s1,8(sp)
    80003946:	e04a                	sd	s2,0(sp)
    80003948:	1000                	addi	s0,sp,32
    8000394a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000394c:	00d5d59b          	srliw	a1,a1,0xd
    80003950:	00025797          	auipc	a5,0x25
    80003954:	2747a783          	lw	a5,628(a5) # 80028bc4 <sb+0x1c>
    80003958:	9dbd                	addw	a1,a1,a5
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	d9e080e7          	jalr	-610(ra) # 800036f8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003962:	0074f713          	andi	a4,s1,7
    80003966:	4785                	li	a5,1
    80003968:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000396c:	14ce                	slli	s1,s1,0x33
    8000396e:	90d9                	srli	s1,s1,0x36
    80003970:	00950733          	add	a4,a0,s1
    80003974:	05874703          	lbu	a4,88(a4)
    80003978:	00e7f6b3          	and	a3,a5,a4
    8000397c:	c69d                	beqz	a3,800039aa <bfree+0x6c>
    8000397e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003980:	94aa                	add	s1,s1,a0
    80003982:	fff7c793          	not	a5,a5
    80003986:	8ff9                	and	a5,a5,a4
    80003988:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000398c:	00001097          	auipc	ra,0x1
    80003990:	430080e7          	jalr	1072(ra) # 80004dbc <log_write>
  brelse(bp);
    80003994:	854a                	mv	a0,s2
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	e92080e7          	jalr	-366(ra) # 80003828 <brelse>
}
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6902                	ld	s2,0(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret
    panic("freeing free block");
    800039aa:	00006517          	auipc	a0,0x6
    800039ae:	e2e50513          	addi	a0,a0,-466 # 800097d8 <syscalls+0xe8>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b78080e7          	jalr	-1160(ra) # 8000052a <panic>

00000000800039ba <balloc>:
{
    800039ba:	711d                	addi	sp,sp,-96
    800039bc:	ec86                	sd	ra,88(sp)
    800039be:	e8a2                	sd	s0,80(sp)
    800039c0:	e4a6                	sd	s1,72(sp)
    800039c2:	e0ca                	sd	s2,64(sp)
    800039c4:	fc4e                	sd	s3,56(sp)
    800039c6:	f852                	sd	s4,48(sp)
    800039c8:	f456                	sd	s5,40(sp)
    800039ca:	f05a                	sd	s6,32(sp)
    800039cc:	ec5e                	sd	s7,24(sp)
    800039ce:	e862                	sd	s8,16(sp)
    800039d0:	e466                	sd	s9,8(sp)
    800039d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039d4:	00025797          	auipc	a5,0x25
    800039d8:	1d87a783          	lw	a5,472(a5) # 80028bac <sb+0x4>
    800039dc:	cbd1                	beqz	a5,80003a70 <balloc+0xb6>
    800039de:	8baa                	mv	s7,a0
    800039e0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039e2:	00025b17          	auipc	s6,0x25
    800039e6:	1c6b0b13          	addi	s6,s6,454 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ea:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039ec:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ee:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039f0:	6c89                	lui	s9,0x2
    800039f2:	a831                	j	80003a0e <balloc+0x54>
    brelse(bp);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	e32080e7          	jalr	-462(ra) # 80003828 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039fe:	015c87bb          	addw	a5,s9,s5
    80003a02:	00078a9b          	sext.w	s5,a5
    80003a06:	004b2703          	lw	a4,4(s6)
    80003a0a:	06eaf363          	bgeu	s5,a4,80003a70 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a0e:	41fad79b          	sraiw	a5,s5,0x1f
    80003a12:	0137d79b          	srliw	a5,a5,0x13
    80003a16:	015787bb          	addw	a5,a5,s5
    80003a1a:	40d7d79b          	sraiw	a5,a5,0xd
    80003a1e:	01cb2583          	lw	a1,28(s6)
    80003a22:	9dbd                	addw	a1,a1,a5
    80003a24:	855e                	mv	a0,s7
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	cd2080e7          	jalr	-814(ra) # 800036f8 <bread>
    80003a2e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a30:	004b2503          	lw	a0,4(s6)
    80003a34:	000a849b          	sext.w	s1,s5
    80003a38:	8662                	mv	a2,s8
    80003a3a:	faa4fde3          	bgeu	s1,a0,800039f4 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a3e:	41f6579b          	sraiw	a5,a2,0x1f
    80003a42:	01d7d69b          	srliw	a3,a5,0x1d
    80003a46:	00c6873b          	addw	a4,a3,a2
    80003a4a:	00777793          	andi	a5,a4,7
    80003a4e:	9f95                	subw	a5,a5,a3
    80003a50:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a54:	4037571b          	sraiw	a4,a4,0x3
    80003a58:	00e906b3          	add	a3,s2,a4
    80003a5c:	0586c683          	lbu	a3,88(a3)
    80003a60:	00d7f5b3          	and	a1,a5,a3
    80003a64:	cd91                	beqz	a1,80003a80 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a66:	2605                	addiw	a2,a2,1
    80003a68:	2485                	addiw	s1,s1,1
    80003a6a:	fd4618e3          	bne	a2,s4,80003a3a <balloc+0x80>
    80003a6e:	b759                	j	800039f4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a70:	00006517          	auipc	a0,0x6
    80003a74:	d8050513          	addi	a0,a0,-640 # 800097f0 <syscalls+0x100>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	ab2080e7          	jalr	-1358(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a80:	974a                	add	a4,a4,s2
    80003a82:	8fd5                	or	a5,a5,a3
    80003a84:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00001097          	auipc	ra,0x1
    80003a8e:	332080e7          	jalr	818(ra) # 80004dbc <log_write>
        brelse(bp);
    80003a92:	854a                	mv	a0,s2
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	d94080e7          	jalr	-620(ra) # 80003828 <brelse>
  bp = bread(dev, bno);
    80003a9c:	85a6                	mv	a1,s1
    80003a9e:	855e                	mv	a0,s7
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	c58080e7          	jalr	-936(ra) # 800036f8 <bread>
    80003aa8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003aaa:	40000613          	li	a2,1024
    80003aae:	4581                	li	a1,0
    80003ab0:	05850513          	addi	a0,a0,88
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	20a080e7          	jalr	522(ra) # 80000cbe <memset>
  log_write(bp);
    80003abc:	854a                	mv	a0,s2
    80003abe:	00001097          	auipc	ra,0x1
    80003ac2:	2fe080e7          	jalr	766(ra) # 80004dbc <log_write>
  brelse(bp);
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	d60080e7          	jalr	-672(ra) # 80003828 <brelse>
}
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	60e6                	ld	ra,88(sp)
    80003ad4:	6446                	ld	s0,80(sp)
    80003ad6:	64a6                	ld	s1,72(sp)
    80003ad8:	6906                	ld	s2,64(sp)
    80003ada:	79e2                	ld	s3,56(sp)
    80003adc:	7a42                	ld	s4,48(sp)
    80003ade:	7aa2                	ld	s5,40(sp)
    80003ae0:	7b02                	ld	s6,32(sp)
    80003ae2:	6be2                	ld	s7,24(sp)
    80003ae4:	6c42                	ld	s8,16(sp)
    80003ae6:	6ca2                	ld	s9,8(sp)
    80003ae8:	6125                	addi	sp,sp,96
    80003aea:	8082                	ret

0000000080003aec <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003aec:	7179                	addi	sp,sp,-48
    80003aee:	f406                	sd	ra,40(sp)
    80003af0:	f022                	sd	s0,32(sp)
    80003af2:	ec26                	sd	s1,24(sp)
    80003af4:	e84a                	sd	s2,16(sp)
    80003af6:	e44e                	sd	s3,8(sp)
    80003af8:	e052                	sd	s4,0(sp)
    80003afa:	1800                	addi	s0,sp,48
    80003afc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003afe:	47ad                	li	a5,11
    80003b00:	04b7fe63          	bgeu	a5,a1,80003b5c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b04:	ff45849b          	addiw	s1,a1,-12
    80003b08:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b0c:	0ff00793          	li	a5,255
    80003b10:	0ae7e463          	bltu	a5,a4,80003bb8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b14:	08052583          	lw	a1,128(a0)
    80003b18:	c5b5                	beqz	a1,80003b84 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b1a:	00092503          	lw	a0,0(s2)
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	bda080e7          	jalr	-1062(ra) # 800036f8 <bread>
    80003b26:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b28:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b2c:	02049713          	slli	a4,s1,0x20
    80003b30:	01e75593          	srli	a1,a4,0x1e
    80003b34:	00b784b3          	add	s1,a5,a1
    80003b38:	0004a983          	lw	s3,0(s1)
    80003b3c:	04098e63          	beqz	s3,80003b98 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b40:	8552                	mv	a0,s4
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	ce6080e7          	jalr	-794(ra) # 80003828 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b4a:	854e                	mv	a0,s3
    80003b4c:	70a2                	ld	ra,40(sp)
    80003b4e:	7402                	ld	s0,32(sp)
    80003b50:	64e2                	ld	s1,24(sp)
    80003b52:	6942                	ld	s2,16(sp)
    80003b54:	69a2                	ld	s3,8(sp)
    80003b56:	6a02                	ld	s4,0(sp)
    80003b58:	6145                	addi	sp,sp,48
    80003b5a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b5c:	02059793          	slli	a5,a1,0x20
    80003b60:	01e7d593          	srli	a1,a5,0x1e
    80003b64:	00b504b3          	add	s1,a0,a1
    80003b68:	0504a983          	lw	s3,80(s1)
    80003b6c:	fc099fe3          	bnez	s3,80003b4a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b70:	4108                	lw	a0,0(a0)
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	e48080e7          	jalr	-440(ra) # 800039ba <balloc>
    80003b7a:	0005099b          	sext.w	s3,a0
    80003b7e:	0534a823          	sw	s3,80(s1)
    80003b82:	b7e1                	j	80003b4a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b84:	4108                	lw	a0,0(a0)
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	e34080e7          	jalr	-460(ra) # 800039ba <balloc>
    80003b8e:	0005059b          	sext.w	a1,a0
    80003b92:	08b92023          	sw	a1,128(s2)
    80003b96:	b751                	j	80003b1a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b98:	00092503          	lw	a0,0(s2)
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	e1e080e7          	jalr	-482(ra) # 800039ba <balloc>
    80003ba4:	0005099b          	sext.w	s3,a0
    80003ba8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bac:	8552                	mv	a0,s4
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	20e080e7          	jalr	526(ra) # 80004dbc <log_write>
    80003bb6:	b769                	j	80003b40 <bmap+0x54>
  panic("bmap: out of range");
    80003bb8:	00006517          	auipc	a0,0x6
    80003bbc:	c5050513          	addi	a0,a0,-944 # 80009808 <syscalls+0x118>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	96a080e7          	jalr	-1686(ra) # 8000052a <panic>

0000000080003bc8 <iget>:
{
    80003bc8:	7179                	addi	sp,sp,-48
    80003bca:	f406                	sd	ra,40(sp)
    80003bcc:	f022                	sd	s0,32(sp)
    80003bce:	ec26                	sd	s1,24(sp)
    80003bd0:	e84a                	sd	s2,16(sp)
    80003bd2:	e44e                	sd	s3,8(sp)
    80003bd4:	e052                	sd	s4,0(sp)
    80003bd6:	1800                	addi	s0,sp,48
    80003bd8:	89aa                	mv	s3,a0
    80003bda:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bdc:	00025517          	auipc	a0,0x25
    80003be0:	fec50513          	addi	a0,a0,-20 # 80028bc8 <itable>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	fde080e7          	jalr	-34(ra) # 80000bc2 <acquire>
  empty = 0;
    80003bec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bee:	00025497          	auipc	s1,0x25
    80003bf2:	ff248493          	addi	s1,s1,-14 # 80028be0 <itable+0x18>
    80003bf6:	00027697          	auipc	a3,0x27
    80003bfa:	a7a68693          	addi	a3,a3,-1414 # 8002a670 <log>
    80003bfe:	a039                	j	80003c0c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c00:	02090b63          	beqz	s2,80003c36 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c04:	08848493          	addi	s1,s1,136
    80003c08:	02d48a63          	beq	s1,a3,80003c3c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c0c:	449c                	lw	a5,8(s1)
    80003c0e:	fef059e3          	blez	a5,80003c00 <iget+0x38>
    80003c12:	4098                	lw	a4,0(s1)
    80003c14:	ff3716e3          	bne	a4,s3,80003c00 <iget+0x38>
    80003c18:	40d8                	lw	a4,4(s1)
    80003c1a:	ff4713e3          	bne	a4,s4,80003c00 <iget+0x38>
      ip->ref++;
    80003c1e:	2785                	addiw	a5,a5,1
    80003c20:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c22:	00025517          	auipc	a0,0x25
    80003c26:	fa650513          	addi	a0,a0,-90 # 80028bc8 <itable>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	04c080e7          	jalr	76(ra) # 80000c76 <release>
      return ip;
    80003c32:	8926                	mv	s2,s1
    80003c34:	a03d                	j	80003c62 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c36:	f7f9                	bnez	a5,80003c04 <iget+0x3c>
    80003c38:	8926                	mv	s2,s1
    80003c3a:	b7e9                	j	80003c04 <iget+0x3c>
  if(empty == 0)
    80003c3c:	02090c63          	beqz	s2,80003c74 <iget+0xac>
  ip->dev = dev;
    80003c40:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c44:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c48:	4785                	li	a5,1
    80003c4a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c4e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c52:	00025517          	auipc	a0,0x25
    80003c56:	f7650513          	addi	a0,a0,-138 # 80028bc8 <itable>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	01c080e7          	jalr	28(ra) # 80000c76 <release>
}
    80003c62:	854a                	mv	a0,s2
    80003c64:	70a2                	ld	ra,40(sp)
    80003c66:	7402                	ld	s0,32(sp)
    80003c68:	64e2                	ld	s1,24(sp)
    80003c6a:	6942                	ld	s2,16(sp)
    80003c6c:	69a2                	ld	s3,8(sp)
    80003c6e:	6a02                	ld	s4,0(sp)
    80003c70:	6145                	addi	sp,sp,48
    80003c72:	8082                	ret
    panic("iget: no inodes");
    80003c74:	00006517          	auipc	a0,0x6
    80003c78:	bac50513          	addi	a0,a0,-1108 # 80009820 <syscalls+0x130>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	8ae080e7          	jalr	-1874(ra) # 8000052a <panic>

0000000080003c84 <fsinit>:
fsinit(int dev) {
    80003c84:	7179                	addi	sp,sp,-48
    80003c86:	f406                	sd	ra,40(sp)
    80003c88:	f022                	sd	s0,32(sp)
    80003c8a:	ec26                	sd	s1,24(sp)
    80003c8c:	e84a                	sd	s2,16(sp)
    80003c8e:	e44e                	sd	s3,8(sp)
    80003c90:	1800                	addi	s0,sp,48
    80003c92:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c94:	4585                	li	a1,1
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	a62080e7          	jalr	-1438(ra) # 800036f8 <bread>
    80003c9e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ca0:	00025997          	auipc	s3,0x25
    80003ca4:	f0898993          	addi	s3,s3,-248 # 80028ba8 <sb>
    80003ca8:	02000613          	li	a2,32
    80003cac:	05850593          	addi	a1,a0,88
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	068080e7          	jalr	104(ra) # 80000d1a <memmove>
  brelse(bp);
    80003cba:	8526                	mv	a0,s1
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	b6c080e7          	jalr	-1172(ra) # 80003828 <brelse>
  if(sb.magic != FSMAGIC)
    80003cc4:	0009a703          	lw	a4,0(s3)
    80003cc8:	102037b7          	lui	a5,0x10203
    80003ccc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cd0:	02f71263          	bne	a4,a5,80003cf4 <fsinit+0x70>
  initlog(dev, &sb);
    80003cd4:	00025597          	auipc	a1,0x25
    80003cd8:	ed458593          	addi	a1,a1,-300 # 80028ba8 <sb>
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00001097          	auipc	ra,0x1
    80003ce2:	e60080e7          	jalr	-416(ra) # 80004b3e <initlog>
}
    80003ce6:	70a2                	ld	ra,40(sp)
    80003ce8:	7402                	ld	s0,32(sp)
    80003cea:	64e2                	ld	s1,24(sp)
    80003cec:	6942                	ld	s2,16(sp)
    80003cee:	69a2                	ld	s3,8(sp)
    80003cf0:	6145                	addi	sp,sp,48
    80003cf2:	8082                	ret
    panic("invalid file system");
    80003cf4:	00006517          	auipc	a0,0x6
    80003cf8:	b3c50513          	addi	a0,a0,-1220 # 80009830 <syscalls+0x140>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	82e080e7          	jalr	-2002(ra) # 8000052a <panic>

0000000080003d04 <iinit>:
{
    80003d04:	7179                	addi	sp,sp,-48
    80003d06:	f406                	sd	ra,40(sp)
    80003d08:	f022                	sd	s0,32(sp)
    80003d0a:	ec26                	sd	s1,24(sp)
    80003d0c:	e84a                	sd	s2,16(sp)
    80003d0e:	e44e                	sd	s3,8(sp)
    80003d10:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d12:	00006597          	auipc	a1,0x6
    80003d16:	b3658593          	addi	a1,a1,-1226 # 80009848 <syscalls+0x158>
    80003d1a:	00025517          	auipc	a0,0x25
    80003d1e:	eae50513          	addi	a0,a0,-338 # 80028bc8 <itable>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	e10080e7          	jalr	-496(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d2a:	00025497          	auipc	s1,0x25
    80003d2e:	ec648493          	addi	s1,s1,-314 # 80028bf0 <itable+0x28>
    80003d32:	00027997          	auipc	s3,0x27
    80003d36:	94e98993          	addi	s3,s3,-1714 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d3a:	00006917          	auipc	s2,0x6
    80003d3e:	b1690913          	addi	s2,s2,-1258 # 80009850 <syscalls+0x160>
    80003d42:	85ca                	mv	a1,s2
    80003d44:	8526                	mv	a0,s1
    80003d46:	00001097          	auipc	ra,0x1
    80003d4a:	15c080e7          	jalr	348(ra) # 80004ea2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d4e:	08848493          	addi	s1,s1,136
    80003d52:	ff3498e3          	bne	s1,s3,80003d42 <iinit+0x3e>
}
    80003d56:	70a2                	ld	ra,40(sp)
    80003d58:	7402                	ld	s0,32(sp)
    80003d5a:	64e2                	ld	s1,24(sp)
    80003d5c:	6942                	ld	s2,16(sp)
    80003d5e:	69a2                	ld	s3,8(sp)
    80003d60:	6145                	addi	sp,sp,48
    80003d62:	8082                	ret

0000000080003d64 <ialloc>:
{
    80003d64:	715d                	addi	sp,sp,-80
    80003d66:	e486                	sd	ra,72(sp)
    80003d68:	e0a2                	sd	s0,64(sp)
    80003d6a:	fc26                	sd	s1,56(sp)
    80003d6c:	f84a                	sd	s2,48(sp)
    80003d6e:	f44e                	sd	s3,40(sp)
    80003d70:	f052                	sd	s4,32(sp)
    80003d72:	ec56                	sd	s5,24(sp)
    80003d74:	e85a                	sd	s6,16(sp)
    80003d76:	e45e                	sd	s7,8(sp)
    80003d78:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d7a:	00025717          	auipc	a4,0x25
    80003d7e:	e3a72703          	lw	a4,-454(a4) # 80028bb4 <sb+0xc>
    80003d82:	4785                	li	a5,1
    80003d84:	04e7fa63          	bgeu	a5,a4,80003dd8 <ialloc+0x74>
    80003d88:	8aaa                	mv	s5,a0
    80003d8a:	8bae                	mv	s7,a1
    80003d8c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d8e:	00025a17          	auipc	s4,0x25
    80003d92:	e1aa0a13          	addi	s4,s4,-486 # 80028ba8 <sb>
    80003d96:	00048b1b          	sext.w	s6,s1
    80003d9a:	0044d793          	srli	a5,s1,0x4
    80003d9e:	018a2583          	lw	a1,24(s4)
    80003da2:	9dbd                	addw	a1,a1,a5
    80003da4:	8556                	mv	a0,s5
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	952080e7          	jalr	-1710(ra) # 800036f8 <bread>
    80003dae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003db0:	05850993          	addi	s3,a0,88
    80003db4:	00f4f793          	andi	a5,s1,15
    80003db8:	079a                	slli	a5,a5,0x6
    80003dba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003dbc:	00099783          	lh	a5,0(s3)
    80003dc0:	c785                	beqz	a5,80003de8 <ialloc+0x84>
    brelse(bp);
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	a66080e7          	jalr	-1434(ra) # 80003828 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dca:	0485                	addi	s1,s1,1
    80003dcc:	00ca2703          	lw	a4,12(s4)
    80003dd0:	0004879b          	sext.w	a5,s1
    80003dd4:	fce7e1e3          	bltu	a5,a4,80003d96 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003dd8:	00006517          	auipc	a0,0x6
    80003ddc:	a8050513          	addi	a0,a0,-1408 # 80009858 <syscalls+0x168>
    80003de0:	ffffc097          	auipc	ra,0xffffc
    80003de4:	74a080e7          	jalr	1866(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003de8:	04000613          	li	a2,64
    80003dec:	4581                	li	a1,0
    80003dee:	854e                	mv	a0,s3
    80003df0:	ffffd097          	auipc	ra,0xffffd
    80003df4:	ece080e7          	jalr	-306(ra) # 80000cbe <memset>
      dip->type = type;
    80003df8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	fbe080e7          	jalr	-66(ra) # 80004dbc <log_write>
      brelse(bp);
    80003e06:	854a                	mv	a0,s2
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	a20080e7          	jalr	-1504(ra) # 80003828 <brelse>
      return iget(dev, inum);
    80003e10:	85da                	mv	a1,s6
    80003e12:	8556                	mv	a0,s5
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	db4080e7          	jalr	-588(ra) # 80003bc8 <iget>
}
    80003e1c:	60a6                	ld	ra,72(sp)
    80003e1e:	6406                	ld	s0,64(sp)
    80003e20:	74e2                	ld	s1,56(sp)
    80003e22:	7942                	ld	s2,48(sp)
    80003e24:	79a2                	ld	s3,40(sp)
    80003e26:	7a02                	ld	s4,32(sp)
    80003e28:	6ae2                	ld	s5,24(sp)
    80003e2a:	6b42                	ld	s6,16(sp)
    80003e2c:	6ba2                	ld	s7,8(sp)
    80003e2e:	6161                	addi	sp,sp,80
    80003e30:	8082                	ret

0000000080003e32 <iupdate>:
{
    80003e32:	1101                	addi	sp,sp,-32
    80003e34:	ec06                	sd	ra,24(sp)
    80003e36:	e822                	sd	s0,16(sp)
    80003e38:	e426                	sd	s1,8(sp)
    80003e3a:	e04a                	sd	s2,0(sp)
    80003e3c:	1000                	addi	s0,sp,32
    80003e3e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e40:	415c                	lw	a5,4(a0)
    80003e42:	0047d79b          	srliw	a5,a5,0x4
    80003e46:	00025597          	auipc	a1,0x25
    80003e4a:	d7a5a583          	lw	a1,-646(a1) # 80028bc0 <sb+0x18>
    80003e4e:	9dbd                	addw	a1,a1,a5
    80003e50:	4108                	lw	a0,0(a0)
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	8a6080e7          	jalr	-1882(ra) # 800036f8 <bread>
    80003e5a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e5c:	05850793          	addi	a5,a0,88
    80003e60:	40c8                	lw	a0,4(s1)
    80003e62:	893d                	andi	a0,a0,15
    80003e64:	051a                	slli	a0,a0,0x6
    80003e66:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e68:	04449703          	lh	a4,68(s1)
    80003e6c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e70:	04649703          	lh	a4,70(s1)
    80003e74:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e78:	04849703          	lh	a4,72(s1)
    80003e7c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e80:	04a49703          	lh	a4,74(s1)
    80003e84:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e88:	44f8                	lw	a4,76(s1)
    80003e8a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e8c:	03400613          	li	a2,52
    80003e90:	05048593          	addi	a1,s1,80
    80003e94:	0531                	addi	a0,a0,12
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	e84080e7          	jalr	-380(ra) # 80000d1a <memmove>
  log_write(bp);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00001097          	auipc	ra,0x1
    80003ea4:	f1c080e7          	jalr	-228(ra) # 80004dbc <log_write>
  brelse(bp);
    80003ea8:	854a                	mv	a0,s2
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	97e080e7          	jalr	-1666(ra) # 80003828 <brelse>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	64a2                	ld	s1,8(sp)
    80003eb8:	6902                	ld	s2,0(sp)
    80003eba:	6105                	addi	sp,sp,32
    80003ebc:	8082                	ret

0000000080003ebe <idup>:
{
    80003ebe:	1101                	addi	sp,sp,-32
    80003ec0:	ec06                	sd	ra,24(sp)
    80003ec2:	e822                	sd	s0,16(sp)
    80003ec4:	e426                	sd	s1,8(sp)
    80003ec6:	1000                	addi	s0,sp,32
    80003ec8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eca:	00025517          	auipc	a0,0x25
    80003ece:	cfe50513          	addi	a0,a0,-770 # 80028bc8 <itable>
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	cf0080e7          	jalr	-784(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003eda:	449c                	lw	a5,8(s1)
    80003edc:	2785                	addiw	a5,a5,1
    80003ede:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ee0:	00025517          	auipc	a0,0x25
    80003ee4:	ce850513          	addi	a0,a0,-792 # 80028bc8 <itable>
    80003ee8:	ffffd097          	auipc	ra,0xffffd
    80003eec:	d8e080e7          	jalr	-626(ra) # 80000c76 <release>
}
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	64a2                	ld	s1,8(sp)
    80003ef8:	6105                	addi	sp,sp,32
    80003efa:	8082                	ret

0000000080003efc <ilock>:
{
    80003efc:	1101                	addi	sp,sp,-32
    80003efe:	ec06                	sd	ra,24(sp)
    80003f00:	e822                	sd	s0,16(sp)
    80003f02:	e426                	sd	s1,8(sp)
    80003f04:	e04a                	sd	s2,0(sp)
    80003f06:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f08:	c115                	beqz	a0,80003f2c <ilock+0x30>
    80003f0a:	84aa                	mv	s1,a0
    80003f0c:	451c                	lw	a5,8(a0)
    80003f0e:	00f05f63          	blez	a5,80003f2c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f12:	0541                	addi	a0,a0,16
    80003f14:	00001097          	auipc	ra,0x1
    80003f18:	fc8080e7          	jalr	-56(ra) # 80004edc <acquiresleep>
  if(ip->valid == 0){
    80003f1c:	40bc                	lw	a5,64(s1)
    80003f1e:	cf99                	beqz	a5,80003f3c <ilock+0x40>
}
    80003f20:	60e2                	ld	ra,24(sp)
    80003f22:	6442                	ld	s0,16(sp)
    80003f24:	64a2                	ld	s1,8(sp)
    80003f26:	6902                	ld	s2,0(sp)
    80003f28:	6105                	addi	sp,sp,32
    80003f2a:	8082                	ret
    panic("ilock");
    80003f2c:	00006517          	auipc	a0,0x6
    80003f30:	94450513          	addi	a0,a0,-1724 # 80009870 <syscalls+0x180>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	5f6080e7          	jalr	1526(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f3c:	40dc                	lw	a5,4(s1)
    80003f3e:	0047d79b          	srliw	a5,a5,0x4
    80003f42:	00025597          	auipc	a1,0x25
    80003f46:	c7e5a583          	lw	a1,-898(a1) # 80028bc0 <sb+0x18>
    80003f4a:	9dbd                	addw	a1,a1,a5
    80003f4c:	4088                	lw	a0,0(s1)
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	7aa080e7          	jalr	1962(ra) # 800036f8 <bread>
    80003f56:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f58:	05850593          	addi	a1,a0,88
    80003f5c:	40dc                	lw	a5,4(s1)
    80003f5e:	8bbd                	andi	a5,a5,15
    80003f60:	079a                	slli	a5,a5,0x6
    80003f62:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f64:	00059783          	lh	a5,0(a1)
    80003f68:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f6c:	00259783          	lh	a5,2(a1)
    80003f70:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f74:	00459783          	lh	a5,4(a1)
    80003f78:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f7c:	00659783          	lh	a5,6(a1)
    80003f80:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f84:	459c                	lw	a5,8(a1)
    80003f86:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f88:	03400613          	li	a2,52
    80003f8c:	05b1                	addi	a1,a1,12
    80003f8e:	05048513          	addi	a0,s1,80
    80003f92:	ffffd097          	auipc	ra,0xffffd
    80003f96:	d88080e7          	jalr	-632(ra) # 80000d1a <memmove>
    brelse(bp);
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	88c080e7          	jalr	-1908(ra) # 80003828 <brelse>
    ip->valid = 1;
    80003fa4:	4785                	li	a5,1
    80003fa6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fa8:	04449783          	lh	a5,68(s1)
    80003fac:	fbb5                	bnez	a5,80003f20 <ilock+0x24>
      panic("ilock: no type");
    80003fae:	00006517          	auipc	a0,0x6
    80003fb2:	8ca50513          	addi	a0,a0,-1846 # 80009878 <syscalls+0x188>
    80003fb6:	ffffc097          	auipc	ra,0xffffc
    80003fba:	574080e7          	jalr	1396(ra) # 8000052a <panic>

0000000080003fbe <iunlock>:
{
    80003fbe:	1101                	addi	sp,sp,-32
    80003fc0:	ec06                	sd	ra,24(sp)
    80003fc2:	e822                	sd	s0,16(sp)
    80003fc4:	e426                	sd	s1,8(sp)
    80003fc6:	e04a                	sd	s2,0(sp)
    80003fc8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fca:	c905                	beqz	a0,80003ffa <iunlock+0x3c>
    80003fcc:	84aa                	mv	s1,a0
    80003fce:	01050913          	addi	s2,a0,16
    80003fd2:	854a                	mv	a0,s2
    80003fd4:	00001097          	auipc	ra,0x1
    80003fd8:	fa2080e7          	jalr	-94(ra) # 80004f76 <holdingsleep>
    80003fdc:	cd19                	beqz	a0,80003ffa <iunlock+0x3c>
    80003fde:	449c                	lw	a5,8(s1)
    80003fe0:	00f05d63          	blez	a5,80003ffa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	00001097          	auipc	ra,0x1
    80003fea:	f4c080e7          	jalr	-180(ra) # 80004f32 <releasesleep>
}
    80003fee:	60e2                	ld	ra,24(sp)
    80003ff0:	6442                	ld	s0,16(sp)
    80003ff2:	64a2                	ld	s1,8(sp)
    80003ff4:	6902                	ld	s2,0(sp)
    80003ff6:	6105                	addi	sp,sp,32
    80003ff8:	8082                	ret
    panic("iunlock");
    80003ffa:	00006517          	auipc	a0,0x6
    80003ffe:	88e50513          	addi	a0,a0,-1906 # 80009888 <syscalls+0x198>
    80004002:	ffffc097          	auipc	ra,0xffffc
    80004006:	528080e7          	jalr	1320(ra) # 8000052a <panic>

000000008000400a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000400a:	7179                	addi	sp,sp,-48
    8000400c:	f406                	sd	ra,40(sp)
    8000400e:	f022                	sd	s0,32(sp)
    80004010:	ec26                	sd	s1,24(sp)
    80004012:	e84a                	sd	s2,16(sp)
    80004014:	e44e                	sd	s3,8(sp)
    80004016:	e052                	sd	s4,0(sp)
    80004018:	1800                	addi	s0,sp,48
    8000401a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000401c:	05050493          	addi	s1,a0,80
    80004020:	08050913          	addi	s2,a0,128
    80004024:	a021                	j	8000402c <itrunc+0x22>
    80004026:	0491                	addi	s1,s1,4
    80004028:	01248d63          	beq	s1,s2,80004042 <itrunc+0x38>
    if(ip->addrs[i]){
    8000402c:	408c                	lw	a1,0(s1)
    8000402e:	dde5                	beqz	a1,80004026 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004030:	0009a503          	lw	a0,0(s3)
    80004034:	00000097          	auipc	ra,0x0
    80004038:	90a080e7          	jalr	-1782(ra) # 8000393e <bfree>
      ip->addrs[i] = 0;
    8000403c:	0004a023          	sw	zero,0(s1)
    80004040:	b7dd                	j	80004026 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004042:	0809a583          	lw	a1,128(s3)
    80004046:	e185                	bnez	a1,80004066 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004048:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000404c:	854e                	mv	a0,s3
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	de4080e7          	jalr	-540(ra) # 80003e32 <iupdate>
}
    80004056:	70a2                	ld	ra,40(sp)
    80004058:	7402                	ld	s0,32(sp)
    8000405a:	64e2                	ld	s1,24(sp)
    8000405c:	6942                	ld	s2,16(sp)
    8000405e:	69a2                	ld	s3,8(sp)
    80004060:	6a02                	ld	s4,0(sp)
    80004062:	6145                	addi	sp,sp,48
    80004064:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004066:	0009a503          	lw	a0,0(s3)
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	68e080e7          	jalr	1678(ra) # 800036f8 <bread>
    80004072:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004074:	05850493          	addi	s1,a0,88
    80004078:	45850913          	addi	s2,a0,1112
    8000407c:	a021                	j	80004084 <itrunc+0x7a>
    8000407e:	0491                	addi	s1,s1,4
    80004080:	01248b63          	beq	s1,s2,80004096 <itrunc+0x8c>
      if(a[j])
    80004084:	408c                	lw	a1,0(s1)
    80004086:	dde5                	beqz	a1,8000407e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004088:	0009a503          	lw	a0,0(s3)
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	8b2080e7          	jalr	-1870(ra) # 8000393e <bfree>
    80004094:	b7ed                	j	8000407e <itrunc+0x74>
    brelse(bp);
    80004096:	8552                	mv	a0,s4
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	790080e7          	jalr	1936(ra) # 80003828 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040a0:	0809a583          	lw	a1,128(s3)
    800040a4:	0009a503          	lw	a0,0(s3)
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	896080e7          	jalr	-1898(ra) # 8000393e <bfree>
    ip->addrs[NDIRECT] = 0;
    800040b0:	0809a023          	sw	zero,128(s3)
    800040b4:	bf51                	j	80004048 <itrunc+0x3e>

00000000800040b6 <iput>:
{
    800040b6:	1101                	addi	sp,sp,-32
    800040b8:	ec06                	sd	ra,24(sp)
    800040ba:	e822                	sd	s0,16(sp)
    800040bc:	e426                	sd	s1,8(sp)
    800040be:	e04a                	sd	s2,0(sp)
    800040c0:	1000                	addi	s0,sp,32
    800040c2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040c4:	00025517          	auipc	a0,0x25
    800040c8:	b0450513          	addi	a0,a0,-1276 # 80028bc8 <itable>
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	af6080e7          	jalr	-1290(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d4:	4498                	lw	a4,8(s1)
    800040d6:	4785                	li	a5,1
    800040d8:	02f70363          	beq	a4,a5,800040fe <iput+0x48>
  ip->ref--;
    800040dc:	449c                	lw	a5,8(s1)
    800040de:	37fd                	addiw	a5,a5,-1
    800040e0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040e2:	00025517          	auipc	a0,0x25
    800040e6:	ae650513          	addi	a0,a0,-1306 # 80028bc8 <itable>
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	b8c080e7          	jalr	-1140(ra) # 80000c76 <release>
}
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	64a2                	ld	s1,8(sp)
    800040f8:	6902                	ld	s2,0(sp)
    800040fa:	6105                	addi	sp,sp,32
    800040fc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040fe:	40bc                	lw	a5,64(s1)
    80004100:	dff1                	beqz	a5,800040dc <iput+0x26>
    80004102:	04a49783          	lh	a5,74(s1)
    80004106:	fbf9                	bnez	a5,800040dc <iput+0x26>
    acquiresleep(&ip->lock);
    80004108:	01048913          	addi	s2,s1,16
    8000410c:	854a                	mv	a0,s2
    8000410e:	00001097          	auipc	ra,0x1
    80004112:	dce080e7          	jalr	-562(ra) # 80004edc <acquiresleep>
    release(&itable.lock);
    80004116:	00025517          	auipc	a0,0x25
    8000411a:	ab250513          	addi	a0,a0,-1358 # 80028bc8 <itable>
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	b58080e7          	jalr	-1192(ra) # 80000c76 <release>
    itrunc(ip);
    80004126:	8526                	mv	a0,s1
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	ee2080e7          	jalr	-286(ra) # 8000400a <itrunc>
    ip->type = 0;
    80004130:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004134:	8526                	mv	a0,s1
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	cfc080e7          	jalr	-772(ra) # 80003e32 <iupdate>
    ip->valid = 0;
    8000413e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004142:	854a                	mv	a0,s2
    80004144:	00001097          	auipc	ra,0x1
    80004148:	dee080e7          	jalr	-530(ra) # 80004f32 <releasesleep>
    acquire(&itable.lock);
    8000414c:	00025517          	auipc	a0,0x25
    80004150:	a7c50513          	addi	a0,a0,-1412 # 80028bc8 <itable>
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	a6e080e7          	jalr	-1426(ra) # 80000bc2 <acquire>
    8000415c:	b741                	j	800040dc <iput+0x26>

000000008000415e <iunlockput>:
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	1000                	addi	s0,sp,32
    80004168:	84aa                	mv	s1,a0
  iunlock(ip);
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	e54080e7          	jalr	-428(ra) # 80003fbe <iunlock>
  iput(ip);
    80004172:	8526                	mv	a0,s1
    80004174:	00000097          	auipc	ra,0x0
    80004178:	f42080e7          	jalr	-190(ra) # 800040b6 <iput>
}
    8000417c:	60e2                	ld	ra,24(sp)
    8000417e:	6442                	ld	s0,16(sp)
    80004180:	64a2                	ld	s1,8(sp)
    80004182:	6105                	addi	sp,sp,32
    80004184:	8082                	ret

0000000080004186 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004186:	1141                	addi	sp,sp,-16
    80004188:	e422                	sd	s0,8(sp)
    8000418a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000418c:	411c                	lw	a5,0(a0)
    8000418e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004190:	415c                	lw	a5,4(a0)
    80004192:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004194:	04451783          	lh	a5,68(a0)
    80004198:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000419c:	04a51783          	lh	a5,74(a0)
    800041a0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041a4:	04c56783          	lwu	a5,76(a0)
    800041a8:	e99c                	sd	a5,16(a1)
}
    800041aa:	6422                	ld	s0,8(sp)
    800041ac:	0141                	addi	sp,sp,16
    800041ae:	8082                	ret

00000000800041b0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041b0:	457c                	lw	a5,76(a0)
    800041b2:	0ed7e963          	bltu	a5,a3,800042a4 <readi+0xf4>
{
    800041b6:	7159                	addi	sp,sp,-112
    800041b8:	f486                	sd	ra,104(sp)
    800041ba:	f0a2                	sd	s0,96(sp)
    800041bc:	eca6                	sd	s1,88(sp)
    800041be:	e8ca                	sd	s2,80(sp)
    800041c0:	e4ce                	sd	s3,72(sp)
    800041c2:	e0d2                	sd	s4,64(sp)
    800041c4:	fc56                	sd	s5,56(sp)
    800041c6:	f85a                	sd	s6,48(sp)
    800041c8:	f45e                	sd	s7,40(sp)
    800041ca:	f062                	sd	s8,32(sp)
    800041cc:	ec66                	sd	s9,24(sp)
    800041ce:	e86a                	sd	s10,16(sp)
    800041d0:	e46e                	sd	s11,8(sp)
    800041d2:	1880                	addi	s0,sp,112
    800041d4:	8baa                	mv	s7,a0
    800041d6:	8c2e                	mv	s8,a1
    800041d8:	8ab2                	mv	s5,a2
    800041da:	84b6                	mv	s1,a3
    800041dc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041de:	9f35                	addw	a4,a4,a3
    return 0;
    800041e0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041e2:	0ad76063          	bltu	a4,a3,80004282 <readi+0xd2>
  if(off + n > ip->size)
    800041e6:	00e7f463          	bgeu	a5,a4,800041ee <readi+0x3e>
    n = ip->size - off;
    800041ea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041ee:	0a0b0963          	beqz	s6,800042a0 <readi+0xf0>
    800041f2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041f4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041f8:	5cfd                	li	s9,-1
    800041fa:	a82d                	j	80004234 <readi+0x84>
    800041fc:	020a1d93          	slli	s11,s4,0x20
    80004200:	020ddd93          	srli	s11,s11,0x20
    80004204:	05890793          	addi	a5,s2,88
    80004208:	86ee                	mv	a3,s11
    8000420a:	963e                	add	a2,a2,a5
    8000420c:	85d6                	mv	a1,s5
    8000420e:	8562                	mv	a0,s8
    80004210:	ffffe097          	auipc	ra,0xffffe
    80004214:	f8c080e7          	jalr	-116(ra) # 8000219c <either_copyout>
    80004218:	05950d63          	beq	a0,s9,80004272 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000421c:	854a                	mv	a0,s2
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	60a080e7          	jalr	1546(ra) # 80003828 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004226:	013a09bb          	addw	s3,s4,s3
    8000422a:	009a04bb          	addw	s1,s4,s1
    8000422e:	9aee                	add	s5,s5,s11
    80004230:	0569f763          	bgeu	s3,s6,8000427e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004234:	000ba903          	lw	s2,0(s7)
    80004238:	00a4d59b          	srliw	a1,s1,0xa
    8000423c:	855e                	mv	a0,s7
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	8ae080e7          	jalr	-1874(ra) # 80003aec <bmap>
    80004246:	0005059b          	sext.w	a1,a0
    8000424a:	854a                	mv	a0,s2
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	4ac080e7          	jalr	1196(ra) # 800036f8 <bread>
    80004254:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004256:	3ff4f613          	andi	a2,s1,1023
    8000425a:	40cd07bb          	subw	a5,s10,a2
    8000425e:	413b073b          	subw	a4,s6,s3
    80004262:	8a3e                	mv	s4,a5
    80004264:	2781                	sext.w	a5,a5
    80004266:	0007069b          	sext.w	a3,a4
    8000426a:	f8f6f9e3          	bgeu	a3,a5,800041fc <readi+0x4c>
    8000426e:	8a3a                	mv	s4,a4
    80004270:	b771                	j	800041fc <readi+0x4c>
      brelse(bp);
    80004272:	854a                	mv	a0,s2
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	5b4080e7          	jalr	1460(ra) # 80003828 <brelse>
      tot = -1;
    8000427c:	59fd                	li	s3,-1
  }
  return tot;
    8000427e:	0009851b          	sext.w	a0,s3
}
    80004282:	70a6                	ld	ra,104(sp)
    80004284:	7406                	ld	s0,96(sp)
    80004286:	64e6                	ld	s1,88(sp)
    80004288:	6946                	ld	s2,80(sp)
    8000428a:	69a6                	ld	s3,72(sp)
    8000428c:	6a06                	ld	s4,64(sp)
    8000428e:	7ae2                	ld	s5,56(sp)
    80004290:	7b42                	ld	s6,48(sp)
    80004292:	7ba2                	ld	s7,40(sp)
    80004294:	7c02                	ld	s8,32(sp)
    80004296:	6ce2                	ld	s9,24(sp)
    80004298:	6d42                	ld	s10,16(sp)
    8000429a:	6da2                	ld	s11,8(sp)
    8000429c:	6165                	addi	sp,sp,112
    8000429e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042a0:	89da                	mv	s3,s6
    800042a2:	bff1                	j	8000427e <readi+0xce>
    return 0;
    800042a4:	4501                	li	a0,0
}
    800042a6:	8082                	ret

00000000800042a8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042a8:	457c                	lw	a5,76(a0)
    800042aa:	10d7e863          	bltu	a5,a3,800043ba <writei+0x112>
{
    800042ae:	7159                	addi	sp,sp,-112
    800042b0:	f486                	sd	ra,104(sp)
    800042b2:	f0a2                	sd	s0,96(sp)
    800042b4:	eca6                	sd	s1,88(sp)
    800042b6:	e8ca                	sd	s2,80(sp)
    800042b8:	e4ce                	sd	s3,72(sp)
    800042ba:	e0d2                	sd	s4,64(sp)
    800042bc:	fc56                	sd	s5,56(sp)
    800042be:	f85a                	sd	s6,48(sp)
    800042c0:	f45e                	sd	s7,40(sp)
    800042c2:	f062                	sd	s8,32(sp)
    800042c4:	ec66                	sd	s9,24(sp)
    800042c6:	e86a                	sd	s10,16(sp)
    800042c8:	e46e                	sd	s11,8(sp)
    800042ca:	1880                	addi	s0,sp,112
    800042cc:	8b2a                	mv	s6,a0
    800042ce:	8c2e                	mv	s8,a1
    800042d0:	8ab2                	mv	s5,a2
    800042d2:	8936                	mv	s2,a3
    800042d4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042d6:	00e687bb          	addw	a5,a3,a4
    800042da:	0ed7e263          	bltu	a5,a3,800043be <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042de:	00043737          	lui	a4,0x43
    800042e2:	0ef76063          	bltu	a4,a5,800043c2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042e6:	0c0b8863          	beqz	s7,800043b6 <writei+0x10e>
    800042ea:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042ec:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042f0:	5cfd                	li	s9,-1
    800042f2:	a091                	j	80004336 <writei+0x8e>
    800042f4:	02099d93          	slli	s11,s3,0x20
    800042f8:	020ddd93          	srli	s11,s11,0x20
    800042fc:	05848793          	addi	a5,s1,88
    80004300:	86ee                	mv	a3,s11
    80004302:	8656                	mv	a2,s5
    80004304:	85e2                	mv	a1,s8
    80004306:	953e                	add	a0,a0,a5
    80004308:	ffffe097          	auipc	ra,0xffffe
    8000430c:	eea080e7          	jalr	-278(ra) # 800021f2 <either_copyin>
    80004310:	07950263          	beq	a0,s9,80004374 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004314:	8526                	mv	a0,s1
    80004316:	00001097          	auipc	ra,0x1
    8000431a:	aa6080e7          	jalr	-1370(ra) # 80004dbc <log_write>
    brelse(bp);
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	508080e7          	jalr	1288(ra) # 80003828 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004328:	01498a3b          	addw	s4,s3,s4
    8000432c:	0129893b          	addw	s2,s3,s2
    80004330:	9aee                	add	s5,s5,s11
    80004332:	057a7663          	bgeu	s4,s7,8000437e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004336:	000b2483          	lw	s1,0(s6)
    8000433a:	00a9559b          	srliw	a1,s2,0xa
    8000433e:	855a                	mv	a0,s6
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	7ac080e7          	jalr	1964(ra) # 80003aec <bmap>
    80004348:	0005059b          	sext.w	a1,a0
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	3aa080e7          	jalr	938(ra) # 800036f8 <bread>
    80004356:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004358:	3ff97513          	andi	a0,s2,1023
    8000435c:	40ad07bb          	subw	a5,s10,a0
    80004360:	414b873b          	subw	a4,s7,s4
    80004364:	89be                	mv	s3,a5
    80004366:	2781                	sext.w	a5,a5
    80004368:	0007069b          	sext.w	a3,a4
    8000436c:	f8f6f4e3          	bgeu	a3,a5,800042f4 <writei+0x4c>
    80004370:	89ba                	mv	s3,a4
    80004372:	b749                	j	800042f4 <writei+0x4c>
      brelse(bp);
    80004374:	8526                	mv	a0,s1
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	4b2080e7          	jalr	1202(ra) # 80003828 <brelse>
  }

  if(off > ip->size)
    8000437e:	04cb2783          	lw	a5,76(s6)
    80004382:	0127f463          	bgeu	a5,s2,8000438a <writei+0xe2>
    ip->size = off;
    80004386:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000438a:	855a                	mv	a0,s6
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	aa6080e7          	jalr	-1370(ra) # 80003e32 <iupdate>

  return tot;
    80004394:	000a051b          	sext.w	a0,s4
}
    80004398:	70a6                	ld	ra,104(sp)
    8000439a:	7406                	ld	s0,96(sp)
    8000439c:	64e6                	ld	s1,88(sp)
    8000439e:	6946                	ld	s2,80(sp)
    800043a0:	69a6                	ld	s3,72(sp)
    800043a2:	6a06                	ld	s4,64(sp)
    800043a4:	7ae2                	ld	s5,56(sp)
    800043a6:	7b42                	ld	s6,48(sp)
    800043a8:	7ba2                	ld	s7,40(sp)
    800043aa:	7c02                	ld	s8,32(sp)
    800043ac:	6ce2                	ld	s9,24(sp)
    800043ae:	6d42                	ld	s10,16(sp)
    800043b0:	6da2                	ld	s11,8(sp)
    800043b2:	6165                	addi	sp,sp,112
    800043b4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043b6:	8a5e                	mv	s4,s7
    800043b8:	bfc9                	j	8000438a <writei+0xe2>
    return -1;
    800043ba:	557d                	li	a0,-1
}
    800043bc:	8082                	ret
    return -1;
    800043be:	557d                	li	a0,-1
    800043c0:	bfe1                	j	80004398 <writei+0xf0>
    return -1;
    800043c2:	557d                	li	a0,-1
    800043c4:	bfd1                	j	80004398 <writei+0xf0>

00000000800043c6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043c6:	1141                	addi	sp,sp,-16
    800043c8:	e406                	sd	ra,8(sp)
    800043ca:	e022                	sd	s0,0(sp)
    800043cc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043ce:	4639                	li	a2,14
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	9c6080e7          	jalr	-1594(ra) # 80000d96 <strncmp>
}
    800043d8:	60a2                	ld	ra,8(sp)
    800043da:	6402                	ld	s0,0(sp)
    800043dc:	0141                	addi	sp,sp,16
    800043de:	8082                	ret

00000000800043e0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043e0:	7139                	addi	sp,sp,-64
    800043e2:	fc06                	sd	ra,56(sp)
    800043e4:	f822                	sd	s0,48(sp)
    800043e6:	f426                	sd	s1,40(sp)
    800043e8:	f04a                	sd	s2,32(sp)
    800043ea:	ec4e                	sd	s3,24(sp)
    800043ec:	e852                	sd	s4,16(sp)
    800043ee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043f0:	04451703          	lh	a4,68(a0)
    800043f4:	4785                	li	a5,1
    800043f6:	00f71a63          	bne	a4,a5,8000440a <dirlookup+0x2a>
    800043fa:	892a                	mv	s2,a0
    800043fc:	89ae                	mv	s3,a1
    800043fe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004400:	457c                	lw	a5,76(a0)
    80004402:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004404:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004406:	e79d                	bnez	a5,80004434 <dirlookup+0x54>
    80004408:	a8a5                	j	80004480 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000440a:	00005517          	auipc	a0,0x5
    8000440e:	48650513          	addi	a0,a0,1158 # 80009890 <syscalls+0x1a0>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	118080e7          	jalr	280(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000441a:	00005517          	auipc	a0,0x5
    8000441e:	48e50513          	addi	a0,a0,1166 # 800098a8 <syscalls+0x1b8>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	108080e7          	jalr	264(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442a:	24c1                	addiw	s1,s1,16
    8000442c:	04c92783          	lw	a5,76(s2)
    80004430:	04f4f763          	bgeu	s1,a5,8000447e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004434:	4741                	li	a4,16
    80004436:	86a6                	mv	a3,s1
    80004438:	fc040613          	addi	a2,s0,-64
    8000443c:	4581                	li	a1,0
    8000443e:	854a                	mv	a0,s2
    80004440:	00000097          	auipc	ra,0x0
    80004444:	d70080e7          	jalr	-656(ra) # 800041b0 <readi>
    80004448:	47c1                	li	a5,16
    8000444a:	fcf518e3          	bne	a0,a5,8000441a <dirlookup+0x3a>
    if(de.inum == 0)
    8000444e:	fc045783          	lhu	a5,-64(s0)
    80004452:	dfe1                	beqz	a5,8000442a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004454:	fc240593          	addi	a1,s0,-62
    80004458:	854e                	mv	a0,s3
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	f6c080e7          	jalr	-148(ra) # 800043c6 <namecmp>
    80004462:	f561                	bnez	a0,8000442a <dirlookup+0x4a>
      if(poff)
    80004464:	000a0463          	beqz	s4,8000446c <dirlookup+0x8c>
        *poff = off;
    80004468:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000446c:	fc045583          	lhu	a1,-64(s0)
    80004470:	00092503          	lw	a0,0(s2)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	754080e7          	jalr	1876(ra) # 80003bc8 <iget>
    8000447c:	a011                	j	80004480 <dirlookup+0xa0>
  return 0;
    8000447e:	4501                	li	a0,0
}
    80004480:	70e2                	ld	ra,56(sp)
    80004482:	7442                	ld	s0,48(sp)
    80004484:	74a2                	ld	s1,40(sp)
    80004486:	7902                	ld	s2,32(sp)
    80004488:	69e2                	ld	s3,24(sp)
    8000448a:	6a42                	ld	s4,16(sp)
    8000448c:	6121                	addi	sp,sp,64
    8000448e:	8082                	ret

0000000080004490 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004490:	711d                	addi	sp,sp,-96
    80004492:	ec86                	sd	ra,88(sp)
    80004494:	e8a2                	sd	s0,80(sp)
    80004496:	e4a6                	sd	s1,72(sp)
    80004498:	e0ca                	sd	s2,64(sp)
    8000449a:	fc4e                	sd	s3,56(sp)
    8000449c:	f852                	sd	s4,48(sp)
    8000449e:	f456                	sd	s5,40(sp)
    800044a0:	f05a                	sd	s6,32(sp)
    800044a2:	ec5e                	sd	s7,24(sp)
    800044a4:	e862                	sd	s8,16(sp)
    800044a6:	e466                	sd	s9,8(sp)
    800044a8:	1080                	addi	s0,sp,96
    800044aa:	84aa                	mv	s1,a0
    800044ac:	8aae                	mv	s5,a1
    800044ae:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044b0:	00054703          	lbu	a4,0(a0)
    800044b4:	02f00793          	li	a5,47
    800044b8:	02f70363          	beq	a4,a5,800044de <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	518080e7          	jalr	1304(ra) # 800019d4 <myproc>
    800044c4:	15053503          	ld	a0,336(a0)
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	9f6080e7          	jalr	-1546(ra) # 80003ebe <idup>
    800044d0:	89aa                	mv	s3,a0
  while(*path == '/')
    800044d2:	02f00913          	li	s2,47
  len = path - s;
    800044d6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044d8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044da:	4b85                	li	s7,1
    800044dc:	a865                	j	80004594 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044de:	4585                	li	a1,1
    800044e0:	4505                	li	a0,1
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	6e6080e7          	jalr	1766(ra) # 80003bc8 <iget>
    800044ea:	89aa                	mv	s3,a0
    800044ec:	b7dd                	j	800044d2 <namex+0x42>
      iunlockput(ip);
    800044ee:	854e                	mv	a0,s3
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	c6e080e7          	jalr	-914(ra) # 8000415e <iunlockput>
      return 0;
    800044f8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044fa:	854e                	mv	a0,s3
    800044fc:	60e6                	ld	ra,88(sp)
    800044fe:	6446                	ld	s0,80(sp)
    80004500:	64a6                	ld	s1,72(sp)
    80004502:	6906                	ld	s2,64(sp)
    80004504:	79e2                	ld	s3,56(sp)
    80004506:	7a42                	ld	s4,48(sp)
    80004508:	7aa2                	ld	s5,40(sp)
    8000450a:	7b02                	ld	s6,32(sp)
    8000450c:	6be2                	ld	s7,24(sp)
    8000450e:	6c42                	ld	s8,16(sp)
    80004510:	6ca2                	ld	s9,8(sp)
    80004512:	6125                	addi	sp,sp,96
    80004514:	8082                	ret
      iunlock(ip);
    80004516:	854e                	mv	a0,s3
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	aa6080e7          	jalr	-1370(ra) # 80003fbe <iunlock>
      return ip;
    80004520:	bfe9                	j	800044fa <namex+0x6a>
      iunlockput(ip);
    80004522:	854e                	mv	a0,s3
    80004524:	00000097          	auipc	ra,0x0
    80004528:	c3a080e7          	jalr	-966(ra) # 8000415e <iunlockput>
      return 0;
    8000452c:	89e6                	mv	s3,s9
    8000452e:	b7f1                	j	800044fa <namex+0x6a>
  len = path - s;
    80004530:	40b48633          	sub	a2,s1,a1
    80004534:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004538:	099c5463          	bge	s8,s9,800045c0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000453c:	4639                	li	a2,14
    8000453e:	8552                	mv	a0,s4
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	7da080e7          	jalr	2010(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004548:	0004c783          	lbu	a5,0(s1)
    8000454c:	01279763          	bne	a5,s2,8000455a <namex+0xca>
    path++;
    80004550:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004552:	0004c783          	lbu	a5,0(s1)
    80004556:	ff278de3          	beq	a5,s2,80004550 <namex+0xc0>
    ilock(ip);
    8000455a:	854e                	mv	a0,s3
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	9a0080e7          	jalr	-1632(ra) # 80003efc <ilock>
    if(ip->type != T_DIR){
    80004564:	04499783          	lh	a5,68(s3)
    80004568:	f97793e3          	bne	a5,s7,800044ee <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000456c:	000a8563          	beqz	s5,80004576 <namex+0xe6>
    80004570:	0004c783          	lbu	a5,0(s1)
    80004574:	d3cd                	beqz	a5,80004516 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004576:	865a                	mv	a2,s6
    80004578:	85d2                	mv	a1,s4
    8000457a:	854e                	mv	a0,s3
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	e64080e7          	jalr	-412(ra) # 800043e0 <dirlookup>
    80004584:	8caa                	mv	s9,a0
    80004586:	dd51                	beqz	a0,80004522 <namex+0x92>
    iunlockput(ip);
    80004588:	854e                	mv	a0,s3
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	bd4080e7          	jalr	-1068(ra) # 8000415e <iunlockput>
    ip = next;
    80004592:	89e6                	mv	s3,s9
  while(*path == '/')
    80004594:	0004c783          	lbu	a5,0(s1)
    80004598:	05279763          	bne	a5,s2,800045e6 <namex+0x156>
    path++;
    8000459c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000459e:	0004c783          	lbu	a5,0(s1)
    800045a2:	ff278de3          	beq	a5,s2,8000459c <namex+0x10c>
  if(*path == 0)
    800045a6:	c79d                	beqz	a5,800045d4 <namex+0x144>
    path++;
    800045a8:	85a6                	mv	a1,s1
  len = path - s;
    800045aa:	8cda                	mv	s9,s6
    800045ac:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800045ae:	01278963          	beq	a5,s2,800045c0 <namex+0x130>
    800045b2:	dfbd                	beqz	a5,80004530 <namex+0xa0>
    path++;
    800045b4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045b6:	0004c783          	lbu	a5,0(s1)
    800045ba:	ff279ce3          	bne	a5,s2,800045b2 <namex+0x122>
    800045be:	bf8d                	j	80004530 <namex+0xa0>
    memmove(name, s, len);
    800045c0:	2601                	sext.w	a2,a2
    800045c2:	8552                	mv	a0,s4
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	756080e7          	jalr	1878(ra) # 80000d1a <memmove>
    name[len] = 0;
    800045cc:	9cd2                	add	s9,s9,s4
    800045ce:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045d2:	bf9d                	j	80004548 <namex+0xb8>
  if(nameiparent){
    800045d4:	f20a83e3          	beqz	s5,800044fa <namex+0x6a>
    iput(ip);
    800045d8:	854e                	mv	a0,s3
    800045da:	00000097          	auipc	ra,0x0
    800045de:	adc080e7          	jalr	-1316(ra) # 800040b6 <iput>
    return 0;
    800045e2:	4981                	li	s3,0
    800045e4:	bf19                	j	800044fa <namex+0x6a>
  if(*path == 0)
    800045e6:	d7fd                	beqz	a5,800045d4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045e8:	0004c783          	lbu	a5,0(s1)
    800045ec:	85a6                	mv	a1,s1
    800045ee:	b7d1                	j	800045b2 <namex+0x122>

00000000800045f0 <dirlink>:
{
    800045f0:	7139                	addi	sp,sp,-64
    800045f2:	fc06                	sd	ra,56(sp)
    800045f4:	f822                	sd	s0,48(sp)
    800045f6:	f426                	sd	s1,40(sp)
    800045f8:	f04a                	sd	s2,32(sp)
    800045fa:	ec4e                	sd	s3,24(sp)
    800045fc:	e852                	sd	s4,16(sp)
    800045fe:	0080                	addi	s0,sp,64
    80004600:	892a                	mv	s2,a0
    80004602:	8a2e                	mv	s4,a1
    80004604:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004606:	4601                	li	a2,0
    80004608:	00000097          	auipc	ra,0x0
    8000460c:	dd8080e7          	jalr	-552(ra) # 800043e0 <dirlookup>
    80004610:	e93d                	bnez	a0,80004686 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004612:	04c92483          	lw	s1,76(s2)
    80004616:	c49d                	beqz	s1,80004644 <dirlink+0x54>
    80004618:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000461a:	4741                	li	a4,16
    8000461c:	86a6                	mv	a3,s1
    8000461e:	fc040613          	addi	a2,s0,-64
    80004622:	4581                	li	a1,0
    80004624:	854a                	mv	a0,s2
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	b8a080e7          	jalr	-1142(ra) # 800041b0 <readi>
    8000462e:	47c1                	li	a5,16
    80004630:	06f51163          	bne	a0,a5,80004692 <dirlink+0xa2>
    if(de.inum == 0)
    80004634:	fc045783          	lhu	a5,-64(s0)
    80004638:	c791                	beqz	a5,80004644 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000463a:	24c1                	addiw	s1,s1,16
    8000463c:	04c92783          	lw	a5,76(s2)
    80004640:	fcf4ede3          	bltu	s1,a5,8000461a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004644:	4639                	li	a2,14
    80004646:	85d2                	mv	a1,s4
    80004648:	fc240513          	addi	a0,s0,-62
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	786080e7          	jalr	1926(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004654:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004658:	4741                	li	a4,16
    8000465a:	86a6                	mv	a3,s1
    8000465c:	fc040613          	addi	a2,s0,-64
    80004660:	4581                	li	a1,0
    80004662:	854a                	mv	a0,s2
    80004664:	00000097          	auipc	ra,0x0
    80004668:	c44080e7          	jalr	-956(ra) # 800042a8 <writei>
    8000466c:	872a                	mv	a4,a0
    8000466e:	47c1                	li	a5,16
  return 0;
    80004670:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004672:	02f71863          	bne	a4,a5,800046a2 <dirlink+0xb2>
}
    80004676:	70e2                	ld	ra,56(sp)
    80004678:	7442                	ld	s0,48(sp)
    8000467a:	74a2                	ld	s1,40(sp)
    8000467c:	7902                	ld	s2,32(sp)
    8000467e:	69e2                	ld	s3,24(sp)
    80004680:	6a42                	ld	s4,16(sp)
    80004682:	6121                	addi	sp,sp,64
    80004684:	8082                	ret
    iput(ip);
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	a30080e7          	jalr	-1488(ra) # 800040b6 <iput>
    return -1;
    8000468e:	557d                	li	a0,-1
    80004690:	b7dd                	j	80004676 <dirlink+0x86>
      panic("dirlink read");
    80004692:	00005517          	auipc	a0,0x5
    80004696:	22650513          	addi	a0,a0,550 # 800098b8 <syscalls+0x1c8>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	e90080e7          	jalr	-368(ra) # 8000052a <panic>
    panic("dirlink");
    800046a2:	00005517          	auipc	a0,0x5
    800046a6:	39e50513          	addi	a0,a0,926 # 80009a40 <syscalls+0x350>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	e80080e7          	jalr	-384(ra) # 8000052a <panic>

00000000800046b2 <namei>:

struct inode*
namei(char *path)
{
    800046b2:	1101                	addi	sp,sp,-32
    800046b4:	ec06                	sd	ra,24(sp)
    800046b6:	e822                	sd	s0,16(sp)
    800046b8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046ba:	fe040613          	addi	a2,s0,-32
    800046be:	4581                	li	a1,0
    800046c0:	00000097          	auipc	ra,0x0
    800046c4:	dd0080e7          	jalr	-560(ra) # 80004490 <namex>
}
    800046c8:	60e2                	ld	ra,24(sp)
    800046ca:	6442                	ld	s0,16(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046d0:	1141                	addi	sp,sp,-16
    800046d2:	e406                	sd	ra,8(sp)
    800046d4:	e022                	sd	s0,0(sp)
    800046d6:	0800                	addi	s0,sp,16
    800046d8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046da:	4585                	li	a1,1
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	db4080e7          	jalr	-588(ra) # 80004490 <namex>
}
    800046e4:	60a2                	ld	ra,8(sp)
    800046e6:	6402                	ld	s0,0(sp)
    800046e8:	0141                	addi	sp,sp,16
    800046ea:	8082                	ret

00000000800046ec <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800046ec:	1101                	addi	sp,sp,-32
    800046ee:	ec22                	sd	s0,24(sp)
    800046f0:	1000                	addi	s0,sp,32
    800046f2:	872a                	mv	a4,a0
    800046f4:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800046f6:	00005797          	auipc	a5,0x5
    800046fa:	1d278793          	addi	a5,a5,466 # 800098c8 <syscalls+0x1d8>
    800046fe:	6394                	ld	a3,0(a5)
    80004700:	fed43023          	sd	a3,-32(s0)
    80004704:	0087d683          	lhu	a3,8(a5)
    80004708:	fed41423          	sh	a3,-24(s0)
    8000470c:	00a7c783          	lbu	a5,10(a5)
    80004710:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004714:	87ae                	mv	a5,a1
    if(i<0){
    80004716:	02074b63          	bltz	a4,8000474c <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    8000471a:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    8000471c:	4629                	li	a2,10
        ++p;
    8000471e:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004720:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004724:	feed                	bnez	a3,8000471e <itoa+0x32>
    *p = '\0';
    80004726:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    8000472a:	4629                	li	a2,10
    8000472c:	17fd                	addi	a5,a5,-1
    8000472e:	02c766bb          	remw	a3,a4,a2
    80004732:	ff040593          	addi	a1,s0,-16
    80004736:	96ae                	add	a3,a3,a1
    80004738:	ff06c683          	lbu	a3,-16(a3)
    8000473c:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004740:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004744:	f765                	bnez	a4,8000472c <itoa+0x40>
    return b;
}
    80004746:	6462                	ld	s0,24(sp)
    80004748:	6105                	addi	sp,sp,32
    8000474a:	8082                	ret
        *p++ = '-';
    8000474c:	00158793          	addi	a5,a1,1
    80004750:	02d00693          	li	a3,45
    80004754:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004758:	40e0073b          	negw	a4,a4
    8000475c:	bf7d                	j	8000471a <itoa+0x2e>

000000008000475e <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000475e:	711d                	addi	sp,sp,-96
    80004760:	ec86                	sd	ra,88(sp)
    80004762:	e8a2                	sd	s0,80(sp)
    80004764:	e4a6                	sd	s1,72(sp)
    80004766:	e0ca                	sd	s2,64(sp)
    80004768:	1080                	addi	s0,sp,96
    8000476a:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000476c:	4619                	li	a2,6
    8000476e:	00005597          	auipc	a1,0x5
    80004772:	16a58593          	addi	a1,a1,362 # 800098d8 <syscalls+0x1e8>
    80004776:	fd040513          	addi	a0,s0,-48
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	5a0080e7          	jalr	1440(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004782:	fd640593          	addi	a1,s0,-42
    80004786:	5888                	lw	a0,48(s1)
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	f64080e7          	jalr	-156(ra) # 800046ec <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004790:	1684b503          	ld	a0,360(s1)
    80004794:	16050763          	beqz	a0,80004902 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004798:	00001097          	auipc	ra,0x1
    8000479c:	918080e7          	jalr	-1768(ra) # 800050b0 <fileclose>

  begin_op();
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	444080e7          	jalr	1092(ra) # 80004be4 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800047a8:	fb040593          	addi	a1,s0,-80
    800047ac:	fd040513          	addi	a0,s0,-48
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	f20080e7          	jalr	-224(ra) # 800046d0 <nameiparent>
    800047b8:	892a                	mv	s2,a0
    800047ba:	cd69                	beqz	a0,80004894 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	740080e7          	jalr	1856(ra) # 80003efc <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800047c4:	00005597          	auipc	a1,0x5
    800047c8:	11c58593          	addi	a1,a1,284 # 800098e0 <syscalls+0x1f0>
    800047cc:	fb040513          	addi	a0,s0,-80
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	bf6080e7          	jalr	-1034(ra) # 800043c6 <namecmp>
    800047d8:	c57d                	beqz	a0,800048c6 <removeSwapFile+0x168>
    800047da:	00005597          	auipc	a1,0x5
    800047de:	10e58593          	addi	a1,a1,270 # 800098e8 <syscalls+0x1f8>
    800047e2:	fb040513          	addi	a0,s0,-80
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	be0080e7          	jalr	-1056(ra) # 800043c6 <namecmp>
    800047ee:	cd61                	beqz	a0,800048c6 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800047f0:	fac40613          	addi	a2,s0,-84
    800047f4:	fb040593          	addi	a1,s0,-80
    800047f8:	854a                	mv	a0,s2
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	be6080e7          	jalr	-1050(ra) # 800043e0 <dirlookup>
    80004802:	84aa                	mv	s1,a0
    80004804:	c169                	beqz	a0,800048c6 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	6f6080e7          	jalr	1782(ra) # 80003efc <ilock>

  if(ip->nlink < 1)
    8000480e:	04a49783          	lh	a5,74(s1)
    80004812:	08f05763          	blez	a5,800048a0 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004816:	04449703          	lh	a4,68(s1)
    8000481a:	4785                	li	a5,1
    8000481c:	08f70a63          	beq	a4,a5,800048b0 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004820:	4641                	li	a2,16
    80004822:	4581                	li	a1,0
    80004824:	fc040513          	addi	a0,s0,-64
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	496080e7          	jalr	1174(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004830:	4741                	li	a4,16
    80004832:	fac42683          	lw	a3,-84(s0)
    80004836:	fc040613          	addi	a2,s0,-64
    8000483a:	4581                	li	a1,0
    8000483c:	854a                	mv	a0,s2
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	a6a080e7          	jalr	-1430(ra) # 800042a8 <writei>
    80004846:	47c1                	li	a5,16
    80004848:	08f51a63          	bne	a0,a5,800048dc <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000484c:	04449703          	lh	a4,68(s1)
    80004850:	4785                	li	a5,1
    80004852:	08f70d63          	beq	a4,a5,800048ec <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004856:	854a                	mv	a0,s2
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	906080e7          	jalr	-1786(ra) # 8000415e <iunlockput>

  ip->nlink--;
    80004860:	04a4d783          	lhu	a5,74(s1)
    80004864:	37fd                	addiw	a5,a5,-1
    80004866:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000486a:	8526                	mv	a0,s1
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	5c6080e7          	jalr	1478(ra) # 80003e32 <iupdate>
  iunlockput(ip);
    80004874:	8526                	mv	a0,s1
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	8e8080e7          	jalr	-1816(ra) # 8000415e <iunlockput>

  end_op();
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	3e6080e7          	jalr	998(ra) # 80004c64 <end_op>

  return 0;
    80004886:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004888:	60e6                	ld	ra,88(sp)
    8000488a:	6446                	ld	s0,80(sp)
    8000488c:	64a6                	ld	s1,72(sp)
    8000488e:	6906                	ld	s2,64(sp)
    80004890:	6125                	addi	sp,sp,96
    80004892:	8082                	ret
    end_op();
    80004894:	00000097          	auipc	ra,0x0
    80004898:	3d0080e7          	jalr	976(ra) # 80004c64 <end_op>
    return -1;
    8000489c:	557d                	li	a0,-1
    8000489e:	b7ed                	j	80004888 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800048a0:	00005517          	auipc	a0,0x5
    800048a4:	05050513          	addi	a0,a0,80 # 800098f0 <syscalls+0x200>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	c82080e7          	jalr	-894(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048b0:	8526                	mv	a0,s1
    800048b2:	00002097          	auipc	ra,0x2
    800048b6:	866080e7          	jalr	-1946(ra) # 80006118 <isdirempty>
    800048ba:	f13d                	bnez	a0,80004820 <removeSwapFile+0xc2>
    iunlockput(ip);
    800048bc:	8526                	mv	a0,s1
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	8a0080e7          	jalr	-1888(ra) # 8000415e <iunlockput>
    iunlockput(dp);
    800048c6:	854a                	mv	a0,s2
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	896080e7          	jalr	-1898(ra) # 8000415e <iunlockput>
    end_op();
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	394080e7          	jalr	916(ra) # 80004c64 <end_op>
    return -1;
    800048d8:	557d                	li	a0,-1
    800048da:	b77d                	j	80004888 <removeSwapFile+0x12a>
    panic("unlink: writei");
    800048dc:	00005517          	auipc	a0,0x5
    800048e0:	02c50513          	addi	a0,a0,44 # 80009908 <syscalls+0x218>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	c46080e7          	jalr	-954(ra) # 8000052a <panic>
    dp->nlink--;
    800048ec:	04a95783          	lhu	a5,74(s2)
    800048f0:	37fd                	addiw	a5,a5,-1
    800048f2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800048f6:	854a                	mv	a0,s2
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	53a080e7          	jalr	1338(ra) # 80003e32 <iupdate>
    80004900:	bf99                	j	80004856 <removeSwapFile+0xf8>
    return -1;
    80004902:	557d                	li	a0,-1
    80004904:	b751                	j	80004888 <removeSwapFile+0x12a>

0000000080004906 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004906:	7179                	addi	sp,sp,-48
    80004908:	f406                	sd	ra,40(sp)
    8000490a:	f022                	sd	s0,32(sp)
    8000490c:	ec26                	sd	s1,24(sp)
    8000490e:	e84a                	sd	s2,16(sp)
    80004910:	1800                	addi	s0,sp,48
    80004912:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004914:	4619                	li	a2,6
    80004916:	00005597          	auipc	a1,0x5
    8000491a:	fc258593          	addi	a1,a1,-62 # 800098d8 <syscalls+0x1e8>
    8000491e:	fd040513          	addi	a0,s0,-48
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	3f8080e7          	jalr	1016(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000492a:	fd640593          	addi	a1,s0,-42
    8000492e:	5888                	lw	a0,48(s1)
    80004930:	00000097          	auipc	ra,0x0
    80004934:	dbc080e7          	jalr	-580(ra) # 800046ec <itoa>

  begin_op();
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	2ac080e7          	jalr	684(ra) # 80004be4 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004940:	4681                	li	a3,0
    80004942:	4601                	li	a2,0
    80004944:	4589                	li	a1,2
    80004946:	fd040513          	addi	a0,s0,-48
    8000494a:	00002097          	auipc	ra,0x2
    8000494e:	9c2080e7          	jalr	-1598(ra) # 8000630c <create>
    80004952:	892a                	mv	s2,a0
  iunlock(in);
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	66a080e7          	jalr	1642(ra) # 80003fbe <iunlock>
  p->swapFile = filealloc();
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	698080e7          	jalr	1688(ra) # 80004ff4 <filealloc>
    80004964:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004968:	cd1d                	beqz	a0,800049a6 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000496a:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000496e:	1684b703          	ld	a4,360(s1)
    80004972:	4789                	li	a5,2
    80004974:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004976:	1684b703          	ld	a4,360(s1)
    8000497a:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    8000497e:	1684b703          	ld	a4,360(s1)
    80004982:	4685                	li	a3,1
    80004984:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004988:	1684b703          	ld	a4,360(s1)
    8000498c:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004990:	00000097          	auipc	ra,0x0
    80004994:	2d4080e7          	jalr	724(ra) # 80004c64 <end_op>

    return 0;
}
    80004998:	4501                	li	a0,0
    8000499a:	70a2                	ld	ra,40(sp)
    8000499c:	7402                	ld	s0,32(sp)
    8000499e:	64e2                	ld	s1,24(sp)
    800049a0:	6942                	ld	s2,16(sp)
    800049a2:	6145                	addi	sp,sp,48
    800049a4:	8082                	ret
    panic("no slot for files on /store");
    800049a6:	00005517          	auipc	a0,0x5
    800049aa:	f7250513          	addi	a0,a0,-142 # 80009918 <syscalls+0x228>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	b7c080e7          	jalr	-1156(ra) # 8000052a <panic>

00000000800049b6 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049b6:	1141                	addi	sp,sp,-16
    800049b8:	e406                	sd	ra,8(sp)
    800049ba:	e022                	sd	s0,0(sp)
    800049bc:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049be:	16853783          	ld	a5,360(a0)
    800049c2:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800049c4:	8636                	mv	a2,a3
    800049c6:	16853503          	ld	a0,360(a0)
    800049ca:	00001097          	auipc	ra,0x1
    800049ce:	ad8080e7          	jalr	-1320(ra) # 800054a2 <kfilewrite>
}
    800049d2:	60a2                	ld	ra,8(sp)
    800049d4:	6402                	ld	s0,0(sp)
    800049d6:	0141                	addi	sp,sp,16
    800049d8:	8082                	ret

00000000800049da <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049da:	1141                	addi	sp,sp,-16
    800049dc:	e406                	sd	ra,8(sp)
    800049de:	e022                	sd	s0,0(sp)
    800049e0:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049e2:	16853783          	ld	a5,360(a0)
    800049e6:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800049e8:	8636                	mv	a2,a3
    800049ea:	16853503          	ld	a0,360(a0)
    800049ee:	00001097          	auipc	ra,0x1
    800049f2:	9f2080e7          	jalr	-1550(ra) # 800053e0 <kfileread>
    800049f6:	60a2                	ld	ra,8(sp)
    800049f8:	6402                	ld	s0,0(sp)
    800049fa:	0141                	addi	sp,sp,16
    800049fc:	8082                	ret

00000000800049fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049fe:	1101                	addi	sp,sp,-32
    80004a00:	ec06                	sd	ra,24(sp)
    80004a02:	e822                	sd	s0,16(sp)
    80004a04:	e426                	sd	s1,8(sp)
    80004a06:	e04a                	sd	s2,0(sp)
    80004a08:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a0a:	00026917          	auipc	s2,0x26
    80004a0e:	c6690913          	addi	s2,s2,-922 # 8002a670 <log>
    80004a12:	01892583          	lw	a1,24(s2)
    80004a16:	02892503          	lw	a0,40(s2)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	cde080e7          	jalr	-802(ra) # 800036f8 <bread>
    80004a22:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a24:	02c92683          	lw	a3,44(s2)
    80004a28:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a2a:	02d05863          	blez	a3,80004a5a <write_head+0x5c>
    80004a2e:	00026797          	auipc	a5,0x26
    80004a32:	c7278793          	addi	a5,a5,-910 # 8002a6a0 <log+0x30>
    80004a36:	05c50713          	addi	a4,a0,92
    80004a3a:	36fd                	addiw	a3,a3,-1
    80004a3c:	02069613          	slli	a2,a3,0x20
    80004a40:	01e65693          	srli	a3,a2,0x1e
    80004a44:	00026617          	auipc	a2,0x26
    80004a48:	c6060613          	addi	a2,a2,-928 # 8002a6a4 <log+0x34>
    80004a4c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a4e:	4390                	lw	a2,0(a5)
    80004a50:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a52:	0791                	addi	a5,a5,4
    80004a54:	0711                	addi	a4,a4,4
    80004a56:	fed79ce3          	bne	a5,a3,80004a4e <write_head+0x50>
  }
  bwrite(buf);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	d8e080e7          	jalr	-626(ra) # 800037ea <bwrite>
  brelse(buf);
    80004a64:	8526                	mv	a0,s1
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	dc2080e7          	jalr	-574(ra) # 80003828 <brelse>
}
    80004a6e:	60e2                	ld	ra,24(sp)
    80004a70:	6442                	ld	s0,16(sp)
    80004a72:	64a2                	ld	s1,8(sp)
    80004a74:	6902                	ld	s2,0(sp)
    80004a76:	6105                	addi	sp,sp,32
    80004a78:	8082                	ret

0000000080004a7a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a7a:	00026797          	auipc	a5,0x26
    80004a7e:	c227a783          	lw	a5,-990(a5) # 8002a69c <log+0x2c>
    80004a82:	0af05d63          	blez	a5,80004b3c <install_trans+0xc2>
{
    80004a86:	7139                	addi	sp,sp,-64
    80004a88:	fc06                	sd	ra,56(sp)
    80004a8a:	f822                	sd	s0,48(sp)
    80004a8c:	f426                	sd	s1,40(sp)
    80004a8e:	f04a                	sd	s2,32(sp)
    80004a90:	ec4e                	sd	s3,24(sp)
    80004a92:	e852                	sd	s4,16(sp)
    80004a94:	e456                	sd	s5,8(sp)
    80004a96:	e05a                	sd	s6,0(sp)
    80004a98:	0080                	addi	s0,sp,64
    80004a9a:	8b2a                	mv	s6,a0
    80004a9c:	00026a97          	auipc	s5,0x26
    80004aa0:	c04a8a93          	addi	s5,s5,-1020 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aa4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004aa6:	00026997          	auipc	s3,0x26
    80004aaa:	bca98993          	addi	s3,s3,-1078 # 8002a670 <log>
    80004aae:	a00d                	j	80004ad0 <install_trans+0x56>
    brelse(lbuf);
    80004ab0:	854a                	mv	a0,s2
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	d76080e7          	jalr	-650(ra) # 80003828 <brelse>
    brelse(dbuf);
    80004aba:	8526                	mv	a0,s1
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	d6c080e7          	jalr	-660(ra) # 80003828 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ac4:	2a05                	addiw	s4,s4,1
    80004ac6:	0a91                	addi	s5,s5,4
    80004ac8:	02c9a783          	lw	a5,44(s3)
    80004acc:	04fa5e63          	bge	s4,a5,80004b28 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ad0:	0189a583          	lw	a1,24(s3)
    80004ad4:	014585bb          	addw	a1,a1,s4
    80004ad8:	2585                	addiw	a1,a1,1
    80004ada:	0289a503          	lw	a0,40(s3)
    80004ade:	fffff097          	auipc	ra,0xfffff
    80004ae2:	c1a080e7          	jalr	-998(ra) # 800036f8 <bread>
    80004ae6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004ae8:	000aa583          	lw	a1,0(s5)
    80004aec:	0289a503          	lw	a0,40(s3)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	c08080e7          	jalr	-1016(ra) # 800036f8 <bread>
    80004af8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004afa:	40000613          	li	a2,1024
    80004afe:	05890593          	addi	a1,s2,88
    80004b02:	05850513          	addi	a0,a0,88
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	214080e7          	jalr	532(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b0e:	8526                	mv	a0,s1
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	cda080e7          	jalr	-806(ra) # 800037ea <bwrite>
    if(recovering == 0)
    80004b18:	f80b1ce3          	bnez	s6,80004ab0 <install_trans+0x36>
      bunpin(dbuf);
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	de4080e7          	jalr	-540(ra) # 80003902 <bunpin>
    80004b26:	b769                	j	80004ab0 <install_trans+0x36>
}
    80004b28:	70e2                	ld	ra,56(sp)
    80004b2a:	7442                	ld	s0,48(sp)
    80004b2c:	74a2                	ld	s1,40(sp)
    80004b2e:	7902                	ld	s2,32(sp)
    80004b30:	69e2                	ld	s3,24(sp)
    80004b32:	6a42                	ld	s4,16(sp)
    80004b34:	6aa2                	ld	s5,8(sp)
    80004b36:	6b02                	ld	s6,0(sp)
    80004b38:	6121                	addi	sp,sp,64
    80004b3a:	8082                	ret
    80004b3c:	8082                	ret

0000000080004b3e <initlog>:
{
    80004b3e:	7179                	addi	sp,sp,-48
    80004b40:	f406                	sd	ra,40(sp)
    80004b42:	f022                	sd	s0,32(sp)
    80004b44:	ec26                	sd	s1,24(sp)
    80004b46:	e84a                	sd	s2,16(sp)
    80004b48:	e44e                	sd	s3,8(sp)
    80004b4a:	1800                	addi	s0,sp,48
    80004b4c:	892a                	mv	s2,a0
    80004b4e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b50:	00026497          	auipc	s1,0x26
    80004b54:	b2048493          	addi	s1,s1,-1248 # 8002a670 <log>
    80004b58:	00005597          	auipc	a1,0x5
    80004b5c:	de058593          	addi	a1,a1,-544 # 80009938 <syscalls+0x248>
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	fd0080e7          	jalr	-48(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004b6a:	0149a583          	lw	a1,20(s3)
    80004b6e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b70:	0109a783          	lw	a5,16(s3)
    80004b74:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b76:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b7a:	854a                	mv	a0,s2
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	b7c080e7          	jalr	-1156(ra) # 800036f8 <bread>
  log.lh.n = lh->n;
    80004b84:	4d34                	lw	a3,88(a0)
    80004b86:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b88:	02d05663          	blez	a3,80004bb4 <initlog+0x76>
    80004b8c:	05c50793          	addi	a5,a0,92
    80004b90:	00026717          	auipc	a4,0x26
    80004b94:	b1070713          	addi	a4,a4,-1264 # 8002a6a0 <log+0x30>
    80004b98:	36fd                	addiw	a3,a3,-1
    80004b9a:	02069613          	slli	a2,a3,0x20
    80004b9e:	01e65693          	srli	a3,a2,0x1e
    80004ba2:	06050613          	addi	a2,a0,96
    80004ba6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004ba8:	4390                	lw	a2,0(a5)
    80004baa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bac:	0791                	addi	a5,a5,4
    80004bae:	0711                	addi	a4,a4,4
    80004bb0:	fed79ce3          	bne	a5,a3,80004ba8 <initlog+0x6a>
  brelse(buf);
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	c74080e7          	jalr	-908(ra) # 80003828 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004bbc:	4505                	li	a0,1
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	ebc080e7          	jalr	-324(ra) # 80004a7a <install_trans>
  log.lh.n = 0;
    80004bc6:	00026797          	auipc	a5,0x26
    80004bca:	ac07ab23          	sw	zero,-1322(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004bce:	00000097          	auipc	ra,0x0
    80004bd2:	e30080e7          	jalr	-464(ra) # 800049fe <write_head>
}
    80004bd6:	70a2                	ld	ra,40(sp)
    80004bd8:	7402                	ld	s0,32(sp)
    80004bda:	64e2                	ld	s1,24(sp)
    80004bdc:	6942                	ld	s2,16(sp)
    80004bde:	69a2                	ld	s3,8(sp)
    80004be0:	6145                	addi	sp,sp,48
    80004be2:	8082                	ret

0000000080004be4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004be4:	1101                	addi	sp,sp,-32
    80004be6:	ec06                	sd	ra,24(sp)
    80004be8:	e822                	sd	s0,16(sp)
    80004bea:	e426                	sd	s1,8(sp)
    80004bec:	e04a                	sd	s2,0(sp)
    80004bee:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004bf0:	00026517          	auipc	a0,0x26
    80004bf4:	a8050513          	addi	a0,a0,-1408 # 8002a670 <log>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	fca080e7          	jalr	-54(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004c00:	00026497          	auipc	s1,0x26
    80004c04:	a7048493          	addi	s1,s1,-1424 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c08:	4979                	li	s2,30
    80004c0a:	a039                	j	80004c18 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c0c:	85a6                	mv	a1,s1
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	3e6080e7          	jalr	998(ra) # 80001ff6 <sleep>
    if(log.committing){
    80004c18:	50dc                	lw	a5,36(s1)
    80004c1a:	fbed                	bnez	a5,80004c0c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c1c:	509c                	lw	a5,32(s1)
    80004c1e:	0017871b          	addiw	a4,a5,1
    80004c22:	0007069b          	sext.w	a3,a4
    80004c26:	0027179b          	slliw	a5,a4,0x2
    80004c2a:	9fb9                	addw	a5,a5,a4
    80004c2c:	0017979b          	slliw	a5,a5,0x1
    80004c30:	54d8                	lw	a4,44(s1)
    80004c32:	9fb9                	addw	a5,a5,a4
    80004c34:	00f95963          	bge	s2,a5,80004c46 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c38:	85a6                	mv	a1,s1
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	3ba080e7          	jalr	954(ra) # 80001ff6 <sleep>
    80004c44:	bfd1                	j	80004c18 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004c46:	00026517          	auipc	a0,0x26
    80004c4a:	a2a50513          	addi	a0,a0,-1494 # 8002a670 <log>
    80004c4e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	026080e7          	jalr	38(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6902                	ld	s2,0(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret

0000000080004c64 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c64:	7139                	addi	sp,sp,-64
    80004c66:	fc06                	sd	ra,56(sp)
    80004c68:	f822                	sd	s0,48(sp)
    80004c6a:	f426                	sd	s1,40(sp)
    80004c6c:	f04a                	sd	s2,32(sp)
    80004c6e:	ec4e                	sd	s3,24(sp)
    80004c70:	e852                	sd	s4,16(sp)
    80004c72:	e456                	sd	s5,8(sp)
    80004c74:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004c76:	00026497          	auipc	s1,0x26
    80004c7a:	9fa48493          	addi	s1,s1,-1542 # 8002a670 <log>
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	f42080e7          	jalr	-190(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004c88:	509c                	lw	a5,32(s1)
    80004c8a:	37fd                	addiw	a5,a5,-1
    80004c8c:	0007891b          	sext.w	s2,a5
    80004c90:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c92:	50dc                	lw	a5,36(s1)
    80004c94:	e7b9                	bnez	a5,80004ce2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c96:	04091e63          	bnez	s2,80004cf2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c9a:	00026497          	auipc	s1,0x26
    80004c9e:	9d648493          	addi	s1,s1,-1578 # 8002a670 <log>
    80004ca2:	4785                	li	a5,1
    80004ca4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	fce080e7          	jalr	-50(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004cb0:	54dc                	lw	a5,44(s1)
    80004cb2:	06f04763          	bgtz	a5,80004d20 <end_op+0xbc>
    acquire(&log.lock);
    80004cb6:	00026497          	auipc	s1,0x26
    80004cba:	9ba48493          	addi	s1,s1,-1606 # 8002a670 <log>
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	f02080e7          	jalr	-254(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004cc8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	38c080e7          	jalr	908(ra) # 8000205a <wakeup>
    release(&log.lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	f9e080e7          	jalr	-98(ra) # 80000c76 <release>
}
    80004ce0:	a03d                	j	80004d0e <end_op+0xaa>
    panic("log.committing");
    80004ce2:	00005517          	auipc	a0,0x5
    80004ce6:	c5e50513          	addi	a0,a0,-930 # 80009940 <syscalls+0x250>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	840080e7          	jalr	-1984(ra) # 8000052a <panic>
    wakeup(&log);
    80004cf2:	00026497          	auipc	s1,0x26
    80004cf6:	97e48493          	addi	s1,s1,-1666 # 8002a670 <log>
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	35e080e7          	jalr	862(ra) # 8000205a <wakeup>
  release(&log.lock);
    80004d04:	8526                	mv	a0,s1
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	f70080e7          	jalr	-144(ra) # 80000c76 <release>
}
    80004d0e:	70e2                	ld	ra,56(sp)
    80004d10:	7442                	ld	s0,48(sp)
    80004d12:	74a2                	ld	s1,40(sp)
    80004d14:	7902                	ld	s2,32(sp)
    80004d16:	69e2                	ld	s3,24(sp)
    80004d18:	6a42                	ld	s4,16(sp)
    80004d1a:	6aa2                	ld	s5,8(sp)
    80004d1c:	6121                	addi	sp,sp,64
    80004d1e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d20:	00026a97          	auipc	s5,0x26
    80004d24:	980a8a93          	addi	s5,s5,-1664 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d28:	00026a17          	auipc	s4,0x26
    80004d2c:	948a0a13          	addi	s4,s4,-1720 # 8002a670 <log>
    80004d30:	018a2583          	lw	a1,24(s4)
    80004d34:	012585bb          	addw	a1,a1,s2
    80004d38:	2585                	addiw	a1,a1,1
    80004d3a:	028a2503          	lw	a0,40(s4)
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	9ba080e7          	jalr	-1606(ra) # 800036f8 <bread>
    80004d46:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d48:	000aa583          	lw	a1,0(s5)
    80004d4c:	028a2503          	lw	a0,40(s4)
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	9a8080e7          	jalr	-1624(ra) # 800036f8 <bread>
    80004d58:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d5a:	40000613          	li	a2,1024
    80004d5e:	05850593          	addi	a1,a0,88
    80004d62:	05848513          	addi	a0,s1,88
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	fb4080e7          	jalr	-76(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004d6e:	8526                	mv	a0,s1
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	a7a080e7          	jalr	-1414(ra) # 800037ea <bwrite>
    brelse(from);
    80004d78:	854e                	mv	a0,s3
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	aae080e7          	jalr	-1362(ra) # 80003828 <brelse>
    brelse(to);
    80004d82:	8526                	mv	a0,s1
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	aa4080e7          	jalr	-1372(ra) # 80003828 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d8c:	2905                	addiw	s2,s2,1
    80004d8e:	0a91                	addi	s5,s5,4
    80004d90:	02ca2783          	lw	a5,44(s4)
    80004d94:	f8f94ee3          	blt	s2,a5,80004d30 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d98:	00000097          	auipc	ra,0x0
    80004d9c:	c66080e7          	jalr	-922(ra) # 800049fe <write_head>
    install_trans(0); // Now install writes to home locations
    80004da0:	4501                	li	a0,0
    80004da2:	00000097          	auipc	ra,0x0
    80004da6:	cd8080e7          	jalr	-808(ra) # 80004a7a <install_trans>
    log.lh.n = 0;
    80004daa:	00026797          	auipc	a5,0x26
    80004dae:	8e07a923          	sw	zero,-1806(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004db2:	00000097          	auipc	ra,0x0
    80004db6:	c4c080e7          	jalr	-948(ra) # 800049fe <write_head>
    80004dba:	bdf5                	j	80004cb6 <end_op+0x52>

0000000080004dbc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004dbc:	1101                	addi	sp,sp,-32
    80004dbe:	ec06                	sd	ra,24(sp)
    80004dc0:	e822                	sd	s0,16(sp)
    80004dc2:	e426                	sd	s1,8(sp)
    80004dc4:	e04a                	sd	s2,0(sp)
    80004dc6:	1000                	addi	s0,sp,32
    80004dc8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004dca:	00026917          	auipc	s2,0x26
    80004dce:	8a690913          	addi	s2,s2,-1882 # 8002a670 <log>
    80004dd2:	854a                	mv	a0,s2
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	dee080e7          	jalr	-530(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ddc:	02c92603          	lw	a2,44(s2)
    80004de0:	47f5                	li	a5,29
    80004de2:	06c7c563          	blt	a5,a2,80004e4c <log_write+0x90>
    80004de6:	00026797          	auipc	a5,0x26
    80004dea:	8a67a783          	lw	a5,-1882(a5) # 8002a68c <log+0x1c>
    80004dee:	37fd                	addiw	a5,a5,-1
    80004df0:	04f65e63          	bge	a2,a5,80004e4c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004df4:	00026797          	auipc	a5,0x26
    80004df8:	89c7a783          	lw	a5,-1892(a5) # 8002a690 <log+0x20>
    80004dfc:	06f05063          	blez	a5,80004e5c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e00:	4781                	li	a5,0
    80004e02:	06c05563          	blez	a2,80004e6c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e06:	44cc                	lw	a1,12(s1)
    80004e08:	00026717          	auipc	a4,0x26
    80004e0c:	89870713          	addi	a4,a4,-1896 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e10:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e12:	4314                	lw	a3,0(a4)
    80004e14:	04b68c63          	beq	a3,a1,80004e6c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e18:	2785                	addiw	a5,a5,1
    80004e1a:	0711                	addi	a4,a4,4
    80004e1c:	fef61be3          	bne	a2,a5,80004e12 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e20:	0621                	addi	a2,a2,8
    80004e22:	060a                	slli	a2,a2,0x2
    80004e24:	00026797          	auipc	a5,0x26
    80004e28:	84c78793          	addi	a5,a5,-1972 # 8002a670 <log>
    80004e2c:	963e                	add	a2,a2,a5
    80004e2e:	44dc                	lw	a5,12(s1)
    80004e30:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e32:	8526                	mv	a0,s1
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	a92080e7          	jalr	-1390(ra) # 800038c6 <bpin>
    log.lh.n++;
    80004e3c:	00026717          	auipc	a4,0x26
    80004e40:	83470713          	addi	a4,a4,-1996 # 8002a670 <log>
    80004e44:	575c                	lw	a5,44(a4)
    80004e46:	2785                	addiw	a5,a5,1
    80004e48:	d75c                	sw	a5,44(a4)
    80004e4a:	a835                	j	80004e86 <log_write+0xca>
    panic("too big a transaction");
    80004e4c:	00005517          	auipc	a0,0x5
    80004e50:	b0450513          	addi	a0,a0,-1276 # 80009950 <syscalls+0x260>
    80004e54:	ffffb097          	auipc	ra,0xffffb
    80004e58:	6d6080e7          	jalr	1750(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004e5c:	00005517          	auipc	a0,0x5
    80004e60:	b0c50513          	addi	a0,a0,-1268 # 80009968 <syscalls+0x278>
    80004e64:	ffffb097          	auipc	ra,0xffffb
    80004e68:	6c6080e7          	jalr	1734(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004e6c:	00878713          	addi	a4,a5,8
    80004e70:	00271693          	slli	a3,a4,0x2
    80004e74:	00025717          	auipc	a4,0x25
    80004e78:	7fc70713          	addi	a4,a4,2044 # 8002a670 <log>
    80004e7c:	9736                	add	a4,a4,a3
    80004e7e:	44d4                	lw	a3,12(s1)
    80004e80:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e82:	faf608e3          	beq	a2,a5,80004e32 <log_write+0x76>
  }
  release(&log.lock);
    80004e86:	00025517          	auipc	a0,0x25
    80004e8a:	7ea50513          	addi	a0,a0,2026 # 8002a670 <log>
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	de8080e7          	jalr	-536(ra) # 80000c76 <release>
}
    80004e96:	60e2                	ld	ra,24(sp)
    80004e98:	6442                	ld	s0,16(sp)
    80004e9a:	64a2                	ld	s1,8(sp)
    80004e9c:	6902                	ld	s2,0(sp)
    80004e9e:	6105                	addi	sp,sp,32
    80004ea0:	8082                	ret

0000000080004ea2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ea2:	1101                	addi	sp,sp,-32
    80004ea4:	ec06                	sd	ra,24(sp)
    80004ea6:	e822                	sd	s0,16(sp)
    80004ea8:	e426                	sd	s1,8(sp)
    80004eaa:	e04a                	sd	s2,0(sp)
    80004eac:	1000                	addi	s0,sp,32
    80004eae:	84aa                	mv	s1,a0
    80004eb0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004eb2:	00005597          	auipc	a1,0x5
    80004eb6:	ad658593          	addi	a1,a1,-1322 # 80009988 <syscalls+0x298>
    80004eba:	0521                	addi	a0,a0,8
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	c76080e7          	jalr	-906(ra) # 80000b32 <initlock>
  lk->name = name;
    80004ec4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ec8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ecc:	0204a423          	sw	zero,40(s1)
}
    80004ed0:	60e2                	ld	ra,24(sp)
    80004ed2:	6442                	ld	s0,16(sp)
    80004ed4:	64a2                	ld	s1,8(sp)
    80004ed6:	6902                	ld	s2,0(sp)
    80004ed8:	6105                	addi	sp,sp,32
    80004eda:	8082                	ret

0000000080004edc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004edc:	1101                	addi	sp,sp,-32
    80004ede:	ec06                	sd	ra,24(sp)
    80004ee0:	e822                	sd	s0,16(sp)
    80004ee2:	e426                	sd	s1,8(sp)
    80004ee4:	e04a                	sd	s2,0(sp)
    80004ee6:	1000                	addi	s0,sp,32
    80004ee8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004eea:	00850913          	addi	s2,a0,8
    80004eee:	854a                	mv	a0,s2
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	cd2080e7          	jalr	-814(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004ef8:	409c                	lw	a5,0(s1)
    80004efa:	cb89                	beqz	a5,80004f0c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004efc:	85ca                	mv	a1,s2
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	0f6080e7          	jalr	246(ra) # 80001ff6 <sleep>
  while (lk->locked) {
    80004f08:	409c                	lw	a5,0(s1)
    80004f0a:	fbed                	bnez	a5,80004efc <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f0c:	4785                	li	a5,1
    80004f0e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	ac4080e7          	jalr	-1340(ra) # 800019d4 <myproc>
    80004f18:	591c                	lw	a5,48(a0)
    80004f1a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f1c:	854a                	mv	a0,s2
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	d58080e7          	jalr	-680(ra) # 80000c76 <release>
}
    80004f26:	60e2                	ld	ra,24(sp)
    80004f28:	6442                	ld	s0,16(sp)
    80004f2a:	64a2                	ld	s1,8(sp)
    80004f2c:	6902                	ld	s2,0(sp)
    80004f2e:	6105                	addi	sp,sp,32
    80004f30:	8082                	ret

0000000080004f32 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f32:	1101                	addi	sp,sp,-32
    80004f34:	ec06                	sd	ra,24(sp)
    80004f36:	e822                	sd	s0,16(sp)
    80004f38:	e426                	sd	s1,8(sp)
    80004f3a:	e04a                	sd	s2,0(sp)
    80004f3c:	1000                	addi	s0,sp,32
    80004f3e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f40:	00850913          	addi	s2,a0,8
    80004f44:	854a                	mv	a0,s2
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	c7c080e7          	jalr	-900(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004f4e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f52:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f56:	8526                	mv	a0,s1
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	102080e7          	jalr	258(ra) # 8000205a <wakeup>
  release(&lk->lk);
    80004f60:	854a                	mv	a0,s2
    80004f62:	ffffc097          	auipc	ra,0xffffc
    80004f66:	d14080e7          	jalr	-748(ra) # 80000c76 <release>
}
    80004f6a:	60e2                	ld	ra,24(sp)
    80004f6c:	6442                	ld	s0,16(sp)
    80004f6e:	64a2                	ld	s1,8(sp)
    80004f70:	6902                	ld	s2,0(sp)
    80004f72:	6105                	addi	sp,sp,32
    80004f74:	8082                	ret

0000000080004f76 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004f76:	7179                	addi	sp,sp,-48
    80004f78:	f406                	sd	ra,40(sp)
    80004f7a:	f022                	sd	s0,32(sp)
    80004f7c:	ec26                	sd	s1,24(sp)
    80004f7e:	e84a                	sd	s2,16(sp)
    80004f80:	e44e                	sd	s3,8(sp)
    80004f82:	1800                	addi	s0,sp,48
    80004f84:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f86:	00850913          	addi	s2,a0,8
    80004f8a:	854a                	mv	a0,s2
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	c36080e7          	jalr	-970(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f94:	409c                	lw	a5,0(s1)
    80004f96:	ef99                	bnez	a5,80004fb4 <holdingsleep+0x3e>
    80004f98:	4481                	li	s1,0
  release(&lk->lk);
    80004f9a:	854a                	mv	a0,s2
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	cda080e7          	jalr	-806(ra) # 80000c76 <release>
  return r;
}
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	70a2                	ld	ra,40(sp)
    80004fa8:	7402                	ld	s0,32(sp)
    80004faa:	64e2                	ld	s1,24(sp)
    80004fac:	6942                	ld	s2,16(sp)
    80004fae:	69a2                	ld	s3,8(sp)
    80004fb0:	6145                	addi	sp,sp,48
    80004fb2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fb4:	0284a983          	lw	s3,40(s1)
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	a1c080e7          	jalr	-1508(ra) # 800019d4 <myproc>
    80004fc0:	5904                	lw	s1,48(a0)
    80004fc2:	413484b3          	sub	s1,s1,s3
    80004fc6:	0014b493          	seqz	s1,s1
    80004fca:	bfc1                	j	80004f9a <holdingsleep+0x24>

0000000080004fcc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004fcc:	1141                	addi	sp,sp,-16
    80004fce:	e406                	sd	ra,8(sp)
    80004fd0:	e022                	sd	s0,0(sp)
    80004fd2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004fd4:	00005597          	auipc	a1,0x5
    80004fd8:	9c458593          	addi	a1,a1,-1596 # 80009998 <syscalls+0x2a8>
    80004fdc:	00025517          	auipc	a0,0x25
    80004fe0:	7dc50513          	addi	a0,a0,2012 # 8002a7b8 <ftable>
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	b4e080e7          	jalr	-1202(ra) # 80000b32 <initlock>
}
    80004fec:	60a2                	ld	ra,8(sp)
    80004fee:	6402                	ld	s0,0(sp)
    80004ff0:	0141                	addi	sp,sp,16
    80004ff2:	8082                	ret

0000000080004ff4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ff4:	1101                	addi	sp,sp,-32
    80004ff6:	ec06                	sd	ra,24(sp)
    80004ff8:	e822                	sd	s0,16(sp)
    80004ffa:	e426                	sd	s1,8(sp)
    80004ffc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ffe:	00025517          	auipc	a0,0x25
    80005002:	7ba50513          	addi	a0,a0,1978 # 8002a7b8 <ftable>
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	bbc080e7          	jalr	-1092(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000500e:	00025497          	auipc	s1,0x25
    80005012:	7c248493          	addi	s1,s1,1986 # 8002a7d0 <ftable+0x18>
    80005016:	00026717          	auipc	a4,0x26
    8000501a:	75a70713          	addi	a4,a4,1882 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    8000501e:	40dc                	lw	a5,4(s1)
    80005020:	cf99                	beqz	a5,8000503e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005022:	02848493          	addi	s1,s1,40
    80005026:	fee49ce3          	bne	s1,a4,8000501e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000502a:	00025517          	auipc	a0,0x25
    8000502e:	78e50513          	addi	a0,a0,1934 # 8002a7b8 <ftable>
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	c44080e7          	jalr	-956(ra) # 80000c76 <release>
  return 0;
    8000503a:	4481                	li	s1,0
    8000503c:	a819                	j	80005052 <filealloc+0x5e>
      f->ref = 1;
    8000503e:	4785                	li	a5,1
    80005040:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005042:	00025517          	auipc	a0,0x25
    80005046:	77650513          	addi	a0,a0,1910 # 8002a7b8 <ftable>
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	c2c080e7          	jalr	-980(ra) # 80000c76 <release>
}
    80005052:	8526                	mv	a0,s1
    80005054:	60e2                	ld	ra,24(sp)
    80005056:	6442                	ld	s0,16(sp)
    80005058:	64a2                	ld	s1,8(sp)
    8000505a:	6105                	addi	sp,sp,32
    8000505c:	8082                	ret

000000008000505e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000505e:	1101                	addi	sp,sp,-32
    80005060:	ec06                	sd	ra,24(sp)
    80005062:	e822                	sd	s0,16(sp)
    80005064:	e426                	sd	s1,8(sp)
    80005066:	1000                	addi	s0,sp,32
    80005068:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000506a:	00025517          	auipc	a0,0x25
    8000506e:	74e50513          	addi	a0,a0,1870 # 8002a7b8 <ftable>
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	b50080e7          	jalr	-1200(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000507a:	40dc                	lw	a5,4(s1)
    8000507c:	02f05263          	blez	a5,800050a0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005080:	2785                	addiw	a5,a5,1
    80005082:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005084:	00025517          	auipc	a0,0x25
    80005088:	73450513          	addi	a0,a0,1844 # 8002a7b8 <ftable>
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	bea080e7          	jalr	-1046(ra) # 80000c76 <release>
  return f;
}
    80005094:	8526                	mv	a0,s1
    80005096:	60e2                	ld	ra,24(sp)
    80005098:	6442                	ld	s0,16(sp)
    8000509a:	64a2                	ld	s1,8(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret
    panic("filedup");
    800050a0:	00005517          	auipc	a0,0x5
    800050a4:	90050513          	addi	a0,a0,-1792 # 800099a0 <syscalls+0x2b0>
    800050a8:	ffffb097          	auipc	ra,0xffffb
    800050ac:	482080e7          	jalr	1154(ra) # 8000052a <panic>

00000000800050b0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800050b0:	7139                	addi	sp,sp,-64
    800050b2:	fc06                	sd	ra,56(sp)
    800050b4:	f822                	sd	s0,48(sp)
    800050b6:	f426                	sd	s1,40(sp)
    800050b8:	f04a                	sd	s2,32(sp)
    800050ba:	ec4e                	sd	s3,24(sp)
    800050bc:	e852                	sd	s4,16(sp)
    800050be:	e456                	sd	s5,8(sp)
    800050c0:	0080                	addi	s0,sp,64
    800050c2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800050c4:	00025517          	auipc	a0,0x25
    800050c8:	6f450513          	addi	a0,a0,1780 # 8002a7b8 <ftable>
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	af6080e7          	jalr	-1290(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800050d4:	40dc                	lw	a5,4(s1)
    800050d6:	06f05163          	blez	a5,80005138 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800050da:	37fd                	addiw	a5,a5,-1
    800050dc:	0007871b          	sext.w	a4,a5
    800050e0:	c0dc                	sw	a5,4(s1)
    800050e2:	06e04363          	bgtz	a4,80005148 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800050e6:	0004a903          	lw	s2,0(s1)
    800050ea:	0094ca83          	lbu	s5,9(s1)
    800050ee:	0104ba03          	ld	s4,16(s1)
    800050f2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800050f6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800050fa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800050fe:	00025517          	auipc	a0,0x25
    80005102:	6ba50513          	addi	a0,a0,1722 # 8002a7b8 <ftable>
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	b70080e7          	jalr	-1168(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000510e:	4785                	li	a5,1
    80005110:	04f90d63          	beq	s2,a5,8000516a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005114:	3979                	addiw	s2,s2,-2
    80005116:	4785                	li	a5,1
    80005118:	0527e063          	bltu	a5,s2,80005158 <fileclose+0xa8>
    begin_op();
    8000511c:	00000097          	auipc	ra,0x0
    80005120:	ac8080e7          	jalr	-1336(ra) # 80004be4 <begin_op>
    iput(ff.ip);
    80005124:	854e                	mv	a0,s3
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	f90080e7          	jalr	-112(ra) # 800040b6 <iput>
    end_op();
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	b36080e7          	jalr	-1226(ra) # 80004c64 <end_op>
    80005136:	a00d                	j	80005158 <fileclose+0xa8>
    panic("fileclose");
    80005138:	00005517          	auipc	a0,0x5
    8000513c:	87050513          	addi	a0,a0,-1936 # 800099a8 <syscalls+0x2b8>
    80005140:	ffffb097          	auipc	ra,0xffffb
    80005144:	3ea080e7          	jalr	1002(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005148:	00025517          	auipc	a0,0x25
    8000514c:	67050513          	addi	a0,a0,1648 # 8002a7b8 <ftable>
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	b26080e7          	jalr	-1242(ra) # 80000c76 <release>
  }
}
    80005158:	70e2                	ld	ra,56(sp)
    8000515a:	7442                	ld	s0,48(sp)
    8000515c:	74a2                	ld	s1,40(sp)
    8000515e:	7902                	ld	s2,32(sp)
    80005160:	69e2                	ld	s3,24(sp)
    80005162:	6a42                	ld	s4,16(sp)
    80005164:	6aa2                	ld	s5,8(sp)
    80005166:	6121                	addi	sp,sp,64
    80005168:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000516a:	85d6                	mv	a1,s5
    8000516c:	8552                	mv	a0,s4
    8000516e:	00000097          	auipc	ra,0x0
    80005172:	542080e7          	jalr	1346(ra) # 800056b0 <pipeclose>
    80005176:	b7cd                	j	80005158 <fileclose+0xa8>

0000000080005178 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005178:	715d                	addi	sp,sp,-80
    8000517a:	e486                	sd	ra,72(sp)
    8000517c:	e0a2                	sd	s0,64(sp)
    8000517e:	fc26                	sd	s1,56(sp)
    80005180:	f84a                	sd	s2,48(sp)
    80005182:	f44e                	sd	s3,40(sp)
    80005184:	0880                	addi	s0,sp,80
    80005186:	84aa                	mv	s1,a0
    80005188:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	84a080e7          	jalr	-1974(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005192:	409c                	lw	a5,0(s1)
    80005194:	37f9                	addiw	a5,a5,-2
    80005196:	4705                	li	a4,1
    80005198:	04f76763          	bltu	a4,a5,800051e6 <filestat+0x6e>
    8000519c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000519e:	6c88                	ld	a0,24(s1)
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	d5c080e7          	jalr	-676(ra) # 80003efc <ilock>
    stati(f->ip, &st);
    800051a8:	fb840593          	addi	a1,s0,-72
    800051ac:	6c88                	ld	a0,24(s1)
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	fd8080e7          	jalr	-40(ra) # 80004186 <stati>
    iunlock(f->ip);
    800051b6:	6c88                	ld	a0,24(s1)
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	e06080e7          	jalr	-506(ra) # 80003fbe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800051c0:	46e1                	li	a3,24
    800051c2:	fb840613          	addi	a2,s0,-72
    800051c6:	85ce                	mv	a1,s3
    800051c8:	05093503          	ld	a0,80(s2)
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	4c8080e7          	jalr	1224(ra) # 80001694 <copyout>
    800051d4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800051d8:	60a6                	ld	ra,72(sp)
    800051da:	6406                	ld	s0,64(sp)
    800051dc:	74e2                	ld	s1,56(sp)
    800051de:	7942                	ld	s2,48(sp)
    800051e0:	79a2                	ld	s3,40(sp)
    800051e2:	6161                	addi	sp,sp,80
    800051e4:	8082                	ret
  return -1;
    800051e6:	557d                	li	a0,-1
    800051e8:	bfc5                	j	800051d8 <filestat+0x60>

00000000800051ea <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800051ea:	7179                	addi	sp,sp,-48
    800051ec:	f406                	sd	ra,40(sp)
    800051ee:	f022                	sd	s0,32(sp)
    800051f0:	ec26                	sd	s1,24(sp)
    800051f2:	e84a                	sd	s2,16(sp)
    800051f4:	e44e                	sd	s3,8(sp)
    800051f6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800051f8:	00854783          	lbu	a5,8(a0)
    800051fc:	c3d5                	beqz	a5,800052a0 <fileread+0xb6>
    800051fe:	84aa                	mv	s1,a0
    80005200:	89ae                	mv	s3,a1
    80005202:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005204:	411c                	lw	a5,0(a0)
    80005206:	4705                	li	a4,1
    80005208:	04e78963          	beq	a5,a4,8000525a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000520c:	470d                	li	a4,3
    8000520e:	04e78d63          	beq	a5,a4,80005268 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005212:	4709                	li	a4,2
    80005214:	06e79e63          	bne	a5,a4,80005290 <fileread+0xa6>
    ilock(f->ip);
    80005218:	6d08                	ld	a0,24(a0)
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	ce2080e7          	jalr	-798(ra) # 80003efc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005222:	874a                	mv	a4,s2
    80005224:	5094                	lw	a3,32(s1)
    80005226:	864e                	mv	a2,s3
    80005228:	4585                	li	a1,1
    8000522a:	6c88                	ld	a0,24(s1)
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	f84080e7          	jalr	-124(ra) # 800041b0 <readi>
    80005234:	892a                	mv	s2,a0
    80005236:	00a05563          	blez	a0,80005240 <fileread+0x56>
      f->off += r;
    8000523a:	509c                	lw	a5,32(s1)
    8000523c:	9fa9                	addw	a5,a5,a0
    8000523e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005240:	6c88                	ld	a0,24(s1)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	d7c080e7          	jalr	-644(ra) # 80003fbe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000524a:	854a                	mv	a0,s2
    8000524c:	70a2                	ld	ra,40(sp)
    8000524e:	7402                	ld	s0,32(sp)
    80005250:	64e2                	ld	s1,24(sp)
    80005252:	6942                	ld	s2,16(sp)
    80005254:	69a2                	ld	s3,8(sp)
    80005256:	6145                	addi	sp,sp,48
    80005258:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000525a:	6908                	ld	a0,16(a0)
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	5b6080e7          	jalr	1462(ra) # 80005812 <piperead>
    80005264:	892a                	mv	s2,a0
    80005266:	b7d5                	j	8000524a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005268:	02451783          	lh	a5,36(a0)
    8000526c:	03079693          	slli	a3,a5,0x30
    80005270:	92c1                	srli	a3,a3,0x30
    80005272:	4725                	li	a4,9
    80005274:	02d76863          	bltu	a4,a3,800052a4 <fileread+0xba>
    80005278:	0792                	slli	a5,a5,0x4
    8000527a:	00025717          	auipc	a4,0x25
    8000527e:	49e70713          	addi	a4,a4,1182 # 8002a718 <devsw>
    80005282:	97ba                	add	a5,a5,a4
    80005284:	639c                	ld	a5,0(a5)
    80005286:	c38d                	beqz	a5,800052a8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005288:	4505                	li	a0,1
    8000528a:	9782                	jalr	a5
    8000528c:	892a                	mv	s2,a0
    8000528e:	bf75                	j	8000524a <fileread+0x60>
    panic("fileread");
    80005290:	00004517          	auipc	a0,0x4
    80005294:	72850513          	addi	a0,a0,1832 # 800099b8 <syscalls+0x2c8>
    80005298:	ffffb097          	auipc	ra,0xffffb
    8000529c:	292080e7          	jalr	658(ra) # 8000052a <panic>
    return -1;
    800052a0:	597d                	li	s2,-1
    800052a2:	b765                	j	8000524a <fileread+0x60>
      return -1;
    800052a4:	597d                	li	s2,-1
    800052a6:	b755                	j	8000524a <fileread+0x60>
    800052a8:	597d                	li	s2,-1
    800052aa:	b745                	j	8000524a <fileread+0x60>

00000000800052ac <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800052ac:	715d                	addi	sp,sp,-80
    800052ae:	e486                	sd	ra,72(sp)
    800052b0:	e0a2                	sd	s0,64(sp)
    800052b2:	fc26                	sd	s1,56(sp)
    800052b4:	f84a                	sd	s2,48(sp)
    800052b6:	f44e                	sd	s3,40(sp)
    800052b8:	f052                	sd	s4,32(sp)
    800052ba:	ec56                	sd	s5,24(sp)
    800052bc:	e85a                	sd	s6,16(sp)
    800052be:	e45e                	sd	s7,8(sp)
    800052c0:	e062                	sd	s8,0(sp)
    800052c2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800052c4:	00954783          	lbu	a5,9(a0)
    800052c8:	10078663          	beqz	a5,800053d4 <filewrite+0x128>
    800052cc:	892a                	mv	s2,a0
    800052ce:	8aae                	mv	s5,a1
    800052d0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800052d2:	411c                	lw	a5,0(a0)
    800052d4:	4705                	li	a4,1
    800052d6:	02e78263          	beq	a5,a4,800052fa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052da:	470d                	li	a4,3
    800052dc:	02e78663          	beq	a5,a4,80005308 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800052e0:	4709                	li	a4,2
    800052e2:	0ee79163          	bne	a5,a4,800053c4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800052e6:	0ac05d63          	blez	a2,800053a0 <filewrite+0xf4>
    int i = 0;
    800052ea:	4981                	li	s3,0
    800052ec:	6b05                	lui	s6,0x1
    800052ee:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800052f2:	6b85                	lui	s7,0x1
    800052f4:	c00b8b9b          	addiw	s7,s7,-1024
    800052f8:	a861                	j	80005390 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052fa:	6908                	ld	a0,16(a0)
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	424080e7          	jalr	1060(ra) # 80005720 <pipewrite>
    80005304:	8a2a                	mv	s4,a0
    80005306:	a045                	j	800053a6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005308:	02451783          	lh	a5,36(a0)
    8000530c:	03079693          	slli	a3,a5,0x30
    80005310:	92c1                	srli	a3,a3,0x30
    80005312:	4725                	li	a4,9
    80005314:	0cd76263          	bltu	a4,a3,800053d8 <filewrite+0x12c>
    80005318:	0792                	slli	a5,a5,0x4
    8000531a:	00025717          	auipc	a4,0x25
    8000531e:	3fe70713          	addi	a4,a4,1022 # 8002a718 <devsw>
    80005322:	97ba                	add	a5,a5,a4
    80005324:	679c                	ld	a5,8(a5)
    80005326:	cbdd                	beqz	a5,800053dc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005328:	4505                	li	a0,1
    8000532a:	9782                	jalr	a5
    8000532c:	8a2a                	mv	s4,a0
    8000532e:	a8a5                	j	800053a6 <filewrite+0xfa>
    80005330:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005334:	00000097          	auipc	ra,0x0
    80005338:	8b0080e7          	jalr	-1872(ra) # 80004be4 <begin_op>
      ilock(f->ip);
    8000533c:	01893503          	ld	a0,24(s2)
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	bbc080e7          	jalr	-1092(ra) # 80003efc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005348:	8762                	mv	a4,s8
    8000534a:	02092683          	lw	a3,32(s2)
    8000534e:	01598633          	add	a2,s3,s5
    80005352:	4585                	li	a1,1
    80005354:	01893503          	ld	a0,24(s2)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	f50080e7          	jalr	-176(ra) # 800042a8 <writei>
    80005360:	84aa                	mv	s1,a0
    80005362:	00a05763          	blez	a0,80005370 <filewrite+0xc4>
        f->off += r;
    80005366:	02092783          	lw	a5,32(s2)
    8000536a:	9fa9                	addw	a5,a5,a0
    8000536c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005370:	01893503          	ld	a0,24(s2)
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	c4a080e7          	jalr	-950(ra) # 80003fbe <iunlock>
      end_op();
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	8e8080e7          	jalr	-1816(ra) # 80004c64 <end_op>

      if(r != n1){
    80005384:	009c1f63          	bne	s8,s1,800053a2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005388:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000538c:	0149db63          	bge	s3,s4,800053a2 <filewrite+0xf6>
      int n1 = n - i;
    80005390:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005394:	84be                	mv	s1,a5
    80005396:	2781                	sext.w	a5,a5
    80005398:	f8fb5ce3          	bge	s6,a5,80005330 <filewrite+0x84>
    8000539c:	84de                	mv	s1,s7
    8000539e:	bf49                	j	80005330 <filewrite+0x84>
    int i = 0;
    800053a0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053a2:	013a1f63          	bne	s4,s3,800053c0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800053a6:	8552                	mv	a0,s4
    800053a8:	60a6                	ld	ra,72(sp)
    800053aa:	6406                	ld	s0,64(sp)
    800053ac:	74e2                	ld	s1,56(sp)
    800053ae:	7942                	ld	s2,48(sp)
    800053b0:	79a2                	ld	s3,40(sp)
    800053b2:	7a02                	ld	s4,32(sp)
    800053b4:	6ae2                	ld	s5,24(sp)
    800053b6:	6b42                	ld	s6,16(sp)
    800053b8:	6ba2                	ld	s7,8(sp)
    800053ba:	6c02                	ld	s8,0(sp)
    800053bc:	6161                	addi	sp,sp,80
    800053be:	8082                	ret
    ret = (i == n ? n : -1);
    800053c0:	5a7d                	li	s4,-1
    800053c2:	b7d5                	j	800053a6 <filewrite+0xfa>
    panic("filewrite");
    800053c4:	00004517          	auipc	a0,0x4
    800053c8:	60450513          	addi	a0,a0,1540 # 800099c8 <syscalls+0x2d8>
    800053cc:	ffffb097          	auipc	ra,0xffffb
    800053d0:	15e080e7          	jalr	350(ra) # 8000052a <panic>
    return -1;
    800053d4:	5a7d                	li	s4,-1
    800053d6:	bfc1                	j	800053a6 <filewrite+0xfa>
      return -1;
    800053d8:	5a7d                	li	s4,-1
    800053da:	b7f1                	j	800053a6 <filewrite+0xfa>
    800053dc:	5a7d                	li	s4,-1
    800053de:	b7e1                	j	800053a6 <filewrite+0xfa>

00000000800053e0 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800053e0:	7179                	addi	sp,sp,-48
    800053e2:	f406                	sd	ra,40(sp)
    800053e4:	f022                	sd	s0,32(sp)
    800053e6:	ec26                	sd	s1,24(sp)
    800053e8:	e84a                	sd	s2,16(sp)
    800053ea:	e44e                	sd	s3,8(sp)
    800053ec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800053ee:	00854783          	lbu	a5,8(a0)
    800053f2:	c3d5                	beqz	a5,80005496 <kfileread+0xb6>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	89ae                	mv	s3,a1
    800053f8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053fa:	411c                	lw	a5,0(a0)
    800053fc:	4705                	li	a4,1
    800053fe:	04e78963          	beq	a5,a4,80005450 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005402:	470d                	li	a4,3
    80005404:	04e78d63          	beq	a5,a4,8000545e <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005408:	4709                	li	a4,2
    8000540a:	06e79e63          	bne	a5,a4,80005486 <kfileread+0xa6>
    ilock(f->ip);
    8000540e:	6d08                	ld	a0,24(a0)
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	aec080e7          	jalr	-1300(ra) # 80003efc <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005418:	874a                	mv	a4,s2
    8000541a:	5094                	lw	a3,32(s1)
    8000541c:	864e                	mv	a2,s3
    8000541e:	4581                	li	a1,0
    80005420:	6c88                	ld	a0,24(s1)
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	d8e080e7          	jalr	-626(ra) # 800041b0 <readi>
    8000542a:	892a                	mv	s2,a0
    8000542c:	00a05563          	blez	a0,80005436 <kfileread+0x56>
      f->off += r;
    80005430:	509c                	lw	a5,32(s1)
    80005432:	9fa9                	addw	a5,a5,a0
    80005434:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005436:	6c88                	ld	a0,24(s1)
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	b86080e7          	jalr	-1146(ra) # 80003fbe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005440:	854a                	mv	a0,s2
    80005442:	70a2                	ld	ra,40(sp)
    80005444:	7402                	ld	s0,32(sp)
    80005446:	64e2                	ld	s1,24(sp)
    80005448:	6942                	ld	s2,16(sp)
    8000544a:	69a2                	ld	s3,8(sp)
    8000544c:	6145                	addi	sp,sp,48
    8000544e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005450:	6908                	ld	a0,16(a0)
    80005452:	00000097          	auipc	ra,0x0
    80005456:	3c0080e7          	jalr	960(ra) # 80005812 <piperead>
    8000545a:	892a                	mv	s2,a0
    8000545c:	b7d5                	j	80005440 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000545e:	02451783          	lh	a5,36(a0)
    80005462:	03079693          	slli	a3,a5,0x30
    80005466:	92c1                	srli	a3,a3,0x30
    80005468:	4725                	li	a4,9
    8000546a:	02d76863          	bltu	a4,a3,8000549a <kfileread+0xba>
    8000546e:	0792                	slli	a5,a5,0x4
    80005470:	00025717          	auipc	a4,0x25
    80005474:	2a870713          	addi	a4,a4,680 # 8002a718 <devsw>
    80005478:	97ba                	add	a5,a5,a4
    8000547a:	639c                	ld	a5,0(a5)
    8000547c:	c38d                	beqz	a5,8000549e <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000547e:	4505                	li	a0,1
    80005480:	9782                	jalr	a5
    80005482:	892a                	mv	s2,a0
    80005484:	bf75                	j	80005440 <kfileread+0x60>
    panic("fileread");
    80005486:	00004517          	auipc	a0,0x4
    8000548a:	53250513          	addi	a0,a0,1330 # 800099b8 <syscalls+0x2c8>
    8000548e:	ffffb097          	auipc	ra,0xffffb
    80005492:	09c080e7          	jalr	156(ra) # 8000052a <panic>
    return -1;
    80005496:	597d                	li	s2,-1
    80005498:	b765                	j	80005440 <kfileread+0x60>
      return -1;
    8000549a:	597d                	li	s2,-1
    8000549c:	b755                	j	80005440 <kfileread+0x60>
    8000549e:	597d                	li	s2,-1
    800054a0:	b745                	j	80005440 <kfileread+0x60>

00000000800054a2 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800054a2:	715d                	addi	sp,sp,-80
    800054a4:	e486                	sd	ra,72(sp)
    800054a6:	e0a2                	sd	s0,64(sp)
    800054a8:	fc26                	sd	s1,56(sp)
    800054aa:	f84a                	sd	s2,48(sp)
    800054ac:	f44e                	sd	s3,40(sp)
    800054ae:	f052                	sd	s4,32(sp)
    800054b0:	ec56                	sd	s5,24(sp)
    800054b2:	e85a                	sd	s6,16(sp)
    800054b4:	e45e                	sd	s7,8(sp)
    800054b6:	e062                	sd	s8,0(sp)
    800054b8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800054ba:	00954783          	lbu	a5,9(a0)
    800054be:	10078663          	beqz	a5,800055ca <kfilewrite+0x128>
    800054c2:	892a                	mv	s2,a0
    800054c4:	8aae                	mv	s5,a1
    800054c6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800054c8:	411c                	lw	a5,0(a0)
    800054ca:	4705                	li	a4,1
    800054cc:	02e78263          	beq	a5,a4,800054f0 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054d0:	470d                	li	a4,3
    800054d2:	02e78663          	beq	a5,a4,800054fe <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800054d6:	4709                	li	a4,2
    800054d8:	0ee79163          	bne	a5,a4,800055ba <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800054dc:	0ac05d63          	blez	a2,80005596 <kfilewrite+0xf4>
    int i = 0;
    800054e0:	4981                	li	s3,0
    800054e2:	6b05                	lui	s6,0x1
    800054e4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800054e8:	6b85                	lui	s7,0x1
    800054ea:	c00b8b9b          	addiw	s7,s7,-1024
    800054ee:	a861                	j	80005586 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800054f0:	6908                	ld	a0,16(a0)
    800054f2:	00000097          	auipc	ra,0x0
    800054f6:	22e080e7          	jalr	558(ra) # 80005720 <pipewrite>
    800054fa:	8a2a                	mv	s4,a0
    800054fc:	a045                	j	8000559c <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800054fe:	02451783          	lh	a5,36(a0)
    80005502:	03079693          	slli	a3,a5,0x30
    80005506:	92c1                	srli	a3,a3,0x30
    80005508:	4725                	li	a4,9
    8000550a:	0cd76263          	bltu	a4,a3,800055ce <kfilewrite+0x12c>
    8000550e:	0792                	slli	a5,a5,0x4
    80005510:	00025717          	auipc	a4,0x25
    80005514:	20870713          	addi	a4,a4,520 # 8002a718 <devsw>
    80005518:	97ba                	add	a5,a5,a4
    8000551a:	679c                	ld	a5,8(a5)
    8000551c:	cbdd                	beqz	a5,800055d2 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000551e:	4505                	li	a0,1
    80005520:	9782                	jalr	a5
    80005522:	8a2a                	mv	s4,a0
    80005524:	a8a5                	j	8000559c <kfilewrite+0xfa>
    80005526:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	6ba080e7          	jalr	1722(ra) # 80004be4 <begin_op>
      ilock(f->ip);
    80005532:	01893503          	ld	a0,24(s2)
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	9c6080e7          	jalr	-1594(ra) # 80003efc <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    8000553e:	8762                	mv	a4,s8
    80005540:	02092683          	lw	a3,32(s2)
    80005544:	01598633          	add	a2,s3,s5
    80005548:	4581                	li	a1,0
    8000554a:	01893503          	ld	a0,24(s2)
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	d5a080e7          	jalr	-678(ra) # 800042a8 <writei>
    80005556:	84aa                	mv	s1,a0
    80005558:	00a05763          	blez	a0,80005566 <kfilewrite+0xc4>
        f->off += r;
    8000555c:	02092783          	lw	a5,32(s2)
    80005560:	9fa9                	addw	a5,a5,a0
    80005562:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005566:	01893503          	ld	a0,24(s2)
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	a54080e7          	jalr	-1452(ra) # 80003fbe <iunlock>
      end_op();
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	6f2080e7          	jalr	1778(ra) # 80004c64 <end_op>

      if(r != n1){
    8000557a:	009c1f63          	bne	s8,s1,80005598 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000557e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005582:	0149db63          	bge	s3,s4,80005598 <kfilewrite+0xf6>
      int n1 = n - i;
    80005586:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000558a:	84be                	mv	s1,a5
    8000558c:	2781                	sext.w	a5,a5
    8000558e:	f8fb5ce3          	bge	s6,a5,80005526 <kfilewrite+0x84>
    80005592:	84de                	mv	s1,s7
    80005594:	bf49                	j	80005526 <kfilewrite+0x84>
    int i = 0;
    80005596:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005598:	013a1f63          	bne	s4,s3,800055b6 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000559c:	8552                	mv	a0,s4
    8000559e:	60a6                	ld	ra,72(sp)
    800055a0:	6406                	ld	s0,64(sp)
    800055a2:	74e2                	ld	s1,56(sp)
    800055a4:	7942                	ld	s2,48(sp)
    800055a6:	79a2                	ld	s3,40(sp)
    800055a8:	7a02                	ld	s4,32(sp)
    800055aa:	6ae2                	ld	s5,24(sp)
    800055ac:	6b42                	ld	s6,16(sp)
    800055ae:	6ba2                	ld	s7,8(sp)
    800055b0:	6c02                	ld	s8,0(sp)
    800055b2:	6161                	addi	sp,sp,80
    800055b4:	8082                	ret
    ret = (i == n ? n : -1);
    800055b6:	5a7d                	li	s4,-1
    800055b8:	b7d5                	j	8000559c <kfilewrite+0xfa>
    panic("filewrite");
    800055ba:	00004517          	auipc	a0,0x4
    800055be:	40e50513          	addi	a0,a0,1038 # 800099c8 <syscalls+0x2d8>
    800055c2:	ffffb097          	auipc	ra,0xffffb
    800055c6:	f68080e7          	jalr	-152(ra) # 8000052a <panic>
    return -1;
    800055ca:	5a7d                	li	s4,-1
    800055cc:	bfc1                	j	8000559c <kfilewrite+0xfa>
      return -1;
    800055ce:	5a7d                	li	s4,-1
    800055d0:	b7f1                	j	8000559c <kfilewrite+0xfa>
    800055d2:	5a7d                	li	s4,-1
    800055d4:	b7e1                	j	8000559c <kfilewrite+0xfa>

00000000800055d6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800055d6:	7179                	addi	sp,sp,-48
    800055d8:	f406                	sd	ra,40(sp)
    800055da:	f022                	sd	s0,32(sp)
    800055dc:	ec26                	sd	s1,24(sp)
    800055de:	e84a                	sd	s2,16(sp)
    800055e0:	e44e                	sd	s3,8(sp)
    800055e2:	e052                	sd	s4,0(sp)
    800055e4:	1800                	addi	s0,sp,48
    800055e6:	84aa                	mv	s1,a0
    800055e8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800055ea:	0005b023          	sd	zero,0(a1)
    800055ee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800055f2:	00000097          	auipc	ra,0x0
    800055f6:	a02080e7          	jalr	-1534(ra) # 80004ff4 <filealloc>
    800055fa:	e088                	sd	a0,0(s1)
    800055fc:	c551                	beqz	a0,80005688 <pipealloc+0xb2>
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	9f6080e7          	jalr	-1546(ra) # 80004ff4 <filealloc>
    80005606:	00aa3023          	sd	a0,0(s4)
    8000560a:	c92d                	beqz	a0,8000567c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	4c6080e7          	jalr	1222(ra) # 80000ad2 <kalloc>
    80005614:	892a                	mv	s2,a0
    80005616:	c125                	beqz	a0,80005676 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005618:	4985                	li	s3,1
    8000561a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000561e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005622:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005626:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000562a:	00004597          	auipc	a1,0x4
    8000562e:	3ae58593          	addi	a1,a1,942 # 800099d8 <syscalls+0x2e8>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	500080e7          	jalr	1280(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    8000563a:	609c                	ld	a5,0(s1)
    8000563c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005640:	609c                	ld	a5,0(s1)
    80005642:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005646:	609c                	ld	a5,0(s1)
    80005648:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000564c:	609c                	ld	a5,0(s1)
    8000564e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005652:	000a3783          	ld	a5,0(s4)
    80005656:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000565a:	000a3783          	ld	a5,0(s4)
    8000565e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005662:	000a3783          	ld	a5,0(s4)
    80005666:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000566a:	000a3783          	ld	a5,0(s4)
    8000566e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005672:	4501                	li	a0,0
    80005674:	a025                	j	8000569c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005676:	6088                	ld	a0,0(s1)
    80005678:	e501                	bnez	a0,80005680 <pipealloc+0xaa>
    8000567a:	a039                	j	80005688 <pipealloc+0xb2>
    8000567c:	6088                	ld	a0,0(s1)
    8000567e:	c51d                	beqz	a0,800056ac <pipealloc+0xd6>
    fileclose(*f0);
    80005680:	00000097          	auipc	ra,0x0
    80005684:	a30080e7          	jalr	-1488(ra) # 800050b0 <fileclose>
  if(*f1)
    80005688:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000568c:	557d                	li	a0,-1
  if(*f1)
    8000568e:	c799                	beqz	a5,8000569c <pipealloc+0xc6>
    fileclose(*f1);
    80005690:	853e                	mv	a0,a5
    80005692:	00000097          	auipc	ra,0x0
    80005696:	a1e080e7          	jalr	-1506(ra) # 800050b0 <fileclose>
  return -1;
    8000569a:	557d                	li	a0,-1
}
    8000569c:	70a2                	ld	ra,40(sp)
    8000569e:	7402                	ld	s0,32(sp)
    800056a0:	64e2                	ld	s1,24(sp)
    800056a2:	6942                	ld	s2,16(sp)
    800056a4:	69a2                	ld	s3,8(sp)
    800056a6:	6a02                	ld	s4,0(sp)
    800056a8:	6145                	addi	sp,sp,48
    800056aa:	8082                	ret
  return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	b7fd                	j	8000569c <pipealloc+0xc6>

00000000800056b0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800056b0:	1101                	addi	sp,sp,-32
    800056b2:	ec06                	sd	ra,24(sp)
    800056b4:	e822                	sd	s0,16(sp)
    800056b6:	e426                	sd	s1,8(sp)
    800056b8:	e04a                	sd	s2,0(sp)
    800056ba:	1000                	addi	s0,sp,32
    800056bc:	84aa                	mv	s1,a0
    800056be:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	502080e7          	jalr	1282(ra) # 80000bc2 <acquire>
  if(writable){
    800056c8:	02090d63          	beqz	s2,80005702 <pipeclose+0x52>
    pi->writeopen = 0;
    800056cc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800056d0:	21848513          	addi	a0,s1,536
    800056d4:	ffffd097          	auipc	ra,0xffffd
    800056d8:	986080e7          	jalr	-1658(ra) # 8000205a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800056dc:	2204b783          	ld	a5,544(s1)
    800056e0:	eb95                	bnez	a5,80005714 <pipeclose+0x64>
    release(&pi->lock);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffb097          	auipc	ra,0xffffb
    800056e8:	592080e7          	jalr	1426(ra) # 80000c76 <release>
    kfree((char*)pi);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	2e8080e7          	jalr	744(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800056f6:	60e2                	ld	ra,24(sp)
    800056f8:	6442                	ld	s0,16(sp)
    800056fa:	64a2                	ld	s1,8(sp)
    800056fc:	6902                	ld	s2,0(sp)
    800056fe:	6105                	addi	sp,sp,32
    80005700:	8082                	ret
    pi->readopen = 0;
    80005702:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005706:	21c48513          	addi	a0,s1,540
    8000570a:	ffffd097          	auipc	ra,0xffffd
    8000570e:	950080e7          	jalr	-1712(ra) # 8000205a <wakeup>
    80005712:	b7e9                	j	800056dc <pipeclose+0x2c>
    release(&pi->lock);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	560080e7          	jalr	1376(ra) # 80000c76 <release>
}
    8000571e:	bfe1                	j	800056f6 <pipeclose+0x46>

0000000080005720 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005720:	711d                	addi	sp,sp,-96
    80005722:	ec86                	sd	ra,88(sp)
    80005724:	e8a2                	sd	s0,80(sp)
    80005726:	e4a6                	sd	s1,72(sp)
    80005728:	e0ca                	sd	s2,64(sp)
    8000572a:	fc4e                	sd	s3,56(sp)
    8000572c:	f852                	sd	s4,48(sp)
    8000572e:	f456                	sd	s5,40(sp)
    80005730:	f05a                	sd	s6,32(sp)
    80005732:	ec5e                	sd	s7,24(sp)
    80005734:	e862                	sd	s8,16(sp)
    80005736:	1080                	addi	s0,sp,96
    80005738:	84aa                	mv	s1,a0
    8000573a:	8aae                	mv	s5,a1
    8000573c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000573e:	ffffc097          	auipc	ra,0xffffc
    80005742:	296080e7          	jalr	662(ra) # 800019d4 <myproc>
    80005746:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffb097          	auipc	ra,0xffffb
    8000574e:	478080e7          	jalr	1144(ra) # 80000bc2 <acquire>
  while(i < n){
    80005752:	0b405363          	blez	s4,800057f8 <pipewrite+0xd8>
  int i = 0;
    80005756:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005758:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000575a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000575e:	21c48b93          	addi	s7,s1,540
    80005762:	a089                	j	800057a4 <pipewrite+0x84>
      release(&pi->lock);
    80005764:	8526                	mv	a0,s1
    80005766:	ffffb097          	auipc	ra,0xffffb
    8000576a:	510080e7          	jalr	1296(ra) # 80000c76 <release>
      return -1;
    8000576e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005770:	854a                	mv	a0,s2
    80005772:	60e6                	ld	ra,88(sp)
    80005774:	6446                	ld	s0,80(sp)
    80005776:	64a6                	ld	s1,72(sp)
    80005778:	6906                	ld	s2,64(sp)
    8000577a:	79e2                	ld	s3,56(sp)
    8000577c:	7a42                	ld	s4,48(sp)
    8000577e:	7aa2                	ld	s5,40(sp)
    80005780:	7b02                	ld	s6,32(sp)
    80005782:	6be2                	ld	s7,24(sp)
    80005784:	6c42                	ld	s8,16(sp)
    80005786:	6125                	addi	sp,sp,96
    80005788:	8082                	ret
      wakeup(&pi->nread);
    8000578a:	8562                	mv	a0,s8
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	8ce080e7          	jalr	-1842(ra) # 8000205a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005794:	85a6                	mv	a1,s1
    80005796:	855e                	mv	a0,s7
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	85e080e7          	jalr	-1954(ra) # 80001ff6 <sleep>
  while(i < n){
    800057a0:	05495d63          	bge	s2,s4,800057fa <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800057a4:	2204a783          	lw	a5,544(s1)
    800057a8:	dfd5                	beqz	a5,80005764 <pipewrite+0x44>
    800057aa:	0289a783          	lw	a5,40(s3)
    800057ae:	fbdd                	bnez	a5,80005764 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800057b0:	2184a783          	lw	a5,536(s1)
    800057b4:	21c4a703          	lw	a4,540(s1)
    800057b8:	2007879b          	addiw	a5,a5,512
    800057bc:	fcf707e3          	beq	a4,a5,8000578a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057c0:	4685                	li	a3,1
    800057c2:	01590633          	add	a2,s2,s5
    800057c6:	faf40593          	addi	a1,s0,-81
    800057ca:	0509b503          	ld	a0,80(s3)
    800057ce:	ffffc097          	auipc	ra,0xffffc
    800057d2:	f52080e7          	jalr	-174(ra) # 80001720 <copyin>
    800057d6:	03650263          	beq	a0,s6,800057fa <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800057da:	21c4a783          	lw	a5,540(s1)
    800057de:	0017871b          	addiw	a4,a5,1
    800057e2:	20e4ae23          	sw	a4,540(s1)
    800057e6:	1ff7f793          	andi	a5,a5,511
    800057ea:	97a6                	add	a5,a5,s1
    800057ec:	faf44703          	lbu	a4,-81(s0)
    800057f0:	00e78c23          	sb	a4,24(a5)
      i++;
    800057f4:	2905                	addiw	s2,s2,1
    800057f6:	b76d                	j	800057a0 <pipewrite+0x80>
  int i = 0;
    800057f8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800057fa:	21848513          	addi	a0,s1,536
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	85c080e7          	jalr	-1956(ra) # 8000205a <wakeup>
  release(&pi->lock);
    80005806:	8526                	mv	a0,s1
    80005808:	ffffb097          	auipc	ra,0xffffb
    8000580c:	46e080e7          	jalr	1134(ra) # 80000c76 <release>
  return i;
    80005810:	b785                	j	80005770 <pipewrite+0x50>

0000000080005812 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005812:	715d                	addi	sp,sp,-80
    80005814:	e486                	sd	ra,72(sp)
    80005816:	e0a2                	sd	s0,64(sp)
    80005818:	fc26                	sd	s1,56(sp)
    8000581a:	f84a                	sd	s2,48(sp)
    8000581c:	f44e                	sd	s3,40(sp)
    8000581e:	f052                	sd	s4,32(sp)
    80005820:	ec56                	sd	s5,24(sp)
    80005822:	e85a                	sd	s6,16(sp)
    80005824:	0880                	addi	s0,sp,80
    80005826:	84aa                	mv	s1,a0
    80005828:	892e                	mv	s2,a1
    8000582a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000582c:	ffffc097          	auipc	ra,0xffffc
    80005830:	1a8080e7          	jalr	424(ra) # 800019d4 <myproc>
    80005834:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffb097          	auipc	ra,0xffffb
    8000583c:	38a080e7          	jalr	906(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005840:	2184a703          	lw	a4,536(s1)
    80005844:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005848:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000584c:	02f71463          	bne	a4,a5,80005874 <piperead+0x62>
    80005850:	2244a783          	lw	a5,548(s1)
    80005854:	c385                	beqz	a5,80005874 <piperead+0x62>
    if(pr->killed){
    80005856:	028a2783          	lw	a5,40(s4)
    8000585a:	ebc1                	bnez	a5,800058ea <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000585c:	85a6                	mv	a1,s1
    8000585e:	854e                	mv	a0,s3
    80005860:	ffffc097          	auipc	ra,0xffffc
    80005864:	796080e7          	jalr	1942(ra) # 80001ff6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005868:	2184a703          	lw	a4,536(s1)
    8000586c:	21c4a783          	lw	a5,540(s1)
    80005870:	fef700e3          	beq	a4,a5,80005850 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005874:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005876:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005878:	05505363          	blez	s5,800058be <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000587c:	2184a783          	lw	a5,536(s1)
    80005880:	21c4a703          	lw	a4,540(s1)
    80005884:	02f70d63          	beq	a4,a5,800058be <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005888:	0017871b          	addiw	a4,a5,1
    8000588c:	20e4ac23          	sw	a4,536(s1)
    80005890:	1ff7f793          	andi	a5,a5,511
    80005894:	97a6                	add	a5,a5,s1
    80005896:	0187c783          	lbu	a5,24(a5)
    8000589a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000589e:	4685                	li	a3,1
    800058a0:	fbf40613          	addi	a2,s0,-65
    800058a4:	85ca                	mv	a1,s2
    800058a6:	050a3503          	ld	a0,80(s4)
    800058aa:	ffffc097          	auipc	ra,0xffffc
    800058ae:	dea080e7          	jalr	-534(ra) # 80001694 <copyout>
    800058b2:	01650663          	beq	a0,s6,800058be <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058b6:	2985                	addiw	s3,s3,1
    800058b8:	0905                	addi	s2,s2,1
    800058ba:	fd3a91e3          	bne	s5,s3,8000587c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800058be:	21c48513          	addi	a0,s1,540
    800058c2:	ffffc097          	auipc	ra,0xffffc
    800058c6:	798080e7          	jalr	1944(ra) # 8000205a <wakeup>
  release(&pi->lock);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	3aa080e7          	jalr	938(ra) # 80000c76 <release>
  return i;
}
    800058d4:	854e                	mv	a0,s3
    800058d6:	60a6                	ld	ra,72(sp)
    800058d8:	6406                	ld	s0,64(sp)
    800058da:	74e2                	ld	s1,56(sp)
    800058dc:	7942                	ld	s2,48(sp)
    800058de:	79a2                	ld	s3,40(sp)
    800058e0:	7a02                	ld	s4,32(sp)
    800058e2:	6ae2                	ld	s5,24(sp)
    800058e4:	6b42                	ld	s6,16(sp)
    800058e6:	6161                	addi	sp,sp,80
    800058e8:	8082                	ret
      release(&pi->lock);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffb097          	auipc	ra,0xffffb
    800058f0:	38a080e7          	jalr	906(ra) # 80000c76 <release>
      return -1;
    800058f4:	59fd                	li	s3,-1
    800058f6:	bff9                	j	800058d4 <piperead+0xc2>

00000000800058f8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058f8:	bd010113          	addi	sp,sp,-1072
    800058fc:	42113423          	sd	ra,1064(sp)
    80005900:	42813023          	sd	s0,1056(sp)
    80005904:	40913c23          	sd	s1,1048(sp)
    80005908:	41213823          	sd	s2,1040(sp)
    8000590c:	41313423          	sd	s3,1032(sp)
    80005910:	41413023          	sd	s4,1024(sp)
    80005914:	3f513c23          	sd	s5,1016(sp)
    80005918:	3f613823          	sd	s6,1008(sp)
    8000591c:	3f713423          	sd	s7,1000(sp)
    80005920:	3f813023          	sd	s8,992(sp)
    80005924:	3d913c23          	sd	s9,984(sp)
    80005928:	3da13823          	sd	s10,976(sp)
    8000592c:	3db13423          	sd	s11,968(sp)
    80005930:	43010413          	addi	s0,sp,1072
    80005934:	89aa                	mv	s3,a0
    80005936:	bea43023          	sd	a0,-1056(s0)
    8000593a:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000593e:	ffffc097          	auipc	ra,0xffffc
    80005942:	096080e7          	jalr	150(ra) # 800019d4 <myproc>
    80005946:	84aa                	mv	s1,a0
    80005948:	c0a43423          	sd	a0,-1016(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_PSYC_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    8000594c:	17050913          	addi	s2,a0,368
    80005950:	10000613          	li	a2,256
    80005954:	85ca                	mv	a1,s2
    80005956:	d1040513          	addi	a0,s0,-752
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	3c0080e7          	jalr	960(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005962:	27048493          	addi	s1,s1,624
    80005966:	10000613          	li	a2,256
    8000596a:	85a6                	mv	a1,s1
    8000596c:	c1040513          	addi	a0,s0,-1008
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	3aa080e7          	jalr	938(ra) # 80000d1a <memmove>

  begin_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	26c080e7          	jalr	620(ra) # 80004be4 <begin_op>

  if((ip = namei(path)) == 0){
    80005980:	854e                	mv	a0,s3
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	d30080e7          	jalr	-720(ra) # 800046b2 <namei>
    8000598a:	c569                	beqz	a0,80005a54 <exec+0x15c>
    8000598c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	56e080e7          	jalr	1390(ra) # 80003efc <ilock>

  // ADDED Q1
  if(relevant_metadata_proc(p) && init_metadata(p) < 0) {
    80005996:	c0843983          	ld	s3,-1016(s0)
    8000599a:	854e                	mv	a0,s3
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	4ae080e7          	jalr	1198(ra) # 80002e4a <relevant_metadata_proc>
    800059a4:	c901                	beqz	a0,800059b4 <exec+0xbc>
    800059a6:	854e                	mv	a0,s3
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	950080e7          	jalr	-1712(ra) # 800022f8 <init_metadata>
    800059b0:	02054963          	bltz	a0,800059e2 <exec+0xea>
    goto bad;
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800059b4:	04000713          	li	a4,64
    800059b8:	4681                	li	a3,0
    800059ba:	e4840613          	addi	a2,s0,-440
    800059be:	4581                	li	a1,0
    800059c0:	8552                	mv	a0,s4
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	7ee080e7          	jalr	2030(ra) # 800041b0 <readi>
    800059ca:	04000793          	li	a5,64
    800059ce:	00f51a63          	bne	a0,a5,800059e2 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800059d2:	e4842703          	lw	a4,-440(s0)
    800059d6:	464c47b7          	lui	a5,0x464c4
    800059da:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800059de:	08f70163          	beq	a4,a5,80005a60 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    800059e2:	10000613          	li	a2,256
    800059e6:	d1040593          	addi	a1,s0,-752
    800059ea:	854a                	mv	a0,s2
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	32e080e7          	jalr	814(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    800059f4:	10000613          	li	a2,256
    800059f8:	c1040593          	addi	a1,s0,-1008
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	31c080e7          	jalr	796(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a06:	8552                	mv	a0,s4
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	756080e7          	jalr	1878(ra) # 8000415e <iunlockput>
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	254080e7          	jalr	596(ra) # 80004c64 <end_op>
  }
  return -1;
    80005a18:	557d                	li	a0,-1
}
    80005a1a:	42813083          	ld	ra,1064(sp)
    80005a1e:	42013403          	ld	s0,1056(sp)
    80005a22:	41813483          	ld	s1,1048(sp)
    80005a26:	41013903          	ld	s2,1040(sp)
    80005a2a:	40813983          	ld	s3,1032(sp)
    80005a2e:	40013a03          	ld	s4,1024(sp)
    80005a32:	3f813a83          	ld	s5,1016(sp)
    80005a36:	3f013b03          	ld	s6,1008(sp)
    80005a3a:	3e813b83          	ld	s7,1000(sp)
    80005a3e:	3e013c03          	ld	s8,992(sp)
    80005a42:	3d813c83          	ld	s9,984(sp)
    80005a46:	3d013d03          	ld	s10,976(sp)
    80005a4a:	3c813d83          	ld	s11,968(sp)
    80005a4e:	43010113          	addi	sp,sp,1072
    80005a52:	8082                	ret
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	210080e7          	jalr	528(ra) # 80004c64 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	bf75                	j	80005a1a <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a60:	c0843503          	ld	a0,-1016(s0)
    80005a64:	ffffc097          	auipc	ra,0xffffc
    80005a68:	034080e7          	jalr	52(ra) # 80001a98 <proc_pagetable>
    80005a6c:	8b2a                	mv	s6,a0
    80005a6e:	d935                	beqz	a0,800059e2 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a70:	e6842783          	lw	a5,-408(s0)
    80005a74:	e8045703          	lhu	a4,-384(s0)
    80005a78:	c735                	beqz	a4,80005ae4 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a7a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a7c:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005a80:	6a85                	lui	s5,0x1
    80005a82:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005a86:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005a8a:	6d85                	lui	s11,0x1
    80005a8c:	7d7d                	lui	s10,0xfffff
    80005a8e:	a4ad                	j	80005cf8 <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005a90:	00004517          	auipc	a0,0x4
    80005a94:	f5050513          	addi	a0,a0,-176 # 800099e0 <syscalls+0x2f0>
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	a92080e7          	jalr	-1390(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005aa0:	874a                	mv	a4,s2
    80005aa2:	009c86bb          	addw	a3,s9,s1
    80005aa6:	4581                	li	a1,0
    80005aa8:	8552                	mv	a0,s4
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	706080e7          	jalr	1798(ra) # 800041b0 <readi>
    80005ab2:	2501                	sext.w	a0,a0
    80005ab4:	1aa91c63          	bne	s2,a0,80005c6c <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005ab8:	009d84bb          	addw	s1,s11,s1
    80005abc:	013d09bb          	addw	s3,s10,s3
    80005ac0:	2174fc63          	bgeu	s1,s7,80005cd8 <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005ac4:	02049593          	slli	a1,s1,0x20
    80005ac8:	9181                	srli	a1,a1,0x20
    80005aca:	95e2                	add	a1,a1,s8
    80005acc:	855a                	mv	a0,s6
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	57e080e7          	jalr	1406(ra) # 8000104c <walkaddr>
    80005ad6:	862a                	mv	a2,a0
    if(pa == 0)
    80005ad8:	dd45                	beqz	a0,80005a90 <exec+0x198>
      n = PGSIZE;
    80005ada:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005adc:	fd59f2e3          	bgeu	s3,s5,80005aa0 <exec+0x1a8>
      n = sz - i;
    80005ae0:	894e                	mv	s2,s3
    80005ae2:	bf7d                	j	80005aa0 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005ae4:	4481                	li	s1,0
  iunlockput(ip);
    80005ae6:	8552                	mv	a0,s4
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	676080e7          	jalr	1654(ra) # 8000415e <iunlockput>
  end_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	174080e7          	jalr	372(ra) # 80004c64 <end_op>
  p = myproc();
    80005af8:	ffffc097          	auipc	ra,0xffffc
    80005afc:	edc080e7          	jalr	-292(ra) # 800019d4 <myproc>
    80005b00:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005b04:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b08:	6785                	lui	a5,0x1
    80005b0a:	17fd                	addi	a5,a5,-1
    80005b0c:	94be                	add	s1,s1,a5
    80005b0e:	77fd                	lui	a5,0xfffff
    80005b10:	8fe5                	and	a5,a5,s1
    80005b12:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b16:	6609                	lui	a2,0x2
    80005b18:	963e                	add	a2,a2,a5
    80005b1a:	85be                	mv	a1,a5
    80005b1c:	855a                	mv	a0,s6
    80005b1e:	ffffc097          	auipc	ra,0xffffc
    80005b22:	916080e7          	jalr	-1770(ra) # 80001434 <uvmalloc>
    80005b26:	8aaa                	mv	s5,a0
  ip = 0;
    80005b28:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b2a:	14050163          	beqz	a0,80005c6c <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b2e:	75f9                	lui	a1,0xffffe
    80005b30:	95aa                	add	a1,a1,a0
    80005b32:	855a                	mv	a0,s6
    80005b34:	ffffc097          	auipc	ra,0xffffc
    80005b38:	b2e080e7          	jalr	-1234(ra) # 80001662 <uvmclear>
  stackbase = sp - PGSIZE;
    80005b3c:	7bfd                	lui	s7,0xfffff
    80005b3e:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b40:	be843783          	ld	a5,-1048(s0)
    80005b44:	6388                	ld	a0,0(a5)
    80005b46:	c925                	beqz	a0,80005bb6 <exec+0x2be>
    80005b48:	e8840993          	addi	s3,s0,-376
    80005b4c:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005b50:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b52:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	2ee080e7          	jalr	750(ra) # 80000e42 <strlen>
    80005b5c:	0015079b          	addiw	a5,a0,1
    80005b60:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005b64:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005b68:	15796c63          	bltu	s2,s7,80005cc0 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005b6c:	be843d03          	ld	s10,-1048(s0)
    80005b70:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005b74:	8552                	mv	a0,s4
    80005b76:	ffffb097          	auipc	ra,0xffffb
    80005b7a:	2cc080e7          	jalr	716(ra) # 80000e42 <strlen>
    80005b7e:	0015069b          	addiw	a3,a0,1
    80005b82:	8652                	mv	a2,s4
    80005b84:	85ca                	mv	a1,s2
    80005b86:	855a                	mv	a0,s6
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	b0c080e7          	jalr	-1268(ra) # 80001694 <copyout>
    80005b90:	12054c63          	bltz	a0,80005cc8 <exec+0x3d0>
    ustack[argc] = sp;
    80005b94:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005b98:	0485                	addi	s1,s1,1
    80005b9a:	008d0793          	addi	a5,s10,8
    80005b9e:	bef43423          	sd	a5,-1048(s0)
    80005ba2:	008d3503          	ld	a0,8(s10)
    80005ba6:	c911                	beqz	a0,80005bba <exec+0x2c2>
    if(argc >= MAXARG)
    80005ba8:	09a1                	addi	s3,s3,8
    80005baa:	fb8995e3          	bne	s3,s8,80005b54 <exec+0x25c>
  sz = sz1;
    80005bae:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005bb2:	4a01                	li	s4,0
    80005bb4:	a865                	j	80005c6c <exec+0x374>
  sp = sz;
    80005bb6:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005bb8:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bba:	00349793          	slli	a5,s1,0x3
    80005bbe:	f9040713          	addi	a4,s0,-112
    80005bc2:	97ba                	add	a5,a5,a4
    80005bc4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005bc8:	00148693          	addi	a3,s1,1
    80005bcc:	068e                	slli	a3,a3,0x3
    80005bce:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005bd2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005bd6:	01797663          	bgeu	s2,s7,80005be2 <exec+0x2ea>
  sz = sz1;
    80005bda:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005bde:	4a01                	li	s4,0
    80005be0:	a071                	j	80005c6c <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005be2:	e8840613          	addi	a2,s0,-376
    80005be6:	85ca                	mv	a1,s2
    80005be8:	855a                	mv	a0,s6
    80005bea:	ffffc097          	auipc	ra,0xffffc
    80005bee:	aaa080e7          	jalr	-1366(ra) # 80001694 <copyout>
    80005bf2:	0c054f63          	bltz	a0,80005cd0 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005bf6:	c0843783          	ld	a5,-1016(s0)
    80005bfa:	6fbc                	ld	a5,88(a5)
    80005bfc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c00:	be043783          	ld	a5,-1056(s0)
    80005c04:	0007c703          	lbu	a4,0(a5)
    80005c08:	cf11                	beqz	a4,80005c24 <exec+0x32c>
    80005c0a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c0c:	02f00693          	li	a3,47
    80005c10:	a039                	j	80005c1e <exec+0x326>
      last = s+1;
    80005c12:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005c16:	0785                	addi	a5,a5,1
    80005c18:	fff7c703          	lbu	a4,-1(a5)
    80005c1c:	c701                	beqz	a4,80005c24 <exec+0x32c>
    if(*s == '/')
    80005c1e:	fed71ce3          	bne	a4,a3,80005c16 <exec+0x31e>
    80005c22:	bfc5                	j	80005c12 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c24:	4641                	li	a2,16
    80005c26:	be043583          	ld	a1,-1056(s0)
    80005c2a:	c0843983          	ld	s3,-1016(s0)
    80005c2e:	15898513          	addi	a0,s3,344
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	1de080e7          	jalr	478(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c3a:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005c3e:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005c42:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c46:	0589b783          	ld	a5,88(s3)
    80005c4a:	e6043703          	ld	a4,-416(s0)
    80005c4e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c50:	0589b783          	ld	a5,88(s3)
    80005c54:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c58:	85e6                	mv	a1,s9
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	eda080e7          	jalr	-294(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c62:	0004851b          	sext.w	a0,s1
    80005c66:	bb55                	j	80005a1a <exec+0x122>
    80005c68:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005c6c:	10000613          	li	a2,256
    80005c70:	d1040593          	addi	a1,s0,-752
    80005c74:	c0843483          	ld	s1,-1016(s0)
    80005c78:	17048513          	addi	a0,s1,368
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	09e080e7          	jalr	158(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005c84:	10000613          	li	a2,256
    80005c88:	c1040593          	addi	a1,s0,-1008
    80005c8c:	27048513          	addi	a0,s1,624
    80005c90:	ffffb097          	auipc	ra,0xffffb
    80005c94:	08a080e7          	jalr	138(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005c98:	bf043583          	ld	a1,-1040(s0)
    80005c9c:	855a                	mv	a0,s6
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	e96080e7          	jalr	-362(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    80005ca6:	d60a10e3          	bnez	s4,80005a06 <exec+0x10e>
  return -1;
    80005caa:	557d                	li	a0,-1
    80005cac:	b3bd                	j	80005a1a <exec+0x122>
    80005cae:	be943823          	sd	s1,-1040(s0)
    80005cb2:	bf6d                	j	80005c6c <exec+0x374>
    80005cb4:	be943823          	sd	s1,-1040(s0)
    80005cb8:	bf55                	j	80005c6c <exec+0x374>
    80005cba:	be943823          	sd	s1,-1040(s0)
    80005cbe:	b77d                	j	80005c6c <exec+0x374>
  sz = sz1;
    80005cc0:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cc4:	4a01                	li	s4,0
    80005cc6:	b75d                	j	80005c6c <exec+0x374>
  sz = sz1;
    80005cc8:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005ccc:	4a01                	li	s4,0
    80005cce:	bf79                	j	80005c6c <exec+0x374>
  sz = sz1;
    80005cd0:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cd4:	4a01                	li	s4,0
    80005cd6:	bf59                	j	80005c6c <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005cd8:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005cdc:	c0043783          	ld	a5,-1024(s0)
    80005ce0:	0017869b          	addiw	a3,a5,1
    80005ce4:	c0d43023          	sd	a3,-1024(s0)
    80005ce8:	bf843783          	ld	a5,-1032(s0)
    80005cec:	0387879b          	addiw	a5,a5,56
    80005cf0:	e8045703          	lhu	a4,-384(s0)
    80005cf4:	dee6d9e3          	bge	a3,a4,80005ae6 <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005cf8:	2781                	sext.w	a5,a5
    80005cfa:	bef43c23          	sd	a5,-1032(s0)
    80005cfe:	03800713          	li	a4,56
    80005d02:	86be                	mv	a3,a5
    80005d04:	e1040613          	addi	a2,s0,-496
    80005d08:	4581                	li	a1,0
    80005d0a:	8552                	mv	a0,s4
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	4a4080e7          	jalr	1188(ra) # 800041b0 <readi>
    80005d14:	03800793          	li	a5,56
    80005d18:	f4f518e3          	bne	a0,a5,80005c68 <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005d1c:	e1042783          	lw	a5,-496(s0)
    80005d20:	4705                	li	a4,1
    80005d22:	fae79de3          	bne	a5,a4,80005cdc <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005d26:	e3843603          	ld	a2,-456(s0)
    80005d2a:	e3043783          	ld	a5,-464(s0)
    80005d2e:	f8f660e3          	bltu	a2,a5,80005cae <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d32:	e2043783          	ld	a5,-480(s0)
    80005d36:	963e                	add	a2,a2,a5
    80005d38:	f6f66ee3          	bltu	a2,a5,80005cb4 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d3c:	85a6                	mv	a1,s1
    80005d3e:	855a                	mv	a0,s6
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	6f4080e7          	jalr	1780(ra) # 80001434 <uvmalloc>
    80005d48:	bea43823          	sd	a0,-1040(s0)
    80005d4c:	d53d                	beqz	a0,80005cba <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005d4e:	e2043c03          	ld	s8,-480(s0)
    80005d52:	bd843783          	ld	a5,-1064(s0)
    80005d56:	00fc77b3          	and	a5,s8,a5
    80005d5a:	fb89                	bnez	a5,80005c6c <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d5c:	e1842c83          	lw	s9,-488(s0)
    80005d60:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d64:	f60b8ae3          	beqz	s7,80005cd8 <exec+0x3e0>
    80005d68:	89de                	mv	s3,s7
    80005d6a:	4481                	li	s1,0
    80005d6c:	bba1                	j	80005ac4 <exec+0x1cc>

0000000080005d6e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d6e:	7179                	addi	sp,sp,-48
    80005d70:	f406                	sd	ra,40(sp)
    80005d72:	f022                	sd	s0,32(sp)
    80005d74:	ec26                	sd	s1,24(sp)
    80005d76:	e84a                	sd	s2,16(sp)
    80005d78:	1800                	addi	s0,sp,48
    80005d7a:	892e                	mv	s2,a1
    80005d7c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005d7e:	fdc40593          	addi	a1,s0,-36
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	608080e7          	jalr	1544(ra) # 8000338a <argint>
    80005d8a:	04054063          	bltz	a0,80005dca <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d8e:	fdc42703          	lw	a4,-36(s0)
    80005d92:	47bd                	li	a5,15
    80005d94:	02e7ed63          	bltu	a5,a4,80005dce <argfd+0x60>
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c3c080e7          	jalr	-964(ra) # 800019d4 <myproc>
    80005da0:	fdc42703          	lw	a4,-36(s0)
    80005da4:	01a70793          	addi	a5,a4,26
    80005da8:	078e                	slli	a5,a5,0x3
    80005daa:	953e                	add	a0,a0,a5
    80005dac:	611c                	ld	a5,0(a0)
    80005dae:	c395                	beqz	a5,80005dd2 <argfd+0x64>
    return -1;
  if(pfd)
    80005db0:	00090463          	beqz	s2,80005db8 <argfd+0x4a>
    *pfd = fd;
    80005db4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005db8:	4501                	li	a0,0
  if(pf)
    80005dba:	c091                	beqz	s1,80005dbe <argfd+0x50>
    *pf = f;
    80005dbc:	e09c                	sd	a5,0(s1)
}
    80005dbe:	70a2                	ld	ra,40(sp)
    80005dc0:	7402                	ld	s0,32(sp)
    80005dc2:	64e2                	ld	s1,24(sp)
    80005dc4:	6942                	ld	s2,16(sp)
    80005dc6:	6145                	addi	sp,sp,48
    80005dc8:	8082                	ret
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	bfcd                	j	80005dbe <argfd+0x50>
    return -1;
    80005dce:	557d                	li	a0,-1
    80005dd0:	b7fd                	j	80005dbe <argfd+0x50>
    80005dd2:	557d                	li	a0,-1
    80005dd4:	b7ed                	j	80005dbe <argfd+0x50>

0000000080005dd6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005dd6:	1101                	addi	sp,sp,-32
    80005dd8:	ec06                	sd	ra,24(sp)
    80005dda:	e822                	sd	s0,16(sp)
    80005ddc:	e426                	sd	s1,8(sp)
    80005dde:	1000                	addi	s0,sp,32
    80005de0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005de2:	ffffc097          	auipc	ra,0xffffc
    80005de6:	bf2080e7          	jalr	-1038(ra) # 800019d4 <myproc>
    80005dea:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005dec:	0d050793          	addi	a5,a0,208
    80005df0:	4501                	li	a0,0
    80005df2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005df4:	6398                	ld	a4,0(a5)
    80005df6:	cb19                	beqz	a4,80005e0c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005df8:	2505                	addiw	a0,a0,1
    80005dfa:	07a1                	addi	a5,a5,8
    80005dfc:	fed51ce3          	bne	a0,a3,80005df4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e00:	557d                	li	a0,-1
}
    80005e02:	60e2                	ld	ra,24(sp)
    80005e04:	6442                	ld	s0,16(sp)
    80005e06:	64a2                	ld	s1,8(sp)
    80005e08:	6105                	addi	sp,sp,32
    80005e0a:	8082                	ret
      p->ofile[fd] = f;
    80005e0c:	01a50793          	addi	a5,a0,26
    80005e10:	078e                	slli	a5,a5,0x3
    80005e12:	963e                	add	a2,a2,a5
    80005e14:	e204                	sd	s1,0(a2)
      return fd;
    80005e16:	b7f5                	j	80005e02 <fdalloc+0x2c>

0000000080005e18 <sys_dup>:

uint64
sys_dup(void)
{
    80005e18:	7179                	addi	sp,sp,-48
    80005e1a:	f406                	sd	ra,40(sp)
    80005e1c:	f022                	sd	s0,32(sp)
    80005e1e:	ec26                	sd	s1,24(sp)
    80005e20:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005e22:	fd840613          	addi	a2,s0,-40
    80005e26:	4581                	li	a1,0
    80005e28:	4501                	li	a0,0
    80005e2a:	00000097          	auipc	ra,0x0
    80005e2e:	f44080e7          	jalr	-188(ra) # 80005d6e <argfd>
    return -1;
    80005e32:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e34:	02054363          	bltz	a0,80005e5a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e38:	fd843503          	ld	a0,-40(s0)
    80005e3c:	00000097          	auipc	ra,0x0
    80005e40:	f9a080e7          	jalr	-102(ra) # 80005dd6 <fdalloc>
    80005e44:	84aa                	mv	s1,a0
    return -1;
    80005e46:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e48:	00054963          	bltz	a0,80005e5a <sys_dup+0x42>
  filedup(f);
    80005e4c:	fd843503          	ld	a0,-40(s0)
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	20e080e7          	jalr	526(ra) # 8000505e <filedup>
  return fd;
    80005e58:	87a6                	mv	a5,s1
}
    80005e5a:	853e                	mv	a0,a5
    80005e5c:	70a2                	ld	ra,40(sp)
    80005e5e:	7402                	ld	s0,32(sp)
    80005e60:	64e2                	ld	s1,24(sp)
    80005e62:	6145                	addi	sp,sp,48
    80005e64:	8082                	ret

0000000080005e66 <sys_read>:

uint64
sys_read(void)
{
    80005e66:	7179                	addi	sp,sp,-48
    80005e68:	f406                	sd	ra,40(sp)
    80005e6a:	f022                	sd	s0,32(sp)
    80005e6c:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e6e:	fe840613          	addi	a2,s0,-24
    80005e72:	4581                	li	a1,0
    80005e74:	4501                	li	a0,0
    80005e76:	00000097          	auipc	ra,0x0
    80005e7a:	ef8080e7          	jalr	-264(ra) # 80005d6e <argfd>
    return -1;
    80005e7e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e80:	04054163          	bltz	a0,80005ec2 <sys_read+0x5c>
    80005e84:	fe440593          	addi	a1,s0,-28
    80005e88:	4509                	li	a0,2
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	500080e7          	jalr	1280(ra) # 8000338a <argint>
    return -1;
    80005e92:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e94:	02054763          	bltz	a0,80005ec2 <sys_read+0x5c>
    80005e98:	fd840593          	addi	a1,s0,-40
    80005e9c:	4505                	li	a0,1
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	50e080e7          	jalr	1294(ra) # 800033ac <argaddr>
    return -1;
    80005ea6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ea8:	00054d63          	bltz	a0,80005ec2 <sys_read+0x5c>
  return fileread(f, p, n);
    80005eac:	fe442603          	lw	a2,-28(s0)
    80005eb0:	fd843583          	ld	a1,-40(s0)
    80005eb4:	fe843503          	ld	a0,-24(s0)
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	332080e7          	jalr	818(ra) # 800051ea <fileread>
    80005ec0:	87aa                	mv	a5,a0
}
    80005ec2:	853e                	mv	a0,a5
    80005ec4:	70a2                	ld	ra,40(sp)
    80005ec6:	7402                	ld	s0,32(sp)
    80005ec8:	6145                	addi	sp,sp,48
    80005eca:	8082                	ret

0000000080005ecc <sys_write>:

uint64
sys_write(void)
{
    80005ecc:	7179                	addi	sp,sp,-48
    80005ece:	f406                	sd	ra,40(sp)
    80005ed0:	f022                	sd	s0,32(sp)
    80005ed2:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed4:	fe840613          	addi	a2,s0,-24
    80005ed8:	4581                	li	a1,0
    80005eda:	4501                	li	a0,0
    80005edc:	00000097          	auipc	ra,0x0
    80005ee0:	e92080e7          	jalr	-366(ra) # 80005d6e <argfd>
    return -1;
    80005ee4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ee6:	04054163          	bltz	a0,80005f28 <sys_write+0x5c>
    80005eea:	fe440593          	addi	a1,s0,-28
    80005eee:	4509                	li	a0,2
    80005ef0:	ffffd097          	auipc	ra,0xffffd
    80005ef4:	49a080e7          	jalr	1178(ra) # 8000338a <argint>
    return -1;
    80005ef8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005efa:	02054763          	bltz	a0,80005f28 <sys_write+0x5c>
    80005efe:	fd840593          	addi	a1,s0,-40
    80005f02:	4505                	li	a0,1
    80005f04:	ffffd097          	auipc	ra,0xffffd
    80005f08:	4a8080e7          	jalr	1192(ra) # 800033ac <argaddr>
    return -1;
    80005f0c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f0e:	00054d63          	bltz	a0,80005f28 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005f12:	fe442603          	lw	a2,-28(s0)
    80005f16:	fd843583          	ld	a1,-40(s0)
    80005f1a:	fe843503          	ld	a0,-24(s0)
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	38e080e7          	jalr	910(ra) # 800052ac <filewrite>
    80005f26:	87aa                	mv	a5,a0
}
    80005f28:	853e                	mv	a0,a5
    80005f2a:	70a2                	ld	ra,40(sp)
    80005f2c:	7402                	ld	s0,32(sp)
    80005f2e:	6145                	addi	sp,sp,48
    80005f30:	8082                	ret

0000000080005f32 <sys_close>:

uint64
sys_close(void)
{
    80005f32:	1101                	addi	sp,sp,-32
    80005f34:	ec06                	sd	ra,24(sp)
    80005f36:	e822                	sd	s0,16(sp)
    80005f38:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005f3a:	fe040613          	addi	a2,s0,-32
    80005f3e:	fec40593          	addi	a1,s0,-20
    80005f42:	4501                	li	a0,0
    80005f44:	00000097          	auipc	ra,0x0
    80005f48:	e2a080e7          	jalr	-470(ra) # 80005d6e <argfd>
    return -1;
    80005f4c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f4e:	02054463          	bltz	a0,80005f76 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	a82080e7          	jalr	-1406(ra) # 800019d4 <myproc>
    80005f5a:	fec42783          	lw	a5,-20(s0)
    80005f5e:	07e9                	addi	a5,a5,26
    80005f60:	078e                	slli	a5,a5,0x3
    80005f62:	97aa                	add	a5,a5,a0
    80005f64:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f68:	fe043503          	ld	a0,-32(s0)
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	144080e7          	jalr	324(ra) # 800050b0 <fileclose>
  return 0;
    80005f74:	4781                	li	a5,0
}
    80005f76:	853e                	mv	a0,a5
    80005f78:	60e2                	ld	ra,24(sp)
    80005f7a:	6442                	ld	s0,16(sp)
    80005f7c:	6105                	addi	sp,sp,32
    80005f7e:	8082                	ret

0000000080005f80 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005f80:	1101                	addi	sp,sp,-32
    80005f82:	ec06                	sd	ra,24(sp)
    80005f84:	e822                	sd	s0,16(sp)
    80005f86:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f88:	fe840613          	addi	a2,s0,-24
    80005f8c:	4581                	li	a1,0
    80005f8e:	4501                	li	a0,0
    80005f90:	00000097          	auipc	ra,0x0
    80005f94:	dde080e7          	jalr	-546(ra) # 80005d6e <argfd>
    return -1;
    80005f98:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f9a:	02054563          	bltz	a0,80005fc4 <sys_fstat+0x44>
    80005f9e:	fe040593          	addi	a1,s0,-32
    80005fa2:	4505                	li	a0,1
    80005fa4:	ffffd097          	auipc	ra,0xffffd
    80005fa8:	408080e7          	jalr	1032(ra) # 800033ac <argaddr>
    return -1;
    80005fac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fae:	00054b63          	bltz	a0,80005fc4 <sys_fstat+0x44>
  return filestat(f, st);
    80005fb2:	fe043583          	ld	a1,-32(s0)
    80005fb6:	fe843503          	ld	a0,-24(s0)
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	1be080e7          	jalr	446(ra) # 80005178 <filestat>
    80005fc2:	87aa                	mv	a5,a0
}
    80005fc4:	853e                	mv	a0,a5
    80005fc6:	60e2                	ld	ra,24(sp)
    80005fc8:	6442                	ld	s0,16(sp)
    80005fca:	6105                	addi	sp,sp,32
    80005fcc:	8082                	ret

0000000080005fce <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005fce:	7169                	addi	sp,sp,-304
    80005fd0:	f606                	sd	ra,296(sp)
    80005fd2:	f222                	sd	s0,288(sp)
    80005fd4:	ee26                	sd	s1,280(sp)
    80005fd6:	ea4a                	sd	s2,272(sp)
    80005fd8:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fda:	08000613          	li	a2,128
    80005fde:	ed040593          	addi	a1,s0,-304
    80005fe2:	4501                	li	a0,0
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	3ea080e7          	jalr	1002(ra) # 800033ce <argstr>
    return -1;
    80005fec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fee:	10054e63          	bltz	a0,8000610a <sys_link+0x13c>
    80005ff2:	08000613          	li	a2,128
    80005ff6:	f5040593          	addi	a1,s0,-176
    80005ffa:	4505                	li	a0,1
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	3d2080e7          	jalr	978(ra) # 800033ce <argstr>
    return -1;
    80006004:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006006:	10054263          	bltz	a0,8000610a <sys_link+0x13c>

  begin_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	bda080e7          	jalr	-1062(ra) # 80004be4 <begin_op>
  if((ip = namei(old)) == 0){
    80006012:	ed040513          	addi	a0,s0,-304
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	69c080e7          	jalr	1692(ra) # 800046b2 <namei>
    8000601e:	84aa                	mv	s1,a0
    80006020:	c551                	beqz	a0,800060ac <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	eda080e7          	jalr	-294(ra) # 80003efc <ilock>
  if(ip->type == T_DIR){
    8000602a:	04449703          	lh	a4,68(s1)
    8000602e:	4785                	li	a5,1
    80006030:	08f70463          	beq	a4,a5,800060b8 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80006034:	04a4d783          	lhu	a5,74(s1)
    80006038:	2785                	addiw	a5,a5,1
    8000603a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000603e:	8526                	mv	a0,s1
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	df2080e7          	jalr	-526(ra) # 80003e32 <iupdate>
  iunlock(ip);
    80006048:	8526                	mv	a0,s1
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	f74080e7          	jalr	-140(ra) # 80003fbe <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80006052:	fd040593          	addi	a1,s0,-48
    80006056:	f5040513          	addi	a0,s0,-176
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	676080e7          	jalr	1654(ra) # 800046d0 <nameiparent>
    80006062:	892a                	mv	s2,a0
    80006064:	c935                	beqz	a0,800060d8 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	e96080e7          	jalr	-362(ra) # 80003efc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000606e:	00092703          	lw	a4,0(s2)
    80006072:	409c                	lw	a5,0(s1)
    80006074:	04f71d63          	bne	a4,a5,800060ce <sys_link+0x100>
    80006078:	40d0                	lw	a2,4(s1)
    8000607a:	fd040593          	addi	a1,s0,-48
    8000607e:	854a                	mv	a0,s2
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	570080e7          	jalr	1392(ra) # 800045f0 <dirlink>
    80006088:	04054363          	bltz	a0,800060ce <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    8000608c:	854a                	mv	a0,s2
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	0d0080e7          	jalr	208(ra) # 8000415e <iunlockput>
  iput(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	01e080e7          	jalr	30(ra) # 800040b6 <iput>

  end_op();
    800060a0:	fffff097          	auipc	ra,0xfffff
    800060a4:	bc4080e7          	jalr	-1084(ra) # 80004c64 <end_op>

  return 0;
    800060a8:	4781                	li	a5,0
    800060aa:	a085                	j	8000610a <sys_link+0x13c>
    end_op();
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	bb8080e7          	jalr	-1096(ra) # 80004c64 <end_op>
    return -1;
    800060b4:	57fd                	li	a5,-1
    800060b6:	a891                	j	8000610a <sys_link+0x13c>
    iunlockput(ip);
    800060b8:	8526                	mv	a0,s1
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	0a4080e7          	jalr	164(ra) # 8000415e <iunlockput>
    end_op();
    800060c2:	fffff097          	auipc	ra,0xfffff
    800060c6:	ba2080e7          	jalr	-1118(ra) # 80004c64 <end_op>
    return -1;
    800060ca:	57fd                	li	a5,-1
    800060cc:	a83d                	j	8000610a <sys_link+0x13c>
    iunlockput(dp);
    800060ce:	854a                	mv	a0,s2
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	08e080e7          	jalr	142(ra) # 8000415e <iunlockput>

bad:
  ilock(ip);
    800060d8:	8526                	mv	a0,s1
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	e22080e7          	jalr	-478(ra) # 80003efc <ilock>
  ip->nlink--;
    800060e2:	04a4d783          	lhu	a5,74(s1)
    800060e6:	37fd                	addiw	a5,a5,-1
    800060e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060ec:	8526                	mv	a0,s1
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	d44080e7          	jalr	-700(ra) # 80003e32 <iupdate>
  iunlockput(ip);
    800060f6:	8526                	mv	a0,s1
    800060f8:	ffffe097          	auipc	ra,0xffffe
    800060fc:	066080e7          	jalr	102(ra) # 8000415e <iunlockput>
  end_op();
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	b64080e7          	jalr	-1180(ra) # 80004c64 <end_op>
  return -1;
    80006108:	57fd                	li	a5,-1
}
    8000610a:	853e                	mv	a0,a5
    8000610c:	70b2                	ld	ra,296(sp)
    8000610e:	7412                	ld	s0,288(sp)
    80006110:	64f2                	ld	s1,280(sp)
    80006112:	6952                	ld	s2,272(sp)
    80006114:	6155                	addi	sp,sp,304
    80006116:	8082                	ret

0000000080006118 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006118:	4578                	lw	a4,76(a0)
    8000611a:	02000793          	li	a5,32
    8000611e:	04e7fa63          	bgeu	a5,a4,80006172 <isdirempty+0x5a>
{
    80006122:	7179                	addi	sp,sp,-48
    80006124:	f406                	sd	ra,40(sp)
    80006126:	f022                	sd	s0,32(sp)
    80006128:	ec26                	sd	s1,24(sp)
    8000612a:	e84a                	sd	s2,16(sp)
    8000612c:	1800                	addi	s0,sp,48
    8000612e:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006130:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006134:	4741                	li	a4,16
    80006136:	86a6                	mv	a3,s1
    80006138:	fd040613          	addi	a2,s0,-48
    8000613c:	4581                	li	a1,0
    8000613e:	854a                	mv	a0,s2
    80006140:	ffffe097          	auipc	ra,0xffffe
    80006144:	070080e7          	jalr	112(ra) # 800041b0 <readi>
    80006148:	47c1                	li	a5,16
    8000614a:	00f51c63          	bne	a0,a5,80006162 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    8000614e:	fd045783          	lhu	a5,-48(s0)
    80006152:	e395                	bnez	a5,80006176 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006154:	24c1                	addiw	s1,s1,16
    80006156:	04c92783          	lw	a5,76(s2)
    8000615a:	fcf4ede3          	bltu	s1,a5,80006134 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    8000615e:	4505                	li	a0,1
    80006160:	a821                	j	80006178 <isdirempty+0x60>
      panic("isdirempty: readi");
    80006162:	00004517          	auipc	a0,0x4
    80006166:	89e50513          	addi	a0,a0,-1890 # 80009a00 <syscalls+0x310>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3c0080e7          	jalr	960(ra) # 8000052a <panic>
  return 1;
    80006172:	4505                	li	a0,1
}
    80006174:	8082                	ret
      return 0;
    80006176:	4501                	li	a0,0
}
    80006178:	70a2                	ld	ra,40(sp)
    8000617a:	7402                	ld	s0,32(sp)
    8000617c:	64e2                	ld	s1,24(sp)
    8000617e:	6942                	ld	s2,16(sp)
    80006180:	6145                	addi	sp,sp,48
    80006182:	8082                	ret

0000000080006184 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006184:	7155                	addi	sp,sp,-208
    80006186:	e586                	sd	ra,200(sp)
    80006188:	e1a2                	sd	s0,192(sp)
    8000618a:	fd26                	sd	s1,184(sp)
    8000618c:	f94a                	sd	s2,176(sp)
    8000618e:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006190:	08000613          	li	a2,128
    80006194:	f4040593          	addi	a1,s0,-192
    80006198:	4501                	li	a0,0
    8000619a:	ffffd097          	auipc	ra,0xffffd
    8000619e:	234080e7          	jalr	564(ra) # 800033ce <argstr>
    800061a2:	16054363          	bltz	a0,80006308 <sys_unlink+0x184>
    return -1;

  begin_op();
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	a3e080e7          	jalr	-1474(ra) # 80004be4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061ae:	fc040593          	addi	a1,s0,-64
    800061b2:	f4040513          	addi	a0,s0,-192
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	51a080e7          	jalr	1306(ra) # 800046d0 <nameiparent>
    800061be:	84aa                	mv	s1,a0
    800061c0:	c961                	beqz	a0,80006290 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800061c2:	ffffe097          	auipc	ra,0xffffe
    800061c6:	d3a080e7          	jalr	-710(ra) # 80003efc <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061ca:	00003597          	auipc	a1,0x3
    800061ce:	71658593          	addi	a1,a1,1814 # 800098e0 <syscalls+0x1f0>
    800061d2:	fc040513          	addi	a0,s0,-64
    800061d6:	ffffe097          	auipc	ra,0xffffe
    800061da:	1f0080e7          	jalr	496(ra) # 800043c6 <namecmp>
    800061de:	c175                	beqz	a0,800062c2 <sys_unlink+0x13e>
    800061e0:	00003597          	auipc	a1,0x3
    800061e4:	70858593          	addi	a1,a1,1800 # 800098e8 <syscalls+0x1f8>
    800061e8:	fc040513          	addi	a0,s0,-64
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	1da080e7          	jalr	474(ra) # 800043c6 <namecmp>
    800061f4:	c579                	beqz	a0,800062c2 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800061f6:	f3c40613          	addi	a2,s0,-196
    800061fa:	fc040593          	addi	a1,s0,-64
    800061fe:	8526                	mv	a0,s1
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	1e0080e7          	jalr	480(ra) # 800043e0 <dirlookup>
    80006208:	892a                	mv	s2,a0
    8000620a:	cd45                	beqz	a0,800062c2 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	cf0080e7          	jalr	-784(ra) # 80003efc <ilock>

  if(ip->nlink < 1)
    80006214:	04a91783          	lh	a5,74(s2)
    80006218:	08f05263          	blez	a5,8000629c <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000621c:	04491703          	lh	a4,68(s2)
    80006220:	4785                	li	a5,1
    80006222:	08f70563          	beq	a4,a5,800062ac <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80006226:	4641                	li	a2,16
    80006228:	4581                	li	a1,0
    8000622a:	fd040513          	addi	a0,s0,-48
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	a90080e7          	jalr	-1392(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006236:	4741                	li	a4,16
    80006238:	f3c42683          	lw	a3,-196(s0)
    8000623c:	fd040613          	addi	a2,s0,-48
    80006240:	4581                	li	a1,0
    80006242:	8526                	mv	a0,s1
    80006244:	ffffe097          	auipc	ra,0xffffe
    80006248:	064080e7          	jalr	100(ra) # 800042a8 <writei>
    8000624c:	47c1                	li	a5,16
    8000624e:	08f51a63          	bne	a0,a5,800062e2 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006252:	04491703          	lh	a4,68(s2)
    80006256:	4785                	li	a5,1
    80006258:	08f70d63          	beq	a4,a5,800062f2 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000625c:	8526                	mv	a0,s1
    8000625e:	ffffe097          	auipc	ra,0xffffe
    80006262:	f00080e7          	jalr	-256(ra) # 8000415e <iunlockput>

  ip->nlink--;
    80006266:	04a95783          	lhu	a5,74(s2)
    8000626a:	37fd                	addiw	a5,a5,-1
    8000626c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006270:	854a                	mv	a0,s2
    80006272:	ffffe097          	auipc	ra,0xffffe
    80006276:	bc0080e7          	jalr	-1088(ra) # 80003e32 <iupdate>
  iunlockput(ip);
    8000627a:	854a                	mv	a0,s2
    8000627c:	ffffe097          	auipc	ra,0xffffe
    80006280:	ee2080e7          	jalr	-286(ra) # 8000415e <iunlockput>

  end_op();
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	9e0080e7          	jalr	-1568(ra) # 80004c64 <end_op>

  return 0;
    8000628c:	4501                	li	a0,0
    8000628e:	a0a1                	j	800062d6 <sys_unlink+0x152>
    end_op();
    80006290:	fffff097          	auipc	ra,0xfffff
    80006294:	9d4080e7          	jalr	-1580(ra) # 80004c64 <end_op>
    return -1;
    80006298:	557d                	li	a0,-1
    8000629a:	a835                	j	800062d6 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000629c:	00003517          	auipc	a0,0x3
    800062a0:	65450513          	addi	a0,a0,1620 # 800098f0 <syscalls+0x200>
    800062a4:	ffffa097          	auipc	ra,0xffffa
    800062a8:	286080e7          	jalr	646(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062ac:	854a                	mv	a0,s2
    800062ae:	00000097          	auipc	ra,0x0
    800062b2:	e6a080e7          	jalr	-406(ra) # 80006118 <isdirempty>
    800062b6:	f925                	bnez	a0,80006226 <sys_unlink+0xa2>
    iunlockput(ip);
    800062b8:	854a                	mv	a0,s2
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	ea4080e7          	jalr	-348(ra) # 8000415e <iunlockput>

bad:
  iunlockput(dp);
    800062c2:	8526                	mv	a0,s1
    800062c4:	ffffe097          	auipc	ra,0xffffe
    800062c8:	e9a080e7          	jalr	-358(ra) # 8000415e <iunlockput>
  end_op();
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	998080e7          	jalr	-1640(ra) # 80004c64 <end_op>
  return -1;
    800062d4:	557d                	li	a0,-1
}
    800062d6:	60ae                	ld	ra,200(sp)
    800062d8:	640e                	ld	s0,192(sp)
    800062da:	74ea                	ld	s1,184(sp)
    800062dc:	794a                	ld	s2,176(sp)
    800062de:	6169                	addi	sp,sp,208
    800062e0:	8082                	ret
    panic("unlink: writei");
    800062e2:	00003517          	auipc	a0,0x3
    800062e6:	62650513          	addi	a0,a0,1574 # 80009908 <syscalls+0x218>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	240080e7          	jalr	576(ra) # 8000052a <panic>
    dp->nlink--;
    800062f2:	04a4d783          	lhu	a5,74(s1)
    800062f6:	37fd                	addiw	a5,a5,-1
    800062f8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062fc:	8526                	mv	a0,s1
    800062fe:	ffffe097          	auipc	ra,0xffffe
    80006302:	b34080e7          	jalr	-1228(ra) # 80003e32 <iupdate>
    80006306:	bf99                	j	8000625c <sys_unlink+0xd8>
    return -1;
    80006308:	557d                	li	a0,-1
    8000630a:	b7f1                	j	800062d6 <sys_unlink+0x152>

000000008000630c <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000630c:	715d                	addi	sp,sp,-80
    8000630e:	e486                	sd	ra,72(sp)
    80006310:	e0a2                	sd	s0,64(sp)
    80006312:	fc26                	sd	s1,56(sp)
    80006314:	f84a                	sd	s2,48(sp)
    80006316:	f44e                	sd	s3,40(sp)
    80006318:	f052                	sd	s4,32(sp)
    8000631a:	ec56                	sd	s5,24(sp)
    8000631c:	0880                	addi	s0,sp,80
    8000631e:	89ae                	mv	s3,a1
    80006320:	8ab2                	mv	s5,a2
    80006322:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006324:	fb040593          	addi	a1,s0,-80
    80006328:	ffffe097          	auipc	ra,0xffffe
    8000632c:	3a8080e7          	jalr	936(ra) # 800046d0 <nameiparent>
    80006330:	892a                	mv	s2,a0
    80006332:	12050e63          	beqz	a0,8000646e <create+0x162>
    return 0;

  ilock(dp);
    80006336:	ffffe097          	auipc	ra,0xffffe
    8000633a:	bc6080e7          	jalr	-1082(ra) # 80003efc <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000633e:	4601                	li	a2,0
    80006340:	fb040593          	addi	a1,s0,-80
    80006344:	854a                	mv	a0,s2
    80006346:	ffffe097          	auipc	ra,0xffffe
    8000634a:	09a080e7          	jalr	154(ra) # 800043e0 <dirlookup>
    8000634e:	84aa                	mv	s1,a0
    80006350:	c921                	beqz	a0,800063a0 <create+0x94>
    iunlockput(dp);
    80006352:	854a                	mv	a0,s2
    80006354:	ffffe097          	auipc	ra,0xffffe
    80006358:	e0a080e7          	jalr	-502(ra) # 8000415e <iunlockput>
    ilock(ip);
    8000635c:	8526                	mv	a0,s1
    8000635e:	ffffe097          	auipc	ra,0xffffe
    80006362:	b9e080e7          	jalr	-1122(ra) # 80003efc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006366:	2981                	sext.w	s3,s3
    80006368:	4789                	li	a5,2
    8000636a:	02f99463          	bne	s3,a5,80006392 <create+0x86>
    8000636e:	0444d783          	lhu	a5,68(s1)
    80006372:	37f9                	addiw	a5,a5,-2
    80006374:	17c2                	slli	a5,a5,0x30
    80006376:	93c1                	srli	a5,a5,0x30
    80006378:	4705                	li	a4,1
    8000637a:	00f76c63          	bltu	a4,a5,80006392 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000637e:	8526                	mv	a0,s1
    80006380:	60a6                	ld	ra,72(sp)
    80006382:	6406                	ld	s0,64(sp)
    80006384:	74e2                	ld	s1,56(sp)
    80006386:	7942                	ld	s2,48(sp)
    80006388:	79a2                	ld	s3,40(sp)
    8000638a:	7a02                	ld	s4,32(sp)
    8000638c:	6ae2                	ld	s5,24(sp)
    8000638e:	6161                	addi	sp,sp,80
    80006390:	8082                	ret
    iunlockput(ip);
    80006392:	8526                	mv	a0,s1
    80006394:	ffffe097          	auipc	ra,0xffffe
    80006398:	dca080e7          	jalr	-566(ra) # 8000415e <iunlockput>
    return 0;
    8000639c:	4481                	li	s1,0
    8000639e:	b7c5                	j	8000637e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800063a0:	85ce                	mv	a1,s3
    800063a2:	00092503          	lw	a0,0(s2)
    800063a6:	ffffe097          	auipc	ra,0xffffe
    800063aa:	9be080e7          	jalr	-1602(ra) # 80003d64 <ialloc>
    800063ae:	84aa                	mv	s1,a0
    800063b0:	c521                	beqz	a0,800063f8 <create+0xec>
  ilock(ip);
    800063b2:	ffffe097          	auipc	ra,0xffffe
    800063b6:	b4a080e7          	jalr	-1206(ra) # 80003efc <ilock>
  ip->major = major;
    800063ba:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800063be:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800063c2:	4a05                	li	s4,1
    800063c4:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800063c8:	8526                	mv	a0,s1
    800063ca:	ffffe097          	auipc	ra,0xffffe
    800063ce:	a68080e7          	jalr	-1432(ra) # 80003e32 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800063d2:	2981                	sext.w	s3,s3
    800063d4:	03498a63          	beq	s3,s4,80006408 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800063d8:	40d0                	lw	a2,4(s1)
    800063da:	fb040593          	addi	a1,s0,-80
    800063de:	854a                	mv	a0,s2
    800063e0:	ffffe097          	auipc	ra,0xffffe
    800063e4:	210080e7          	jalr	528(ra) # 800045f0 <dirlink>
    800063e8:	06054b63          	bltz	a0,8000645e <create+0x152>
  iunlockput(dp);
    800063ec:	854a                	mv	a0,s2
    800063ee:	ffffe097          	auipc	ra,0xffffe
    800063f2:	d70080e7          	jalr	-656(ra) # 8000415e <iunlockput>
  return ip;
    800063f6:	b761                	j	8000637e <create+0x72>
    panic("create: ialloc");
    800063f8:	00003517          	auipc	a0,0x3
    800063fc:	62050513          	addi	a0,a0,1568 # 80009a18 <syscalls+0x328>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	12a080e7          	jalr	298(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006408:	04a95783          	lhu	a5,74(s2)
    8000640c:	2785                	addiw	a5,a5,1
    8000640e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006412:	854a                	mv	a0,s2
    80006414:	ffffe097          	auipc	ra,0xffffe
    80006418:	a1e080e7          	jalr	-1506(ra) # 80003e32 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000641c:	40d0                	lw	a2,4(s1)
    8000641e:	00003597          	auipc	a1,0x3
    80006422:	4c258593          	addi	a1,a1,1218 # 800098e0 <syscalls+0x1f0>
    80006426:	8526                	mv	a0,s1
    80006428:	ffffe097          	auipc	ra,0xffffe
    8000642c:	1c8080e7          	jalr	456(ra) # 800045f0 <dirlink>
    80006430:	00054f63          	bltz	a0,8000644e <create+0x142>
    80006434:	00492603          	lw	a2,4(s2)
    80006438:	00003597          	auipc	a1,0x3
    8000643c:	4b058593          	addi	a1,a1,1200 # 800098e8 <syscalls+0x1f8>
    80006440:	8526                	mv	a0,s1
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	1ae080e7          	jalr	430(ra) # 800045f0 <dirlink>
    8000644a:	f80557e3          	bgez	a0,800063d8 <create+0xcc>
      panic("create dots");
    8000644e:	00003517          	auipc	a0,0x3
    80006452:	5da50513          	addi	a0,a0,1498 # 80009a28 <syscalls+0x338>
    80006456:	ffffa097          	auipc	ra,0xffffa
    8000645a:	0d4080e7          	jalr	212(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000645e:	00003517          	auipc	a0,0x3
    80006462:	5da50513          	addi	a0,a0,1498 # 80009a38 <syscalls+0x348>
    80006466:	ffffa097          	auipc	ra,0xffffa
    8000646a:	0c4080e7          	jalr	196(ra) # 8000052a <panic>
    return 0;
    8000646e:	84aa                	mv	s1,a0
    80006470:	b739                	j	8000637e <create+0x72>

0000000080006472 <sys_open>:

uint64
sys_open(void)
{
    80006472:	7131                	addi	sp,sp,-192
    80006474:	fd06                	sd	ra,184(sp)
    80006476:	f922                	sd	s0,176(sp)
    80006478:	f526                	sd	s1,168(sp)
    8000647a:	f14a                	sd	s2,160(sp)
    8000647c:	ed4e                	sd	s3,152(sp)
    8000647e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006480:	08000613          	li	a2,128
    80006484:	f5040593          	addi	a1,s0,-176
    80006488:	4501                	li	a0,0
    8000648a:	ffffd097          	auipc	ra,0xffffd
    8000648e:	f44080e7          	jalr	-188(ra) # 800033ce <argstr>
    return -1;
    80006492:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006494:	0c054163          	bltz	a0,80006556 <sys_open+0xe4>
    80006498:	f4c40593          	addi	a1,s0,-180
    8000649c:	4505                	li	a0,1
    8000649e:	ffffd097          	auipc	ra,0xffffd
    800064a2:	eec080e7          	jalr	-276(ra) # 8000338a <argint>
    800064a6:	0a054863          	bltz	a0,80006556 <sys_open+0xe4>

  begin_op();
    800064aa:	ffffe097          	auipc	ra,0xffffe
    800064ae:	73a080e7          	jalr	1850(ra) # 80004be4 <begin_op>

  if(omode & O_CREATE){
    800064b2:	f4c42783          	lw	a5,-180(s0)
    800064b6:	2007f793          	andi	a5,a5,512
    800064ba:	cbdd                	beqz	a5,80006570 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800064bc:	4681                	li	a3,0
    800064be:	4601                	li	a2,0
    800064c0:	4589                	li	a1,2
    800064c2:	f5040513          	addi	a0,s0,-176
    800064c6:	00000097          	auipc	ra,0x0
    800064ca:	e46080e7          	jalr	-442(ra) # 8000630c <create>
    800064ce:	892a                	mv	s2,a0
    if(ip == 0){
    800064d0:	c959                	beqz	a0,80006566 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800064d2:	04491703          	lh	a4,68(s2)
    800064d6:	478d                	li	a5,3
    800064d8:	00f71763          	bne	a4,a5,800064e6 <sys_open+0x74>
    800064dc:	04695703          	lhu	a4,70(s2)
    800064e0:	47a5                	li	a5,9
    800064e2:	0ce7ec63          	bltu	a5,a4,800065ba <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800064e6:	fffff097          	auipc	ra,0xfffff
    800064ea:	b0e080e7          	jalr	-1266(ra) # 80004ff4 <filealloc>
    800064ee:	89aa                	mv	s3,a0
    800064f0:	10050263          	beqz	a0,800065f4 <sys_open+0x182>
    800064f4:	00000097          	auipc	ra,0x0
    800064f8:	8e2080e7          	jalr	-1822(ra) # 80005dd6 <fdalloc>
    800064fc:	84aa                	mv	s1,a0
    800064fe:	0e054663          	bltz	a0,800065ea <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006502:	04491703          	lh	a4,68(s2)
    80006506:	478d                	li	a5,3
    80006508:	0cf70463          	beq	a4,a5,800065d0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000650c:	4789                	li	a5,2
    8000650e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006512:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006516:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000651a:	f4c42783          	lw	a5,-180(s0)
    8000651e:	0017c713          	xori	a4,a5,1
    80006522:	8b05                	andi	a4,a4,1
    80006524:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006528:	0037f713          	andi	a4,a5,3
    8000652c:	00e03733          	snez	a4,a4
    80006530:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006534:	4007f793          	andi	a5,a5,1024
    80006538:	c791                	beqz	a5,80006544 <sys_open+0xd2>
    8000653a:	04491703          	lh	a4,68(s2)
    8000653e:	4789                	li	a5,2
    80006540:	08f70f63          	beq	a4,a5,800065de <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006544:	854a                	mv	a0,s2
    80006546:	ffffe097          	auipc	ra,0xffffe
    8000654a:	a78080e7          	jalr	-1416(ra) # 80003fbe <iunlock>
  end_op();
    8000654e:	ffffe097          	auipc	ra,0xffffe
    80006552:	716080e7          	jalr	1814(ra) # 80004c64 <end_op>

  return fd;
}
    80006556:	8526                	mv	a0,s1
    80006558:	70ea                	ld	ra,184(sp)
    8000655a:	744a                	ld	s0,176(sp)
    8000655c:	74aa                	ld	s1,168(sp)
    8000655e:	790a                	ld	s2,160(sp)
    80006560:	69ea                	ld	s3,152(sp)
    80006562:	6129                	addi	sp,sp,192
    80006564:	8082                	ret
      end_op();
    80006566:	ffffe097          	auipc	ra,0xffffe
    8000656a:	6fe080e7          	jalr	1790(ra) # 80004c64 <end_op>
      return -1;
    8000656e:	b7e5                	j	80006556 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006570:	f5040513          	addi	a0,s0,-176
    80006574:	ffffe097          	auipc	ra,0xffffe
    80006578:	13e080e7          	jalr	318(ra) # 800046b2 <namei>
    8000657c:	892a                	mv	s2,a0
    8000657e:	c905                	beqz	a0,800065ae <sys_open+0x13c>
    ilock(ip);
    80006580:	ffffe097          	auipc	ra,0xffffe
    80006584:	97c080e7          	jalr	-1668(ra) # 80003efc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006588:	04491703          	lh	a4,68(s2)
    8000658c:	4785                	li	a5,1
    8000658e:	f4f712e3          	bne	a4,a5,800064d2 <sys_open+0x60>
    80006592:	f4c42783          	lw	a5,-180(s0)
    80006596:	dba1                	beqz	a5,800064e6 <sys_open+0x74>
      iunlockput(ip);
    80006598:	854a                	mv	a0,s2
    8000659a:	ffffe097          	auipc	ra,0xffffe
    8000659e:	bc4080e7          	jalr	-1084(ra) # 8000415e <iunlockput>
      end_op();
    800065a2:	ffffe097          	auipc	ra,0xffffe
    800065a6:	6c2080e7          	jalr	1730(ra) # 80004c64 <end_op>
      return -1;
    800065aa:	54fd                	li	s1,-1
    800065ac:	b76d                	j	80006556 <sys_open+0xe4>
      end_op();
    800065ae:	ffffe097          	auipc	ra,0xffffe
    800065b2:	6b6080e7          	jalr	1718(ra) # 80004c64 <end_op>
      return -1;
    800065b6:	54fd                	li	s1,-1
    800065b8:	bf79                	j	80006556 <sys_open+0xe4>
    iunlockput(ip);
    800065ba:	854a                	mv	a0,s2
    800065bc:	ffffe097          	auipc	ra,0xffffe
    800065c0:	ba2080e7          	jalr	-1118(ra) # 8000415e <iunlockput>
    end_op();
    800065c4:	ffffe097          	auipc	ra,0xffffe
    800065c8:	6a0080e7          	jalr	1696(ra) # 80004c64 <end_op>
    return -1;
    800065cc:	54fd                	li	s1,-1
    800065ce:	b761                	j	80006556 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065d0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800065d4:	04691783          	lh	a5,70(s2)
    800065d8:	02f99223          	sh	a5,36(s3)
    800065dc:	bf2d                	j	80006516 <sys_open+0xa4>
    itrunc(ip);
    800065de:	854a                	mv	a0,s2
    800065e0:	ffffe097          	auipc	ra,0xffffe
    800065e4:	a2a080e7          	jalr	-1494(ra) # 8000400a <itrunc>
    800065e8:	bfb1                	j	80006544 <sys_open+0xd2>
      fileclose(f);
    800065ea:	854e                	mv	a0,s3
    800065ec:	fffff097          	auipc	ra,0xfffff
    800065f0:	ac4080e7          	jalr	-1340(ra) # 800050b0 <fileclose>
    iunlockput(ip);
    800065f4:	854a                	mv	a0,s2
    800065f6:	ffffe097          	auipc	ra,0xffffe
    800065fa:	b68080e7          	jalr	-1176(ra) # 8000415e <iunlockput>
    end_op();
    800065fe:	ffffe097          	auipc	ra,0xffffe
    80006602:	666080e7          	jalr	1638(ra) # 80004c64 <end_op>
    return -1;
    80006606:	54fd                	li	s1,-1
    80006608:	b7b9                	j	80006556 <sys_open+0xe4>

000000008000660a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000660a:	7175                	addi	sp,sp,-144
    8000660c:	e506                	sd	ra,136(sp)
    8000660e:	e122                	sd	s0,128(sp)
    80006610:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006612:	ffffe097          	auipc	ra,0xffffe
    80006616:	5d2080e7          	jalr	1490(ra) # 80004be4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000661a:	08000613          	li	a2,128
    8000661e:	f7040593          	addi	a1,s0,-144
    80006622:	4501                	li	a0,0
    80006624:	ffffd097          	auipc	ra,0xffffd
    80006628:	daa080e7          	jalr	-598(ra) # 800033ce <argstr>
    8000662c:	02054963          	bltz	a0,8000665e <sys_mkdir+0x54>
    80006630:	4681                	li	a3,0
    80006632:	4601                	li	a2,0
    80006634:	4585                	li	a1,1
    80006636:	f7040513          	addi	a0,s0,-144
    8000663a:	00000097          	auipc	ra,0x0
    8000663e:	cd2080e7          	jalr	-814(ra) # 8000630c <create>
    80006642:	cd11                	beqz	a0,8000665e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006644:	ffffe097          	auipc	ra,0xffffe
    80006648:	b1a080e7          	jalr	-1254(ra) # 8000415e <iunlockput>
  end_op();
    8000664c:	ffffe097          	auipc	ra,0xffffe
    80006650:	618080e7          	jalr	1560(ra) # 80004c64 <end_op>
  return 0;
    80006654:	4501                	li	a0,0
}
    80006656:	60aa                	ld	ra,136(sp)
    80006658:	640a                	ld	s0,128(sp)
    8000665a:	6149                	addi	sp,sp,144
    8000665c:	8082                	ret
    end_op();
    8000665e:	ffffe097          	auipc	ra,0xffffe
    80006662:	606080e7          	jalr	1542(ra) # 80004c64 <end_op>
    return -1;
    80006666:	557d                	li	a0,-1
    80006668:	b7fd                	j	80006656 <sys_mkdir+0x4c>

000000008000666a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000666a:	7135                	addi	sp,sp,-160
    8000666c:	ed06                	sd	ra,152(sp)
    8000666e:	e922                	sd	s0,144(sp)
    80006670:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006672:	ffffe097          	auipc	ra,0xffffe
    80006676:	572080e7          	jalr	1394(ra) # 80004be4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000667a:	08000613          	li	a2,128
    8000667e:	f7040593          	addi	a1,s0,-144
    80006682:	4501                	li	a0,0
    80006684:	ffffd097          	auipc	ra,0xffffd
    80006688:	d4a080e7          	jalr	-694(ra) # 800033ce <argstr>
    8000668c:	04054a63          	bltz	a0,800066e0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006690:	f6c40593          	addi	a1,s0,-148
    80006694:	4505                	li	a0,1
    80006696:	ffffd097          	auipc	ra,0xffffd
    8000669a:	cf4080e7          	jalr	-780(ra) # 8000338a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000669e:	04054163          	bltz	a0,800066e0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800066a2:	f6840593          	addi	a1,s0,-152
    800066a6:	4509                	li	a0,2
    800066a8:	ffffd097          	auipc	ra,0xffffd
    800066ac:	ce2080e7          	jalr	-798(ra) # 8000338a <argint>
     argint(1, &major) < 0 ||
    800066b0:	02054863          	bltz	a0,800066e0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800066b4:	f6841683          	lh	a3,-152(s0)
    800066b8:	f6c41603          	lh	a2,-148(s0)
    800066bc:	458d                	li	a1,3
    800066be:	f7040513          	addi	a0,s0,-144
    800066c2:	00000097          	auipc	ra,0x0
    800066c6:	c4a080e7          	jalr	-950(ra) # 8000630c <create>
     argint(2, &minor) < 0 ||
    800066ca:	c919                	beqz	a0,800066e0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066cc:	ffffe097          	auipc	ra,0xffffe
    800066d0:	a92080e7          	jalr	-1390(ra) # 8000415e <iunlockput>
  end_op();
    800066d4:	ffffe097          	auipc	ra,0xffffe
    800066d8:	590080e7          	jalr	1424(ra) # 80004c64 <end_op>
  return 0;
    800066dc:	4501                	li	a0,0
    800066de:	a031                	j	800066ea <sys_mknod+0x80>
    end_op();
    800066e0:	ffffe097          	auipc	ra,0xffffe
    800066e4:	584080e7          	jalr	1412(ra) # 80004c64 <end_op>
    return -1;
    800066e8:	557d                	li	a0,-1
}
    800066ea:	60ea                	ld	ra,152(sp)
    800066ec:	644a                	ld	s0,144(sp)
    800066ee:	610d                	addi	sp,sp,160
    800066f0:	8082                	ret

00000000800066f2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800066f2:	7135                	addi	sp,sp,-160
    800066f4:	ed06                	sd	ra,152(sp)
    800066f6:	e922                	sd	s0,144(sp)
    800066f8:	e526                	sd	s1,136(sp)
    800066fa:	e14a                	sd	s2,128(sp)
    800066fc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800066fe:	ffffb097          	auipc	ra,0xffffb
    80006702:	2d6080e7          	jalr	726(ra) # 800019d4 <myproc>
    80006706:	892a                	mv	s2,a0
  
  begin_op();
    80006708:	ffffe097          	auipc	ra,0xffffe
    8000670c:	4dc080e7          	jalr	1244(ra) # 80004be4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006710:	08000613          	li	a2,128
    80006714:	f6040593          	addi	a1,s0,-160
    80006718:	4501                	li	a0,0
    8000671a:	ffffd097          	auipc	ra,0xffffd
    8000671e:	cb4080e7          	jalr	-844(ra) # 800033ce <argstr>
    80006722:	04054b63          	bltz	a0,80006778 <sys_chdir+0x86>
    80006726:	f6040513          	addi	a0,s0,-160
    8000672a:	ffffe097          	auipc	ra,0xffffe
    8000672e:	f88080e7          	jalr	-120(ra) # 800046b2 <namei>
    80006732:	84aa                	mv	s1,a0
    80006734:	c131                	beqz	a0,80006778 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006736:	ffffd097          	auipc	ra,0xffffd
    8000673a:	7c6080e7          	jalr	1990(ra) # 80003efc <ilock>
  if(ip->type != T_DIR){
    8000673e:	04449703          	lh	a4,68(s1)
    80006742:	4785                	li	a5,1
    80006744:	04f71063          	bne	a4,a5,80006784 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006748:	8526                	mv	a0,s1
    8000674a:	ffffe097          	auipc	ra,0xffffe
    8000674e:	874080e7          	jalr	-1932(ra) # 80003fbe <iunlock>
  iput(p->cwd);
    80006752:	15093503          	ld	a0,336(s2)
    80006756:	ffffe097          	auipc	ra,0xffffe
    8000675a:	960080e7          	jalr	-1696(ra) # 800040b6 <iput>
  end_op();
    8000675e:	ffffe097          	auipc	ra,0xffffe
    80006762:	506080e7          	jalr	1286(ra) # 80004c64 <end_op>
  p->cwd = ip;
    80006766:	14993823          	sd	s1,336(s2)
  return 0;
    8000676a:	4501                	li	a0,0
}
    8000676c:	60ea                	ld	ra,152(sp)
    8000676e:	644a                	ld	s0,144(sp)
    80006770:	64aa                	ld	s1,136(sp)
    80006772:	690a                	ld	s2,128(sp)
    80006774:	610d                	addi	sp,sp,160
    80006776:	8082                	ret
    end_op();
    80006778:	ffffe097          	auipc	ra,0xffffe
    8000677c:	4ec080e7          	jalr	1260(ra) # 80004c64 <end_op>
    return -1;
    80006780:	557d                	li	a0,-1
    80006782:	b7ed                	j	8000676c <sys_chdir+0x7a>
    iunlockput(ip);
    80006784:	8526                	mv	a0,s1
    80006786:	ffffe097          	auipc	ra,0xffffe
    8000678a:	9d8080e7          	jalr	-1576(ra) # 8000415e <iunlockput>
    end_op();
    8000678e:	ffffe097          	auipc	ra,0xffffe
    80006792:	4d6080e7          	jalr	1238(ra) # 80004c64 <end_op>
    return -1;
    80006796:	557d                	li	a0,-1
    80006798:	bfd1                	j	8000676c <sys_chdir+0x7a>

000000008000679a <sys_exec>:

uint64
sys_exec(void)
{
    8000679a:	7145                	addi	sp,sp,-464
    8000679c:	e786                	sd	ra,456(sp)
    8000679e:	e3a2                	sd	s0,448(sp)
    800067a0:	ff26                	sd	s1,440(sp)
    800067a2:	fb4a                	sd	s2,432(sp)
    800067a4:	f74e                	sd	s3,424(sp)
    800067a6:	f352                	sd	s4,416(sp)
    800067a8:	ef56                	sd	s5,408(sp)
    800067aa:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067ac:	08000613          	li	a2,128
    800067b0:	f4040593          	addi	a1,s0,-192
    800067b4:	4501                	li	a0,0
    800067b6:	ffffd097          	auipc	ra,0xffffd
    800067ba:	c18080e7          	jalr	-1000(ra) # 800033ce <argstr>
    return -1;
    800067be:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067c0:	0c054a63          	bltz	a0,80006894 <sys_exec+0xfa>
    800067c4:	e3840593          	addi	a1,s0,-456
    800067c8:	4505                	li	a0,1
    800067ca:	ffffd097          	auipc	ra,0xffffd
    800067ce:	be2080e7          	jalr	-1054(ra) # 800033ac <argaddr>
    800067d2:	0c054163          	bltz	a0,80006894 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800067d6:	10000613          	li	a2,256
    800067da:	4581                	li	a1,0
    800067dc:	e4040513          	addi	a0,s0,-448
    800067e0:	ffffa097          	auipc	ra,0xffffa
    800067e4:	4de080e7          	jalr	1246(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800067e8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800067ec:	89a6                	mv	s3,s1
    800067ee:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800067f0:	02000a13          	li	s4,32
    800067f4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800067f8:	00391793          	slli	a5,s2,0x3
    800067fc:	e3040593          	addi	a1,s0,-464
    80006800:	e3843503          	ld	a0,-456(s0)
    80006804:	953e                	add	a0,a0,a5
    80006806:	ffffd097          	auipc	ra,0xffffd
    8000680a:	aea080e7          	jalr	-1302(ra) # 800032f0 <fetchaddr>
    8000680e:	02054a63          	bltz	a0,80006842 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006812:	e3043783          	ld	a5,-464(s0)
    80006816:	c3b9                	beqz	a5,8000685c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006818:	ffffa097          	auipc	ra,0xffffa
    8000681c:	2ba080e7          	jalr	698(ra) # 80000ad2 <kalloc>
    80006820:	85aa                	mv	a1,a0
    80006822:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006826:	cd11                	beqz	a0,80006842 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006828:	6605                	lui	a2,0x1
    8000682a:	e3043503          	ld	a0,-464(s0)
    8000682e:	ffffd097          	auipc	ra,0xffffd
    80006832:	b14080e7          	jalr	-1260(ra) # 80003342 <fetchstr>
    80006836:	00054663          	bltz	a0,80006842 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000683a:	0905                	addi	s2,s2,1
    8000683c:	09a1                	addi	s3,s3,8
    8000683e:	fb491be3          	bne	s2,s4,800067f4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006842:	10048913          	addi	s2,s1,256
    80006846:	6088                	ld	a0,0(s1)
    80006848:	c529                	beqz	a0,80006892 <sys_exec+0xf8>
    kfree(argv[i]);
    8000684a:	ffffa097          	auipc	ra,0xffffa
    8000684e:	18c080e7          	jalr	396(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006852:	04a1                	addi	s1,s1,8
    80006854:	ff2499e3          	bne	s1,s2,80006846 <sys_exec+0xac>
  return -1;
    80006858:	597d                	li	s2,-1
    8000685a:	a82d                	j	80006894 <sys_exec+0xfa>
      argv[i] = 0;
    8000685c:	0a8e                	slli	s5,s5,0x3
    8000685e:	fc040793          	addi	a5,s0,-64
    80006862:	9abe                	add	s5,s5,a5
    80006864:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006868:	e4040593          	addi	a1,s0,-448
    8000686c:	f4040513          	addi	a0,s0,-192
    80006870:	fffff097          	auipc	ra,0xfffff
    80006874:	088080e7          	jalr	136(ra) # 800058f8 <exec>
    80006878:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000687a:	10048993          	addi	s3,s1,256
    8000687e:	6088                	ld	a0,0(s1)
    80006880:	c911                	beqz	a0,80006894 <sys_exec+0xfa>
    kfree(argv[i]);
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	154080e7          	jalr	340(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000688a:	04a1                	addi	s1,s1,8
    8000688c:	ff3499e3          	bne	s1,s3,8000687e <sys_exec+0xe4>
    80006890:	a011                	j	80006894 <sys_exec+0xfa>
  return -1;
    80006892:	597d                	li	s2,-1
}
    80006894:	854a                	mv	a0,s2
    80006896:	60be                	ld	ra,456(sp)
    80006898:	641e                	ld	s0,448(sp)
    8000689a:	74fa                	ld	s1,440(sp)
    8000689c:	795a                	ld	s2,432(sp)
    8000689e:	79ba                	ld	s3,424(sp)
    800068a0:	7a1a                	ld	s4,416(sp)
    800068a2:	6afa                	ld	s5,408(sp)
    800068a4:	6179                	addi	sp,sp,464
    800068a6:	8082                	ret

00000000800068a8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800068a8:	7139                	addi	sp,sp,-64
    800068aa:	fc06                	sd	ra,56(sp)
    800068ac:	f822                	sd	s0,48(sp)
    800068ae:	f426                	sd	s1,40(sp)
    800068b0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800068b2:	ffffb097          	auipc	ra,0xffffb
    800068b6:	122080e7          	jalr	290(ra) # 800019d4 <myproc>
    800068ba:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800068bc:	fd840593          	addi	a1,s0,-40
    800068c0:	4501                	li	a0,0
    800068c2:	ffffd097          	auipc	ra,0xffffd
    800068c6:	aea080e7          	jalr	-1302(ra) # 800033ac <argaddr>
    return -1;
    800068ca:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800068cc:	0e054063          	bltz	a0,800069ac <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068d0:	fc840593          	addi	a1,s0,-56
    800068d4:	fd040513          	addi	a0,s0,-48
    800068d8:	fffff097          	auipc	ra,0xfffff
    800068dc:	cfe080e7          	jalr	-770(ra) # 800055d6 <pipealloc>
    return -1;
    800068e0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800068e2:	0c054563          	bltz	a0,800069ac <sys_pipe+0x104>
  fd0 = -1;
    800068e6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800068ea:	fd043503          	ld	a0,-48(s0)
    800068ee:	fffff097          	auipc	ra,0xfffff
    800068f2:	4e8080e7          	jalr	1256(ra) # 80005dd6 <fdalloc>
    800068f6:	fca42223          	sw	a0,-60(s0)
    800068fa:	08054c63          	bltz	a0,80006992 <sys_pipe+0xea>
    800068fe:	fc843503          	ld	a0,-56(s0)
    80006902:	fffff097          	auipc	ra,0xfffff
    80006906:	4d4080e7          	jalr	1236(ra) # 80005dd6 <fdalloc>
    8000690a:	fca42023          	sw	a0,-64(s0)
    8000690e:	06054863          	bltz	a0,8000697e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006912:	4691                	li	a3,4
    80006914:	fc440613          	addi	a2,s0,-60
    80006918:	fd843583          	ld	a1,-40(s0)
    8000691c:	68a8                	ld	a0,80(s1)
    8000691e:	ffffb097          	auipc	ra,0xffffb
    80006922:	d76080e7          	jalr	-650(ra) # 80001694 <copyout>
    80006926:	02054063          	bltz	a0,80006946 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000692a:	4691                	li	a3,4
    8000692c:	fc040613          	addi	a2,s0,-64
    80006930:	fd843583          	ld	a1,-40(s0)
    80006934:	0591                	addi	a1,a1,4
    80006936:	68a8                	ld	a0,80(s1)
    80006938:	ffffb097          	auipc	ra,0xffffb
    8000693c:	d5c080e7          	jalr	-676(ra) # 80001694 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006940:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006942:	06055563          	bgez	a0,800069ac <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006946:	fc442783          	lw	a5,-60(s0)
    8000694a:	07e9                	addi	a5,a5,26
    8000694c:	078e                	slli	a5,a5,0x3
    8000694e:	97a6                	add	a5,a5,s1
    80006950:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006954:	fc042503          	lw	a0,-64(s0)
    80006958:	0569                	addi	a0,a0,26
    8000695a:	050e                	slli	a0,a0,0x3
    8000695c:	9526                	add	a0,a0,s1
    8000695e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006962:	fd043503          	ld	a0,-48(s0)
    80006966:	ffffe097          	auipc	ra,0xffffe
    8000696a:	74a080e7          	jalr	1866(ra) # 800050b0 <fileclose>
    fileclose(wf);
    8000696e:	fc843503          	ld	a0,-56(s0)
    80006972:	ffffe097          	auipc	ra,0xffffe
    80006976:	73e080e7          	jalr	1854(ra) # 800050b0 <fileclose>
    return -1;
    8000697a:	57fd                	li	a5,-1
    8000697c:	a805                	j	800069ac <sys_pipe+0x104>
    if(fd0 >= 0)
    8000697e:	fc442783          	lw	a5,-60(s0)
    80006982:	0007c863          	bltz	a5,80006992 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006986:	01a78513          	addi	a0,a5,26
    8000698a:	050e                	slli	a0,a0,0x3
    8000698c:	9526                	add	a0,a0,s1
    8000698e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006992:	fd043503          	ld	a0,-48(s0)
    80006996:	ffffe097          	auipc	ra,0xffffe
    8000699a:	71a080e7          	jalr	1818(ra) # 800050b0 <fileclose>
    fileclose(wf);
    8000699e:	fc843503          	ld	a0,-56(s0)
    800069a2:	ffffe097          	auipc	ra,0xffffe
    800069a6:	70e080e7          	jalr	1806(ra) # 800050b0 <fileclose>
    return -1;
    800069aa:	57fd                	li	a5,-1
}
    800069ac:	853e                	mv	a0,a5
    800069ae:	70e2                	ld	ra,56(sp)
    800069b0:	7442                	ld	s0,48(sp)
    800069b2:	74a2                	ld	s1,40(sp)
    800069b4:	6121                	addi	sp,sp,64
    800069b6:	8082                	ret
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
    80006a00:	fbcfc0ef          	jal	ra,800031bc <kerneltrap>
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
    80006a9c:	f10080e7          	jalr	-240(ra) # 800019a8 <cpuid>
  
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
    80006ad4:	ed8080e7          	jalr	-296(ra) # 800019a8 <cpuid>
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
    80006afc:	eb0080e7          	jalr	-336(ra) # 800019a8 <cpuid>
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
    80006b86:	4d8080e7          	jalr	1240(ra) # 8000205a <wakeup>
}
    80006b8a:	60a2                	ld	ra,8(sp)
    80006b8c:	6402                	ld	s0,0(sp)
    80006b8e:	0141                	addi	sp,sp,16
    80006b90:	8082                	ret
    panic("free_desc 1");
    80006b92:	00003517          	auipc	a0,0x3
    80006b96:	eb650513          	addi	a0,a0,-330 # 80009a48 <syscalls+0x358>
    80006b9a:	ffffa097          	auipc	ra,0xffffa
    80006b9e:	990080e7          	jalr	-1648(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006ba2:	00003517          	auipc	a0,0x3
    80006ba6:	eb650513          	addi	a0,a0,-330 # 80009a58 <syscalls+0x368>
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
    80006bc0:	eac58593          	addi	a1,a1,-340 # 80009a68 <syscalls+0x378>
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
    80006cca:	db250513          	addi	a0,a0,-590 # 80009a78 <syscalls+0x388>
    80006cce:	ffffa097          	auipc	ra,0xffffa
    80006cd2:	85c080e7          	jalr	-1956(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006cd6:	00003517          	auipc	a0,0x3
    80006cda:	dc250513          	addi	a0,a0,-574 # 80009a98 <syscalls+0x3a8>
    80006cde:	ffffa097          	auipc	ra,0xffffa
    80006ce2:	84c080e7          	jalr	-1972(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006ce6:	00003517          	auipc	a0,0x3
    80006cea:	dd250513          	addi	a0,a0,-558 # 80009ab8 <syscalls+0x3c8>
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
    80006dac:	24e080e7          	jalr	590(ra) # 80001ff6 <sleep>
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
    80006e7a:	180080e7          	jalr	384(ra) # 80001ff6 <sleep>
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
    80007000:	05e080e7          	jalr	94(ra) # 8000205a <wakeup>

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
    8000703c:	aa050513          	addi	a0,a0,-1376 # 80009ad8 <syscalls+0x3e8>
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
