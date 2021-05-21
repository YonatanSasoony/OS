
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
    80000068:	b5c78793          	addi	a5,a5,-1188 # 80006bc0 <timervec>
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
    80000122:	23e080e7          	jalr	574(ra) # 8000235c <either_copyin>
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
    800001b6:	864080e7          	jalr	-1948(ra) # 80001a16 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e76080e7          	jalr	-394(ra) # 80002038 <sleep>
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
    80000202:	108080e7          	jalr	264(ra) # 80002306 <either_copyout>
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
    800002e2:	0d4080e7          	jalr	212(ra) # 800023b2 <procdump>
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
    80000436:	d92080e7          	jalr	-622(ra) # 800021c4 <wakeup>
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
    8000055c:	0f050513          	addi	a0,a0,240 # 80009648 <digits+0x608>
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
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	946080e7          	jalr	-1722(ra) # 800021c4 <wakeup>
    
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
    8000090e:	72e080e7          	jalr	1838(ra) # 80002038 <sleep>
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
    80000b60:	e9e080e7          	jalr	-354(ra) # 800019fa <mycpu>
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
    80000b92:	e6c080e7          	jalr	-404(ra) # 800019fa <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e60080e7          	jalr	-416(ra) # 800019fa <mycpu>
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
    80000bb6:	e48080e7          	jalr	-440(ra) # 800019fa <mycpu>
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
    80000bf6:	e08080e7          	jalr	-504(ra) # 800019fa <mycpu>
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
    80000c34:	dca080e7          	jalr	-566(ra) # 800019fa <mycpu>
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
    80000e8a:	b64080e7          	jalr	-1180(ra) # 800019ea <cpuid>
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
    80000ea6:	b48080e7          	jalr	-1208(ra) # 800019ea <cpuid>
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
    80000ec8:	182080e7          	jalr	386(ra) # 80003046 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ecc:	00006097          	auipc	ra,0x6
    80000ed0:	d34080e7          	jalr	-716(ra) # 80006c00 <plicinithart>
  }

  scheduler();        
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	fb2080e7          	jalr	-78(ra) # 80001e86 <scheduler>
    consoleinit();
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	560080e7          	jalr	1376(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	870080e7          	jalr	-1936(ra) # 80000754 <printfinit>
    printf("\n");
    80000eec:	00008517          	auipc	a0,0x8
    80000ef0:	75c50513          	addi	a0,a0,1884 # 80009648 <digits+0x608>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	680080e7          	jalr	1664(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efc:	00008517          	auipc	a0,0x8
    80000f00:	1c450513          	addi	a0,a0,452 # 800090c0 <digits+0x80>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	670080e7          	jalr	1648(ra) # 80000574 <printf>
    printf("\n");
    80000f0c:	00008517          	auipc	a0,0x8
    80000f10:	73c50513          	addi	a0,a0,1852 # 80009648 <digits+0x608>
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
    80000f38:	a06080e7          	jalr	-1530(ra) # 8000193a <procinit>
    trapinit();      // trap vectors
    80000f3c:	00002097          	auipc	ra,0x2
    80000f40:	0e2080e7          	jalr	226(ra) # 8000301e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f44:	00002097          	auipc	ra,0x2
    80000f48:	102080e7          	jalr	258(ra) # 80003046 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4c:	00006097          	auipc	ra,0x6
    80000f50:	c9e080e7          	jalr	-866(ra) # 80006bea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f54:	00006097          	auipc	ra,0x6
    80000f58:	cac080e7          	jalr	-852(ra) # 80006c00 <plicinithart>
    binit();         // buffer cache
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	882080e7          	jalr	-1918(ra) # 800037de <binit>
    iinit();         // inode cache
    80000f64:	00003097          	auipc	ra,0x3
    80000f68:	f14080e7          	jalr	-236(ra) # 80003e78 <iinit>
    fileinit();      // file table
    80000f6c:	00004097          	auipc	ra,0x4
    80000f70:	1d4080e7          	jalr	468(ra) # 80005140 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f74:	00006097          	auipc	ra,0x6
    80000f78:	dae080e7          	jalr	-594(ra) # 80006d22 <virtio_disk_init>
    userinit();      // first user process
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	d72080e7          	jalr	-654(ra) # 80001cee <userinit>
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
    80001232:	676080e7          	jalr	1654(ra) # 800018a4 <proc_mapstacks>
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
    if(do_free && ((*pte & PTE_PG) == 0)){ // ADDED Q1
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
    800013d0:	7139                	addi	sp,sp,-64
    800013d2:	fc06                	sd	ra,56(sp)
    800013d4:	f822                	sd	s0,48(sp)
    800013d6:	f426                	sd	s1,40(sp)
    800013d8:	f04a                	sd	s2,32(sp)
    800013da:	ec4e                	sd	s3,24(sp)
    800013dc:	e852                	sd	s4,16(sp)
    800013de:	e456                	sd	s5,8(sp)
    800013e0:	0080                	addi	s0,sp,64
    800013e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e4:	00b66c63          	bltu	a2,a1,800013fc <uvmdealloc+0x2c>
      remove_page_from_ram(p, a);
    }
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	70e2                	ld	ra,56(sp)
    800013ec:	7442                	ld	s0,48(sp)
    800013ee:	74a2                	ld	s1,40(sp)
    800013f0:	7902                	ld	s2,32(sp)
    800013f2:	69e2                	ld	s3,24(sp)
    800013f4:	6a42                	ld	s4,16(sp)
    800013f6:	6aa2                	ld	s5,8(sp)
    800013f8:	6121                	addi	sp,sp,64
    800013fa:	8082                	ret
    800013fc:	8a2a                	mv	s4,a0
    800013fe:	8932                	mv	s2,a2
  struct proc *p = myproc();
    80001400:	00000097          	auipc	ra,0x0
    80001404:	616080e7          	jalr	1558(ra) # 80001a16 <myproc>
    80001408:	89aa                	mv	s3,a0
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000140a:	6785                	lui	a5,0x1
    8000140c:	17fd                	addi	a5,a5,-1
    8000140e:	00f905b3          	add	a1,s2,a5
    80001412:	767d                	lui	a2,0xfffff
    80001414:	8df1                	and	a1,a1,a2
    80001416:	97a6                	add	a5,a5,s1
    80001418:	8ff1                	and	a5,a5,a2
    8000141a:	00f5e463          	bltu	a1,a5,80001422 <uvmdealloc+0x52>
  return newsz;
    8000141e:	84ca                	mv	s1,s2
    80001420:	b7e1                	j	800013e8 <uvmdealloc+0x18>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001422:	8f8d                	sub	a5,a5,a1
    80001424:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001426:	4685                	li	a3,1
    80001428:	0007861b          	sext.w	a2,a5
    8000142c:	8552                	mv	a0,s4
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	e36080e7          	jalr	-458(ra) # 80001264 <uvmunmap>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001436:	77fd                	lui	a5,0xfffff
    80001438:	00f4f5b3          	and	a1,s1,a5
    8000143c:	0005849b          	sext.w	s1,a1
    80001440:	7a7d                	lui	s4,0xfffff
    80001442:	01497a33          	and	s4,s2,s4
    80001446:	009a7e63          	bgeu	s4,s1,80001462 <uvmdealloc+0x92>
    8000144a:	7afd                	lui	s5,0xfffff
      remove_page_from_ram(p, a);
    8000144c:	85a6                	mv	a1,s1
    8000144e:	854e                	mv	a0,s3
    80001450:	00001097          	auipc	ra,0x1
    80001454:	76a080e7          	jalr	1898(ra) # 80002bba <remove_page_from_ram>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001458:	94d6                	add	s1,s1,s5
    8000145a:	fe9a69e3          	bltu	s4,s1,8000144c <uvmdealloc+0x7c>
  return newsz;
    8000145e:	84ca                	mv	s1,s2
    80001460:	b761                	j	800013e8 <uvmdealloc+0x18>
    80001462:	84ca                	mv	s1,s2
    80001464:	b751                	j	800013e8 <uvmdealloc+0x18>

0000000080001466 <uvmalloc>:
{
    80001466:	7139                	addi	sp,sp,-64
    80001468:	fc06                	sd	ra,56(sp)
    8000146a:	f822                	sd	s0,48(sp)
    8000146c:	f426                	sd	s1,40(sp)
    8000146e:	f04a                	sd	s2,32(sp)
    80001470:	ec4e                	sd	s3,24(sp)
    80001472:	e852                	sd	s4,16(sp)
    80001474:	e456                	sd	s5,8(sp)
    80001476:	e05a                	sd	s6,0(sp)
    80001478:	0080                	addi	s0,sp,64
    8000147a:	84ae                	mv	s1,a1
  if(newsz < oldsz)
    8000147c:	00b67d63          	bgeu	a2,a1,80001496 <uvmalloc+0x30>
}
    80001480:	8526                	mv	a0,s1
    80001482:	70e2                	ld	ra,56(sp)
    80001484:	7442                	ld	s0,48(sp)
    80001486:	74a2                	ld	s1,40(sp)
    80001488:	7902                	ld	s2,32(sp)
    8000148a:	69e2                	ld	s3,24(sp)
    8000148c:	6a42                	ld	s4,16(sp)
    8000148e:	6aa2                	ld	s5,8(sp)
    80001490:	6b02                	ld	s6,0(sp)
    80001492:	6121                	addi	sp,sp,64
    80001494:	8082                	ret
    80001496:	8aaa                	mv	s5,a0
    80001498:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	57c080e7          	jalr	1404(ra) # 80001a16 <myproc>
    800014a2:	8b2a                	mv	s6,a0
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6a05                	lui	s4,0x1
    800014a6:	1a7d                	addi	s4,s4,-1
    800014a8:	94d2                	add	s1,s1,s4
    800014aa:	7a7d                	lui	s4,0xfffff
    800014ac:	0144fa33          	and	s4,s1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	073a7b63          	bgeu	s4,s3,80001526 <uvmalloc+0xc0>
    800014b4:	8952                	mv	s2,s4
    mem = kalloc();
    800014b6:	fffff097          	auipc	ra,0xfffff
    800014ba:	61c080e7          	jalr	1564(ra) # 80000ad2 <kalloc>
    800014be:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c0:	cd0d                	beqz	a0,800014fa <uvmalloc+0x94>
    memset(mem, 0, PGSIZE);
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	80a080e7          	jalr	-2038(ra) # 80000cd0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ce:	4779                	li	a4,30
    800014d0:	86a6                	mv	a3,s1
    800014d2:	6605                	lui	a2,0x1
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	bc8080e7          	jalr	-1080(ra) # 800010a0 <mappages>
    800014e0:	e50d                	bnez	a0,8000150a <uvmalloc+0xa4>
    insert_page_to_ram(p, a);
    800014e2:	85ca                	mv	a1,s2
    800014e4:	855a                	mv	a0,s6
    800014e6:	00002097          	auipc	ra,0x2
    800014ea:	984080e7          	jalr	-1660(ra) # 80002e6a <insert_page_to_ram>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ee:	6785                	lui	a5,0x1
    800014f0:	993e                	add	s2,s2,a5
    800014f2:	fd3962e3          	bltu	s2,s3,800014b6 <uvmalloc+0x50>
  return newsz;
    800014f6:	84ce                	mv	s1,s3
    800014f8:	b761                	j	80001480 <uvmalloc+0x1a>
      uvmdealloc(pagetable, a, oldsz);
    800014fa:	8652                	mv	a2,s4
    800014fc:	85ca                	mv	a1,s2
    800014fe:	8556                	mv	a0,s5
    80001500:	00000097          	auipc	ra,0x0
    80001504:	ed0080e7          	jalr	-304(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001508:	bfa5                	j	80001480 <uvmalloc+0x1a>
      kfree(mem);
    8000150a:	8526                	mv	a0,s1
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	4ca080e7          	jalr	1226(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001514:	8652                	mv	a2,s4
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	eb6080e7          	jalr	-330(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001522:	4481                	li	s1,0
    80001524:	bfb1                	j	80001480 <uvmalloc+0x1a>
  return newsz;
    80001526:	84ce                	mv	s1,s3
    80001528:	bfa1                	j	80001480 <uvmalloc+0x1a>

000000008000152a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000152a:	7179                	addi	sp,sp,-48
    8000152c:	f406                	sd	ra,40(sp)
    8000152e:	f022                	sd	s0,32(sp)
    80001530:	ec26                	sd	s1,24(sp)
    80001532:	e84a                	sd	s2,16(sp)
    80001534:	e44e                	sd	s3,8(sp)
    80001536:	e052                	sd	s4,0(sp)
    80001538:	1800                	addi	s0,sp,48
    8000153a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000153c:	84aa                	mv	s1,a0
    8000153e:	6905                	lui	s2,0x1
    80001540:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	4985                	li	s3,1
    80001544:	a821                	j	8000155c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001546:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001548:	0532                	slli	a0,a0,0xc
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	fe0080e7          	jalr	-32(ra) # 8000152a <freewalk>
      pagetable[i] = 0;
    80001552:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001556:	04a1                	addi	s1,s1,8
    80001558:	03248163          	beq	s1,s2,8000157a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000155e:	00f57793          	andi	a5,a0,15
    80001562:	ff3782e3          	beq	a5,s3,80001546 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001566:	8905                	andi	a0,a0,1
    80001568:	d57d                	beqz	a0,80001556 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156a:	00008517          	auipc	a0,0x8
    8000156e:	c1650513          	addi	a0,a0,-1002 # 80009180 <digits+0x140>
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	fb8080e7          	jalr	-72(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000157a:	8552                	mv	a0,s4
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	45a080e7          	jalr	1114(ra) # 800009d6 <kfree>
}
    80001584:	70a2                	ld	ra,40(sp)
    80001586:	7402                	ld	s0,32(sp)
    80001588:	64e2                	ld	s1,24(sp)
    8000158a:	6942                	ld	s2,16(sp)
    8000158c:	69a2                	ld	s3,8(sp)
    8000158e:	6a02                	ld	s4,0(sp)
    80001590:	6145                	addi	sp,sp,48
    80001592:	8082                	ret

0000000080001594 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001594:	1101                	addi	sp,sp,-32
    80001596:	ec06                	sd	ra,24(sp)
    80001598:	e822                	sd	s0,16(sp)
    8000159a:	e426                	sd	s1,8(sp)
    8000159c:	1000                	addi	s0,sp,32
    8000159e:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a0:	e999                	bnez	a1,800015b6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015a2:	8526                	mv	a0,s1
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	f86080e7          	jalr	-122(ra) # 8000152a <freewalk>
}
    800015ac:	60e2                	ld	ra,24(sp)
    800015ae:	6442                	ld	s0,16(sp)
    800015b0:	64a2                	ld	s1,8(sp)
    800015b2:	6105                	addi	sp,sp,32
    800015b4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b6:	6605                	lui	a2,0x1
    800015b8:	167d                	addi	a2,a2,-1
    800015ba:	962e                	add	a2,a2,a1
    800015bc:	4685                	li	a3,1
    800015be:	8231                	srli	a2,a2,0xc
    800015c0:	4581                	li	a1,0
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	ca2080e7          	jalr	-862(ra) # 80001264 <uvmunmap>
    800015ca:	bfe1                	j	800015a2 <uvmfree+0xe>

00000000800015cc <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015cc:	ca71                	beqz	a2,800016a0 <uvmcopy+0xd4>
{
    800015ce:	715d                	addi	sp,sp,-80
    800015d0:	e486                	sd	ra,72(sp)
    800015d2:	e0a2                	sd	s0,64(sp)
    800015d4:	fc26                	sd	s1,56(sp)
    800015d6:	f84a                	sd	s2,48(sp)
    800015d8:	f44e                	sd	s3,40(sp)
    800015da:	f052                	sd	s4,32(sp)
    800015dc:	ec56                	sd	s5,24(sp)
    800015de:	e85a                	sd	s6,16(sp)
    800015e0:	e45e                	sd	s7,8(sp)
    800015e2:	0880                	addi	s0,sp,80
    800015e4:	8b2a                	mv	s6,a0
    800015e6:	8aae                	mv	s5,a1
    800015e8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ea:	4901                	li	s2,0
    800015ec:	a081                	j	8000162c <uvmcopy+0x60>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015ee:	00008517          	auipc	a0,0x8
    800015f2:	ba250513          	addi	a0,a0,-1118 # 80009190 <digits+0x150>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f34080e7          	jalr	-204(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015fe:	00008517          	auipc	a0,0x8
    80001602:	bb250513          	addi	a0,a0,-1102 # 800091b0 <digits+0x170>
    80001606:	fffff097          	auipc	ra,0xfffff
    8000160a:	f24080e7          	jalr	-220(ra) # 8000052a <panic>
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if (flags & PTE_PG){// ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
      mem = 0;
    8000160e:	4981                	li	s3,0
    } else {
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    }
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001610:	875e                	mv	a4,s7
    80001612:	86ce                	mv	a3,s3
    80001614:	6605                	lui	a2,0x1
    80001616:	85ca                	mv	a1,s2
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	a86080e7          	jalr	-1402(ra) # 800010a0 <mappages>
    80001622:	e529                	bnez	a0,8000166c <uvmcopy+0xa0>
  for(i = 0; i < sz; i += PGSIZE){
    80001624:	6785                	lui	a5,0x1
    80001626:	993e                	add	s2,s2,a5
    80001628:	07497163          	bgeu	s2,s4,8000168a <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000162c:	4601                	li	a2,0
    8000162e:	85ca                	mv	a1,s2
    80001630:	855a                	mv	a0,s6
    80001632:	00000097          	auipc	ra,0x0
    80001636:	986080e7          	jalr	-1658(ra) # 80000fb8 <walk>
    8000163a:	d955                	beqz	a0,800015ee <uvmcopy+0x22>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
    8000163c:	6104                	ld	s1,0(a0)
    8000163e:	2014f793          	andi	a5,s1,513
    80001642:	dfd5                	beqz	a5,800015fe <uvmcopy+0x32>
    flags = PTE_FLAGS(*pte);
    80001644:	3ff4fb93          	andi	s7,s1,1023
    if (flags & PTE_PG){// ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
    80001648:	2004f793          	andi	a5,s1,512
    8000164c:	f3e9                	bnez	a5,8000160e <uvmcopy+0x42>
      if((mem = kalloc()) == 0)
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	484080e7          	jalr	1156(ra) # 80000ad2 <kalloc>
    80001656:	89aa                	mv	s3,a0
    80001658:	cd19                	beqz	a0,80001676 <uvmcopy+0xaa>
    pa = PTE2PA(*pte);
    8000165a:	00a4d593          	srli	a1,s1,0xa
      memmove(mem, (char*)pa, PGSIZE);
    8000165e:	6605                	lui	a2,0x1
    80001660:	05b2                	slli	a1,a1,0xc
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	6ca080e7          	jalr	1738(ra) # 80000d2c <memmove>
    8000166a:	b75d                	j	80001610 <uvmcopy+0x44>
      kfree(mem);
    8000166c:	854e                	mv	a0,s3
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	368080e7          	jalr	872(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001676:	4685                	li	a3,1
    80001678:	00c95613          	srli	a2,s2,0xc
    8000167c:	4581                	li	a1,0
    8000167e:	8556                	mv	a0,s5
    80001680:	00000097          	auipc	ra,0x0
    80001684:	be4080e7          	jalr	-1052(ra) # 80001264 <uvmunmap>
  return -1;
    80001688:	557d                	li	a0,-1
}
    8000168a:	60a6                	ld	ra,72(sp)
    8000168c:	6406                	ld	s0,64(sp)
    8000168e:	74e2                	ld	s1,56(sp)
    80001690:	7942                	ld	s2,48(sp)
    80001692:	79a2                	ld	s3,40(sp)
    80001694:	7a02                	ld	s4,32(sp)
    80001696:	6ae2                	ld	s5,24(sp)
    80001698:	6b42                	ld	s6,16(sp)
    8000169a:	6ba2                	ld	s7,8(sp)
    8000169c:	6161                	addi	sp,sp,80
    8000169e:	8082                	ret
  return 0;
    800016a0:	4501                	li	a0,0
}
    800016a2:	8082                	ret

00000000800016a4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016a4:	1141                	addi	sp,sp,-16
    800016a6:	e406                	sd	ra,8(sp)
    800016a8:	e022                	sd	s0,0(sp)
    800016aa:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ac:	4601                	li	a2,0
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	90a080e7          	jalr	-1782(ra) # 80000fb8 <walk>
  if(pte == 0)
    800016b6:	c901                	beqz	a0,800016c6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016b8:	611c                	ld	a5,0(a0)
    800016ba:	9bbd                	andi	a5,a5,-17
    800016bc:	e11c                	sd	a5,0(a0)
}
    800016be:	60a2                	ld	ra,8(sp)
    800016c0:	6402                	ld	s0,0(sp)
    800016c2:	0141                	addi	sp,sp,16
    800016c4:	8082                	ret
    panic("uvmclear");
    800016c6:	00008517          	auipc	a0,0x8
    800016ca:	b0a50513          	addi	a0,a0,-1270 # 800091d0 <digits+0x190>
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	e5c080e7          	jalr	-420(ra) # 8000052a <panic>

00000000800016d6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016d6:	c6bd                	beqz	a3,80001744 <copyout+0x6e>
{
    800016d8:	715d                	addi	sp,sp,-80
    800016da:	e486                	sd	ra,72(sp)
    800016dc:	e0a2                	sd	s0,64(sp)
    800016de:	fc26                	sd	s1,56(sp)
    800016e0:	f84a                	sd	s2,48(sp)
    800016e2:	f44e                	sd	s3,40(sp)
    800016e4:	f052                	sd	s4,32(sp)
    800016e6:	ec56                	sd	s5,24(sp)
    800016e8:	e85a                	sd	s6,16(sp)
    800016ea:	e45e                	sd	s7,8(sp)
    800016ec:	e062                	sd	s8,0(sp)
    800016ee:	0880                	addi	s0,sp,80
    800016f0:	8b2a                	mv	s6,a0
    800016f2:	8c2e                	mv	s8,a1
    800016f4:	8a32                	mv	s4,a2
    800016f6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016f8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016fa:	6a85                	lui	s5,0x1
    800016fc:	a015                	j	80001720 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016fe:	9562                	add	a0,a0,s8
    80001700:	0004861b          	sext.w	a2,s1
    80001704:	85d2                	mv	a1,s4
    80001706:	41250533          	sub	a0,a0,s2
    8000170a:	fffff097          	auipc	ra,0xfffff
    8000170e:	622080e7          	jalr	1570(ra) # 80000d2c <memmove>

    len -= n;
    80001712:	409989b3          	sub	s3,s3,s1
    src += n;
    80001716:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001718:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000171c:	02098263          	beqz	s3,80001740 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001720:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001724:	85ca                	mv	a1,s2
    80001726:	855a                	mv	a0,s6
    80001728:	00000097          	auipc	ra,0x0
    8000172c:	936080e7          	jalr	-1738(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    80001730:	cd01                	beqz	a0,80001748 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001732:	418904b3          	sub	s1,s2,s8
    80001736:	94d6                	add	s1,s1,s5
    if(n > len)
    80001738:	fc99f3e3          	bgeu	s3,s1,800016fe <copyout+0x28>
    8000173c:	84ce                	mv	s1,s3
    8000173e:	b7c1                	j	800016fe <copyout+0x28>
  }
  return 0;
    80001740:	4501                	li	a0,0
    80001742:	a021                	j	8000174a <copyout+0x74>
    80001744:	4501                	li	a0,0
}
    80001746:	8082                	ret
      return -1;
    80001748:	557d                	li	a0,-1
}
    8000174a:	60a6                	ld	ra,72(sp)
    8000174c:	6406                	ld	s0,64(sp)
    8000174e:	74e2                	ld	s1,56(sp)
    80001750:	7942                	ld	s2,48(sp)
    80001752:	79a2                	ld	s3,40(sp)
    80001754:	7a02                	ld	s4,32(sp)
    80001756:	6ae2                	ld	s5,24(sp)
    80001758:	6b42                	ld	s6,16(sp)
    8000175a:	6ba2                	ld	s7,8(sp)
    8000175c:	6c02                	ld	s8,0(sp)
    8000175e:	6161                	addi	sp,sp,80
    80001760:	8082                	ret

0000000080001762 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001762:	caa5                	beqz	a3,800017d2 <copyin+0x70>
{
    80001764:	715d                	addi	sp,sp,-80
    80001766:	e486                	sd	ra,72(sp)
    80001768:	e0a2                	sd	s0,64(sp)
    8000176a:	fc26                	sd	s1,56(sp)
    8000176c:	f84a                	sd	s2,48(sp)
    8000176e:	f44e                	sd	s3,40(sp)
    80001770:	f052                	sd	s4,32(sp)
    80001772:	ec56                	sd	s5,24(sp)
    80001774:	e85a                	sd	s6,16(sp)
    80001776:	e45e                	sd	s7,8(sp)
    80001778:	e062                	sd	s8,0(sp)
    8000177a:	0880                	addi	s0,sp,80
    8000177c:	8b2a                	mv	s6,a0
    8000177e:	8a2e                	mv	s4,a1
    80001780:	8c32                	mv	s8,a2
    80001782:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001784:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001786:	6a85                	lui	s5,0x1
    80001788:	a01d                	j	800017ae <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000178a:	018505b3          	add	a1,a0,s8
    8000178e:	0004861b          	sext.w	a2,s1
    80001792:	412585b3          	sub	a1,a1,s2
    80001796:	8552                	mv	a0,s4
    80001798:	fffff097          	auipc	ra,0xfffff
    8000179c:	594080e7          	jalr	1428(ra) # 80000d2c <memmove>

    len -= n;
    800017a0:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017a4:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017a6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017aa:	02098263          	beqz	s3,800017ce <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017ae:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017b2:	85ca                	mv	a1,s2
    800017b4:	855a                	mv	a0,s6
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	8a8080e7          	jalr	-1880(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    800017be:	cd01                	beqz	a0,800017d6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017c0:	418904b3          	sub	s1,s2,s8
    800017c4:	94d6                	add	s1,s1,s5
    if(n > len)
    800017c6:	fc99f2e3          	bgeu	s3,s1,8000178a <copyin+0x28>
    800017ca:	84ce                	mv	s1,s3
    800017cc:	bf7d                	j	8000178a <copyin+0x28>
  }
  return 0;
    800017ce:	4501                	li	a0,0
    800017d0:	a021                	j	800017d8 <copyin+0x76>
    800017d2:	4501                	li	a0,0
}
    800017d4:	8082                	ret
      return -1;
    800017d6:	557d                	li	a0,-1
}
    800017d8:	60a6                	ld	ra,72(sp)
    800017da:	6406                	ld	s0,64(sp)
    800017dc:	74e2                	ld	s1,56(sp)
    800017de:	7942                	ld	s2,48(sp)
    800017e0:	79a2                	ld	s3,40(sp)
    800017e2:	7a02                	ld	s4,32(sp)
    800017e4:	6ae2                	ld	s5,24(sp)
    800017e6:	6b42                	ld	s6,16(sp)
    800017e8:	6ba2                	ld	s7,8(sp)
    800017ea:	6c02                	ld	s8,0(sp)
    800017ec:	6161                	addi	sp,sp,80
    800017ee:	8082                	ret

00000000800017f0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017f0:	c6c5                	beqz	a3,80001898 <copyinstr+0xa8>
{
    800017f2:	715d                	addi	sp,sp,-80
    800017f4:	e486                	sd	ra,72(sp)
    800017f6:	e0a2                	sd	s0,64(sp)
    800017f8:	fc26                	sd	s1,56(sp)
    800017fa:	f84a                	sd	s2,48(sp)
    800017fc:	f44e                	sd	s3,40(sp)
    800017fe:	f052                	sd	s4,32(sp)
    80001800:	ec56                	sd	s5,24(sp)
    80001802:	e85a                	sd	s6,16(sp)
    80001804:	e45e                	sd	s7,8(sp)
    80001806:	0880                	addi	s0,sp,80
    80001808:	8a2a                	mv	s4,a0
    8000180a:	8b2e                	mv	s6,a1
    8000180c:	8bb2                	mv	s7,a2
    8000180e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001810:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001812:	6985                	lui	s3,0x1
    80001814:	a035                	j	80001840 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001816:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000181a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000181c:	0017b793          	seqz	a5,a5
    80001820:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001824:	60a6                	ld	ra,72(sp)
    80001826:	6406                	ld	s0,64(sp)
    80001828:	74e2                	ld	s1,56(sp)
    8000182a:	7942                	ld	s2,48(sp)
    8000182c:	79a2                	ld	s3,40(sp)
    8000182e:	7a02                	ld	s4,32(sp)
    80001830:	6ae2                	ld	s5,24(sp)
    80001832:	6b42                	ld	s6,16(sp)
    80001834:	6ba2                	ld	s7,8(sp)
    80001836:	6161                	addi	sp,sp,80
    80001838:	8082                	ret
    srcva = va0 + PGSIZE;
    8000183a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000183e:	c8a9                	beqz	s1,80001890 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001840:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001844:	85ca                	mv	a1,s2
    80001846:	8552                	mv	a0,s4
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	816080e7          	jalr	-2026(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    80001850:	c131                	beqz	a0,80001894 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001852:	41790833          	sub	a6,s2,s7
    80001856:	984e                	add	a6,a6,s3
    if(n > max)
    80001858:	0104f363          	bgeu	s1,a6,8000185e <copyinstr+0x6e>
    8000185c:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000185e:	955e                	add	a0,a0,s7
    80001860:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001864:	fc080be3          	beqz	a6,8000183a <copyinstr+0x4a>
    80001868:	985a                	add	a6,a6,s6
    8000186a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000186c:	41650633          	sub	a2,a0,s6
    80001870:	14fd                	addi	s1,s1,-1
    80001872:	9b26                	add	s6,s6,s1
    80001874:	00f60733          	add	a4,a2,a5
    80001878:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0000>
    8000187c:	df49                	beqz	a4,80001816 <copyinstr+0x26>
        *dst = *p;
    8000187e:	00e78023          	sb	a4,0(a5)
      --max;
    80001882:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001886:	0785                	addi	a5,a5,1
    while(n > 0){
    80001888:	ff0796e3          	bne	a5,a6,80001874 <copyinstr+0x84>
      dst++;
    8000188c:	8b42                	mv	s6,a6
    8000188e:	b775                	j	8000183a <copyinstr+0x4a>
    80001890:	4781                	li	a5,0
    80001892:	b769                	j	8000181c <copyinstr+0x2c>
      return -1;
    80001894:	557d                	li	a0,-1
    80001896:	b779                	j	80001824 <copyinstr+0x34>
  int got_null = 0;
    80001898:	4781                	li	a5,0
  if(got_null){
    8000189a:	0017b793          	seqz	a5,a5
    8000189e:	40f00533          	neg	a0,a5
}
    800018a2:	8082                	ret

00000000800018a4 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018a4:	7139                	addi	sp,sp,-64
    800018a6:	fc06                	sd	ra,56(sp)
    800018a8:	f822                	sd	s0,48(sp)
    800018aa:	f426                	sd	s1,40(sp)
    800018ac:	f04a                	sd	s2,32(sp)
    800018ae:	ec4e                	sd	s3,24(sp)
    800018b0:	e852                	sd	s4,16(sp)
    800018b2:	e456                	sd	s5,8(sp)
    800018b4:	e05a                	sd	s6,0(sp)
    800018b6:	0080                	addi	s0,sp,64
    800018b8:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	00011497          	auipc	s1,0x11
    800018be:	e1648493          	addi	s1,s1,-490 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018c2:	8b26                	mv	s6,s1
    800018c4:	00007a97          	auipc	s5,0x7
    800018c8:	73ca8a93          	addi	s5,s5,1852 # 80009000 <etext>
    800018cc:	04000937          	lui	s2,0x4000
    800018d0:	197d                	addi	s2,s2,-1
    800018d2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d4:	0001fa17          	auipc	s4,0x1f
    800018d8:	bfca0a13          	addi	s4,s4,-1028 # 800204d0 <tickslock>
    char *pa = kalloc();
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	1f6080e7          	jalr	502(ra) # 80000ad2 <kalloc>
    800018e4:	862a                	mv	a2,a0
    if(pa == 0)
    800018e6:	c131                	beqz	a0,8000192a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018e8:	416485b3          	sub	a1,s1,s6
    800018ec:	858d                	srai	a1,a1,0x3
    800018ee:	000ab783          	ld	a5,0(s5)
    800018f2:	02f585b3          	mul	a1,a1,a5
    800018f6:	2585                	addiw	a1,a1,1
    800018f8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018fc:	4719                	li	a4,6
    800018fe:	6685                	lui	a3,0x1
    80001900:	40b905b3          	sub	a1,s2,a1
    80001904:	854e                	mv	a0,s3
    80001906:	00000097          	auipc	ra,0x0
    8000190a:	838080e7          	jalr	-1992(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	37848493          	addi	s1,s1,888
    80001912:	fd4495e3          	bne	s1,s4,800018dc <proc_mapstacks+0x38>
  }
}
    80001916:	70e2                	ld	ra,56(sp)
    80001918:	7442                	ld	s0,48(sp)
    8000191a:	74a2                	ld	s1,40(sp)
    8000191c:	7902                	ld	s2,32(sp)
    8000191e:	69e2                	ld	s3,24(sp)
    80001920:	6a42                	ld	s4,16(sp)
    80001922:	6aa2                	ld	s5,8(sp)
    80001924:	6b02                	ld	s6,0(sp)
    80001926:	6121                	addi	sp,sp,64
    80001928:	8082                	ret
      panic("kalloc");
    8000192a:	00008517          	auipc	a0,0x8
    8000192e:	8b650513          	addi	a0,a0,-1866 # 800091e0 <digits+0x1a0>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	bf8080e7          	jalr	-1032(ra) # 8000052a <panic>

000000008000193a <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000193a:	7139                	addi	sp,sp,-64
    8000193c:	fc06                	sd	ra,56(sp)
    8000193e:	f822                	sd	s0,48(sp)
    80001940:	f426                	sd	s1,40(sp)
    80001942:	f04a                	sd	s2,32(sp)
    80001944:	ec4e                	sd	s3,24(sp)
    80001946:	e852                	sd	s4,16(sp)
    80001948:	e456                	sd	s5,8(sp)
    8000194a:	e05a                	sd	s6,0(sp)
    8000194c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000194e:	00008597          	auipc	a1,0x8
    80001952:	89a58593          	addi	a1,a1,-1894 # 800091e8 <digits+0x1a8>
    80001956:	00011517          	auipc	a0,0x11
    8000195a:	94a50513          	addi	a0,a0,-1718 # 800122a0 <pid_lock>
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	1d4080e7          	jalr	468(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001966:	00008597          	auipc	a1,0x8
    8000196a:	88a58593          	addi	a1,a1,-1910 # 800091f0 <digits+0x1b0>
    8000196e:	00011517          	auipc	a0,0x11
    80001972:	94a50513          	addi	a0,a0,-1718 # 800122b8 <wait_lock>
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	1bc080e7          	jalr	444(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	00011497          	auipc	s1,0x11
    80001982:	d5248493          	addi	s1,s1,-686 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80001986:	00008b17          	auipc	s6,0x8
    8000198a:	87ab0b13          	addi	s6,s6,-1926 # 80009200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    8000198e:	8aa6                	mv	s5,s1
    80001990:	00007a17          	auipc	s4,0x7
    80001994:	670a0a13          	addi	s4,s4,1648 # 80009000 <etext>
    80001998:	04000937          	lui	s2,0x4000
    8000199c:	197d                	addi	s2,s2,-1
    8000199e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	0001f997          	auipc	s3,0x1f
    800019a4:	b3098993          	addi	s3,s3,-1232 # 800204d0 <tickslock>
      initlock(&p->lock, "proc");
    800019a8:	85da                	mv	a1,s6
    800019aa:	8526                	mv	a0,s1
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	186080e7          	jalr	390(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019b4:	415487b3          	sub	a5,s1,s5
    800019b8:	878d                	srai	a5,a5,0x3
    800019ba:	000a3703          	ld	a4,0(s4)
    800019be:	02e787b3          	mul	a5,a5,a4
    800019c2:	2785                	addiw	a5,a5,1
    800019c4:	00d7979b          	slliw	a5,a5,0xd
    800019c8:	40f907b3          	sub	a5,s2,a5
    800019cc:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ce:	37848493          	addi	s1,s1,888
    800019d2:	fd349be3          	bne	s1,s3,800019a8 <procinit+0x6e>
  }
}
    800019d6:	70e2                	ld	ra,56(sp)
    800019d8:	7442                	ld	s0,48(sp)
    800019da:	74a2                	ld	s1,40(sp)
    800019dc:	7902                	ld	s2,32(sp)
    800019de:	69e2                	ld	s3,24(sp)
    800019e0:	6a42                	ld	s4,16(sp)
    800019e2:	6aa2                	ld	s5,8(sp)
    800019e4:	6b02                	ld	s6,0(sp)
    800019e6:	6121                	addi	sp,sp,64
    800019e8:	8082                	ret

00000000800019ea <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ea:	1141                	addi	sp,sp,-16
    800019ec:	e422                	sd	s0,8(sp)
    800019ee:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019f2:	2501                	sext.w	a0,a0
    800019f4:	6422                	ld	s0,8(sp)
    800019f6:	0141                	addi	sp,sp,16
    800019f8:	8082                	ret

00000000800019fa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e422                	sd	s0,8(sp)
    800019fe:	0800                	addi	s0,sp,16
    80001a00:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a02:	2781                	sext.w	a5,a5
    80001a04:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a06:	00011517          	auipc	a0,0x11
    80001a0a:	8ca50513          	addi	a0,a0,-1846 # 800122d0 <cpus>
    80001a0e:	953e                	add	a0,a0,a5
    80001a10:	6422                	ld	s0,8(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret

0000000080001a16 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a16:	1101                	addi	sp,sp,-32
    80001a18:	ec06                	sd	ra,24(sp)
    80001a1a:	e822                	sd	s0,16(sp)
    80001a1c:	e426                	sd	s1,8(sp)
    80001a1e:	1000                	addi	s0,sp,32
  push_off();
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	156080e7          	jalr	342(ra) # 80000b76 <push_off>
    80001a28:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a2a:	2781                	sext.w	a5,a5
    80001a2c:	079e                	slli	a5,a5,0x7
    80001a2e:	00011717          	auipc	a4,0x11
    80001a32:	87270713          	addi	a4,a4,-1934 # 800122a0 <pid_lock>
    80001a36:	97ba                	add	a5,a5,a4
    80001a38:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	1ee080e7          	jalr	494(ra) # 80000c28 <pop_off>
  return p;
}
    80001a42:	8526                	mv	a0,s1
    80001a44:	60e2                	ld	ra,24(sp)
    80001a46:	6442                	ld	s0,16(sp)
    80001a48:	64a2                	ld	s1,8(sp)
    80001a4a:	6105                	addi	sp,sp,32
    80001a4c:	8082                	ret

0000000080001a4e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a4e:	1141                	addi	sp,sp,-16
    80001a50:	e406                	sd	ra,8(sp)
    80001a52:	e022                	sd	s0,0(sp)
    80001a54:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a56:	00000097          	auipc	ra,0x0
    80001a5a:	fc0080e7          	jalr	-64(ra) # 80001a16 <myproc>
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	22a080e7          	jalr	554(ra) # 80000c88 <release>

  if (first) {
    80001a66:	00008797          	auipc	a5,0x8
    80001a6a:	22a7a783          	lw	a5,554(a5) # 80009c90 <first.1>
    80001a6e:	eb89                	bnez	a5,80001a80 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a70:	00001097          	auipc	ra,0x1
    80001a74:	5ee080e7          	jalr	1518(ra) # 8000305e <usertrapret>
}
    80001a78:	60a2                	ld	ra,8(sp)
    80001a7a:	6402                	ld	s0,0(sp)
    80001a7c:	0141                	addi	sp,sp,16
    80001a7e:	8082                	ret
    first = 0;
    80001a80:	00008797          	auipc	a5,0x8
    80001a84:	2007a823          	sw	zero,528(a5) # 80009c90 <first.1>
    fsinit(ROOTDEV);
    80001a88:	4505                	li	a0,1
    80001a8a:	00002097          	auipc	ra,0x2
    80001a8e:	36e080e7          	jalr	878(ra) # 80003df8 <fsinit>
    80001a92:	bff9                	j	80001a70 <forkret+0x22>

0000000080001a94 <allocpid>:
allocpid() {
    80001a94:	1101                	addi	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	e426                	sd	s1,8(sp)
    80001a9c:	e04a                	sd	s2,0(sp)
    80001a9e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aa0:	00011917          	auipc	s2,0x11
    80001aa4:	80090913          	addi	s2,s2,-2048 # 800122a0 <pid_lock>
    80001aa8:	854a                	mv	a0,s2
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	118080e7          	jalr	280(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001ab2:	00008797          	auipc	a5,0x8
    80001ab6:	1e278793          	addi	a5,a5,482 # 80009c94 <nextpid>
    80001aba:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001abc:	0014871b          	addiw	a4,s1,1
    80001ac0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ac2:	854a                	mv	a0,s2
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	1c4080e7          	jalr	452(ra) # 80000c88 <release>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret

0000000080001ada <proc_pagetable>:
{
    80001ada:	1101                	addi	sp,sp,-32
    80001adc:	ec06                	sd	ra,24(sp)
    80001ade:	e822                	sd	s0,16(sp)
    80001ae0:	e426                	sd	s1,8(sp)
    80001ae2:	e04a                	sd	s2,0(sp)
    80001ae4:	1000                	addi	s0,sp,32
    80001ae6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	848080e7          	jalr	-1976(ra) # 80001330 <uvmcreate>
    80001af0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001af2:	c121                	beqz	a0,80001b32 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001af4:	4729                	li	a4,10
    80001af6:	00006697          	auipc	a3,0x6
    80001afa:	50a68693          	addi	a3,a3,1290 # 80008000 <_trampoline>
    80001afe:	6605                	lui	a2,0x1
    80001b00:	040005b7          	lui	a1,0x4000
    80001b04:	15fd                	addi	a1,a1,-1
    80001b06:	05b2                	slli	a1,a1,0xc
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	598080e7          	jalr	1432(ra) # 800010a0 <mappages>
    80001b10:	02054863          	bltz	a0,80001b40 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b14:	4719                	li	a4,6
    80001b16:	05893683          	ld	a3,88(s2)
    80001b1a:	6605                	lui	a2,0x1
    80001b1c:	020005b7          	lui	a1,0x2000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b6                	slli	a1,a1,0xd
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	57a080e7          	jalr	1402(ra) # 800010a0 <mappages>
    80001b2e:	02054163          	bltz	a0,80001b50 <proc_pagetable+0x76>
}
    80001b32:	8526                	mv	a0,s1
    80001b34:	60e2                	ld	ra,24(sp)
    80001b36:	6442                	ld	s0,16(sp)
    80001b38:	64a2                	ld	s1,8(sp)
    80001b3a:	6902                	ld	s2,0(sp)
    80001b3c:	6105                	addi	sp,sp,32
    80001b3e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b40:	4581                	li	a1,0
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	a50080e7          	jalr	-1456(ra) # 80001594 <uvmfree>
    return 0;
    80001b4c:	4481                	li	s1,0
    80001b4e:	b7d5                	j	80001b32 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	040005b7          	lui	a1,0x4000
    80001b58:	15fd                	addi	a1,a1,-1
    80001b5a:	05b2                	slli	a1,a1,0xc
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	706080e7          	jalr	1798(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b66:	4581                	li	a1,0
    80001b68:	8526                	mv	a0,s1
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	a2a080e7          	jalr	-1494(ra) # 80001594 <uvmfree>
    return 0;
    80001b72:	4481                	li	s1,0
    80001b74:	bf7d                	j	80001b32 <proc_pagetable+0x58>

0000000080001b76 <proc_freepagetable>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
    80001b84:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	040005b7          	lui	a1,0x4000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b2                	slli	a1,a1,0xc
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	6d2080e7          	jalr	1746(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b9a:	4681                	li	a3,0
    80001b9c:	4605                	li	a2,1
    80001b9e:	020005b7          	lui	a1,0x2000
    80001ba2:	15fd                	addi	a1,a1,-1
    80001ba4:	05b6                	slli	a1,a1,0xd
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	6bc080e7          	jalr	1724(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bb0:	85ca                	mv	a1,s2
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	9e0080e7          	jalr	-1568(ra) # 80001594 <uvmfree>
}
    80001bbc:	60e2                	ld	ra,24(sp)
    80001bbe:	6442                	ld	s0,16(sp)
    80001bc0:	64a2                	ld	s1,8(sp)
    80001bc2:	6902                	ld	s2,0(sp)
    80001bc4:	6105                	addi	sp,sp,32
    80001bc6:	8082                	ret

0000000080001bc8 <freeproc>:
{
    80001bc8:	1101                	addi	sp,sp,-32
    80001bca:	ec06                	sd	ra,24(sp)
    80001bcc:	e822                	sd	s0,16(sp)
    80001bce:	e426                	sd	s1,8(sp)
    80001bd0:	1000                	addi	s0,sp,32
    80001bd2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bd4:	6d28                	ld	a0,88(a0)
    80001bd6:	c509                	beqz	a0,80001be0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	dfe080e7          	jalr	-514(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001be0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001be4:	68a8                	ld	a0,80(s1)
    80001be6:	c511                	beqz	a0,80001bf2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001be8:	64ac                	ld	a1,72(s1)
    80001bea:	00000097          	auipc	ra,0x0
    80001bee:	f8c080e7          	jalr	-116(ra) # 80001b76 <proc_freepagetable>
  p->pagetable = 0;
    80001bf2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bf6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bfa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bfe:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c02:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c06:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c0a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c0e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c12:	0004ac23          	sw	zero,24(s1)
}
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6105                	addi	sp,sp,32
    80001c1e:	8082                	ret

0000000080001c20 <allocproc>:
{
    80001c20:	1101                	addi	sp,sp,-32
    80001c22:	ec06                	sd	ra,24(sp)
    80001c24:	e822                	sd	s0,16(sp)
    80001c26:	e426                	sd	s1,8(sp)
    80001c28:	e04a                	sd	s2,0(sp)
    80001c2a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2c:	00011497          	auipc	s1,0x11
    80001c30:	aa448493          	addi	s1,s1,-1372 # 800126d0 <proc>
    80001c34:	0001f917          	auipc	s2,0x1f
    80001c38:	89c90913          	addi	s2,s2,-1892 # 800204d0 <tickslock>
    acquire(&p->lock);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	f84080e7          	jalr	-124(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001c46:	4c9c                	lw	a5,24(s1)
    80001c48:	cf81                	beqz	a5,80001c60 <allocproc+0x40>
      release(&p->lock);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	03c080e7          	jalr	60(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c54:	37848493          	addi	s1,s1,888
    80001c58:	ff2492e3          	bne	s1,s2,80001c3c <allocproc+0x1c>
  return 0;
    80001c5c:	4481                	li	s1,0
    80001c5e:	a889                	j	80001cb0 <allocproc+0x90>
  p->pid = allocpid();
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	e34080e7          	jalr	-460(ra) # 80001a94 <allocpid>
    80001c68:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c6a:	4785                	li	a5,1
    80001c6c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	e64080e7          	jalr	-412(ra) # 80000ad2 <kalloc>
    80001c76:	892a                	mv	s2,a0
    80001c78:	eca8                	sd	a0,88(s1)
    80001c7a:	c131                	beqz	a0,80001cbe <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	e5c080e7          	jalr	-420(ra) # 80001ada <proc_pagetable>
    80001c86:	892a                	mv	s2,a0
    80001c88:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c8a:	c531                	beqz	a0,80001cd6 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c8c:	07000613          	li	a2,112
    80001c90:	4581                	li	a1,0
    80001c92:	06048513          	addi	a0,s1,96
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	03a080e7          	jalr	58(ra) # 80000cd0 <memset>
  p->context.ra = (uint64)forkret;
    80001c9e:	00000797          	auipc	a5,0x0
    80001ca2:	db078793          	addi	a5,a5,-592 # 80001a4e <forkret>
    80001ca6:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ca8:	60bc                	ld	a5,64(s1)
    80001caa:	6705                	lui	a4,0x1
    80001cac:	97ba                	add	a5,a5,a4
    80001cae:	f4bc                	sd	a5,104(s1)
}
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6902                	ld	s2,0(sp)
    80001cba:	6105                	addi	sp,sp,32
    80001cbc:	8082                	ret
    freeproc(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	f08080e7          	jalr	-248(ra) # 80001bc8 <freeproc>
    release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fbe080e7          	jalr	-66(ra) # 80000c88 <release>
    return 0;
    80001cd2:	84ca                	mv	s1,s2
    80001cd4:	bff1                	j	80001cb0 <allocproc+0x90>
    freeproc(p);
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	ef0080e7          	jalr	-272(ra) # 80001bc8 <freeproc>
    release(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	fa6080e7          	jalr	-90(ra) # 80000c88 <release>
    return 0;
    80001cea:	84ca                	mv	s1,s2
    80001cec:	b7d1                	j	80001cb0 <allocproc+0x90>

0000000080001cee <userinit>:
{
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	f28080e7          	jalr	-216(ra) # 80001c20 <allocproc>
    80001d00:	84aa                	mv	s1,a0
  initproc = p;
    80001d02:	00008797          	auipc	a5,0x8
    80001d06:	32a7b323          	sd	a0,806(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0a:	03400613          	li	a2,52
    80001d0e:	00008597          	auipc	a1,0x8
    80001d12:	f9258593          	addi	a1,a1,-110 # 80009ca0 <initcode>
    80001d16:	6928                	ld	a0,80(a0)
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	646080e7          	jalr	1606(ra) # 8000135e <uvminit>
  p->sz = PGSIZE;
    80001d20:	6785                	lui	a5,0x1
    80001d22:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d24:	6cb8                	ld	a4,88(s1)
    80001d26:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2a:	6cb8                	ld	a4,88(s1)
    80001d2c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d2e:	4641                	li	a2,16
    80001d30:	00007597          	auipc	a1,0x7
    80001d34:	4d858593          	addi	a1,a1,1240 # 80009208 <digits+0x1c8>
    80001d38:	15848513          	addi	a0,s1,344
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	0e6080e7          	jalr	230(ra) # 80000e22 <safestrcpy>
  p->cwd = namei("/");
    80001d44:	00007517          	auipc	a0,0x7
    80001d48:	4d450513          	addi	a0,a0,1236 # 80009218 <digits+0x1d8>
    80001d4c:	00003097          	auipc	ra,0x3
    80001d50:	ada080e7          	jalr	-1318(ra) # 80004826 <namei>
    80001d54:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d58:	478d                	li	a5,3
    80001d5a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5c:	8526                	mv	a0,s1
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	f2a080e7          	jalr	-214(ra) # 80000c88 <release>
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret

0000000080001d70 <growproc>:
{
    80001d70:	1101                	addi	sp,sp,-32
    80001d72:	ec06                	sd	ra,24(sp)
    80001d74:	e822                	sd	s0,16(sp)
    80001d76:	e426                	sd	s1,8(sp)
    80001d78:	e04a                	sd	s2,0(sp)
    80001d7a:	1000                	addi	s0,sp,32
    80001d7c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	c98080e7          	jalr	-872(ra) # 80001a16 <myproc>
    80001d86:	892a                	mv	s2,a0
  sz = p->sz;
    80001d88:	652c                	ld	a1,72(a0)
    80001d8a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d8e:	00904f63          	bgtz	s1,80001dac <growproc+0x3c>
  } else if(n < 0){
    80001d92:	0204cc63          	bltz	s1,80001dca <growproc+0x5a>
  p->sz = sz;
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d9e:	4501                	li	a0,0
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6902                	ld	s2,0(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dac:	9e25                	addw	a2,a2,s1
    80001dae:	1602                	slli	a2,a2,0x20
    80001db0:	9201                	srli	a2,a2,0x20
    80001db2:	1582                	slli	a1,a1,0x20
    80001db4:	9181                	srli	a1,a1,0x20
    80001db6:	6928                	ld	a0,80(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	6ae080e7          	jalr	1710(ra) # 80001466 <uvmalloc>
    80001dc0:	0005061b          	sext.w	a2,a0
    80001dc4:	fa69                	bnez	a2,80001d96 <growproc+0x26>
      return -1;
    80001dc6:	557d                	li	a0,-1
    80001dc8:	bfe1                	j	80001da0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dca:	9e25                	addw	a2,a2,s1
    80001dcc:	1602                	slli	a2,a2,0x20
    80001dce:	9201                	srli	a2,a2,0x20
    80001dd0:	1582                	slli	a1,a1,0x20
    80001dd2:	9181                	srli	a1,a1,0x20
    80001dd4:	6928                	ld	a0,80(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	5fa080e7          	jalr	1530(ra) # 800013d0 <uvmdealloc>
    80001dde:	0005061b          	sext.w	a2,a0
    80001de2:	bf55                	j	80001d96 <growproc+0x26>

0000000080001de4 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001de4:	c559                	beqz	a0,80001e72 <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001de6:	7139                	addi	sp,sp,-64
    80001de8:	fc06                	sd	ra,56(sp)
    80001dea:	f822                	sd	s0,48(sp)
    80001dec:	f426                	sd	s1,40(sp)
    80001dee:	f04a                	sd	s2,32(sp)
    80001df0:	ec4e                	sd	s3,24(sp)
    80001df2:	e852                	sd	s4,16(sp)
    80001df4:	e456                	sd	s5,8(sp)
    80001df6:	0080                	addi	s0,sp,64
    80001df8:	89aa                	mv	s3,a0
    80001dfa:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001dfc:	16853783          	ld	a5,360(a0)
    80001e00:	cbbd                	beqz	a5,80001e76 <copy_swapFile+0x92>
    80001e02:	cda5                	beqz	a1,80001e7a <copy_swapFile+0x96>
    80001e04:	1685b783          	ld	a5,360(a1)
    80001e08:	cbbd                	beqz	a5,80001e7e <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	cc8080e7          	jalr	-824(ra) # 80000ad2 <kalloc>
    80001e12:	892a                	mv	s2,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_PSYC_PAGES]; disk_pg++) {
    80001e14:	27098493          	addi	s1,s3,624
    80001e18:	37098a13          	addi	s4,s3,880
    80001e1c:	a021                	j	80001e24 <copy_swapFile+0x40>
    80001e1e:	04c1                	addi	s1,s1,16
    80001e20:	029a0a63          	beq	s4,s1,80001e54 <copy_swapFile+0x70>
    if(!disk_pg->used) {
    80001e24:	44dc                	lw	a5,12(s1)
    80001e26:	dfe5                	beqz	a5,80001e1e <copy_swapFile+0x3a>
    if (readFromSwapFile(src, buffer, disk_pg->offset, total_size) < 0) {
    80001e28:	66c1                	lui	a3,0x10
    80001e2a:	4490                	lw	a2,8(s1)
    80001e2c:	85ca                	mv	a1,s2
    80001e2e:	854e                	mv	a0,s3
    80001e30:	00003097          	auipc	ra,0x3
    80001e34:	d1e080e7          	jalr	-738(ra) # 80004b4e <readFromSwapFile>
    80001e38:	04054563          	bltz	a0,80001e82 <copy_swapFile+0x9e>
    if (writeToSwapFile(dst, buffer, disk_pg->offset, total_size) < 0) {
    80001e3c:	66c1                	lui	a3,0x10
    80001e3e:	4490                	lw	a2,8(s1)
    80001e40:	85ca                	mv	a1,s2
    80001e42:	8556                	mv	a0,s5
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	ce6080e7          	jalr	-794(ra) # 80004b2a <writeToSwapFile>
    80001e4c:	fc0559e3          	bgez	a0,80001e1e <copy_swapFile+0x3a>
      return -1;
    80001e50:	557d                	li	a0,-1
    80001e52:	a039                	j	80001e60 <copy_swapFile+0x7c>
  kfree(buffer);
    80001e54:	854a                	mv	a0,s2
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	b80080e7          	jalr	-1152(ra) # 800009d6 <kfree>
  return 0;
    80001e5e:	4501                	li	a0,0
}
    80001e60:	70e2                	ld	ra,56(sp)
    80001e62:	7442                	ld	s0,48(sp)
    80001e64:	74a2                	ld	s1,40(sp)
    80001e66:	7902                	ld	s2,32(sp)
    80001e68:	69e2                	ld	s3,24(sp)
    80001e6a:	6a42                	ld	s4,16(sp)
    80001e6c:	6aa2                	ld	s5,8(sp)
    80001e6e:	6121                	addi	sp,sp,64
    80001e70:	8082                	ret
    return -1;
    80001e72:	557d                	li	a0,-1
}
    80001e74:	8082                	ret
    return -1;
    80001e76:	557d                	li	a0,-1
    80001e78:	b7e5                	j	80001e60 <copy_swapFile+0x7c>
    80001e7a:	557d                	li	a0,-1
    80001e7c:	b7d5                	j	80001e60 <copy_swapFile+0x7c>
    80001e7e:	557d                	li	a0,-1
    80001e80:	b7c5                	j	80001e60 <copy_swapFile+0x7c>
      return -1;
    80001e82:	557d                	li	a0,-1
    80001e84:	bff1                	j	80001e60 <copy_swapFile+0x7c>

0000000080001e86 <scheduler>:
{
    80001e86:	7139                	addi	sp,sp,-64
    80001e88:	fc06                	sd	ra,56(sp)
    80001e8a:	f822                	sd	s0,48(sp)
    80001e8c:	f426                	sd	s1,40(sp)
    80001e8e:	f04a                	sd	s2,32(sp)
    80001e90:	ec4e                	sd	s3,24(sp)
    80001e92:	e852                	sd	s4,16(sp)
    80001e94:	e456                	sd	s5,8(sp)
    80001e96:	e05a                	sd	s6,0(sp)
    80001e98:	0080                	addi	s0,sp,64
    80001e9a:	8792                	mv	a5,tp
  int id = r_tp();
    80001e9c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e9e:	00779a93          	slli	s5,a5,0x7
    80001ea2:	00010717          	auipc	a4,0x10
    80001ea6:	3fe70713          	addi	a4,a4,1022 # 800122a0 <pid_lock>
    80001eaa:	9756                	add	a4,a4,s5
    80001eac:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eb0:	00010717          	auipc	a4,0x10
    80001eb4:	42870713          	addi	a4,a4,1064 # 800122d8 <cpus+0x8>
    80001eb8:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eba:	498d                	li	s3,3
        p->state = RUNNING;
    80001ebc:	4b11                	li	s6,4
        c->proc = p;
    80001ebe:	079e                	slli	a5,a5,0x7
    80001ec0:	00010a17          	auipc	s4,0x10
    80001ec4:	3e0a0a13          	addi	s4,s4,992 # 800122a0 <pid_lock>
    80001ec8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eca:	0001e917          	auipc	s2,0x1e
    80001ece:	60690913          	addi	s2,s2,1542 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ed2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ed6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eda:	10079073          	csrw	sstatus,a5
    80001ede:	00010497          	auipc	s1,0x10
    80001ee2:	7f248493          	addi	s1,s1,2034 # 800126d0 <proc>
    80001ee6:	a811                	j	80001efa <scheduler+0x74>
      release(&p->lock);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	d9e080e7          	jalr	-610(ra) # 80000c88 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef2:	37848493          	addi	s1,s1,888
    80001ef6:	fd248ee3          	beq	s1,s2,80001ed2 <scheduler+0x4c>
      acquire(&p->lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	cc6080e7          	jalr	-826(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f04:	4c9c                	lw	a5,24(s1)
    80001f06:	ff3791e3          	bne	a5,s3,80001ee8 <scheduler+0x62>
        p->state = RUNNING;
    80001f0a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f0e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f12:	06048593          	addi	a1,s1,96
    80001f16:	8556                	mv	a0,s5
    80001f18:	00001097          	auipc	ra,0x1
    80001f1c:	09c080e7          	jalr	156(ra) # 80002fb4 <swtch>
        c->proc = 0;
    80001f20:	020a3823          	sd	zero,48(s4)
    80001f24:	b7d1                	j	80001ee8 <scheduler+0x62>

0000000080001f26 <sched>:
{
    80001f26:	7179                	addi	sp,sp,-48
    80001f28:	f406                	sd	ra,40(sp)
    80001f2a:	f022                	sd	s0,32(sp)
    80001f2c:	ec26                	sd	s1,24(sp)
    80001f2e:	e84a                	sd	s2,16(sp)
    80001f30:	e44e                	sd	s3,8(sp)
    80001f32:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	ae2080e7          	jalr	-1310(ra) # 80001a16 <myproc>
    80001f3c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	c0a080e7          	jalr	-1014(ra) # 80000b48 <holding>
    80001f46:	c93d                	beqz	a0,80001fbc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f48:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f4a:	2781                	sext.w	a5,a5
    80001f4c:	079e                	slli	a5,a5,0x7
    80001f4e:	00010717          	auipc	a4,0x10
    80001f52:	35270713          	addi	a4,a4,850 # 800122a0 <pid_lock>
    80001f56:	97ba                	add	a5,a5,a4
    80001f58:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f5c:	4785                	li	a5,1
    80001f5e:	06f71763          	bne	a4,a5,80001fcc <sched+0xa6>
  if(p->state == RUNNING)
    80001f62:	4c98                	lw	a4,24(s1)
    80001f64:	4791                	li	a5,4
    80001f66:	06f70b63          	beq	a4,a5,80001fdc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f6e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f70:	efb5                	bnez	a5,80001fec <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f72:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f74:	00010917          	auipc	s2,0x10
    80001f78:	32c90913          	addi	s2,s2,812 # 800122a0 <pid_lock>
    80001f7c:	2781                	sext.w	a5,a5
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	97ca                	add	a5,a5,s2
    80001f82:	0ac7a983          	lw	s3,172(a5)
    80001f86:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f88:	2781                	sext.w	a5,a5
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	00010597          	auipc	a1,0x10
    80001f90:	34c58593          	addi	a1,a1,844 # 800122d8 <cpus+0x8>
    80001f94:	95be                	add	a1,a1,a5
    80001f96:	06048513          	addi	a0,s1,96
    80001f9a:	00001097          	auipc	ra,0x1
    80001f9e:	01a080e7          	jalr	26(ra) # 80002fb4 <swtch>
    80001fa2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	97ca                	add	a5,a5,s2
    80001faa:	0b37a623          	sw	s3,172(a5)
}
    80001fae:	70a2                	ld	ra,40(sp)
    80001fb0:	7402                	ld	s0,32(sp)
    80001fb2:	64e2                	ld	s1,24(sp)
    80001fb4:	6942                	ld	s2,16(sp)
    80001fb6:	69a2                	ld	s3,8(sp)
    80001fb8:	6145                	addi	sp,sp,48
    80001fba:	8082                	ret
    panic("sched p->lock");
    80001fbc:	00007517          	auipc	a0,0x7
    80001fc0:	26450513          	addi	a0,a0,612 # 80009220 <digits+0x1e0>
    80001fc4:	ffffe097          	auipc	ra,0xffffe
    80001fc8:	566080e7          	jalr	1382(ra) # 8000052a <panic>
    panic("sched locks");
    80001fcc:	00007517          	auipc	a0,0x7
    80001fd0:	26450513          	addi	a0,a0,612 # 80009230 <digits+0x1f0>
    80001fd4:	ffffe097          	auipc	ra,0xffffe
    80001fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    panic("sched running");
    80001fdc:	00007517          	auipc	a0,0x7
    80001fe0:	26450513          	addi	a0,a0,612 # 80009240 <digits+0x200>
    80001fe4:	ffffe097          	auipc	ra,0xffffe
    80001fe8:	546080e7          	jalr	1350(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001fec:	00007517          	auipc	a0,0x7
    80001ff0:	26450513          	addi	a0,a0,612 # 80009250 <digits+0x210>
    80001ff4:	ffffe097          	auipc	ra,0xffffe
    80001ff8:	536080e7          	jalr	1334(ra) # 8000052a <panic>

0000000080001ffc <yield>:
{
    80001ffc:	1101                	addi	sp,sp,-32
    80001ffe:	ec06                	sd	ra,24(sp)
    80002000:	e822                	sd	s0,16(sp)
    80002002:	e426                	sd	s1,8(sp)
    80002004:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	a10080e7          	jalr	-1520(ra) # 80001a16 <myproc>
    8000200e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	bb2080e7          	jalr	-1102(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002018:	478d                	li	a5,3
    8000201a:	cc9c                	sw	a5,24(s1)
  sched();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	f0a080e7          	jalr	-246(ra) # 80001f26 <sched>
  release(&p->lock);
    80002024:	8526                	mv	a0,s1
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	c62080e7          	jalr	-926(ra) # 80000c88 <release>
}
    8000202e:	60e2                	ld	ra,24(sp)
    80002030:	6442                	ld	s0,16(sp)
    80002032:	64a2                	ld	s1,8(sp)
    80002034:	6105                	addi	sp,sp,32
    80002036:	8082                	ret

0000000080002038 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002038:	7179                	addi	sp,sp,-48
    8000203a:	f406                	sd	ra,40(sp)
    8000203c:	f022                	sd	s0,32(sp)
    8000203e:	ec26                	sd	s1,24(sp)
    80002040:	e84a                	sd	s2,16(sp)
    80002042:	e44e                	sd	s3,8(sp)
    80002044:	1800                	addi	s0,sp,48
    80002046:	89aa                	mv	s3,a0
    80002048:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	9cc080e7          	jalr	-1588(ra) # 80001a16 <myproc>
    80002052:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	b6e080e7          	jalr	-1170(ra) # 80000bc2 <acquire>
  release(lk);
    8000205c:	854a                	mv	a0,s2
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c2a080e7          	jalr	-982(ra) # 80000c88 <release>

  // Go to sleep.
  p->chan = chan;
    80002066:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000206a:	4789                	li	a5,2
    8000206c:	cc9c                	sw	a5,24(s1)

  sched();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	eb8080e7          	jalr	-328(ra) # 80001f26 <sched>

  // Tidy up.
  p->chan = 0;
    80002076:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c0c080e7          	jalr	-1012(ra) # 80000c88 <release>
  acquire(lk);
    80002084:	854a                	mv	a0,s2
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b3c080e7          	jalr	-1220(ra) # 80000bc2 <acquire>
}
    8000208e:	70a2                	ld	ra,40(sp)
    80002090:	7402                	ld	s0,32(sp)
    80002092:	64e2                	ld	s1,24(sp)
    80002094:	6942                	ld	s2,16(sp)
    80002096:	69a2                	ld	s3,8(sp)
    80002098:	6145                	addi	sp,sp,48
    8000209a:	8082                	ret

000000008000209c <wait>:
{
    8000209c:	715d                	addi	sp,sp,-80
    8000209e:	e486                	sd	ra,72(sp)
    800020a0:	e0a2                	sd	s0,64(sp)
    800020a2:	fc26                	sd	s1,56(sp)
    800020a4:	f84a                	sd	s2,48(sp)
    800020a6:	f44e                	sd	s3,40(sp)
    800020a8:	f052                	sd	s4,32(sp)
    800020aa:	ec56                	sd	s5,24(sp)
    800020ac:	e85a                	sd	s6,16(sp)
    800020ae:	e45e                	sd	s7,8(sp)
    800020b0:	e062                	sd	s8,0(sp)
    800020b2:	0880                	addi	s0,sp,80
    800020b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	960080e7          	jalr	-1696(ra) # 80001a16 <myproc>
    800020be:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020c0:	00010517          	auipc	a0,0x10
    800020c4:	1f850513          	addi	a0,a0,504 # 800122b8 <wait_lock>
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	afa080e7          	jalr	-1286(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020d0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020d2:	4a15                	li	s4,5
        havekids = 1;
    800020d4:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020d6:	0001e997          	auipc	s3,0x1e
    800020da:	3fa98993          	addi	s3,s3,1018 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020de:	00010c17          	auipc	s8,0x10
    800020e2:	1dac0c13          	addi	s8,s8,474 # 800122b8 <wait_lock>
    havekids = 0;
    800020e6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020e8:	00010497          	auipc	s1,0x10
    800020ec:	5e848493          	addi	s1,s1,1512 # 800126d0 <proc>
    800020f0:	a0bd                	j	8000215e <wait+0xc2>
          pid = np->pid;
    800020f2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020f6:	000b0e63          	beqz	s6,80002112 <wait+0x76>
    800020fa:	4691                	li	a3,4
    800020fc:	02c48613          	addi	a2,s1,44
    80002100:	85da                	mv	a1,s6
    80002102:	05093503          	ld	a0,80(s2)
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	5d0080e7          	jalr	1488(ra) # 800016d6 <copyout>
    8000210e:	02054563          	bltz	a0,80002138 <wait+0x9c>
          freeproc(np);
    80002112:	8526                	mv	a0,s1
    80002114:	00000097          	auipc	ra,0x0
    80002118:	ab4080e7          	jalr	-1356(ra) # 80001bc8 <freeproc>
          release(&np->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b6a080e7          	jalr	-1174(ra) # 80000c88 <release>
          release(&wait_lock);
    80002126:	00010517          	auipc	a0,0x10
    8000212a:	19250513          	addi	a0,a0,402 # 800122b8 <wait_lock>
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b5a080e7          	jalr	-1190(ra) # 80000c88 <release>
          return pid;
    80002136:	a09d                	j	8000219c <wait+0x100>
            release(&np->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b4e080e7          	jalr	-1202(ra) # 80000c88 <release>
            release(&wait_lock);
    80002142:	00010517          	auipc	a0,0x10
    80002146:	17650513          	addi	a0,a0,374 # 800122b8 <wait_lock>
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b3e080e7          	jalr	-1218(ra) # 80000c88 <release>
            return -1;
    80002152:	59fd                	li	s3,-1
    80002154:	a0a1                	j	8000219c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002156:	37848493          	addi	s1,s1,888
    8000215a:	03348463          	beq	s1,s3,80002182 <wait+0xe6>
      if(np->parent == p){
    8000215e:	7c9c                	ld	a5,56(s1)
    80002160:	ff279be3          	bne	a5,s2,80002156 <wait+0xba>
        acquire(&np->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	a5c080e7          	jalr	-1444(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000216e:	4c9c                	lw	a5,24(s1)
    80002170:	f94781e3          	beq	a5,s4,800020f2 <wait+0x56>
        release(&np->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b12080e7          	jalr	-1262(ra) # 80000c88 <release>
        havekids = 1;
    8000217e:	8756                	mv	a4,s5
    80002180:	bfd9                	j	80002156 <wait+0xba>
    if(!havekids || p->killed){
    80002182:	c701                	beqz	a4,8000218a <wait+0xee>
    80002184:	02892783          	lw	a5,40(s2)
    80002188:	c79d                	beqz	a5,800021b6 <wait+0x11a>
      release(&wait_lock);
    8000218a:	00010517          	auipc	a0,0x10
    8000218e:	12e50513          	addi	a0,a0,302 # 800122b8 <wait_lock>
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	af6080e7          	jalr	-1290(ra) # 80000c88 <release>
      return -1;
    8000219a:	59fd                	li	s3,-1
}
    8000219c:	854e                	mv	a0,s3
    8000219e:	60a6                	ld	ra,72(sp)
    800021a0:	6406                	ld	s0,64(sp)
    800021a2:	74e2                	ld	s1,56(sp)
    800021a4:	7942                	ld	s2,48(sp)
    800021a6:	79a2                	ld	s3,40(sp)
    800021a8:	7a02                	ld	s4,32(sp)
    800021aa:	6ae2                	ld	s5,24(sp)
    800021ac:	6b42                	ld	s6,16(sp)
    800021ae:	6ba2                	ld	s7,8(sp)
    800021b0:	6c02                	ld	s8,0(sp)
    800021b2:	6161                	addi	sp,sp,80
    800021b4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021b6:	85e2                	mv	a1,s8
    800021b8:	854a                	mv	a0,s2
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	e7e080e7          	jalr	-386(ra) # 80002038 <sleep>
    havekids = 0;
    800021c2:	b715                	j	800020e6 <wait+0x4a>

00000000800021c4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021c4:	7139                	addi	sp,sp,-64
    800021c6:	fc06                	sd	ra,56(sp)
    800021c8:	f822                	sd	s0,48(sp)
    800021ca:	f426                	sd	s1,40(sp)
    800021cc:	f04a                	sd	s2,32(sp)
    800021ce:	ec4e                	sd	s3,24(sp)
    800021d0:	e852                	sd	s4,16(sp)
    800021d2:	e456                	sd	s5,8(sp)
    800021d4:	0080                	addi	s0,sp,64
    800021d6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021d8:	00010497          	auipc	s1,0x10
    800021dc:	4f848493          	addi	s1,s1,1272 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021e0:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021e2:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021e4:	0001e917          	auipc	s2,0x1e
    800021e8:	2ec90913          	addi	s2,s2,748 # 800204d0 <tickslock>
    800021ec:	a811                	j	80002200 <wakeup+0x3c>
      }
      release(&p->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	a98080e7          	jalr	-1384(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f8:	37848493          	addi	s1,s1,888
    800021fc:	03248663          	beq	s1,s2,80002228 <wakeup+0x64>
    if(p != myproc()){
    80002200:	00000097          	auipc	ra,0x0
    80002204:	816080e7          	jalr	-2026(ra) # 80001a16 <myproc>
    80002208:	fea488e3          	beq	s1,a0,800021f8 <wakeup+0x34>
      acquire(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	9b4080e7          	jalr	-1612(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002216:	4c9c                	lw	a5,24(s1)
    80002218:	fd379be3          	bne	a5,s3,800021ee <wakeup+0x2a>
    8000221c:	709c                	ld	a5,32(s1)
    8000221e:	fd4798e3          	bne	a5,s4,800021ee <wakeup+0x2a>
        p->state = RUNNABLE;
    80002222:	0154ac23          	sw	s5,24(s1)
    80002226:	b7e1                	j	800021ee <wakeup+0x2a>
    }
  }
}
    80002228:	70e2                	ld	ra,56(sp)
    8000222a:	7442                	ld	s0,48(sp)
    8000222c:	74a2                	ld	s1,40(sp)
    8000222e:	7902                	ld	s2,32(sp)
    80002230:	69e2                	ld	s3,24(sp)
    80002232:	6a42                	ld	s4,16(sp)
    80002234:	6aa2                	ld	s5,8(sp)
    80002236:	6121                	addi	sp,sp,64
    80002238:	8082                	ret

000000008000223a <reparent>:
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	e052                	sd	s4,0(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000224c:	00010497          	auipc	s1,0x10
    80002250:	48448493          	addi	s1,s1,1156 # 800126d0 <proc>
      pp->parent = initproc;
    80002254:	00008a17          	auipc	s4,0x8
    80002258:	dd4a0a13          	addi	s4,s4,-556 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225c:	0001e997          	auipc	s3,0x1e
    80002260:	27498993          	addi	s3,s3,628 # 800204d0 <tickslock>
    80002264:	a029                	j	8000226e <reparent+0x34>
    80002266:	37848493          	addi	s1,s1,888
    8000226a:	01348d63          	beq	s1,s3,80002284 <reparent+0x4a>
    if(pp->parent == p){
    8000226e:	7c9c                	ld	a5,56(s1)
    80002270:	ff279be3          	bne	a5,s2,80002266 <reparent+0x2c>
      pp->parent = initproc;
    80002274:	000a3503          	ld	a0,0(s4)
    80002278:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	f4a080e7          	jalr	-182(ra) # 800021c4 <wakeup>
    80002282:	b7d5                	j	80002266 <reparent+0x2c>
}
    80002284:	70a2                	ld	ra,40(sp)
    80002286:	7402                	ld	s0,32(sp)
    80002288:	64e2                	ld	s1,24(sp)
    8000228a:	6942                	ld	s2,16(sp)
    8000228c:	69a2                	ld	s3,8(sp)
    8000228e:	6a02                	ld	s4,0(sp)
    80002290:	6145                	addi	sp,sp,48
    80002292:	8082                	ret

0000000080002294 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	1800                	addi	s0,sp,48
    800022a2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022a4:	00010497          	auipc	s1,0x10
    800022a8:	42c48493          	addi	s1,s1,1068 # 800126d0 <proc>
    800022ac:	0001e997          	auipc	s3,0x1e
    800022b0:	22498993          	addi	s3,s3,548 # 800204d0 <tickslock>
    acquire(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	90c080e7          	jalr	-1780(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800022be:	589c                	lw	a5,48(s1)
    800022c0:	01278d63          	beq	a5,s2,800022da <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9c2080e7          	jalr	-1598(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ce:	37848493          	addi	s1,s1,888
    800022d2:	ff3491e3          	bne	s1,s3,800022b4 <kill+0x20>
  }
  return -1;
    800022d6:	557d                	li	a0,-1
    800022d8:	a829                	j	800022f2 <kill+0x5e>
      p->killed = 1;
    800022da:	4785                	li	a5,1
    800022dc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022de:	4c98                	lw	a4,24(s1)
    800022e0:	4789                	li	a5,2
    800022e2:	00f70f63          	beq	a4,a5,80002300 <kill+0x6c>
      release(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9a0080e7          	jalr	-1632(ra) # 80000c88 <release>
      return 0;
    800022f0:	4501                	li	a0,0
}
    800022f2:	70a2                	ld	ra,40(sp)
    800022f4:	7402                	ld	s0,32(sp)
    800022f6:	64e2                	ld	s1,24(sp)
    800022f8:	6942                	ld	s2,16(sp)
    800022fa:	69a2                	ld	s3,8(sp)
    800022fc:	6145                	addi	sp,sp,48
    800022fe:	8082                	ret
        p->state = RUNNABLE;
    80002300:	478d                	li	a5,3
    80002302:	cc9c                	sw	a5,24(s1)
    80002304:	b7cd                	j	800022e6 <kill+0x52>

0000000080002306 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002306:	7179                	addi	sp,sp,-48
    80002308:	f406                	sd	ra,40(sp)
    8000230a:	f022                	sd	s0,32(sp)
    8000230c:	ec26                	sd	s1,24(sp)
    8000230e:	e84a                	sd	s2,16(sp)
    80002310:	e44e                	sd	s3,8(sp)
    80002312:	e052                	sd	s4,0(sp)
    80002314:	1800                	addi	s0,sp,48
    80002316:	84aa                	mv	s1,a0
    80002318:	892e                	mv	s2,a1
    8000231a:	89b2                	mv	s3,a2
    8000231c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	6f8080e7          	jalr	1784(ra) # 80001a16 <myproc>
  if(user_dst){
    80002326:	c08d                	beqz	s1,80002348 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002328:	86d2                	mv	a3,s4
    8000232a:	864e                	mv	a2,s3
    8000232c:	85ca                	mv	a1,s2
    8000232e:	6928                	ld	a0,80(a0)
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	3a6080e7          	jalr	934(ra) # 800016d6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002338:	70a2                	ld	ra,40(sp)
    8000233a:	7402                	ld	s0,32(sp)
    8000233c:	64e2                	ld	s1,24(sp)
    8000233e:	6942                	ld	s2,16(sp)
    80002340:	69a2                	ld	s3,8(sp)
    80002342:	6a02                	ld	s4,0(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
    memmove((char *)dst, src, len);
    80002348:	000a061b          	sext.w	a2,s4
    8000234c:	85ce                	mv	a1,s3
    8000234e:	854a                	mv	a0,s2
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	9dc080e7          	jalr	-1572(ra) # 80000d2c <memmove>
    return 0;
    80002358:	8526                	mv	a0,s1
    8000235a:	bff9                	j	80002338 <either_copyout+0x32>

000000008000235c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000235c:	7179                	addi	sp,sp,-48
    8000235e:	f406                	sd	ra,40(sp)
    80002360:	f022                	sd	s0,32(sp)
    80002362:	ec26                	sd	s1,24(sp)
    80002364:	e84a                	sd	s2,16(sp)
    80002366:	e44e                	sd	s3,8(sp)
    80002368:	e052                	sd	s4,0(sp)
    8000236a:	1800                	addi	s0,sp,48
    8000236c:	892a                	mv	s2,a0
    8000236e:	84ae                	mv	s1,a1
    80002370:	89b2                	mv	s3,a2
    80002372:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	6a2080e7          	jalr	1698(ra) # 80001a16 <myproc>
  if(user_src){
    8000237c:	c08d                	beqz	s1,8000239e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000237e:	86d2                	mv	a3,s4
    80002380:	864e                	mv	a2,s3
    80002382:	85ca                	mv	a1,s2
    80002384:	6928                	ld	a0,80(a0)
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	3dc080e7          	jalr	988(ra) # 80001762 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6a02                	ld	s4,0(sp)
    8000239a:	6145                	addi	sp,sp,48
    8000239c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000239e:	000a061b          	sext.w	a2,s4
    800023a2:	85ce                	mv	a1,s3
    800023a4:	854a                	mv	a0,s2
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	986080e7          	jalr	-1658(ra) # 80000d2c <memmove>
    return 0;
    800023ae:	8526                	mv	a0,s1
    800023b0:	bff9                	j	8000238e <either_copyin+0x32>

00000000800023b2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023b2:	715d                	addi	sp,sp,-80
    800023b4:	e486                	sd	ra,72(sp)
    800023b6:	e0a2                	sd	s0,64(sp)
    800023b8:	fc26                	sd	s1,56(sp)
    800023ba:	f84a                	sd	s2,48(sp)
    800023bc:	f44e                	sd	s3,40(sp)
    800023be:	f052                	sd	s4,32(sp)
    800023c0:	ec56                	sd	s5,24(sp)
    800023c2:	e85a                	sd	s6,16(sp)
    800023c4:	e45e                	sd	s7,8(sp)
    800023c6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800023c8:	00007517          	auipc	a0,0x7
    800023cc:	28050513          	addi	a0,a0,640 # 80009648 <digits+0x608>
    800023d0:	ffffe097          	auipc	ra,0xffffe
    800023d4:	1a4080e7          	jalr	420(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d8:	00010497          	auipc	s1,0x10
    800023dc:	45048493          	addi	s1,s1,1104 # 80012828 <proc+0x158>
    800023e0:	0001e917          	auipc	s2,0x1e
    800023e4:	24890913          	addi	s2,s2,584 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023e8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800023ea:	00007997          	auipc	s3,0x7
    800023ee:	e7e98993          	addi	s3,s3,-386 # 80009268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800023f2:	00007a97          	auipc	s5,0x7
    800023f6:	e7ea8a93          	addi	s5,s5,-386 # 80009270 <digits+0x230>
    printf("\n");
    800023fa:	00007a17          	auipc	s4,0x7
    800023fe:	24ea0a13          	addi	s4,s4,590 # 80009648 <digits+0x608>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002402:	00007b97          	auipc	s7,0x7
    80002406:	2d6b8b93          	addi	s7,s7,726 # 800096d8 <states.0>
    8000240a:	a00d                	j	8000242c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000240c:	ed86a583          	lw	a1,-296(a3) # fed8 <_entry-0x7fff0128>
    80002410:	8556                	mv	a0,s5
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	162080e7          	jalr	354(ra) # 80000574 <printf>
    printf("\n");
    8000241a:	8552                	mv	a0,s4
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	158080e7          	jalr	344(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002424:	37848493          	addi	s1,s1,888
    80002428:	03248263          	beq	s1,s2,8000244c <procdump+0x9a>
    if(p->state == UNUSED)
    8000242c:	86a6                	mv	a3,s1
    8000242e:	ec04a783          	lw	a5,-320(s1)
    80002432:	dbed                	beqz	a5,80002424 <procdump+0x72>
      state = "???";
    80002434:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002436:	fcfb6be3          	bltu	s6,a5,8000240c <procdump+0x5a>
    8000243a:	02079713          	slli	a4,a5,0x20
    8000243e:	01d75793          	srli	a5,a4,0x1d
    80002442:	97de                	add	a5,a5,s7
    80002444:	6390                	ld	a2,0(a5)
    80002446:	f279                	bnez	a2,8000240c <procdump+0x5a>
      state = "???";
    80002448:	864e                	mv	a2,s3
    8000244a:	b7c9                	j	8000240c <procdump+0x5a>
  }
}
    8000244c:	60a6                	ld	ra,72(sp)
    8000244e:	6406                	ld	s0,64(sp)
    80002450:	74e2                	ld	s1,56(sp)
    80002452:	7942                	ld	s2,48(sp)
    80002454:	79a2                	ld	s3,40(sp)
    80002456:	7a02                	ld	s4,32(sp)
    80002458:	6ae2                	ld	s5,24(sp)
    8000245a:	6b42                	ld	s6,16(sp)
    8000245c:	6ba2                	ld	s7,8(sp)
    8000245e:	6161                	addi	sp,sp,80
    80002460:	8082                	ret

0000000080002462 <init_metadata>:

// ADDED Q1 - p->lock must bot be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    80002462:	1101                	addi	sp,sp,-32
    80002464:	ec06                	sd	ra,24(sp)
    80002466:	e822                	sd	s0,16(sp)
    80002468:	e426                	sd	s1,8(sp)
    8000246a:	1000                	addi	s0,sp,32
    8000246c:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    8000246e:	16853783          	ld	a5,360(a0)
    80002472:	cf95                	beqz	a5,800024ae <init_metadata+0x4c>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002474:	17048793          	addi	a5,s1,368
{
    80002478:	4701                	li	a4,0
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000247a:	6605                	lui	a2,0x1
    8000247c:	66c1                	lui	a3,0x10
    p->ram_pages[i].va = 0;
    8000247e:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002482:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    80002486:	0007a623          	sw	zero,12(a5)
    
    p->disk_pages[i].va = 0;
    8000248a:	1007b023          	sd	zero,256(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    8000248e:	10e7a423          	sw	a4,264(a5)
    p->disk_pages[i].used = 0;
    80002492:	1007a623          	sw	zero,268(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002496:	07c1                	addi	a5,a5,16
    80002498:	9f31                	addw	a4,a4,a2
    8000249a:	fed712e3          	bne	a4,a3,8000247e <init_metadata+0x1c>
  }
  p->scfifo_index = 0; // ADDED Q2
    8000249e:	3604a823          	sw	zero,880(s1)
  return 0;
    800024a2:	4501                	li	a0,0
}
    800024a4:	60e2                	ld	ra,24(sp)
    800024a6:	6442                	ld	s0,16(sp)
    800024a8:	64a2                	ld	s1,8(sp)
    800024aa:	6105                	addi	sp,sp,32
    800024ac:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    800024ae:	00002097          	auipc	ra,0x2
    800024b2:	5cc080e7          	jalr	1484(ra) # 80004a7a <createSwapFile>
    800024b6:	fa055fe3          	bgez	a0,80002474 <init_metadata+0x12>
    return -1;
    800024ba:	557d                	li	a0,-1
    800024bc:	b7e5                	j	800024a4 <init_metadata+0x42>

00000000800024be <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800024be:	1101                	addi	sp,sp,-32
    800024c0:	ec06                	sd	ra,24(sp)
    800024c2:	e822                	sd	s0,16(sp)
    800024c4:	e426                	sd	s1,8(sp)
    800024c6:	1000                	addi	s0,sp,32
    800024c8:	84aa                	mv	s1,a0
    if (removeSwapFile(p) < 0) {
    800024ca:	00002097          	auipc	ra,0x2
    800024ce:	408080e7          	jalr	1032(ra) # 800048d2 <removeSwapFile>
    800024d2:	02054e63          	bltz	a0,8000250e <free_metadata+0x50>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800024d6:	1604b423          	sd	zero,360(s1)

    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800024da:	17048793          	addi	a5,s1,368
    800024de:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800024e2:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800024e6:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    800024ea:	0007a623          	sw	zero,12(a5)

      p->disk_pages[i].va = 0;
    800024ee:	1007b023          	sd	zero,256(a5)
      p->disk_pages[i].offset = 0;
    800024f2:	1007a423          	sw	zero,264(a5)
      p->disk_pages[i].used = 0;
    800024f6:	1007a623          	sw	zero,268(a5)
    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800024fa:	07c1                	addi	a5,a5,16
    800024fc:	fee793e3          	bne	a5,a4,800024e2 <free_metadata+0x24>
    }
    p->scfifo_index = 0; // ADDED Q2
    80002500:	3604a823          	sw	zero,880(s1)
}
    80002504:	60e2                	ld	ra,24(sp)
    80002506:	6442                	ld	s0,16(sp)
    80002508:	64a2                	ld	s1,8(sp)
    8000250a:	6105                	addi	sp,sp,32
    8000250c:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    8000250e:	00007517          	auipc	a0,0x7
    80002512:	d7250513          	addi	a0,a0,-654 # 80009280 <digits+0x240>
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	014080e7          	jalr	20(ra) # 8000052a <panic>

000000008000251e <fork>:
{
    8000251e:	7139                	addi	sp,sp,-64
    80002520:	fc06                	sd	ra,56(sp)
    80002522:	f822                	sd	s0,48(sp)
    80002524:	f426                	sd	s1,40(sp)
    80002526:	f04a                	sd	s2,32(sp)
    80002528:	ec4e                	sd	s3,24(sp)
    8000252a:	e852                	sd	s4,16(sp)
    8000252c:	e456                	sd	s5,8(sp)
    8000252e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	4e6080e7          	jalr	1254(ra) # 80001a16 <myproc>
    80002538:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	6e6080e7          	jalr	1766(ra) # 80001c20 <allocproc>
    80002542:	1c050e63          	beqz	a0,8000271e <fork+0x200>
    80002546:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002548:	048ab603          	ld	a2,72(s5)
    8000254c:	692c                	ld	a1,80(a0)
    8000254e:	050ab503          	ld	a0,80(s5)
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	07a080e7          	jalr	122(ra) # 800015cc <uvmcopy>
    8000255a:	04054863          	bltz	a0,800025aa <fork+0x8c>
  np->sz = p->sz;
    8000255e:	048ab783          	ld	a5,72(s5)
    80002562:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002566:	058ab683          	ld	a3,88(s5)
    8000256a:	87b6                	mv	a5,a3
    8000256c:	0589b703          	ld	a4,88(s3)
    80002570:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    80002574:	0007b803          	ld	a6,0(a5)
    80002578:	6788                	ld	a0,8(a5)
    8000257a:	6b8c                	ld	a1,16(a5)
    8000257c:	6f90                	ld	a2,24(a5)
    8000257e:	01073023          	sd	a6,0(a4)
    80002582:	e708                	sd	a0,8(a4)
    80002584:	eb0c                	sd	a1,16(a4)
    80002586:	ef10                	sd	a2,24(a4)
    80002588:	02078793          	addi	a5,a5,32
    8000258c:	02070713          	addi	a4,a4,32
    80002590:	fed792e3          	bne	a5,a3,80002574 <fork+0x56>
  np->trapframe->a0 = 0;
    80002594:	0589b783          	ld	a5,88(s3)
    80002598:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000259c:	0d0a8493          	addi	s1,s5,208
    800025a0:	0d098913          	addi	s2,s3,208
    800025a4:	150a8a13          	addi	s4,s5,336
    800025a8:	a00d                	j	800025ca <fork+0xac>
    freeproc(np);
    800025aa:	854e                	mv	a0,s3
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	61c080e7          	jalr	1564(ra) # 80001bc8 <freeproc>
    release(&np->lock);
    800025b4:	854e                	mv	a0,s3
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	6d2080e7          	jalr	1746(ra) # 80000c88 <release>
    return -1;
    800025be:	54fd                	li	s1,-1
    800025c0:	a0f5                	j	800026ac <fork+0x18e>
  for(i = 0; i < NOFILE; i++)
    800025c2:	04a1                	addi	s1,s1,8
    800025c4:	0921                	addi	s2,s2,8
    800025c6:	01448b63          	beq	s1,s4,800025dc <fork+0xbe>
    if(p->ofile[i])
    800025ca:	6088                	ld	a0,0(s1)
    800025cc:	d97d                	beqz	a0,800025c2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800025ce:	00003097          	auipc	ra,0x3
    800025d2:	c04080e7          	jalr	-1020(ra) # 800051d2 <filedup>
    800025d6:	00a93023          	sd	a0,0(s2)
    800025da:	b7e5                	j	800025c2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800025dc:	150ab503          	ld	a0,336(s5)
    800025e0:	00002097          	auipc	ra,0x2
    800025e4:	a52080e7          	jalr	-1454(ra) # 80004032 <idup>
    800025e8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800025ec:	4641                	li	a2,16
    800025ee:	158a8593          	addi	a1,s5,344
    800025f2:	15898513          	addi	a0,s3,344
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	82c080e7          	jalr	-2004(ra) # 80000e22 <safestrcpy>
  pid = np->pid;
    800025fe:	0309a483          	lw	s1,48(s3)
  if (relevant_metadata_proc(np)) {
    80002602:	fff4871b          	addiw	a4,s1,-1
    80002606:	4785                	li	a5,1
    80002608:	0ae7ec63          	bltu	a5,a4,800026c0 <fork+0x1a2>
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    8000260c:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    80002610:	37fd                	addiw	a5,a5,-1
    80002612:	4705                	li	a4,1
    80002614:	04f77263          	bgeu	a4,a5,80002658 <fork+0x13a>
    if (copy_swapFile(p, np) < 0) {
    80002618:	85ce                	mv	a1,s3
    8000261a:	8556                	mv	a0,s5
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	7c8080e7          	jalr	1992(ra) # 80001de4 <copy_swapFile>
    80002624:	0c054c63          	bltz	a0,800026fc <fork+0x1de>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    80002628:	10000613          	li	a2,256
    8000262c:	170a8593          	addi	a1,s5,368
    80002630:	17098513          	addi	a0,s3,368
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	6f8080e7          	jalr	1784(ra) # 80000d2c <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    8000263c:	10000613          	li	a2,256
    80002640:	270a8593          	addi	a1,s5,624
    80002644:	27098513          	addi	a0,s3,624
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	6e4080e7          	jalr	1764(ra) # 80000d2c <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    80002650:	370aa783          	lw	a5,880(s5)
    80002654:	36f9a823          	sw	a5,880(s3)
  printf("FORK COPIED METASATA & SWAP FILE @@@@@@@@@\n"); // REMOVE
    80002658:	00007517          	auipc	a0,0x7
    8000265c:	c5050513          	addi	a0,a0,-944 # 800092a8 <digits+0x268>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	f14080e7          	jalr	-236(ra) # 80000574 <printf>
  release(&np->lock);
    80002668:	854e                	mv	a0,s3
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	61e080e7          	jalr	1566(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80002672:	00010917          	auipc	s2,0x10
    80002676:	c4690913          	addi	s2,s2,-954 # 800122b8 <wait_lock>
    8000267a:	854a                	mv	a0,s2
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	546080e7          	jalr	1350(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002684:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002688:	854a                	mv	a0,s2
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	5fe080e7          	jalr	1534(ra) # 80000c88 <release>
  acquire(&np->lock);
    80002692:	854e                	mv	a0,s3
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	52e080e7          	jalr	1326(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    8000269c:	478d                	li	a5,3
    8000269e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800026a2:	854e                	mv	a0,s3
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e4080e7          	jalr	1508(ra) # 80000c88 <release>
}
    800026ac:	8526                	mv	a0,s1
    800026ae:	70e2                	ld	ra,56(sp)
    800026b0:	7442                	ld	s0,48(sp)
    800026b2:	74a2                	ld	s1,40(sp)
    800026b4:	7902                	ld	s2,32(sp)
    800026b6:	69e2                	ld	s3,24(sp)
    800026b8:	6a42                	ld	s4,16(sp)
    800026ba:	6aa2                	ld	s5,8(sp)
    800026bc:	6121                	addi	sp,sp,64
    800026be:	8082                	ret
    release(&np->lock);
    800026c0:	854e                	mv	a0,s3
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c6080e7          	jalr	1478(ra) # 80000c88 <release>
    if (init_metadata(np) < 0) {
    800026ca:	854e                	mv	a0,s3
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	d96080e7          	jalr	-618(ra) # 80002462 <init_metadata>
    800026d4:	00054863          	bltz	a0,800026e4 <fork+0x1c6>
    acquire(&np->lock);
    800026d8:	854e                	mv	a0,s3
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	4e8080e7          	jalr	1256(ra) # 80000bc2 <acquire>
    800026e2:	b72d                	j	8000260c <fork+0xee>
      freeproc(np);
    800026e4:	854e                	mv	a0,s3
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	4e2080e7          	jalr	1250(ra) # 80001bc8 <freeproc>
      release(&np->lock);
    800026ee:	854e                	mv	a0,s3
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	598080e7          	jalr	1432(ra) # 80000c88 <release>
      return -1;
    800026f8:	54fd                	li	s1,-1
    800026fa:	bf4d                	j	800026ac <fork+0x18e>
      freeproc(np);
    800026fc:	854e                	mv	a0,s3
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	4ca080e7          	jalr	1226(ra) # 80001bc8 <freeproc>
      release(&np->lock);
    80002706:	854e                	mv	a0,s3
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	580080e7          	jalr	1408(ra) # 80000c88 <release>
      free_metadata(np);
    80002710:	854e                	mv	a0,s3
    80002712:	00000097          	auipc	ra,0x0
    80002716:	dac080e7          	jalr	-596(ra) # 800024be <free_metadata>
      return -1;
    8000271a:	54fd                	li	s1,-1
    8000271c:	bf41                	j	800026ac <fork+0x18e>
    return -1;
    8000271e:	54fd                	li	s1,-1
    80002720:	b771                	j	800026ac <fork+0x18e>

0000000080002722 <exit>:
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	e052                	sd	s4,0(sp)
    80002730:	1800                	addi	s0,sp,48
    80002732:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002734:	fffff097          	auipc	ra,0xfffff
    80002738:	2e2080e7          	jalr	738(ra) # 80001a16 <myproc>
    8000273c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000273e:	00008797          	auipc	a5,0x8
    80002742:	8ea7b783          	ld	a5,-1814(a5) # 8000a028 <initproc>
    80002746:	0d050493          	addi	s1,a0,208
    8000274a:	15050913          	addi	s2,a0,336
    8000274e:	02a79363          	bne	a5,a0,80002774 <exit+0x52>
    panic("init exiting");
    80002752:	00007517          	auipc	a0,0x7
    80002756:	b8650513          	addi	a0,a0,-1146 # 800092d8 <digits+0x298>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	dd0080e7          	jalr	-560(ra) # 8000052a <panic>
      fileclose(f);
    80002762:	00003097          	auipc	ra,0x3
    80002766:	ac2080e7          	jalr	-1342(ra) # 80005224 <fileclose>
      p->ofile[fd] = 0;
    8000276a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000276e:	04a1                	addi	s1,s1,8
    80002770:	01248563          	beq	s1,s2,8000277a <exit+0x58>
    if(p->ofile[fd]){
    80002774:	6088                	ld	a0,0(s1)
    80002776:	f575                	bnez	a0,80002762 <exit+0x40>
    80002778:	bfdd                	j	8000276e <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    8000277a:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    8000277e:	37fd                	addiw	a5,a5,-1
    80002780:	4705                	li	a4,1
    80002782:	08f76163          	bltu	a4,a5,80002804 <exit+0xe2>
  begin_op();
    80002786:	00002097          	auipc	ra,0x2
    8000278a:	5d2080e7          	jalr	1490(ra) # 80004d58 <begin_op>
  iput(p->cwd);
    8000278e:	1509b503          	ld	a0,336(s3)
    80002792:	00002097          	auipc	ra,0x2
    80002796:	a98080e7          	jalr	-1384(ra) # 8000422a <iput>
  end_op();
    8000279a:	00002097          	auipc	ra,0x2
    8000279e:	63e080e7          	jalr	1598(ra) # 80004dd8 <end_op>
  p->cwd = 0;
    800027a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800027a6:	00010497          	auipc	s1,0x10
    800027aa:	b1248493          	addi	s1,s1,-1262 # 800122b8 <wait_lock>
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	412080e7          	jalr	1042(ra) # 80000bc2 <acquire>
  reparent(p);
    800027b8:	854e                	mv	a0,s3
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	a80080e7          	jalr	-1408(ra) # 8000223a <reparent>
  wakeup(p->parent);
    800027c2:	0389b503          	ld	a0,56(s3)
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	9fe080e7          	jalr	-1538(ra) # 800021c4 <wakeup>
  acquire(&p->lock);
    800027ce:	854e                	mv	a0,s3
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	3f2080e7          	jalr	1010(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800027d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027dc:	4795                	li	a5,5
    800027de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a4080e7          	jalr	1188(ra) # 80000c88 <release>
  sched();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	73a080e7          	jalr	1850(ra) # 80001f26 <sched>
  panic("zombie exit");
    800027f4:	00007517          	auipc	a0,0x7
    800027f8:	af450513          	addi	a0,a0,-1292 # 800092e8 <digits+0x2a8>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d2e080e7          	jalr	-722(ra) # 8000052a <panic>
    free_metadata(p);
    80002804:	854e                	mv	a0,s3
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	cb8080e7          	jalr	-840(ra) # 800024be <free_metadata>
    8000280e:	bfa5                	j	80002786 <exit+0x64>

0000000080002810 <get_free_page_in_disk>:
{
    80002810:	1141                	addi	sp,sp,-16
    80002812:	e406                	sd	ra,8(sp)
    80002814:	e022                	sd	s0,0(sp)
    80002816:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	1fe080e7          	jalr	510(ra) # 80001a16 <myproc>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002820:	27050793          	addi	a5,a0,624
  int index = 0;
    80002824:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002826:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002828:	47d8                	lw	a4,12(a5)
    8000282a:	c711                	beqz	a4,80002836 <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    8000282c:	07c1                	addi	a5,a5,16
    8000282e:	2505                	addiw	a0,a0,1
    80002830:	fed51ce3          	bne	a0,a3,80002828 <get_free_page_in_disk+0x18>
  return -1;
    80002834:	557d                	li	a0,-1
}
    80002836:	60a2                	ld	ra,8(sp)
    80002838:	6402                	ld	s0,0(sp)
    8000283a:	0141                	addi	sp,sp,16
    8000283c:	8082                	ret

000000008000283e <swapout>:
{
    8000283e:	715d                	addi	sp,sp,-80
    80002840:	e486                	sd	ra,72(sp)
    80002842:	e0a2                	sd	s0,64(sp)
    80002844:	fc26                	sd	s1,56(sp)
    80002846:	f84a                	sd	s2,48(sp)
    80002848:	f44e                	sd	s3,40(sp)
    8000284a:	f052                	sd	s4,32(sp)
    8000284c:	ec56                	sd	s5,24(sp)
    8000284e:	e85a                	sd	s6,16(sp)
    80002850:	0880                	addi	s0,sp,80
    80002852:	737d                	lui	t1,0xfffff
    80002854:	911a                	add	sp,sp,t1
    80002856:	8a2a                	mv	s4,a0
    80002858:	84ae                	mv	s1,a1
  printf("swapout: 0\n"); //REMOVE
    8000285a:	00007517          	auipc	a0,0x7
    8000285e:	a9e50513          	addi	a0,a0,-1378 # 800092f8 <digits+0x2b8>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	d12080e7          	jalr	-750(ra) # 80000574 <printf>
  if (ram_pg_index < 0 || ram_pg_index > MAX_PSYC_PAGES) {
    8000286a:	0004871b          	sext.w	a4,s1
    8000286e:	47c1                	li	a5,16
    80002870:	12e7ec63          	bltu	a5,a4,800029a8 <swapout+0x16a>
  printf("swapout: 1\n"); //REMOVE
    80002874:	00007517          	auipc	a0,0x7
    80002878:	abc50513          	addi	a0,a0,-1348 # 80009330 <digits+0x2f0>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	cf8080e7          	jalr	-776(ra) # 80000574 <printf>
  if (!ram_pg_to_swap->used) {
    80002884:	0492                	slli	s1,s1,0x4
    80002886:	94d2                	add	s1,s1,s4
    80002888:	17c4a783          	lw	a5,380(s1)
    8000288c:	12078663          	beqz	a5,800029b8 <swapout+0x17a>
  printf("swapout: 2\n"); //REMOVE
    80002890:	00007517          	auipc	a0,0x7
    80002894:	ac850513          	addi	a0,a0,-1336 # 80009358 <digits+0x318>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	cdc080e7          	jalr	-804(ra) # 80000574 <printf>
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    800028a0:	4601                	li	a2,0
    800028a2:	1704b583          	ld	a1,368(s1)
    800028a6:	050a3503          	ld	a0,80(s4)
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	70e080e7          	jalr	1806(ra) # 80000fb8 <walk>
    800028b2:	89aa                	mv	s3,a0
    800028b4:	10050a63          	beqz	a0,800029c8 <swapout+0x18a>
  printf("swapout: 3\n"); //REMOVE
    800028b8:	00007517          	auipc	a0,0x7
    800028bc:	ac850513          	addi	a0,a0,-1336 # 80009380 <digits+0x340>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cb4080e7          	jalr	-844(ra) # 80000574 <printf>
  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    800028c8:	0009b783          	ld	a5,0(s3)
    800028cc:	2017f793          	andi	a5,a5,513
    800028d0:	4705                	li	a4,1
    800028d2:	10e79363          	bne	a5,a4,800029d8 <swapout+0x19a>
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	f3a080e7          	jalr	-198(ra) # 80002810 <get_free_page_in_disk>
    800028de:	892a                	mv	s2,a0
    800028e0:	10054463          	bltz	a0,800029e8 <swapout+0x1aa>
    printf("swapout: 4\n"); //REMOVE
    800028e4:	00007517          	auipc	a0,0x7
    800028e8:	ae450513          	addi	a0,a0,-1308 # 800093c8 <digits+0x388>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	c88080e7          	jalr	-888(ra) # 80000574 <printf>
  uint64 pa = PTE2PA(*pte);
    800028f4:	0009ba83          	ld	s5,0(s3)
    800028f8:	00aada93          	srli	s5,s5,0xa
    800028fc:	0ab2                	slli	s5,s5,0xc
  printf("swapout: before memove\n"); //REMOVE
    800028fe:	00007517          	auipc	a0,0x7
    80002902:	ada50513          	addi	a0,a0,-1318 # 800093d8 <digits+0x398>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c6e080e7          	jalr	-914(ra) # 80000574 <printf>
  memmove(buffer, (void *)pa, PGSIZE); // TODO: Check va as opposed to pa.
    8000290e:	77fd                	lui	a5,0xfffff
    80002910:	fc040713          	addi	a4,s0,-64
    80002914:	97ba                	add	a5,a5,a4
    80002916:	7b7d                	lui	s6,0xfffff
    80002918:	fb8b0713          	addi	a4,s6,-72 # ffffffffffffefb8 <end+0xffffffff7ffcffb8>
    8000291c:	9722                	add	a4,a4,s0
    8000291e:	e31c                	sd	a5,0(a4)
    80002920:	6605                	lui	a2,0x1
    80002922:	85d6                	mv	a1,s5
    80002924:	6308                	ld	a0,0(a4)
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	406080e7          	jalr	1030(ra) # 80000d2c <memmove>
  printf("swapout: after memove\n"); //REMOVE
    8000292e:	00007517          	auipc	a0,0x7
    80002932:	ac250513          	addi	a0,a0,-1342 # 800093f0 <digits+0x3b0>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c3e080e7          	jalr	-962(ra) # 80000574 <printf>
  if (writeToSwapFile(p, buffer, disk_pg_to_store->offset, PGSIZE) < 0) {
    8000293e:	0912                	slli	s2,s2,0x4
    80002940:	9952                	add	s2,s2,s4
    80002942:	6685                	lui	a3,0x1
    80002944:	27892603          	lw	a2,632(s2)
    80002948:	fb8b0793          	addi	a5,s6,-72
    8000294c:	97a2                	add	a5,a5,s0
    8000294e:	638c                	ld	a1,0(a5)
    80002950:	8552                	mv	a0,s4
    80002952:	00002097          	auipc	ra,0x2
    80002956:	1d8080e7          	jalr	472(ra) # 80004b2a <writeToSwapFile>
    8000295a:	08054f63          	bltz	a0,800029f8 <swapout+0x1ba>
  disk_pg_to_store->used = 1;
    8000295e:	4785                	li	a5,1
    80002960:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    80002964:	1704b783          	ld	a5,368(s1)
    80002968:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    8000296c:	8556                	mv	a0,s5
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	068080e7          	jalr	104(ra) # 800009d6 <kfree>
  ram_pg_to_swap->va = 0;
    80002976:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    8000297a:	1604ae23          	sw	zero,380(s1)
  *pte = *pte & ~PTE_V;
    8000297e:	0009b783          	ld	a5,0(s3)
    80002982:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    80002984:	2007e793          	ori	a5,a5,512
    80002988:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    8000298c:	12000073          	sfence.vma
}
    80002990:	6305                	lui	t1,0x1
    80002992:	911a                	add	sp,sp,t1
    80002994:	60a6                	ld	ra,72(sp)
    80002996:	6406                	ld	s0,64(sp)
    80002998:	74e2                	ld	s1,56(sp)
    8000299a:	7942                	ld	s2,48(sp)
    8000299c:	79a2                	ld	s3,40(sp)
    8000299e:	7a02                	ld	s4,32(sp)
    800029a0:	6ae2                	ld	s5,24(sp)
    800029a2:	6b42                	ld	s6,16(sp)
    800029a4:	6161                	addi	sp,sp,80
    800029a6:	8082                	ret
    panic("swapout: ram page index out of bounds");
    800029a8:	00007517          	auipc	a0,0x7
    800029ac:	96050513          	addi	a0,a0,-1696 # 80009308 <digits+0x2c8>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b7a080e7          	jalr	-1158(ra) # 8000052a <panic>
    panic("swapout: page unused");
    800029b8:	00007517          	auipc	a0,0x7
    800029bc:	98850513          	addi	a0,a0,-1656 # 80009340 <digits+0x300>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	b6a080e7          	jalr	-1174(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    800029c8:	00007517          	auipc	a0,0x7
    800029cc:	9a050513          	addi	a0,a0,-1632 # 80009368 <digits+0x328>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	b5a080e7          	jalr	-1190(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    800029d8:	00007517          	auipc	a0,0x7
    800029dc:	9b850513          	addi	a0,a0,-1608 # 80009390 <digits+0x350>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b4a080e7          	jalr	-1206(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    800029e8:	00007517          	auipc	a0,0x7
    800029ec:	9c850513          	addi	a0,a0,-1592 # 800093b0 <digits+0x370>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	b3a080e7          	jalr	-1222(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    800029f8:	00007517          	auipc	a0,0x7
    800029fc:	a1050513          	addi	a0,a0,-1520 # 80009408 <digits+0x3c8>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b2a080e7          	jalr	-1238(ra) # 8000052a <panic>

0000000080002a08 <swapin>:
{
    80002a08:	715d                	addi	sp,sp,-80
    80002a0a:	e486                	sd	ra,72(sp)
    80002a0c:	e0a2                	sd	s0,64(sp)
    80002a0e:	fc26                	sd	s1,56(sp)
    80002a10:	f84a                	sd	s2,48(sp)
    80002a12:	f44e                	sd	s3,40(sp)
    80002a14:	f052                	sd	s4,32(sp)
    80002a16:	ec56                	sd	s5,24(sp)
    80002a18:	0880                	addi	s0,sp,80
    80002a1a:	737d                	lui	t1,0xfffff
    80002a1c:	0341                	addi	t1,t1,16
    80002a1e:	911a                	add	sp,sp,t1
  if (disk_index < 0 || disk_index > MAX_PSYC_PAGES) {
    80002a20:	47c1                	li	a5,16
    80002a22:	0cb7e963          	bltu	a5,a1,80002af4 <swapin+0xec>
    80002a26:	8aaa                	mv	s5,a0
    80002a28:	89b2                	mv	s3,a2
  if (ram_index < 0 || ram_index > MAX_PSYC_PAGES) {
    80002a2a:	0006079b          	sext.w	a5,a2
    80002a2e:	4741                	li	a4,16
    80002a30:	0cf76a63          	bltu	a4,a5,80002b04 <swapin+0xfc>
  if (!disk_pg->used) {
    80002a34:	00459913          	slli	s2,a1,0x4
    80002a38:	992a                	add	s2,s2,a0
    80002a3a:	27c92783          	lw	a5,636(s2)
    80002a3e:	cbf9                	beqz	a5,80002b14 <swapin+0x10c>
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    80002a40:	4601                	li	a2,0
    80002a42:	27093583          	ld	a1,624(s2)
    80002a46:	6928                	ld	a0,80(a0)
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	570080e7          	jalr	1392(ra) # 80000fb8 <walk>
    80002a50:	8a2a                	mv	s4,a0
    80002a52:	c969                	beqz	a0,80002b24 <swapin+0x11c>
  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    80002a54:	611c                	ld	a5,0(a0)
    80002a56:	2017f793          	andi	a5,a5,513
    80002a5a:	20000713          	li	a4,512
    80002a5e:	0ce79b63          	bne	a5,a4,80002b34 <swapin+0x12c>
  if (ram_pg->used) {
    80002a62:	0992                	slli	s3,s3,0x4
    80002a64:	99d6                	add	s3,s3,s5
    80002a66:	17c9a783          	lw	a5,380(s3)
    80002a6a:	efe9                	bnez	a5,80002b44 <swapin+0x13c>
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	066080e7          	jalr	102(ra) # 80000ad2 <kalloc>
    80002a74:	84aa                	mv	s1,a0
    80002a76:	cd79                	beqz	a0,80002b54 <swapin+0x14c>
  if (readFromSwapFile(p, buffer, disk_pg->offset, PGSIZE) < 0) {
    80002a78:	6685                	lui	a3,0x1
    80002a7a:	27892603          	lw	a2,632(s2)
    80002a7e:	75fd                	lui	a1,0xfffff
    80002a80:	fc040793          	addi	a5,s0,-64
    80002a84:	95be                	add	a1,a1,a5
    80002a86:	8556                	mv	a0,s5
    80002a88:	00002097          	auipc	ra,0x2
    80002a8c:	0c6080e7          	jalr	198(ra) # 80004b4e <readFromSwapFile>
    80002a90:	0c054a63          	bltz	a0,80002b64 <swapin+0x15c>
  memmove((void *)npa, buffer, PGSIZE); 
    80002a94:	6605                	lui	a2,0x1
    80002a96:	75fd                	lui	a1,0xfffff
    80002a98:	fc040793          	addi	a5,s0,-64
    80002a9c:	95be                	add	a1,a1,a5
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	28c080e7          	jalr	652(ra) # 80000d2c <memmove>
  ram_pg->used = 1;
    80002aa8:	4785                	li	a5,1
    80002aaa:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    80002aae:	27093783          	ld	a5,624(s2)
    80002ab2:	16f9b823          	sd	a5,368(s3)
    ram_pg->age = 0;
    80002ab6:	1609ac23          	sw	zero,376(s3)
  disk_pg->va = 0;
    80002aba:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002abe:	26092e23          	sw	zero,636(s2)
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002ac2:	80b1                	srli	s1,s1,0xc
    80002ac4:	04aa                	slli	s1,s1,0xa
    80002ac6:	000a3783          	ld	a5,0(s4)
    80002aca:	1ff7f793          	andi	a5,a5,511
    80002ace:	8cdd                	or	s1,s1,a5
    80002ad0:	0014e493          	ori	s1,s1,1
    80002ad4:	009a3023          	sd	s1,0(s4)
    80002ad8:	12000073          	sfence.vma
}
    80002adc:	6305                	lui	t1,0x1
    80002ade:	1341                	addi	t1,t1,-16
    80002ae0:	911a                	add	sp,sp,t1
    80002ae2:	60a6                	ld	ra,72(sp)
    80002ae4:	6406                	ld	s0,64(sp)
    80002ae6:	74e2                	ld	s1,56(sp)
    80002ae8:	7942                	ld	s2,48(sp)
    80002aea:	79a2                	ld	s3,40(sp)
    80002aec:	7a02                	ld	s4,32(sp)
    80002aee:	6ae2                	ld	s5,24(sp)
    80002af0:	6161                	addi	sp,sp,80
    80002af2:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002af4:	00007517          	auipc	a0,0x7
    80002af8:	93c50513          	addi	a0,a0,-1732 # 80009430 <digits+0x3f0>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a2e080e7          	jalr	-1490(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002b04:	00007517          	auipc	a0,0x7
    80002b08:	95450513          	addi	a0,a0,-1708 # 80009458 <digits+0x418>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a1e080e7          	jalr	-1506(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002b14:	00007517          	auipc	a0,0x7
    80002b18:	96450513          	addi	a0,a0,-1692 # 80009478 <digits+0x438>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a0e080e7          	jalr	-1522(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002b24:	00007517          	auipc	a0,0x7
    80002b28:	96c50513          	addi	a0,a0,-1684 # 80009490 <digits+0x450>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	9fe080e7          	jalr	-1538(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002b34:	00007517          	auipc	a0,0x7
    80002b38:	97450513          	addi	a0,a0,-1676 # 800094a8 <digits+0x468>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	9ee080e7          	jalr	-1554(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002b44:	00007517          	auipc	a0,0x7
    80002b48:	98450513          	addi	a0,a0,-1660 # 800094c8 <digits+0x488>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9de080e7          	jalr	-1570(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002b54:	00007517          	auipc	a0,0x7
    80002b58:	98c50513          	addi	a0,a0,-1652 # 800094e0 <digits+0x4a0>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	9ce080e7          	jalr	-1586(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002b64:	00007517          	auipc	a0,0x7
    80002b68:	9a450513          	addi	a0,a0,-1628 # 80009508 <digits+0x4c8>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	9be080e7          	jalr	-1602(ra) # 8000052a <panic>

0000000080002b74 <get_unused_ram_index>:
{
    80002b74:	1141                	addi	sp,sp,-16
    80002b76:	e422                	sd	s0,8(sp)
    80002b78:	0800                	addi	s0,sp,16
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002b7a:	17c50793          	addi	a5,a0,380
    80002b7e:	4501                	li	a0,0
    80002b80:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002b82:	4398                	lw	a4,0(a5)
    80002b84:	c711                	beqz	a4,80002b90 <get_unused_ram_index+0x1c>
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002b86:	2505                	addiw	a0,a0,1
    80002b88:	07c1                	addi	a5,a5,16
    80002b8a:	fed51ce3          	bne	a0,a3,80002b82 <get_unused_ram_index+0xe>
  return -1;
    80002b8e:	557d                	li	a0,-1
}
    80002b90:	6422                	ld	s0,8(sp)
    80002b92:	0141                	addi	sp,sp,16
    80002b94:	8082                	ret

0000000080002b96 <get_disk_page_index>:
{
    80002b96:	1141                	addi	sp,sp,-16
    80002b98:	e422                	sd	s0,8(sp)
    80002b9a:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b9c:	27050793          	addi	a5,a0,624
    80002ba0:	4501                	li	a0,0
    80002ba2:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002ba4:	6398                	ld	a4,0(a5)
    80002ba6:	00b70763          	beq	a4,a1,80002bb4 <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002baa:	2505                	addiw	a0,a0,1
    80002bac:	07c1                	addi	a5,a5,16
    80002bae:	fed51be3          	bne	a0,a3,80002ba4 <get_disk_page_index+0xe>
  return -1;
    80002bb2:	557d                	li	a0,-1
}
    80002bb4:	6422                	ld	s0,8(sp)
    80002bb6:	0141                	addi	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <remove_page_from_ram>:
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002bba:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002bbc:	37fd                	addiw	a5,a5,-1
    80002bbe:	4705                	li	a4,1
    80002bc0:	04f77563          	bgeu	a4,a5,80002c0a <remove_page_from_ram+0x50>
    80002bc4:	17050793          	addi	a5,a0,368
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002bc8:	4701                	li	a4,0
    80002bca:	4641                	li	a2,16
    80002bcc:	a029                	j	80002bd6 <remove_page_from_ram+0x1c>
    80002bce:	2705                	addiw	a4,a4,1
    80002bd0:	07c1                	addi	a5,a5,16
    80002bd2:	02c70063          	beq	a4,a2,80002bf2 <remove_page_from_ram+0x38>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002bd6:	6394                	ld	a3,0(a5)
    80002bd8:	feb69be3          	bne	a3,a1,80002bce <remove_page_from_ram+0x14>
    80002bdc:	47d4                	lw	a3,12(a5)
    80002bde:	dae5                	beqz	a3,80002bce <remove_page_from_ram+0x14>
      p->ram_pages[i].va = 0;
    80002be0:	0712                	slli	a4,a4,0x4
    80002be2:	972a                	add	a4,a4,a0
    80002be4:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002be8:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002bec:	16072c23          	sw	zero,376(a4)
      return;
    80002bf0:	8082                	ret
{
    80002bf2:	1141                	addi	sp,sp,-16
    80002bf4:	e406                	sd	ra,8(sp)
    80002bf6:	e022                	sd	s0,0(sp)
    80002bf8:	0800                	addi	s0,sp,16
  panic("remove_page_from_ram failed");
    80002bfa:	00007517          	auipc	a0,0x7
    80002bfe:	92e50513          	addi	a0,a0,-1746 # 80009528 <digits+0x4e8>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	928080e7          	jalr	-1752(ra) # 8000052a <panic>
    80002c0a:	8082                	ret

0000000080002c0c <nfua>:
{
    80002c0c:	1141                	addi	sp,sp,-16
    80002c0e:	e422                	sd	s0,8(sp)
    80002c10:	0800                	addi	s0,sp,16
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c12:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c16:	567d                	li	a2,-1
  int min_index = 0;
    80002c18:	4501                	li	a0,0
  int i = 0;
    80002c1a:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c1c:	45c1                	li	a1,16
    80002c1e:	a029                	j	80002c28 <nfua+0x1c>
    80002c20:	0741                	addi	a4,a4,16
    80002c22:	2785                	addiw	a5,a5,1
    80002c24:	00b78863          	beq	a5,a1,80002c34 <nfua+0x28>
    if(ram_pg->age < min_age){
    80002c28:	4714                	lw	a3,8(a4)
    80002c2a:	fec6fbe3          	bgeu	a3,a2,80002c20 <nfua+0x14>
      min_age = ram_pg->age;
    80002c2e:	8636                	mv	a2,a3
    if(ram_pg->age < min_age){
    80002c30:	853e                	mv	a0,a5
    80002c32:	b7fd                	j	80002c20 <nfua+0x14>
}
    80002c34:	6422                	ld	s0,8(sp)
    80002c36:	0141                	addi	sp,sp,16
    80002c38:	8082                	ret

0000000080002c3a <count_ones>:
{
    80002c3a:	1141                	addi	sp,sp,-16
    80002c3c:	e422                	sd	s0,8(sp)
    80002c3e:	0800                	addi	s0,sp,16
  while(num > 0){
    80002c40:	c105                	beqz	a0,80002c60 <count_ones+0x26>
    80002c42:	87aa                	mv	a5,a0
  int count = 0;
    80002c44:	4501                	li	a0,0
  while(num > 0){
    80002c46:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002c48:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002c4c:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002c4e:	0007871b          	sext.w	a4,a5
    80002c52:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002c56:	fee6e9e3          	bltu	a3,a4,80002c48 <count_ones+0xe>
}
    80002c5a:	6422                	ld	s0,8(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret
  int count = 0;
    80002c60:	4501                	li	a0,0
    80002c62:	bfe5                	j	80002c5a <count_ones+0x20>

0000000080002c64 <lapa>:
{
    80002c64:	715d                	addi	sp,sp,-80
    80002c66:	e486                	sd	ra,72(sp)
    80002c68:	e0a2                	sd	s0,64(sp)
    80002c6a:	fc26                	sd	s1,56(sp)
    80002c6c:	f84a                	sd	s2,48(sp)
    80002c6e:	f44e                	sd	s3,40(sp)
    80002c70:	f052                	sd	s4,32(sp)
    80002c72:	ec56                	sd	s5,24(sp)
    80002c74:	e85a                	sd	s6,16(sp)
    80002c76:	e45e                	sd	s7,8(sp)
    80002c78:	0880                	addi	s0,sp,80
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c7a:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c7e:	5afd                	li	s5,-1
  int min_index = 0;
    80002c80:	4b81                	li	s7,0
  int i = 0;
    80002c82:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c84:	4b41                	li	s6,16
    80002c86:	a039                	j	80002c94 <lapa+0x30>
      min_age = ram_pg->age;
    80002c88:	8ad2                	mv	s5,s4
    80002c8a:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c8c:	09c1                	addi	s3,s3,16
    80002c8e:	2905                	addiw	s2,s2,1
    80002c90:	03690863          	beq	s2,s6,80002cc0 <lapa+0x5c>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c94:	0089aa03          	lw	s4,8(s3)
    80002c98:	8552                	mv	a0,s4
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	fa0080e7          	jalr	-96(ra) # 80002c3a <count_ones>
    80002ca2:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002ca4:	8556                	mv	a0,s5
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	f94080e7          	jalr	-108(ra) # 80002c3a <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002cae:	fca4cde3          	blt	s1,a0,80002c88 <lapa+0x24>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002cb2:	fca49de3          	bne	s1,a0,80002c8c <lapa+0x28>
    80002cb6:	fd5a7be3          	bgeu	s4,s5,80002c8c <lapa+0x28>
      min_age = ram_pg->age;
    80002cba:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002cbc:	8bca                	mv	s7,s2
    80002cbe:	b7f9                	j	80002c8c <lapa+0x28>
}
    80002cc0:	855e                	mv	a0,s7
    80002cc2:	60a6                	ld	ra,72(sp)
    80002cc4:	6406                	ld	s0,64(sp)
    80002cc6:	74e2                	ld	s1,56(sp)
    80002cc8:	7942                	ld	s2,48(sp)
    80002cca:	79a2                	ld	s3,40(sp)
    80002ccc:	7a02                	ld	s4,32(sp)
    80002cce:	6ae2                	ld	s5,24(sp)
    80002cd0:	6b42                	ld	s6,16(sp)
    80002cd2:	6ba2                	ld	s7,8(sp)
    80002cd4:	6161                	addi	sp,sp,80
    80002cd6:	8082                	ret

0000000080002cd8 <scfifo>:
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	e04a                	sd	s2,0(sp)
    80002ce2:	1000                	addi	s0,sp,32
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
    80002d02:	c10d                	beqz	a0,80002d24 <scfifo+0x4c>
    if(*pte & PTE_A){
    80002d04:	611c                	ld	a5,0(a0)
    80002d06:	0407f713          	andi	a4,a5,64
    80002d0a:	c70d                	beqz	a4,80002d34 <scfifo+0x5c>
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
    80002d22:	b7e1                	j	80002cea <scfifo+0x12>
      panic("scfifo: walk failed");
    80002d24:	00007517          	auipc	a0,0x7
    80002d28:	82450513          	addi	a0,a0,-2012 # 80009548 <digits+0x508>
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
    80002d58:	1101                	addi	sp,sp,-32
    80002d5a:	ec06                	sd	ra,24(sp)
    80002d5c:	e822                	sd	s0,16(sp)
    80002d5e:	e426                	sd	s1,8(sp)
    80002d60:	1000                	addi	s0,sp,32
    80002d62:	84aa                	mv	s1,a0
      printf("scfifo swap\n");//REMOVE
    80002d64:	00006517          	auipc	a0,0x6
    80002d68:	7fc50513          	addi	a0,a0,2044 # 80009560 <digits+0x520>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	808080e7          	jalr	-2040(ra) # 80000574 <printf>
    return scfifo(p);
    80002d74:	8526                	mv	a0,s1
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	f62080e7          	jalr	-158(ra) # 80002cd8 <scfifo>
}
    80002d7e:	60e2                	ld	ra,24(sp)
    80002d80:	6442                	ld	s0,16(sp)
    80002d82:	64a2                	ld	s1,8(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <handle_page_fault>:
{
    80002d88:	7179                	addi	sp,sp,-48
    80002d8a:	f406                	sd	ra,40(sp)
    80002d8c:	f022                	sd	s0,32(sp)
    80002d8e:	ec26                	sd	s1,24(sp)
    80002d90:	e84a                	sd	s2,16(sp)
    80002d92:	e44e                	sd	s3,8(sp)
    80002d94:	1800                	addi	s0,sp,48
    80002d96:	89aa                	mv	s3,a0
  printf("##### PAGE FAULT #### \n");//REMOVE
    80002d98:	00006517          	auipc	a0,0x6
    80002d9c:	7d850513          	addi	a0,a0,2008 # 80009570 <digits+0x530>
    80002da0:	ffffd097          	auipc	ra,0xffffd
    80002da4:	7d4080e7          	jalr	2004(ra) # 80000574 <printf>
  struct proc *p = myproc();
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	c6e080e7          	jalr	-914(ra) # 80001a16 <myproc>
    80002db0:	84aa                	mv	s1,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002db2:	4601                	li	a2,0
    80002db4:	85ce                	mv	a1,s3
    80002db6:	6928                	ld	a0,80(a0)
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	200080e7          	jalr	512(ra) # 80000fb8 <walk>
    80002dc0:	c921                	beqz	a0,80002e10 <handle_page_fault+0x88>
  if(*pte & PTE_V){
    80002dc2:	611c                	ld	a5,0(a0)
    80002dc4:	0017f713          	andi	a4,a5,1
    80002dc8:	ef21                	bnez	a4,80002e20 <handle_page_fault+0x98>
  if(!(*pte & PTE_PG)) {
    80002dca:	2007f793          	andi	a5,a5,512
    80002dce:	c3ad                	beqz	a5,80002e30 <handle_page_fault+0xa8>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	da2080e7          	jalr	-606(ra) # 80002b74 <get_unused_ram_index>
    80002dda:	892a                	mv	s2,a0
    80002ddc:	06054263          	bltz	a0,80002e40 <handle_page_fault+0xb8>
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002de0:	75fd                	lui	a1,0xfffff
    80002de2:	00b9f5b3          	and	a1,s3,a1
    80002de6:	8526                	mv	a0,s1
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	dae080e7          	jalr	-594(ra) # 80002b96 <get_disk_page_index>
    80002df0:	85aa                	mv	a1,a0
    80002df2:	06054463          	bltz	a0,80002e5a <handle_page_fault+0xd2>
  swapin(p, target_idx, unused_ram_pg_index);
    80002df6:	864a                	mv	a2,s2
    80002df8:	8526                	mv	a0,s1
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	c0e080e7          	jalr	-1010(ra) # 80002a08 <swapin>
}
    80002e02:	70a2                	ld	ra,40(sp)
    80002e04:	7402                	ld	s0,32(sp)
    80002e06:	64e2                	ld	s1,24(sp)
    80002e08:	6942                	ld	s2,16(sp)
    80002e0a:	69a2                	ld	s3,8(sp)
    80002e0c:	6145                	addi	sp,sp,48
    80002e0e:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002e10:	00006517          	auipc	a0,0x6
    80002e14:	77850513          	addi	a0,a0,1912 # 80009588 <digits+0x548>
    80002e18:	ffffd097          	auipc	ra,0xffffd
    80002e1c:	712080e7          	jalr	1810(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002e20:	00006517          	auipc	a0,0x6
    80002e24:	78850513          	addi	a0,a0,1928 # 800095a8 <digits+0x568>
    80002e28:	ffffd097          	auipc	ra,0xffffd
    80002e2c:	702080e7          	jalr	1794(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002e30:	00006517          	auipc	a0,0x6
    80002e34:	79850513          	addi	a0,a0,1944 # 800095c8 <digits+0x588>
    80002e38:	ffffd097          	auipc	ra,0xffffd
    80002e3c:	6f2080e7          	jalr	1778(ra) # 8000052a <panic>
      int ram_pg_index_to_swap =  index_page_to_swap(p);
    80002e40:	8526                	mv	a0,s1
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	f16080e7          	jalr	-234(ra) # 80002d58 <index_page_to_swap>
    80002e4a:	892a                	mv	s2,a0
      swapout(p, ram_pg_index_to_swap); 
    80002e4c:	85aa                	mv	a1,a0
    80002e4e:	8526                	mv	a0,s1
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	9ee080e7          	jalr	-1554(ra) # 8000283e <swapout>
      unused_ram_pg_index = ram_pg_index_to_swap;
    80002e58:	b761                	j	80002de0 <handle_page_fault+0x58>
    panic("handle_page_fault: get_disk_page_index failed");
    80002e5a:	00006517          	auipc	a0,0x6
    80002e5e:	78e50513          	addi	a0,a0,1934 # 800095e8 <digits+0x5a8>
    80002e62:	ffffd097          	auipc	ra,0xffffd
    80002e66:	6c8080e7          	jalr	1736(ra) # 8000052a <panic>

0000000080002e6a <insert_page_to_ram>:
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002e6a:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002e6c:	37fd                	addiw	a5,a5,-1
    80002e6e:	4705                	li	a4,1
    80002e70:	00f76363          	bltu	a4,a5,80002e76 <insert_page_to_ram+0xc>
    80002e74:	8082                	ret
{
    80002e76:	7179                	addi	sp,sp,-48
    80002e78:	f406                	sd	ra,40(sp)
    80002e7a:	f022                	sd	s0,32(sp)
    80002e7c:	ec26                	sd	s1,24(sp)
    80002e7e:	e84a                	sd	s2,16(sp)
    80002e80:	e44e                	sd	s3,8(sp)
    80002e82:	1800                	addi	s0,sp,48
    80002e84:	84aa                	mv	s1,a0
    80002e86:	89ae                	mv	s3,a1
  printf("insert_page_to_ram1\n");//REMOVE
    80002e88:	00006517          	auipc	a0,0x6
    80002e8c:	79050513          	addi	a0,a0,1936 # 80009618 <digits+0x5d8>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6e4080e7          	jalr	1764(ra) # 80000574 <printf>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002e98:	8526                	mv	a0,s1
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	cda080e7          	jalr	-806(ra) # 80002b74 <get_unused_ram_index>
    80002ea2:	892a                	mv	s2,a0
    80002ea4:	02054263          	bltz	a0,80002ec8 <insert_page_to_ram+0x5e>
  ram_pg->va = va;
    80002ea8:	0912                	slli	s2,s2,0x4
    80002eaa:	94ca                	add	s1,s1,s2
    80002eac:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002eb0:	4785                	li	a5,1
    80002eb2:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002eb6:	1604ac23          	sw	zero,376(s1)
}
    80002eba:	70a2                	ld	ra,40(sp)
    80002ebc:	7402                	ld	s0,32(sp)
    80002ebe:	64e2                	ld	s1,24(sp)
    80002ec0:	6942                	ld	s2,16(sp)
    80002ec2:	69a2                	ld	s3,8(sp)
    80002ec4:	6145                	addi	sp,sp,48
    80002ec6:	8082                	ret
    int ram_pg_index_to_swap = index_page_to_swap(p);
    80002ec8:	8526                	mv	a0,s1
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	e8e080e7          	jalr	-370(ra) # 80002d58 <index_page_to_swap>
    80002ed2:	892a                	mv	s2,a0
    printf("ram_pg_index_to_swap: %d\n",ram_pg_index_to_swap);//REMOVE
    80002ed4:	85aa                	mv	a1,a0
    80002ed6:	00006517          	auipc	a0,0x6
    80002eda:	75a50513          	addi	a0,a0,1882 # 80009630 <digits+0x5f0>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	696080e7          	jalr	1686(ra) # 80000574 <printf>
    printf("pid: %d\n",p->pid);//REMOVE
    80002ee6:	588c                	lw	a1,48(s1)
    80002ee8:	00006517          	auipc	a0,0x6
    80002eec:	76850513          	addi	a0,a0,1896 # 80009650 <digits+0x610>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	684080e7          	jalr	1668(ra) # 80000574 <printf>
    swapout(p, ram_pg_index_to_swap);
    80002ef8:	85ca                	mv	a1,s2
    80002efa:	8526                	mv	a0,s1
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	942080e7          	jalr	-1726(ra) # 8000283e <swapout>
    printf("insert_page_to_ram2\n");//REMOVE
    80002f04:	00006517          	auipc	a0,0x6
    80002f08:	75c50513          	addi	a0,a0,1884 # 80009660 <digits+0x620>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	668080e7          	jalr	1640(ra) # 80000574 <printf>
    printf("insert_page_to_ram3\n");//REMOVE
    80002f14:	00006517          	auipc	a0,0x6
    80002f18:	76450513          	addi	a0,a0,1892 # 80009678 <digits+0x638>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	658080e7          	jalr	1624(ra) # 80000574 <printf>
    80002f24:	b751                	j	80002ea8 <insert_page_to_ram+0x3e>

0000000080002f26 <maintain_age>:
void maintain_age(struct proc *p){
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	e84a                	sd	s2,16(sp)
    80002f30:	e44e                	sd	s3,8(sp)
    80002f32:	e052                	sd	s4,0(sp)
    80002f34:	1800                	addi	s0,sp,48
    80002f36:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002f38:	17050493          	addi	s1,a0,368
    80002f3c:	27050993          	addi	s3,a0,624
      ram_pg->age = ram_pg->age | (1 << 31);
    80002f40:	80000a37          	lui	s4,0x80000
    80002f44:	a821                	j	80002f5c <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002f46:	00006517          	auipc	a0,0x6
    80002f4a:	74a50513          	addi	a0,a0,1866 # 80009690 <digits+0x650>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	5dc080e7          	jalr	1500(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002f56:	04c1                	addi	s1,s1,16
    80002f58:	02998b63          	beq	s3,s1,80002f8e <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002f5c:	4601                	li	a2,0
    80002f5e:	608c                	ld	a1,0(s1)
    80002f60:	05093503          	ld	a0,80(s2)
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	054080e7          	jalr	84(ra) # 80000fb8 <walk>
    80002f6c:	dd69                	beqz	a0,80002f46 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002f6e:	449c                	lw	a5,8(s1)
    80002f70:	0017d79b          	srliw	a5,a5,0x1
    80002f74:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002f76:	6118                	ld	a4,0(a0)
    80002f78:	04077713          	andi	a4,a4,64
    80002f7c:	df69                	beqz	a4,80002f56 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002f7e:	0147e7b3          	or	a5,a5,s4
    80002f82:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002f84:	611c                	ld	a5,0(a0)
    80002f86:	fbf7f793          	andi	a5,a5,-65
    80002f8a:	e11c                	sd	a5,0(a0)
    80002f8c:	b7e9                	j	80002f56 <maintain_age+0x30>
}
    80002f8e:	70a2                	ld	ra,40(sp)
    80002f90:	7402                	ld	s0,32(sp)
    80002f92:	64e2                	ld	s1,24(sp)
    80002f94:	6942                	ld	s2,16(sp)
    80002f96:	69a2                	ld	s3,8(sp)
    80002f98:	6a02                	ld	s4,0(sp)
    80002f9a:	6145                	addi	sp,sp,48
    80002f9c:	8082                	ret

0000000080002f9e <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80002f9e:	1141                	addi	sp,sp,-16
    80002fa0:	e422                	sd	s0,8(sp)
    80002fa2:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002fa4:	591c                	lw	a5,48(a0)
    80002fa6:	37fd                	addiw	a5,a5,-1
  //return (strncmp(p->name, "initcode", sizeof(p->name)) != 0) && (strncmp(p->name, "init", sizeof(p->name)) != 0) && (strncmp(p->parent->name, "init", sizeof(p->parent->name)) != 0);
    80002fa8:	4505                	li	a0,1
    80002faa:	00f53533          	sltu	a0,a0,a5
    80002fae:	6422                	ld	s0,8(sp)
    80002fb0:	0141                	addi	sp,sp,16
    80002fb2:	8082                	ret

0000000080002fb4 <swtch>:
    80002fb4:	00153023          	sd	ra,0(a0)
    80002fb8:	00253423          	sd	sp,8(a0)
    80002fbc:	e900                	sd	s0,16(a0)
    80002fbe:	ed04                	sd	s1,24(a0)
    80002fc0:	03253023          	sd	s2,32(a0)
    80002fc4:	03353423          	sd	s3,40(a0)
    80002fc8:	03453823          	sd	s4,48(a0)
    80002fcc:	03553c23          	sd	s5,56(a0)
    80002fd0:	05653023          	sd	s6,64(a0)
    80002fd4:	05753423          	sd	s7,72(a0)
    80002fd8:	05853823          	sd	s8,80(a0)
    80002fdc:	05953c23          	sd	s9,88(a0)
    80002fe0:	07a53023          	sd	s10,96(a0)
    80002fe4:	07b53423          	sd	s11,104(a0)
    80002fe8:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002fec:	0085b103          	ld	sp,8(a1)
    80002ff0:	6980                	ld	s0,16(a1)
    80002ff2:	6d84                	ld	s1,24(a1)
    80002ff4:	0205b903          	ld	s2,32(a1)
    80002ff8:	0285b983          	ld	s3,40(a1)
    80002ffc:	0305ba03          	ld	s4,48(a1)
    80003000:	0385ba83          	ld	s5,56(a1)
    80003004:	0405bb03          	ld	s6,64(a1)
    80003008:	0485bb83          	ld	s7,72(a1)
    8000300c:	0505bc03          	ld	s8,80(a1)
    80003010:	0585bc83          	ld	s9,88(a1)
    80003014:	0605bd03          	ld	s10,96(a1)
    80003018:	0685bd83          	ld	s11,104(a1)
    8000301c:	8082                	ret

000000008000301e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000301e:	1141                	addi	sp,sp,-16
    80003020:	e406                	sd	ra,8(sp)
    80003022:	e022                	sd	s0,0(sp)
    80003024:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003026:	00006597          	auipc	a1,0x6
    8000302a:	6e258593          	addi	a1,a1,1762 # 80009708 <states.0+0x30>
    8000302e:	0001d517          	auipc	a0,0x1d
    80003032:	4a250513          	addi	a0,a0,1186 # 800204d0 <tickslock>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	afc080e7          	jalr	-1284(ra) # 80000b32 <initlock>
}
    8000303e:	60a2                	ld	ra,8(sp)
    80003040:	6402                	ld	s0,0(sp)
    80003042:	0141                	addi	sp,sp,16
    80003044:	8082                	ret

0000000080003046 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003046:	1141                	addi	sp,sp,-16
    80003048:	e422                	sd	s0,8(sp)
    8000304a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000304c:	00004797          	auipc	a5,0x4
    80003050:	ae478793          	addi	a5,a5,-1308 # 80006b30 <kernelvec>
    80003054:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003058:	6422                	ld	s0,8(sp)
    8000305a:	0141                	addi	sp,sp,16
    8000305c:	8082                	ret

000000008000305e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000305e:	1141                	addi	sp,sp,-16
    80003060:	e406                	sd	ra,8(sp)
    80003062:	e022                	sd	s0,0(sp)
    80003064:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	9b0080e7          	jalr	-1616(ra) # 80001a16 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000306e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003072:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003074:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003078:	00005617          	auipc	a2,0x5
    8000307c:	f8860613          	addi	a2,a2,-120 # 80008000 <_trampoline>
    80003080:	00005697          	auipc	a3,0x5
    80003084:	f8068693          	addi	a3,a3,-128 # 80008000 <_trampoline>
    80003088:	8e91                	sub	a3,a3,a2
    8000308a:	040007b7          	lui	a5,0x4000
    8000308e:	17fd                	addi	a5,a5,-1
    80003090:	07b2                	slli	a5,a5,0xc
    80003092:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003094:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003098:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000309a:	180026f3          	csrr	a3,satp
    8000309e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800030a0:	6d38                	ld	a4,88(a0)
    800030a2:	6134                	ld	a3,64(a0)
    800030a4:	6585                	lui	a1,0x1
    800030a6:	96ae                	add	a3,a3,a1
    800030a8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800030aa:	6d38                	ld	a4,88(a0)
    800030ac:	00000697          	auipc	a3,0x0
    800030b0:	13868693          	addi	a3,a3,312 # 800031e4 <usertrap>
    800030b4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800030b6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800030b8:	8692                	mv	a3,tp
    800030ba:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030bc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800030c0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800030c4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030c8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800030cc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ce:	6f18                	ld	a4,24(a4)
    800030d0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800030d4:	692c                	ld	a1,80(a0)
    800030d6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800030d8:	00005717          	auipc	a4,0x5
    800030dc:	fb870713          	addi	a4,a4,-72 # 80008090 <userret>
    800030e0:	8f11                	sub	a4,a4,a2
    800030e2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800030e4:	577d                	li	a4,-1
    800030e6:	177e                	slli	a4,a4,0x3f
    800030e8:	8dd9                	or	a1,a1,a4
    800030ea:	02000537          	lui	a0,0x2000
    800030ee:	157d                	addi	a0,a0,-1
    800030f0:	0536                	slli	a0,a0,0xd
    800030f2:	9782                	jalr	a5
}
    800030f4:	60a2                	ld	ra,8(sp)
    800030f6:	6402                	ld	s0,0(sp)
    800030f8:	0141                	addi	sp,sp,16
    800030fa:	8082                	ret

00000000800030fc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030fc:	1101                	addi	sp,sp,-32
    800030fe:	ec06                	sd	ra,24(sp)
    80003100:	e822                	sd	s0,16(sp)
    80003102:	e426                	sd	s1,8(sp)
    80003104:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003106:	0001d497          	auipc	s1,0x1d
    8000310a:	3ca48493          	addi	s1,s1,970 # 800204d0 <tickslock>
    8000310e:	8526                	mv	a0,s1
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
  ticks++;
    80003118:	00007517          	auipc	a0,0x7
    8000311c:	f1850513          	addi	a0,a0,-232 # 8000a030 <ticks>
    80003120:	411c                	lw	a5,0(a0)
    80003122:	2785                	addiw	a5,a5,1
    80003124:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	09e080e7          	jalr	158(ra) # 800021c4 <wakeup>
  release(&tickslock);
    8000312e:	8526                	mv	a0,s1
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b58080e7          	jalr	-1192(ra) # 80000c88 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000314c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003150:	00074d63          	bltz	a4,8000316a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003154:	57fd                	li	a5,-1
    80003156:	17fe                	slli	a5,a5,0x3f
    80003158:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000315a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000315c:	06f70363          	beq	a4,a5,800031c2 <devintr+0x80>
  }
}
    80003160:	60e2                	ld	ra,24(sp)
    80003162:	6442                	ld	s0,16(sp)
    80003164:	64a2                	ld	s1,8(sp)
    80003166:	6105                	addi	sp,sp,32
    80003168:	8082                	ret
     (scause & 0xff) == 9){
    8000316a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000316e:	46a5                	li	a3,9
    80003170:	fed792e3          	bne	a5,a3,80003154 <devintr+0x12>
    int irq = plic_claim();
    80003174:	00004097          	auipc	ra,0x4
    80003178:	ac4080e7          	jalr	-1340(ra) # 80006c38 <plic_claim>
    8000317c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000317e:	47a9                	li	a5,10
    80003180:	02f50763          	beq	a0,a5,800031ae <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003184:	4785                	li	a5,1
    80003186:	02f50963          	beq	a0,a5,800031b8 <devintr+0x76>
    return 1;
    8000318a:	4505                	li	a0,1
    } else if(irq){
    8000318c:	d8f1                	beqz	s1,80003160 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000318e:	85a6                	mv	a1,s1
    80003190:	00006517          	auipc	a0,0x6
    80003194:	58050513          	addi	a0,a0,1408 # 80009710 <states.0+0x38>
    80003198:	ffffd097          	auipc	ra,0xffffd
    8000319c:	3dc080e7          	jalr	988(ra) # 80000574 <printf>
      plic_complete(irq);
    800031a0:	8526                	mv	a0,s1
    800031a2:	00004097          	auipc	ra,0x4
    800031a6:	aba080e7          	jalr	-1350(ra) # 80006c5c <plic_complete>
    return 1;
    800031aa:	4505                	li	a0,1
    800031ac:	bf55                	j	80003160 <devintr+0x1e>
      uartintr();
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	7d8080e7          	jalr	2008(ra) # 80000986 <uartintr>
    800031b6:	b7ed                	j	800031a0 <devintr+0x5e>
      virtio_disk_intr();
    800031b8:	00004097          	auipc	ra,0x4
    800031bc:	f36080e7          	jalr	-202(ra) # 800070ee <virtio_disk_intr>
    800031c0:	b7c5                	j	800031a0 <devintr+0x5e>
    if(cpuid() == 0){
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	828080e7          	jalr	-2008(ra) # 800019ea <cpuid>
    800031ca:	c901                	beqz	a0,800031da <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800031cc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800031d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800031d2:	14479073          	csrw	sip,a5
    return 2;
    800031d6:	4509                	li	a0,2
    800031d8:	b761                	j	80003160 <devintr+0x1e>
      clockintr();
    800031da:	00000097          	auipc	ra,0x0
    800031de:	f22080e7          	jalr	-222(ra) # 800030fc <clockintr>
    800031e2:	b7ed                	j	800031cc <devintr+0x8a>

00000000800031e4 <usertrap>:
{
    800031e4:	1101                	addi	sp,sp,-32
    800031e6:	ec06                	sd	ra,24(sp)
    800031e8:	e822                	sd	s0,16(sp)
    800031ea:	e426                	sd	s1,8(sp)
    800031ec:	e04a                	sd	s2,0(sp)
    800031ee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800031f4:	1007f793          	andi	a5,a5,256
    800031f8:	e3ad                	bnez	a5,8000325a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031fa:	00004797          	auipc	a5,0x4
    800031fe:	93678793          	addi	a5,a5,-1738 # 80006b30 <kernelvec>
    80003202:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	810080e7          	jalr	-2032(ra) # 80001a16 <myproc>
    8000320e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003210:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003212:	14102773          	csrr	a4,sepc
    80003216:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003218:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000321c:	47a1                	li	a5,8
    8000321e:	04f71c63          	bne	a4,a5,80003276 <usertrap+0x92>
    if(p->killed)
    80003222:	551c                	lw	a5,40(a0)
    80003224:	e3b9                	bnez	a5,8000326a <usertrap+0x86>
    p->trapframe->epc += 4;
    80003226:	6cb8                	ld	a4,88(s1)
    80003228:	6f1c                	ld	a5,24(a4)
    8000322a:	0791                	addi	a5,a5,4
    8000322c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000322e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003232:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003236:	10079073          	csrw	sstatus,a5
    syscall();
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	338080e7          	jalr	824(ra) # 80003572 <syscall>
  if(p->killed)
    80003242:	549c                	lw	a5,40(s1)
    80003244:	ebe1                	bnez	a5,80003314 <usertrap+0x130>
  usertrapret();
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	e18080e7          	jalr	-488(ra) # 8000305e <usertrapret>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6902                	ld	s2,0(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret
    panic("usertrap: not from user mode");
    8000325a:	00006517          	auipc	a0,0x6
    8000325e:	4d650513          	addi	a0,a0,1238 # 80009730 <states.0+0x58>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2c8080e7          	jalr	712(ra) # 8000052a <panic>
      exit(-1);
    8000326a:	557d                	li	a0,-1
    8000326c:	fffff097          	auipc	ra,0xfffff
    80003270:	4b6080e7          	jalr	1206(ra) # 80002722 <exit>
    80003274:	bf4d                	j	80003226 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	ecc080e7          	jalr	-308(ra) # 80003142 <devintr>
    8000327e:	892a                	mv	s2,a0
    80003280:	c501                	beqz	a0,80003288 <usertrap+0xa4>
  if(p->killed)
    80003282:	549c                	lw	a5,40(s1)
    80003284:	cfd1                	beqz	a5,80003320 <usertrap+0x13c>
    80003286:	a841                	j	80003316 <usertrap+0x132>
  } else if (relevant_metadata_proc(p) && 
    80003288:	8526                	mv	a0,s1
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	d14080e7          	jalr	-748(ra) # 80002f9e <relevant_metadata_proc>
    80003292:	c105                	beqz	a0,800032b2 <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003294:	14202773          	csrr	a4,scause
    80003298:	47b1                	li	a5,12
    8000329a:	04f70e63          	beq	a4,a5,800032f6 <usertrap+0x112>
    8000329e:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800032a2:	47b5                	li	a5,13
    800032a4:	04f70963          	beq	a4,a5,800032f6 <usertrap+0x112>
    800032a8:	14202773          	csrr	a4,scause
    800032ac:	47bd                	li	a5,15
    800032ae:	04f70463          	beq	a4,a5,800032f6 <usertrap+0x112>
    printf("$$$$$$$$HERE#######\n");//REMOVE
    800032b2:	00006517          	auipc	a0,0x6
    800032b6:	4ae50513          	addi	a0,a0,1198 # 80009760 <states.0+0x88>
    800032ba:	ffffd097          	auipc	ra,0xffffd
    800032be:	2ba080e7          	jalr	698(ra) # 80000574 <printf>
    800032c2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800032c6:	5890                	lw	a2,48(s1)
    800032c8:	00006517          	auipc	a0,0x6
    800032cc:	4b050513          	addi	a0,a0,1200 # 80009778 <states.0+0xa0>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	2a4080e7          	jalr	676(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032d8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032dc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032e0:	00006517          	auipc	a0,0x6
    800032e4:	4c850513          	addi	a0,a0,1224 # 800097a8 <states.0+0xd0>
    800032e8:	ffffd097          	auipc	ra,0xffffd
    800032ec:	28c080e7          	jalr	652(ra) # 80000574 <printf>
    p->killed = 1;
    800032f0:	4785                	li	a5,1
    800032f2:	d49c                	sw	a5,40(s1)
  if(p->killed)
    800032f4:	a00d                	j	80003316 <usertrap+0x132>
      printf("USERTRAP FAULT");
    800032f6:	00006517          	auipc	a0,0x6
    800032fa:	45a50513          	addi	a0,a0,1114 # 80009750 <states.0+0x78>
    800032fe:	ffffd097          	auipc	ra,0xffffd
    80003302:	276080e7          	jalr	630(ra) # 80000574 <printf>
    80003306:	14302573          	csrr	a0,stval
      handle_page_fault(va);    
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	a7e080e7          	jalr	-1410(ra) # 80002d88 <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    80003312:	bf05                	j	80003242 <usertrap+0x5e>
  if(p->killed)
    80003314:	4901                	li	s2,0
    exit(-1);
    80003316:	557d                	li	a0,-1
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	40a080e7          	jalr	1034(ra) # 80002722 <exit>
  if(which_dev == 2)
    80003320:	4789                	li	a5,2
    80003322:	f2f912e3          	bne	s2,a5,80003246 <usertrap+0x62>
    yield();
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	cd6080e7          	jalr	-810(ra) # 80001ffc <yield>
    8000332e:	bf21                	j	80003246 <usertrap+0x62>

0000000080003330 <kerneltrap>:
{
    80003330:	7179                	addi	sp,sp,-48
    80003332:	f406                	sd	ra,40(sp)
    80003334:	f022                	sd	s0,32(sp)
    80003336:	ec26                	sd	s1,24(sp)
    80003338:	e84a                	sd	s2,16(sp)
    8000333a:	e44e                	sd	s3,8(sp)
    8000333c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000333e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003342:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003346:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000334a:	1004f793          	andi	a5,s1,256
    8000334e:	cb85                	beqz	a5,8000337e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003350:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003354:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003356:	ef85                	bnez	a5,8000338e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	dea080e7          	jalr	-534(ra) # 80003142 <devintr>
    80003360:	cd1d                	beqz	a0,8000339e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003362:	4789                	li	a5,2
    80003364:	06f50a63          	beq	a0,a5,800033d8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003368:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000336c:	10049073          	csrw	sstatus,s1
}
    80003370:	70a2                	ld	ra,40(sp)
    80003372:	7402                	ld	s0,32(sp)
    80003374:	64e2                	ld	s1,24(sp)
    80003376:	6942                	ld	s2,16(sp)
    80003378:	69a2                	ld	s3,8(sp)
    8000337a:	6145                	addi	sp,sp,48
    8000337c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000337e:	00006517          	auipc	a0,0x6
    80003382:	44a50513          	addi	a0,a0,1098 # 800097c8 <states.0+0xf0>
    80003386:	ffffd097          	auipc	ra,0xffffd
    8000338a:	1a4080e7          	jalr	420(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000338e:	00006517          	auipc	a0,0x6
    80003392:	46250513          	addi	a0,a0,1122 # 800097f0 <states.0+0x118>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	194080e7          	jalr	404(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000339e:	85ce                	mv	a1,s3
    800033a0:	00006517          	auipc	a0,0x6
    800033a4:	47050513          	addi	a0,a0,1136 # 80009810 <states.0+0x138>
    800033a8:	ffffd097          	auipc	ra,0xffffd
    800033ac:	1cc080e7          	jalr	460(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033b0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033b4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800033b8:	00006517          	auipc	a0,0x6
    800033bc:	46850513          	addi	a0,a0,1128 # 80009820 <states.0+0x148>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	1b4080e7          	jalr	436(ra) # 80000574 <printf>
    panic("kerneltrap");
    800033c8:	00006517          	auipc	a0,0x6
    800033cc:	47050513          	addi	a0,a0,1136 # 80009838 <states.0+0x160>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	15a080e7          	jalr	346(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	63e080e7          	jalr	1598(ra) # 80001a16 <myproc>
    800033e0:	d541                	beqz	a0,80003368 <kerneltrap+0x38>
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	634080e7          	jalr	1588(ra) # 80001a16 <myproc>
    800033ea:	4d18                	lw	a4,24(a0)
    800033ec:	4791                	li	a5,4
    800033ee:	f6f71de3          	bne	a4,a5,80003368 <kerneltrap+0x38>
    yield();
    800033f2:	fffff097          	auipc	ra,0xfffff
    800033f6:	c0a080e7          	jalr	-1014(ra) # 80001ffc <yield>
    800033fa:	b7bd                	j	80003368 <kerneltrap+0x38>

00000000800033fc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800033fc:	1101                	addi	sp,sp,-32
    800033fe:	ec06                	sd	ra,24(sp)
    80003400:	e822                	sd	s0,16(sp)
    80003402:	e426                	sd	s1,8(sp)
    80003404:	1000                	addi	s0,sp,32
    80003406:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	60e080e7          	jalr	1550(ra) # 80001a16 <myproc>
  switch (n) {
    80003410:	4795                	li	a5,5
    80003412:	0497e163          	bltu	a5,s1,80003454 <argraw+0x58>
    80003416:	048a                	slli	s1,s1,0x2
    80003418:	00006717          	auipc	a4,0x6
    8000341c:	45870713          	addi	a4,a4,1112 # 80009870 <states.0+0x198>
    80003420:	94ba                	add	s1,s1,a4
    80003422:	409c                	lw	a5,0(s1)
    80003424:	97ba                	add	a5,a5,a4
    80003426:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003428:	6d3c                	ld	a5,88(a0)
    8000342a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000342c:	60e2                	ld	ra,24(sp)
    8000342e:	6442                	ld	s0,16(sp)
    80003430:	64a2                	ld	s1,8(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret
    return p->trapframe->a1;
    80003436:	6d3c                	ld	a5,88(a0)
    80003438:	7fa8                	ld	a0,120(a5)
    8000343a:	bfcd                	j	8000342c <argraw+0x30>
    return p->trapframe->a2;
    8000343c:	6d3c                	ld	a5,88(a0)
    8000343e:	63c8                	ld	a0,128(a5)
    80003440:	b7f5                	j	8000342c <argraw+0x30>
    return p->trapframe->a3;
    80003442:	6d3c                	ld	a5,88(a0)
    80003444:	67c8                	ld	a0,136(a5)
    80003446:	b7dd                	j	8000342c <argraw+0x30>
    return p->trapframe->a4;
    80003448:	6d3c                	ld	a5,88(a0)
    8000344a:	6bc8                	ld	a0,144(a5)
    8000344c:	b7c5                	j	8000342c <argraw+0x30>
    return p->trapframe->a5;
    8000344e:	6d3c                	ld	a5,88(a0)
    80003450:	6fc8                	ld	a0,152(a5)
    80003452:	bfe9                	j	8000342c <argraw+0x30>
  panic("argraw");
    80003454:	00006517          	auipc	a0,0x6
    80003458:	3f450513          	addi	a0,a0,1012 # 80009848 <states.0+0x170>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0ce080e7          	jalr	206(ra) # 8000052a <panic>

0000000080003464 <fetchaddr>:
{
    80003464:	1101                	addi	sp,sp,-32
    80003466:	ec06                	sd	ra,24(sp)
    80003468:	e822                	sd	s0,16(sp)
    8000346a:	e426                	sd	s1,8(sp)
    8000346c:	e04a                	sd	s2,0(sp)
    8000346e:	1000                	addi	s0,sp,32
    80003470:	84aa                	mv	s1,a0
    80003472:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	5a2080e7          	jalr	1442(ra) # 80001a16 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000347c:	653c                	ld	a5,72(a0)
    8000347e:	02f4f863          	bgeu	s1,a5,800034ae <fetchaddr+0x4a>
    80003482:	00848713          	addi	a4,s1,8
    80003486:	02e7e663          	bltu	a5,a4,800034b2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000348a:	46a1                	li	a3,8
    8000348c:	8626                	mv	a2,s1
    8000348e:	85ca                	mv	a1,s2
    80003490:	6928                	ld	a0,80(a0)
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	2d0080e7          	jalr	720(ra) # 80001762 <copyin>
    8000349a:	00a03533          	snez	a0,a0
    8000349e:	40a00533          	neg	a0,a0
}
    800034a2:	60e2                	ld	ra,24(sp)
    800034a4:	6442                	ld	s0,16(sp)
    800034a6:	64a2                	ld	s1,8(sp)
    800034a8:	6902                	ld	s2,0(sp)
    800034aa:	6105                	addi	sp,sp,32
    800034ac:	8082                	ret
    return -1;
    800034ae:	557d                	li	a0,-1
    800034b0:	bfcd                	j	800034a2 <fetchaddr+0x3e>
    800034b2:	557d                	li	a0,-1
    800034b4:	b7fd                	j	800034a2 <fetchaddr+0x3e>

00000000800034b6 <fetchstr>:
{
    800034b6:	7179                	addi	sp,sp,-48
    800034b8:	f406                	sd	ra,40(sp)
    800034ba:	f022                	sd	s0,32(sp)
    800034bc:	ec26                	sd	s1,24(sp)
    800034be:	e84a                	sd	s2,16(sp)
    800034c0:	e44e                	sd	s3,8(sp)
    800034c2:	1800                	addi	s0,sp,48
    800034c4:	892a                	mv	s2,a0
    800034c6:	84ae                	mv	s1,a1
    800034c8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800034ca:	ffffe097          	auipc	ra,0xffffe
    800034ce:	54c080e7          	jalr	1356(ra) # 80001a16 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800034d2:	86ce                	mv	a3,s3
    800034d4:	864a                	mv	a2,s2
    800034d6:	85a6                	mv	a1,s1
    800034d8:	6928                	ld	a0,80(a0)
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	316080e7          	jalr	790(ra) # 800017f0 <copyinstr>
  if(err < 0)
    800034e2:	00054763          	bltz	a0,800034f0 <fetchstr+0x3a>
  return strlen(buf);
    800034e6:	8526                	mv	a0,s1
    800034e8:	ffffe097          	auipc	ra,0xffffe
    800034ec:	96c080e7          	jalr	-1684(ra) # 80000e54 <strlen>
}
    800034f0:	70a2                	ld	ra,40(sp)
    800034f2:	7402                	ld	s0,32(sp)
    800034f4:	64e2                	ld	s1,24(sp)
    800034f6:	6942                	ld	s2,16(sp)
    800034f8:	69a2                	ld	s3,8(sp)
    800034fa:	6145                	addi	sp,sp,48
    800034fc:	8082                	ret

00000000800034fe <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	1000                	addi	s0,sp,32
    80003508:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	ef2080e7          	jalr	-270(ra) # 800033fc <argraw>
    80003512:	c088                	sw	a0,0(s1)
  return 0;
}
    80003514:	4501                	li	a0,0
    80003516:	60e2                	ld	ra,24(sp)
    80003518:	6442                	ld	s0,16(sp)
    8000351a:	64a2                	ld	s1,8(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret

0000000080003520 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	e426                	sd	s1,8(sp)
    80003528:	1000                	addi	s0,sp,32
    8000352a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	ed0080e7          	jalr	-304(ra) # 800033fc <argraw>
    80003534:	e088                	sd	a0,0(s1)
  return 0;
}
    80003536:	4501                	li	a0,0
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	64a2                	ld	s1,8(sp)
    8000353e:	6105                	addi	sp,sp,32
    80003540:	8082                	ret

0000000080003542 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003542:	1101                	addi	sp,sp,-32
    80003544:	ec06                	sd	ra,24(sp)
    80003546:	e822                	sd	s0,16(sp)
    80003548:	e426                	sd	s1,8(sp)
    8000354a:	e04a                	sd	s2,0(sp)
    8000354c:	1000                	addi	s0,sp,32
    8000354e:	84ae                	mv	s1,a1
    80003550:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003552:	00000097          	auipc	ra,0x0
    80003556:	eaa080e7          	jalr	-342(ra) # 800033fc <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000355a:	864a                	mv	a2,s2
    8000355c:	85a6                	mv	a1,s1
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	f58080e7          	jalr	-168(ra) # 800034b6 <fetchstr>
}
    80003566:	60e2                	ld	ra,24(sp)
    80003568:	6442                	ld	s0,16(sp)
    8000356a:	64a2                	ld	s1,8(sp)
    8000356c:	6902                	ld	s2,0(sp)
    8000356e:	6105                	addi	sp,sp,32
    80003570:	8082                	ret

0000000080003572 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	e426                	sd	s1,8(sp)
    8000357a:	e04a                	sd	s2,0(sp)
    8000357c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000357e:	ffffe097          	auipc	ra,0xffffe
    80003582:	498080e7          	jalr	1176(ra) # 80001a16 <myproc>
    80003586:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003588:	05853903          	ld	s2,88(a0)
    8000358c:	0a893783          	ld	a5,168(s2)
    80003590:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003594:	37fd                	addiw	a5,a5,-1
    80003596:	4751                	li	a4,20
    80003598:	00f76f63          	bltu	a4,a5,800035b6 <syscall+0x44>
    8000359c:	00369713          	slli	a4,a3,0x3
    800035a0:	00006797          	auipc	a5,0x6
    800035a4:	2e878793          	addi	a5,a5,744 # 80009888 <syscalls>
    800035a8:	97ba                	add	a5,a5,a4
    800035aa:	639c                	ld	a5,0(a5)
    800035ac:	c789                	beqz	a5,800035b6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800035ae:	9782                	jalr	a5
    800035b0:	06a93823          	sd	a0,112(s2)
    800035b4:	a839                	j	800035d2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800035b6:	15848613          	addi	a2,s1,344
    800035ba:	588c                	lw	a1,48(s1)
    800035bc:	00006517          	auipc	a0,0x6
    800035c0:	29450513          	addi	a0,a0,660 # 80009850 <states.0+0x178>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	fb0080e7          	jalr	-80(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800035cc:	6cbc                	ld	a5,88(s1)
    800035ce:	577d                	li	a4,-1
    800035d0:	fbb8                	sd	a4,112(a5)
  }
}
    800035d2:	60e2                	ld	ra,24(sp)
    800035d4:	6442                	ld	s0,16(sp)
    800035d6:	64a2                	ld	s1,8(sp)
    800035d8:	6902                	ld	s2,0(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800035e6:	fec40593          	addi	a1,s0,-20
    800035ea:	4501                	li	a0,0
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	f12080e7          	jalr	-238(ra) # 800034fe <argint>
    return -1;
    800035f4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035f6:	00054963          	bltz	a0,80003608 <sys_exit+0x2a>
  exit(n);
    800035fa:	fec42503          	lw	a0,-20(s0)
    800035fe:	fffff097          	auipc	ra,0xfffff
    80003602:	124080e7          	jalr	292(ra) # 80002722 <exit>
  return 0;  // not reached
    80003606:	4781                	li	a5,0
}
    80003608:	853e                	mv	a0,a5
    8000360a:	60e2                	ld	ra,24(sp)
    8000360c:	6442                	ld	s0,16(sp)
    8000360e:	6105                	addi	sp,sp,32
    80003610:	8082                	ret

0000000080003612 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003612:	1141                	addi	sp,sp,-16
    80003614:	e406                	sd	ra,8(sp)
    80003616:	e022                	sd	s0,0(sp)
    80003618:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000361a:	ffffe097          	auipc	ra,0xffffe
    8000361e:	3fc080e7          	jalr	1020(ra) # 80001a16 <myproc>
}
    80003622:	5908                	lw	a0,48(a0)
    80003624:	60a2                	ld	ra,8(sp)
    80003626:	6402                	ld	s0,0(sp)
    80003628:	0141                	addi	sp,sp,16
    8000362a:	8082                	ret

000000008000362c <sys_fork>:

uint64
sys_fork(void)
{
    8000362c:	1141                	addi	sp,sp,-16
    8000362e:	e406                	sd	ra,8(sp)
    80003630:	e022                	sd	s0,0(sp)
    80003632:	0800                	addi	s0,sp,16
  return fork();
    80003634:	fffff097          	auipc	ra,0xfffff
    80003638:	eea080e7          	jalr	-278(ra) # 8000251e <fork>
}
    8000363c:	60a2                	ld	ra,8(sp)
    8000363e:	6402                	ld	s0,0(sp)
    80003640:	0141                	addi	sp,sp,16
    80003642:	8082                	ret

0000000080003644 <sys_wait>:

uint64
sys_wait(void)
{
    80003644:	1101                	addi	sp,sp,-32
    80003646:	ec06                	sd	ra,24(sp)
    80003648:	e822                	sd	s0,16(sp)
    8000364a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000364c:	fe840593          	addi	a1,s0,-24
    80003650:	4501                	li	a0,0
    80003652:	00000097          	auipc	ra,0x0
    80003656:	ece080e7          	jalr	-306(ra) # 80003520 <argaddr>
    8000365a:	87aa                	mv	a5,a0
    return -1;
    8000365c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000365e:	0007c863          	bltz	a5,8000366e <sys_wait+0x2a>
  return wait(p);
    80003662:	fe843503          	ld	a0,-24(s0)
    80003666:	fffff097          	auipc	ra,0xfffff
    8000366a:	a36080e7          	jalr	-1482(ra) # 8000209c <wait>
}
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret

0000000080003676 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003676:	7179                	addi	sp,sp,-48
    80003678:	f406                	sd	ra,40(sp)
    8000367a:	f022                	sd	s0,32(sp)
    8000367c:	ec26                	sd	s1,24(sp)
    8000367e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003680:	fdc40593          	addi	a1,s0,-36
    80003684:	4501                	li	a0,0
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	e78080e7          	jalr	-392(ra) # 800034fe <argint>
    return -1;
    8000368e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003690:	00054f63          	bltz	a0,800036ae <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003694:	ffffe097          	auipc	ra,0xffffe
    80003698:	382080e7          	jalr	898(ra) # 80001a16 <myproc>
    8000369c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000369e:	fdc42503          	lw	a0,-36(s0)
    800036a2:	ffffe097          	auipc	ra,0xffffe
    800036a6:	6ce080e7          	jalr	1742(ra) # 80001d70 <growproc>
    800036aa:	00054863          	bltz	a0,800036ba <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800036ae:	8526                	mv	a0,s1
    800036b0:	70a2                	ld	ra,40(sp)
    800036b2:	7402                	ld	s0,32(sp)
    800036b4:	64e2                	ld	s1,24(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret
    return -1;
    800036ba:	54fd                	li	s1,-1
    800036bc:	bfcd                	j	800036ae <sys_sbrk+0x38>

00000000800036be <sys_sleep>:

uint64
sys_sleep(void)
{
    800036be:	7139                	addi	sp,sp,-64
    800036c0:	fc06                	sd	ra,56(sp)
    800036c2:	f822                	sd	s0,48(sp)
    800036c4:	f426                	sd	s1,40(sp)
    800036c6:	f04a                	sd	s2,32(sp)
    800036c8:	ec4e                	sd	s3,24(sp)
    800036ca:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800036cc:	fcc40593          	addi	a1,s0,-52
    800036d0:	4501                	li	a0,0
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	e2c080e7          	jalr	-468(ra) # 800034fe <argint>
    return -1;
    800036da:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800036dc:	06054563          	bltz	a0,80003746 <sys_sleep+0x88>
  acquire(&tickslock);
    800036e0:	0001d517          	auipc	a0,0x1d
    800036e4:	df050513          	addi	a0,a0,-528 # 800204d0 <tickslock>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	4da080e7          	jalr	1242(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800036f0:	00007917          	auipc	s2,0x7
    800036f4:	94092903          	lw	s2,-1728(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    800036f8:	fcc42783          	lw	a5,-52(s0)
    800036fc:	cf85                	beqz	a5,80003734 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800036fe:	0001d997          	auipc	s3,0x1d
    80003702:	dd298993          	addi	s3,s3,-558 # 800204d0 <tickslock>
    80003706:	00007497          	auipc	s1,0x7
    8000370a:	92a48493          	addi	s1,s1,-1750 # 8000a030 <ticks>
    if(myproc()->killed){
    8000370e:	ffffe097          	auipc	ra,0xffffe
    80003712:	308080e7          	jalr	776(ra) # 80001a16 <myproc>
    80003716:	551c                	lw	a5,40(a0)
    80003718:	ef9d                	bnez	a5,80003756 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000371a:	85ce                	mv	a1,s3
    8000371c:	8526                	mv	a0,s1
    8000371e:	fffff097          	auipc	ra,0xfffff
    80003722:	91a080e7          	jalr	-1766(ra) # 80002038 <sleep>
  while(ticks - ticks0 < n){
    80003726:	409c                	lw	a5,0(s1)
    80003728:	412787bb          	subw	a5,a5,s2
    8000372c:	fcc42703          	lw	a4,-52(s0)
    80003730:	fce7efe3          	bltu	a5,a4,8000370e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003734:	0001d517          	auipc	a0,0x1d
    80003738:	d9c50513          	addi	a0,a0,-612 # 800204d0 <tickslock>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	54c080e7          	jalr	1356(ra) # 80000c88 <release>
  return 0;
    80003744:	4781                	li	a5,0
}
    80003746:	853e                	mv	a0,a5
    80003748:	70e2                	ld	ra,56(sp)
    8000374a:	7442                	ld	s0,48(sp)
    8000374c:	74a2                	ld	s1,40(sp)
    8000374e:	7902                	ld	s2,32(sp)
    80003750:	69e2                	ld	s3,24(sp)
    80003752:	6121                	addi	sp,sp,64
    80003754:	8082                	ret
      release(&tickslock);
    80003756:	0001d517          	auipc	a0,0x1d
    8000375a:	d7a50513          	addi	a0,a0,-646 # 800204d0 <tickslock>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	52a080e7          	jalr	1322(ra) # 80000c88 <release>
      return -1;
    80003766:	57fd                	li	a5,-1
    80003768:	bff9                	j	80003746 <sys_sleep+0x88>

000000008000376a <sys_kill>:

uint64
sys_kill(void)
{
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003772:	fec40593          	addi	a1,s0,-20
    80003776:	4501                	li	a0,0
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	d86080e7          	jalr	-634(ra) # 800034fe <argint>
    80003780:	87aa                	mv	a5,a0
    return -1;
    80003782:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003784:	0007c863          	bltz	a5,80003794 <sys_kill+0x2a>
  return kill(pid);
    80003788:	fec42503          	lw	a0,-20(s0)
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	b08080e7          	jalr	-1272(ra) # 80002294 <kill>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	6105                	addi	sp,sp,32
    8000379a:	8082                	ret

000000008000379c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	e426                	sd	s1,8(sp)
    800037a4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800037a6:	0001d517          	auipc	a0,0x1d
    800037aa:	d2a50513          	addi	a0,a0,-726 # 800204d0 <tickslock>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	414080e7          	jalr	1044(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800037b6:	00007497          	auipc	s1,0x7
    800037ba:	87a4a483          	lw	s1,-1926(s1) # 8000a030 <ticks>
  release(&tickslock);
    800037be:	0001d517          	auipc	a0,0x1d
    800037c2:	d1250513          	addi	a0,a0,-750 # 800204d0 <tickslock>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	4c2080e7          	jalr	1218(ra) # 80000c88 <release>
  return xticks;
}
    800037ce:	02049513          	slli	a0,s1,0x20
    800037d2:	9101                	srli	a0,a0,0x20
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret

00000000800037de <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037de:	7179                	addi	sp,sp,-48
    800037e0:	f406                	sd	ra,40(sp)
    800037e2:	f022                	sd	s0,32(sp)
    800037e4:	ec26                	sd	s1,24(sp)
    800037e6:	e84a                	sd	s2,16(sp)
    800037e8:	e44e                	sd	s3,8(sp)
    800037ea:	e052                	sd	s4,0(sp)
    800037ec:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037ee:	00006597          	auipc	a1,0x6
    800037f2:	14a58593          	addi	a1,a1,330 # 80009938 <syscalls+0xb0>
    800037f6:	0001d517          	auipc	a0,0x1d
    800037fa:	cf250513          	addi	a0,a0,-782 # 800204e8 <bcache>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	334080e7          	jalr	820(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003806:	00025797          	auipc	a5,0x25
    8000380a:	ce278793          	addi	a5,a5,-798 # 800284e8 <bcache+0x8000>
    8000380e:	00025717          	auipc	a4,0x25
    80003812:	f4270713          	addi	a4,a4,-190 # 80028750 <bcache+0x8268>
    80003816:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000381a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000381e:	0001d497          	auipc	s1,0x1d
    80003822:	ce248493          	addi	s1,s1,-798 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    80003826:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003828:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000382a:	00006a17          	auipc	s4,0x6
    8000382e:	116a0a13          	addi	s4,s4,278 # 80009940 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003832:	2b893783          	ld	a5,696(s2)
    80003836:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003838:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000383c:	85d2                	mv	a1,s4
    8000383e:	01048513          	addi	a0,s1,16
    80003842:	00001097          	auipc	ra,0x1
    80003846:	7d4080e7          	jalr	2004(ra) # 80005016 <initsleeplock>
    bcache.head.next->prev = b;
    8000384a:	2b893783          	ld	a5,696(s2)
    8000384e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003850:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003854:	45848493          	addi	s1,s1,1112
    80003858:	fd349de3          	bne	s1,s3,80003832 <binit+0x54>
  }
}
    8000385c:	70a2                	ld	ra,40(sp)
    8000385e:	7402                	ld	s0,32(sp)
    80003860:	64e2                	ld	s1,24(sp)
    80003862:	6942                	ld	s2,16(sp)
    80003864:	69a2                	ld	s3,8(sp)
    80003866:	6a02                	ld	s4,0(sp)
    80003868:	6145                	addi	sp,sp,48
    8000386a:	8082                	ret

000000008000386c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000386c:	7179                	addi	sp,sp,-48
    8000386e:	f406                	sd	ra,40(sp)
    80003870:	f022                	sd	s0,32(sp)
    80003872:	ec26                	sd	s1,24(sp)
    80003874:	e84a                	sd	s2,16(sp)
    80003876:	e44e                	sd	s3,8(sp)
    80003878:	1800                	addi	s0,sp,48
    8000387a:	892a                	mv	s2,a0
    8000387c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000387e:	0001d517          	auipc	a0,0x1d
    80003882:	c6a50513          	addi	a0,a0,-918 # 800204e8 <bcache>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	33c080e7          	jalr	828(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000388e:	00025497          	auipc	s1,0x25
    80003892:	f124b483          	ld	s1,-238(s1) # 800287a0 <bcache+0x82b8>
    80003896:	00025797          	auipc	a5,0x25
    8000389a:	eba78793          	addi	a5,a5,-326 # 80028750 <bcache+0x8268>
    8000389e:	02f48f63          	beq	s1,a5,800038dc <bread+0x70>
    800038a2:	873e                	mv	a4,a5
    800038a4:	a021                	j	800038ac <bread+0x40>
    800038a6:	68a4                	ld	s1,80(s1)
    800038a8:	02e48a63          	beq	s1,a4,800038dc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800038ac:	449c                	lw	a5,8(s1)
    800038ae:	ff279ce3          	bne	a5,s2,800038a6 <bread+0x3a>
    800038b2:	44dc                	lw	a5,12(s1)
    800038b4:	ff3799e3          	bne	a5,s3,800038a6 <bread+0x3a>
      b->refcnt++;
    800038b8:	40bc                	lw	a5,64(s1)
    800038ba:	2785                	addiw	a5,a5,1
    800038bc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038be:	0001d517          	auipc	a0,0x1d
    800038c2:	c2a50513          	addi	a0,a0,-982 # 800204e8 <bcache>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	3c2080e7          	jalr	962(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    800038ce:	01048513          	addi	a0,s1,16
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	77e080e7          	jalr	1918(ra) # 80005050 <acquiresleep>
      return b;
    800038da:	a8b9                	j	80003938 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038dc:	00025497          	auipc	s1,0x25
    800038e0:	ebc4b483          	ld	s1,-324(s1) # 80028798 <bcache+0x82b0>
    800038e4:	00025797          	auipc	a5,0x25
    800038e8:	e6c78793          	addi	a5,a5,-404 # 80028750 <bcache+0x8268>
    800038ec:	00f48863          	beq	s1,a5,800038fc <bread+0x90>
    800038f0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038f2:	40bc                	lw	a5,64(s1)
    800038f4:	cf81                	beqz	a5,8000390c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038f6:	64a4                	ld	s1,72(s1)
    800038f8:	fee49de3          	bne	s1,a4,800038f2 <bread+0x86>
  panic("bget: no buffers");
    800038fc:	00006517          	auipc	a0,0x6
    80003900:	04c50513          	addi	a0,a0,76 # 80009948 <syscalls+0xc0>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	c26080e7          	jalr	-986(ra) # 8000052a <panic>
      b->dev = dev;
    8000390c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003910:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003914:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003918:	4785                	li	a5,1
    8000391a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000391c:	0001d517          	auipc	a0,0x1d
    80003920:	bcc50513          	addi	a0,a0,-1076 # 800204e8 <bcache>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	364080e7          	jalr	868(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    8000392c:	01048513          	addi	a0,s1,16
    80003930:	00001097          	auipc	ra,0x1
    80003934:	720080e7          	jalr	1824(ra) # 80005050 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003938:	409c                	lw	a5,0(s1)
    8000393a:	cb89                	beqz	a5,8000394c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000393c:	8526                	mv	a0,s1
    8000393e:	70a2                	ld	ra,40(sp)
    80003940:	7402                	ld	s0,32(sp)
    80003942:	64e2                	ld	s1,24(sp)
    80003944:	6942                	ld	s2,16(sp)
    80003946:	69a2                	ld	s3,8(sp)
    80003948:	6145                	addi	sp,sp,48
    8000394a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000394c:	4581                	li	a1,0
    8000394e:	8526                	mv	a0,s1
    80003950:	00003097          	auipc	ra,0x3
    80003954:	516080e7          	jalr	1302(ra) # 80006e66 <virtio_disk_rw>
    b->valid = 1;
    80003958:	4785                	li	a5,1
    8000395a:	c09c                	sw	a5,0(s1)
  return b;
    8000395c:	b7c5                	j	8000393c <bread+0xd0>

000000008000395e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000395e:	1101                	addi	sp,sp,-32
    80003960:	ec06                	sd	ra,24(sp)
    80003962:	e822                	sd	s0,16(sp)
    80003964:	e426                	sd	s1,8(sp)
    80003966:	1000                	addi	s0,sp,32
    80003968:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000396a:	0541                	addi	a0,a0,16
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	77e080e7          	jalr	1918(ra) # 800050ea <holdingsleep>
    80003974:	cd01                	beqz	a0,8000398c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003976:	4585                	li	a1,1
    80003978:	8526                	mv	a0,s1
    8000397a:	00003097          	auipc	ra,0x3
    8000397e:	4ec080e7          	jalr	1260(ra) # 80006e66 <virtio_disk_rw>
}
    80003982:	60e2                	ld	ra,24(sp)
    80003984:	6442                	ld	s0,16(sp)
    80003986:	64a2                	ld	s1,8(sp)
    80003988:	6105                	addi	sp,sp,32
    8000398a:	8082                	ret
    panic("bwrite");
    8000398c:	00006517          	auipc	a0,0x6
    80003990:	fd450513          	addi	a0,a0,-44 # 80009960 <syscalls+0xd8>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	b96080e7          	jalr	-1130(ra) # 8000052a <panic>

000000008000399c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	e04a                	sd	s2,0(sp)
    800039a6:	1000                	addi	s0,sp,32
    800039a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039aa:	01050913          	addi	s2,a0,16
    800039ae:	854a                	mv	a0,s2
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	73a080e7          	jalr	1850(ra) # 800050ea <holdingsleep>
    800039b8:	c92d                	beqz	a0,80003a2a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	6ea080e7          	jalr	1770(ra) # 800050a6 <releasesleep>

  acquire(&bcache.lock);
    800039c4:	0001d517          	auipc	a0,0x1d
    800039c8:	b2450513          	addi	a0,a0,-1244 # 800204e8 <bcache>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	1f6080e7          	jalr	502(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800039d4:	40bc                	lw	a5,64(s1)
    800039d6:	37fd                	addiw	a5,a5,-1
    800039d8:	0007871b          	sext.w	a4,a5
    800039dc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039de:	eb05                	bnez	a4,80003a0e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039e0:	68bc                	ld	a5,80(s1)
    800039e2:	64b8                	ld	a4,72(s1)
    800039e4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039e6:	64bc                	ld	a5,72(s1)
    800039e8:	68b8                	ld	a4,80(s1)
    800039ea:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039ec:	00025797          	auipc	a5,0x25
    800039f0:	afc78793          	addi	a5,a5,-1284 # 800284e8 <bcache+0x8000>
    800039f4:	2b87b703          	ld	a4,696(a5)
    800039f8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039fa:	00025717          	auipc	a4,0x25
    800039fe:	d5670713          	addi	a4,a4,-682 # 80028750 <bcache+0x8268>
    80003a02:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a04:	2b87b703          	ld	a4,696(a5)
    80003a08:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a0a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a0e:	0001d517          	auipc	a0,0x1d
    80003a12:	ada50513          	addi	a0,a0,-1318 # 800204e8 <bcache>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	272080e7          	jalr	626(ra) # 80000c88 <release>
}
    80003a1e:	60e2                	ld	ra,24(sp)
    80003a20:	6442                	ld	s0,16(sp)
    80003a22:	64a2                	ld	s1,8(sp)
    80003a24:	6902                	ld	s2,0(sp)
    80003a26:	6105                	addi	sp,sp,32
    80003a28:	8082                	ret
    panic("brelse");
    80003a2a:	00006517          	auipc	a0,0x6
    80003a2e:	f3e50513          	addi	a0,a0,-194 # 80009968 <syscalls+0xe0>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	af8080e7          	jalr	-1288(ra) # 8000052a <panic>

0000000080003a3a <bpin>:

void
bpin(struct buf *b) {
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	1000                	addi	s0,sp,32
    80003a44:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a46:	0001d517          	auipc	a0,0x1d
    80003a4a:	aa250513          	addi	a0,a0,-1374 # 800204e8 <bcache>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	174080e7          	jalr	372(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003a56:	40bc                	lw	a5,64(s1)
    80003a58:	2785                	addiw	a5,a5,1
    80003a5a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a5c:	0001d517          	auipc	a0,0x1d
    80003a60:	a8c50513          	addi	a0,a0,-1396 # 800204e8 <bcache>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	224080e7          	jalr	548(ra) # 80000c88 <release>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret

0000000080003a76 <bunpin>:

void
bunpin(struct buf *b) {
    80003a76:	1101                	addi	sp,sp,-32
    80003a78:	ec06                	sd	ra,24(sp)
    80003a7a:	e822                	sd	s0,16(sp)
    80003a7c:	e426                	sd	s1,8(sp)
    80003a7e:	1000                	addi	s0,sp,32
    80003a80:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a82:	0001d517          	auipc	a0,0x1d
    80003a86:	a6650513          	addi	a0,a0,-1434 # 800204e8 <bcache>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	138080e7          	jalr	312(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003a92:	40bc                	lw	a5,64(s1)
    80003a94:	37fd                	addiw	a5,a5,-1
    80003a96:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a98:	0001d517          	auipc	a0,0x1d
    80003a9c:	a5050513          	addi	a0,a0,-1456 # 800204e8 <bcache>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	1e8080e7          	jalr	488(ra) # 80000c88 <release>
}
    80003aa8:	60e2                	ld	ra,24(sp)
    80003aaa:	6442                	ld	s0,16(sp)
    80003aac:	64a2                	ld	s1,8(sp)
    80003aae:	6105                	addi	sp,sp,32
    80003ab0:	8082                	ret

0000000080003ab2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ab2:	1101                	addi	sp,sp,-32
    80003ab4:	ec06                	sd	ra,24(sp)
    80003ab6:	e822                	sd	s0,16(sp)
    80003ab8:	e426                	sd	s1,8(sp)
    80003aba:	e04a                	sd	s2,0(sp)
    80003abc:	1000                	addi	s0,sp,32
    80003abe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003ac0:	00d5d59b          	srliw	a1,a1,0xd
    80003ac4:	00025797          	auipc	a5,0x25
    80003ac8:	1007a783          	lw	a5,256(a5) # 80028bc4 <sb+0x1c>
    80003acc:	9dbd                	addw	a1,a1,a5
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	d9e080e7          	jalr	-610(ra) # 8000386c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003ad6:	0074f713          	andi	a4,s1,7
    80003ada:	4785                	li	a5,1
    80003adc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003ae0:	14ce                	slli	s1,s1,0x33
    80003ae2:	90d9                	srli	s1,s1,0x36
    80003ae4:	00950733          	add	a4,a0,s1
    80003ae8:	05874703          	lbu	a4,88(a4)
    80003aec:	00e7f6b3          	and	a3,a5,a4
    80003af0:	c69d                	beqz	a3,80003b1e <bfree+0x6c>
    80003af2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003af4:	94aa                	add	s1,s1,a0
    80003af6:	fff7c793          	not	a5,a5
    80003afa:	8ff9                	and	a5,a5,a4
    80003afc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	430080e7          	jalr	1072(ra) # 80004f30 <log_write>
  brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	e92080e7          	jalr	-366(ra) # 8000399c <brelse>
}
    80003b12:	60e2                	ld	ra,24(sp)
    80003b14:	6442                	ld	s0,16(sp)
    80003b16:	64a2                	ld	s1,8(sp)
    80003b18:	6902                	ld	s2,0(sp)
    80003b1a:	6105                	addi	sp,sp,32
    80003b1c:	8082                	ret
    panic("freeing free block");
    80003b1e:	00006517          	auipc	a0,0x6
    80003b22:	e5250513          	addi	a0,a0,-430 # 80009970 <syscalls+0xe8>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a04080e7          	jalr	-1532(ra) # 8000052a <panic>

0000000080003b2e <balloc>:
{
    80003b2e:	711d                	addi	sp,sp,-96
    80003b30:	ec86                	sd	ra,88(sp)
    80003b32:	e8a2                	sd	s0,80(sp)
    80003b34:	e4a6                	sd	s1,72(sp)
    80003b36:	e0ca                	sd	s2,64(sp)
    80003b38:	fc4e                	sd	s3,56(sp)
    80003b3a:	f852                	sd	s4,48(sp)
    80003b3c:	f456                	sd	s5,40(sp)
    80003b3e:	f05a                	sd	s6,32(sp)
    80003b40:	ec5e                	sd	s7,24(sp)
    80003b42:	e862                	sd	s8,16(sp)
    80003b44:	e466                	sd	s9,8(sp)
    80003b46:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b48:	00025797          	auipc	a5,0x25
    80003b4c:	0647a783          	lw	a5,100(a5) # 80028bac <sb+0x4>
    80003b50:	cbd1                	beqz	a5,80003be4 <balloc+0xb6>
    80003b52:	8baa                	mv	s7,a0
    80003b54:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b56:	00025b17          	auipc	s6,0x25
    80003b5a:	052b0b13          	addi	s6,s6,82 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b5e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b60:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b62:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b64:	6c89                	lui	s9,0x2
    80003b66:	a831                	j	80003b82 <balloc+0x54>
    brelse(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	e32080e7          	jalr	-462(ra) # 8000399c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b72:	015c87bb          	addw	a5,s9,s5
    80003b76:	00078a9b          	sext.w	s5,a5
    80003b7a:	004b2703          	lw	a4,4(s6)
    80003b7e:	06eaf363          	bgeu	s5,a4,80003be4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003b82:	41fad79b          	sraiw	a5,s5,0x1f
    80003b86:	0137d79b          	srliw	a5,a5,0x13
    80003b8a:	015787bb          	addw	a5,a5,s5
    80003b8e:	40d7d79b          	sraiw	a5,a5,0xd
    80003b92:	01cb2583          	lw	a1,28(s6)
    80003b96:	9dbd                	addw	a1,a1,a5
    80003b98:	855e                	mv	a0,s7
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	cd2080e7          	jalr	-814(ra) # 8000386c <bread>
    80003ba2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ba4:	004b2503          	lw	a0,4(s6)
    80003ba8:	000a849b          	sext.w	s1,s5
    80003bac:	8662                	mv	a2,s8
    80003bae:	faa4fde3          	bgeu	s1,a0,80003b68 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003bb2:	41f6579b          	sraiw	a5,a2,0x1f
    80003bb6:	01d7d69b          	srliw	a3,a5,0x1d
    80003bba:	00c6873b          	addw	a4,a3,a2
    80003bbe:	00777793          	andi	a5,a4,7
    80003bc2:	9f95                	subw	a5,a5,a3
    80003bc4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bc8:	4037571b          	sraiw	a4,a4,0x3
    80003bcc:	00e906b3          	add	a3,s2,a4
    80003bd0:	0586c683          	lbu	a3,88(a3)
    80003bd4:	00d7f5b3          	and	a1,a5,a3
    80003bd8:	cd91                	beqz	a1,80003bf4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bda:	2605                	addiw	a2,a2,1
    80003bdc:	2485                	addiw	s1,s1,1
    80003bde:	fd4618e3          	bne	a2,s4,80003bae <balloc+0x80>
    80003be2:	b759                	j	80003b68 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003be4:	00006517          	auipc	a0,0x6
    80003be8:	da450513          	addi	a0,a0,-604 # 80009988 <syscalls+0x100>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	93e080e7          	jalr	-1730(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bf4:	974a                	add	a4,a4,s2
    80003bf6:	8fd5                	or	a5,a5,a3
    80003bf8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	332080e7          	jalr	818(ra) # 80004f30 <log_write>
        brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	d94080e7          	jalr	-620(ra) # 8000399c <brelse>
  bp = bread(dev, bno);
    80003c10:	85a6                	mv	a1,s1
    80003c12:	855e                	mv	a0,s7
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	c58080e7          	jalr	-936(ra) # 8000386c <bread>
    80003c1c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c1e:	40000613          	li	a2,1024
    80003c22:	4581                	li	a1,0
    80003c24:	05850513          	addi	a0,a0,88
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	0a8080e7          	jalr	168(ra) # 80000cd0 <memset>
  log_write(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	2fe080e7          	jalr	766(ra) # 80004f30 <log_write>
  brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	d60080e7          	jalr	-672(ra) # 8000399c <brelse>
}
    80003c44:	8526                	mv	a0,s1
    80003c46:	60e6                	ld	ra,88(sp)
    80003c48:	6446                	ld	s0,80(sp)
    80003c4a:	64a6                	ld	s1,72(sp)
    80003c4c:	6906                	ld	s2,64(sp)
    80003c4e:	79e2                	ld	s3,56(sp)
    80003c50:	7a42                	ld	s4,48(sp)
    80003c52:	7aa2                	ld	s5,40(sp)
    80003c54:	7b02                	ld	s6,32(sp)
    80003c56:	6be2                	ld	s7,24(sp)
    80003c58:	6c42                	ld	s8,16(sp)
    80003c5a:	6ca2                	ld	s9,8(sp)
    80003c5c:	6125                	addi	sp,sp,96
    80003c5e:	8082                	ret

0000000080003c60 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c60:	7179                	addi	sp,sp,-48
    80003c62:	f406                	sd	ra,40(sp)
    80003c64:	f022                	sd	s0,32(sp)
    80003c66:	ec26                	sd	s1,24(sp)
    80003c68:	e84a                	sd	s2,16(sp)
    80003c6a:	e44e                	sd	s3,8(sp)
    80003c6c:	e052                	sd	s4,0(sp)
    80003c6e:	1800                	addi	s0,sp,48
    80003c70:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c72:	47ad                	li	a5,11
    80003c74:	04b7fe63          	bgeu	a5,a1,80003cd0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003c78:	ff45849b          	addiw	s1,a1,-12
    80003c7c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c80:	0ff00793          	li	a5,255
    80003c84:	0ae7e463          	bltu	a5,a4,80003d2c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003c88:	08052583          	lw	a1,128(a0)
    80003c8c:	c5b5                	beqz	a1,80003cf8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003c8e:	00092503          	lw	a0,0(s2)
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	bda080e7          	jalr	-1062(ra) # 8000386c <bread>
    80003c9a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c9c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ca0:	02049713          	slli	a4,s1,0x20
    80003ca4:	01e75593          	srli	a1,a4,0x1e
    80003ca8:	00b784b3          	add	s1,a5,a1
    80003cac:	0004a983          	lw	s3,0(s1)
    80003cb0:	04098e63          	beqz	s3,80003d0c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003cb4:	8552                	mv	a0,s4
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	ce6080e7          	jalr	-794(ra) # 8000399c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	70a2                	ld	ra,40(sp)
    80003cc2:	7402                	ld	s0,32(sp)
    80003cc4:	64e2                	ld	s1,24(sp)
    80003cc6:	6942                	ld	s2,16(sp)
    80003cc8:	69a2                	ld	s3,8(sp)
    80003cca:	6a02                	ld	s4,0(sp)
    80003ccc:	6145                	addi	sp,sp,48
    80003cce:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003cd0:	02059793          	slli	a5,a1,0x20
    80003cd4:	01e7d593          	srli	a1,a5,0x1e
    80003cd8:	00b504b3          	add	s1,a0,a1
    80003cdc:	0504a983          	lw	s3,80(s1)
    80003ce0:	fc099fe3          	bnez	s3,80003cbe <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ce4:	4108                	lw	a0,0(a0)
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	e48080e7          	jalr	-440(ra) # 80003b2e <balloc>
    80003cee:	0005099b          	sext.w	s3,a0
    80003cf2:	0534a823          	sw	s3,80(s1)
    80003cf6:	b7e1                	j	80003cbe <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003cf8:	4108                	lw	a0,0(a0)
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	e34080e7          	jalr	-460(ra) # 80003b2e <balloc>
    80003d02:	0005059b          	sext.w	a1,a0
    80003d06:	08b92023          	sw	a1,128(s2)
    80003d0a:	b751                	j	80003c8e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003d0c:	00092503          	lw	a0,0(s2)
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	e1e080e7          	jalr	-482(ra) # 80003b2e <balloc>
    80003d18:	0005099b          	sext.w	s3,a0
    80003d1c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003d20:	8552                	mv	a0,s4
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	20e080e7          	jalr	526(ra) # 80004f30 <log_write>
    80003d2a:	b769                	j	80003cb4 <bmap+0x54>
  panic("bmap: out of range");
    80003d2c:	00006517          	auipc	a0,0x6
    80003d30:	c7450513          	addi	a0,a0,-908 # 800099a0 <syscalls+0x118>
    80003d34:	ffffc097          	auipc	ra,0xffffc
    80003d38:	7f6080e7          	jalr	2038(ra) # 8000052a <panic>

0000000080003d3c <iget>:
{
    80003d3c:	7179                	addi	sp,sp,-48
    80003d3e:	f406                	sd	ra,40(sp)
    80003d40:	f022                	sd	s0,32(sp)
    80003d42:	ec26                	sd	s1,24(sp)
    80003d44:	e84a                	sd	s2,16(sp)
    80003d46:	e44e                	sd	s3,8(sp)
    80003d48:	e052                	sd	s4,0(sp)
    80003d4a:	1800                	addi	s0,sp,48
    80003d4c:	89aa                	mv	s3,a0
    80003d4e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d50:	00025517          	auipc	a0,0x25
    80003d54:	e7850513          	addi	a0,a0,-392 # 80028bc8 <itable>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	e6a080e7          	jalr	-406(ra) # 80000bc2 <acquire>
  empty = 0;
    80003d60:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d62:	00025497          	auipc	s1,0x25
    80003d66:	e7e48493          	addi	s1,s1,-386 # 80028be0 <itable+0x18>
    80003d6a:	00027697          	auipc	a3,0x27
    80003d6e:	90668693          	addi	a3,a3,-1786 # 8002a670 <log>
    80003d72:	a039                	j	80003d80 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d74:	02090b63          	beqz	s2,80003daa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d78:	08848493          	addi	s1,s1,136
    80003d7c:	02d48a63          	beq	s1,a3,80003db0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d80:	449c                	lw	a5,8(s1)
    80003d82:	fef059e3          	blez	a5,80003d74 <iget+0x38>
    80003d86:	4098                	lw	a4,0(s1)
    80003d88:	ff3716e3          	bne	a4,s3,80003d74 <iget+0x38>
    80003d8c:	40d8                	lw	a4,4(s1)
    80003d8e:	ff4713e3          	bne	a4,s4,80003d74 <iget+0x38>
      ip->ref++;
    80003d92:	2785                	addiw	a5,a5,1
    80003d94:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d96:	00025517          	auipc	a0,0x25
    80003d9a:	e3250513          	addi	a0,a0,-462 # 80028bc8 <itable>
    80003d9e:	ffffd097          	auipc	ra,0xffffd
    80003da2:	eea080e7          	jalr	-278(ra) # 80000c88 <release>
      return ip;
    80003da6:	8926                	mv	s2,s1
    80003da8:	a03d                	j	80003dd6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003daa:	f7f9                	bnez	a5,80003d78 <iget+0x3c>
    80003dac:	8926                	mv	s2,s1
    80003dae:	b7e9                	j	80003d78 <iget+0x3c>
  if(empty == 0)
    80003db0:	02090c63          	beqz	s2,80003de8 <iget+0xac>
  ip->dev = dev;
    80003db4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003db8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003dbc:	4785                	li	a5,1
    80003dbe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003dc2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003dc6:	00025517          	auipc	a0,0x25
    80003dca:	e0250513          	addi	a0,a0,-510 # 80028bc8 <itable>
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	eba080e7          	jalr	-326(ra) # 80000c88 <release>
}
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	70a2                	ld	ra,40(sp)
    80003dda:	7402                	ld	s0,32(sp)
    80003ddc:	64e2                	ld	s1,24(sp)
    80003dde:	6942                	ld	s2,16(sp)
    80003de0:	69a2                	ld	s3,8(sp)
    80003de2:	6a02                	ld	s4,0(sp)
    80003de4:	6145                	addi	sp,sp,48
    80003de6:	8082                	ret
    panic("iget: no inodes");
    80003de8:	00006517          	auipc	a0,0x6
    80003dec:	bd050513          	addi	a0,a0,-1072 # 800099b8 <syscalls+0x130>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	73a080e7          	jalr	1850(ra) # 8000052a <panic>

0000000080003df8 <fsinit>:
fsinit(int dev) {
    80003df8:	7179                	addi	sp,sp,-48
    80003dfa:	f406                	sd	ra,40(sp)
    80003dfc:	f022                	sd	s0,32(sp)
    80003dfe:	ec26                	sd	s1,24(sp)
    80003e00:	e84a                	sd	s2,16(sp)
    80003e02:	e44e                	sd	s3,8(sp)
    80003e04:	1800                	addi	s0,sp,48
    80003e06:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e08:	4585                	li	a1,1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	a62080e7          	jalr	-1438(ra) # 8000386c <bread>
    80003e12:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e14:	00025997          	auipc	s3,0x25
    80003e18:	d9498993          	addi	s3,s3,-620 # 80028ba8 <sb>
    80003e1c:	02000613          	li	a2,32
    80003e20:	05850593          	addi	a1,a0,88
    80003e24:	854e                	mv	a0,s3
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	f06080e7          	jalr	-250(ra) # 80000d2c <memmove>
  brelse(bp);
    80003e2e:	8526                	mv	a0,s1
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	b6c080e7          	jalr	-1172(ra) # 8000399c <brelse>
  if(sb.magic != FSMAGIC)
    80003e38:	0009a703          	lw	a4,0(s3)
    80003e3c:	102037b7          	lui	a5,0x10203
    80003e40:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e44:	02f71263          	bne	a4,a5,80003e68 <fsinit+0x70>
  initlog(dev, &sb);
    80003e48:	00025597          	auipc	a1,0x25
    80003e4c:	d6058593          	addi	a1,a1,-672 # 80028ba8 <sb>
    80003e50:	854a                	mv	a0,s2
    80003e52:	00001097          	auipc	ra,0x1
    80003e56:	e60080e7          	jalr	-416(ra) # 80004cb2 <initlog>
}
    80003e5a:	70a2                	ld	ra,40(sp)
    80003e5c:	7402                	ld	s0,32(sp)
    80003e5e:	64e2                	ld	s1,24(sp)
    80003e60:	6942                	ld	s2,16(sp)
    80003e62:	69a2                	ld	s3,8(sp)
    80003e64:	6145                	addi	sp,sp,48
    80003e66:	8082                	ret
    panic("invalid file system");
    80003e68:	00006517          	auipc	a0,0x6
    80003e6c:	b6050513          	addi	a0,a0,-1184 # 800099c8 <syscalls+0x140>
    80003e70:	ffffc097          	auipc	ra,0xffffc
    80003e74:	6ba080e7          	jalr	1722(ra) # 8000052a <panic>

0000000080003e78 <iinit>:
{
    80003e78:	7179                	addi	sp,sp,-48
    80003e7a:	f406                	sd	ra,40(sp)
    80003e7c:	f022                	sd	s0,32(sp)
    80003e7e:	ec26                	sd	s1,24(sp)
    80003e80:	e84a                	sd	s2,16(sp)
    80003e82:	e44e                	sd	s3,8(sp)
    80003e84:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e86:	00006597          	auipc	a1,0x6
    80003e8a:	b5a58593          	addi	a1,a1,-1190 # 800099e0 <syscalls+0x158>
    80003e8e:	00025517          	auipc	a0,0x25
    80003e92:	d3a50513          	addi	a0,a0,-710 # 80028bc8 <itable>
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	c9c080e7          	jalr	-868(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e9e:	00025497          	auipc	s1,0x25
    80003ea2:	d5248493          	addi	s1,s1,-686 # 80028bf0 <itable+0x28>
    80003ea6:	00026997          	auipc	s3,0x26
    80003eaa:	7da98993          	addi	s3,s3,2010 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003eae:	00006917          	auipc	s2,0x6
    80003eb2:	b3a90913          	addi	s2,s2,-1222 # 800099e8 <syscalls+0x160>
    80003eb6:	85ca                	mv	a1,s2
    80003eb8:	8526                	mv	a0,s1
    80003eba:	00001097          	auipc	ra,0x1
    80003ebe:	15c080e7          	jalr	348(ra) # 80005016 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ec2:	08848493          	addi	s1,s1,136
    80003ec6:	ff3498e3          	bne	s1,s3,80003eb6 <iinit+0x3e>
}
    80003eca:	70a2                	ld	ra,40(sp)
    80003ecc:	7402                	ld	s0,32(sp)
    80003ece:	64e2                	ld	s1,24(sp)
    80003ed0:	6942                	ld	s2,16(sp)
    80003ed2:	69a2                	ld	s3,8(sp)
    80003ed4:	6145                	addi	sp,sp,48
    80003ed6:	8082                	ret

0000000080003ed8 <ialloc>:
{
    80003ed8:	715d                	addi	sp,sp,-80
    80003eda:	e486                	sd	ra,72(sp)
    80003edc:	e0a2                	sd	s0,64(sp)
    80003ede:	fc26                	sd	s1,56(sp)
    80003ee0:	f84a                	sd	s2,48(sp)
    80003ee2:	f44e                	sd	s3,40(sp)
    80003ee4:	f052                	sd	s4,32(sp)
    80003ee6:	ec56                	sd	s5,24(sp)
    80003ee8:	e85a                	sd	s6,16(sp)
    80003eea:	e45e                	sd	s7,8(sp)
    80003eec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003eee:	00025717          	auipc	a4,0x25
    80003ef2:	cc672703          	lw	a4,-826(a4) # 80028bb4 <sb+0xc>
    80003ef6:	4785                	li	a5,1
    80003ef8:	04e7fa63          	bgeu	a5,a4,80003f4c <ialloc+0x74>
    80003efc:	8aaa                	mv	s5,a0
    80003efe:	8bae                	mv	s7,a1
    80003f00:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f02:	00025a17          	auipc	s4,0x25
    80003f06:	ca6a0a13          	addi	s4,s4,-858 # 80028ba8 <sb>
    80003f0a:	00048b1b          	sext.w	s6,s1
    80003f0e:	0044d793          	srli	a5,s1,0x4
    80003f12:	018a2583          	lw	a1,24(s4)
    80003f16:	9dbd                	addw	a1,a1,a5
    80003f18:	8556                	mv	a0,s5
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	952080e7          	jalr	-1710(ra) # 8000386c <bread>
    80003f22:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f24:	05850993          	addi	s3,a0,88
    80003f28:	00f4f793          	andi	a5,s1,15
    80003f2c:	079a                	slli	a5,a5,0x6
    80003f2e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f30:	00099783          	lh	a5,0(s3)
    80003f34:	c785                	beqz	a5,80003f5c <ialloc+0x84>
    brelse(bp);
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	a66080e7          	jalr	-1434(ra) # 8000399c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f3e:	0485                	addi	s1,s1,1
    80003f40:	00ca2703          	lw	a4,12(s4)
    80003f44:	0004879b          	sext.w	a5,s1
    80003f48:	fce7e1e3          	bltu	a5,a4,80003f0a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f4c:	00006517          	auipc	a0,0x6
    80003f50:	aa450513          	addi	a0,a0,-1372 # 800099f0 <syscalls+0x168>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5d6080e7          	jalr	1494(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003f5c:	04000613          	li	a2,64
    80003f60:	4581                	li	a1,0
    80003f62:	854e                	mv	a0,s3
    80003f64:	ffffd097          	auipc	ra,0xffffd
    80003f68:	d6c080e7          	jalr	-660(ra) # 80000cd0 <memset>
      dip->type = type;
    80003f6c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f70:	854a                	mv	a0,s2
    80003f72:	00001097          	auipc	ra,0x1
    80003f76:	fbe080e7          	jalr	-66(ra) # 80004f30 <log_write>
      brelse(bp);
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	a20080e7          	jalr	-1504(ra) # 8000399c <brelse>
      return iget(dev, inum);
    80003f84:	85da                	mv	a1,s6
    80003f86:	8556                	mv	a0,s5
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	db4080e7          	jalr	-588(ra) # 80003d3c <iget>
}
    80003f90:	60a6                	ld	ra,72(sp)
    80003f92:	6406                	ld	s0,64(sp)
    80003f94:	74e2                	ld	s1,56(sp)
    80003f96:	7942                	ld	s2,48(sp)
    80003f98:	79a2                	ld	s3,40(sp)
    80003f9a:	7a02                	ld	s4,32(sp)
    80003f9c:	6ae2                	ld	s5,24(sp)
    80003f9e:	6b42                	ld	s6,16(sp)
    80003fa0:	6ba2                	ld	s7,8(sp)
    80003fa2:	6161                	addi	sp,sp,80
    80003fa4:	8082                	ret

0000000080003fa6 <iupdate>:
{
    80003fa6:	1101                	addi	sp,sp,-32
    80003fa8:	ec06                	sd	ra,24(sp)
    80003faa:	e822                	sd	s0,16(sp)
    80003fac:	e426                	sd	s1,8(sp)
    80003fae:	e04a                	sd	s2,0(sp)
    80003fb0:	1000                	addi	s0,sp,32
    80003fb2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fb4:	415c                	lw	a5,4(a0)
    80003fb6:	0047d79b          	srliw	a5,a5,0x4
    80003fba:	00025597          	auipc	a1,0x25
    80003fbe:	c065a583          	lw	a1,-1018(a1) # 80028bc0 <sb+0x18>
    80003fc2:	9dbd                	addw	a1,a1,a5
    80003fc4:	4108                	lw	a0,0(a0)
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	8a6080e7          	jalr	-1882(ra) # 8000386c <bread>
    80003fce:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fd0:	05850793          	addi	a5,a0,88
    80003fd4:	40c8                	lw	a0,4(s1)
    80003fd6:	893d                	andi	a0,a0,15
    80003fd8:	051a                	slli	a0,a0,0x6
    80003fda:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003fdc:	04449703          	lh	a4,68(s1)
    80003fe0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003fe4:	04649703          	lh	a4,70(s1)
    80003fe8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003fec:	04849703          	lh	a4,72(s1)
    80003ff0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ff4:	04a49703          	lh	a4,74(s1)
    80003ff8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ffc:	44f8                	lw	a4,76(s1)
    80003ffe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004000:	03400613          	li	a2,52
    80004004:	05048593          	addi	a1,s1,80
    80004008:	0531                	addi	a0,a0,12
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	d22080e7          	jalr	-734(ra) # 80000d2c <memmove>
  log_write(bp);
    80004012:	854a                	mv	a0,s2
    80004014:	00001097          	auipc	ra,0x1
    80004018:	f1c080e7          	jalr	-228(ra) # 80004f30 <log_write>
  brelse(bp);
    8000401c:	854a                	mv	a0,s2
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	97e080e7          	jalr	-1666(ra) # 8000399c <brelse>
}
    80004026:	60e2                	ld	ra,24(sp)
    80004028:	6442                	ld	s0,16(sp)
    8000402a:	64a2                	ld	s1,8(sp)
    8000402c:	6902                	ld	s2,0(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <idup>:
{
    80004032:	1101                	addi	sp,sp,-32
    80004034:	ec06                	sd	ra,24(sp)
    80004036:	e822                	sd	s0,16(sp)
    80004038:	e426                	sd	s1,8(sp)
    8000403a:	1000                	addi	s0,sp,32
    8000403c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000403e:	00025517          	auipc	a0,0x25
    80004042:	b8a50513          	addi	a0,a0,-1142 # 80028bc8 <itable>
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	b7c080e7          	jalr	-1156(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000404e:	449c                	lw	a5,8(s1)
    80004050:	2785                	addiw	a5,a5,1
    80004052:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004054:	00025517          	auipc	a0,0x25
    80004058:	b7450513          	addi	a0,a0,-1164 # 80028bc8 <itable>
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	c2c080e7          	jalr	-980(ra) # 80000c88 <release>
}
    80004064:	8526                	mv	a0,s1
    80004066:	60e2                	ld	ra,24(sp)
    80004068:	6442                	ld	s0,16(sp)
    8000406a:	64a2                	ld	s1,8(sp)
    8000406c:	6105                	addi	sp,sp,32
    8000406e:	8082                	ret

0000000080004070 <ilock>:
{
    80004070:	1101                	addi	sp,sp,-32
    80004072:	ec06                	sd	ra,24(sp)
    80004074:	e822                	sd	s0,16(sp)
    80004076:	e426                	sd	s1,8(sp)
    80004078:	e04a                	sd	s2,0(sp)
    8000407a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000407c:	c115                	beqz	a0,800040a0 <ilock+0x30>
    8000407e:	84aa                	mv	s1,a0
    80004080:	451c                	lw	a5,8(a0)
    80004082:	00f05f63          	blez	a5,800040a0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004086:	0541                	addi	a0,a0,16
    80004088:	00001097          	auipc	ra,0x1
    8000408c:	fc8080e7          	jalr	-56(ra) # 80005050 <acquiresleep>
  if(ip->valid == 0){
    80004090:	40bc                	lw	a5,64(s1)
    80004092:	cf99                	beqz	a5,800040b0 <ilock+0x40>
}
    80004094:	60e2                	ld	ra,24(sp)
    80004096:	6442                	ld	s0,16(sp)
    80004098:	64a2                	ld	s1,8(sp)
    8000409a:	6902                	ld	s2,0(sp)
    8000409c:	6105                	addi	sp,sp,32
    8000409e:	8082                	ret
    panic("ilock");
    800040a0:	00006517          	auipc	a0,0x6
    800040a4:	96850513          	addi	a0,a0,-1688 # 80009a08 <syscalls+0x180>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	482080e7          	jalr	1154(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040b0:	40dc                	lw	a5,4(s1)
    800040b2:	0047d79b          	srliw	a5,a5,0x4
    800040b6:	00025597          	auipc	a1,0x25
    800040ba:	b0a5a583          	lw	a1,-1270(a1) # 80028bc0 <sb+0x18>
    800040be:	9dbd                	addw	a1,a1,a5
    800040c0:	4088                	lw	a0,0(s1)
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	7aa080e7          	jalr	1962(ra) # 8000386c <bread>
    800040ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040cc:	05850593          	addi	a1,a0,88
    800040d0:	40dc                	lw	a5,4(s1)
    800040d2:	8bbd                	andi	a5,a5,15
    800040d4:	079a                	slli	a5,a5,0x6
    800040d6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800040d8:	00059783          	lh	a5,0(a1)
    800040dc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040e0:	00259783          	lh	a5,2(a1)
    800040e4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040e8:	00459783          	lh	a5,4(a1)
    800040ec:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040f0:	00659783          	lh	a5,6(a1)
    800040f4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040f8:	459c                	lw	a5,8(a1)
    800040fa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040fc:	03400613          	li	a2,52
    80004100:	05b1                	addi	a1,a1,12
    80004102:	05048513          	addi	a0,s1,80
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	c26080e7          	jalr	-986(ra) # 80000d2c <memmove>
    brelse(bp);
    8000410e:	854a                	mv	a0,s2
    80004110:	00000097          	auipc	ra,0x0
    80004114:	88c080e7          	jalr	-1908(ra) # 8000399c <brelse>
    ip->valid = 1;
    80004118:	4785                	li	a5,1
    8000411a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000411c:	04449783          	lh	a5,68(s1)
    80004120:	fbb5                	bnez	a5,80004094 <ilock+0x24>
      panic("ilock: no type");
    80004122:	00006517          	auipc	a0,0x6
    80004126:	8ee50513          	addi	a0,a0,-1810 # 80009a10 <syscalls+0x188>
    8000412a:	ffffc097          	auipc	ra,0xffffc
    8000412e:	400080e7          	jalr	1024(ra) # 8000052a <panic>

0000000080004132 <iunlock>:
{
    80004132:	1101                	addi	sp,sp,-32
    80004134:	ec06                	sd	ra,24(sp)
    80004136:	e822                	sd	s0,16(sp)
    80004138:	e426                	sd	s1,8(sp)
    8000413a:	e04a                	sd	s2,0(sp)
    8000413c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000413e:	c905                	beqz	a0,8000416e <iunlock+0x3c>
    80004140:	84aa                	mv	s1,a0
    80004142:	01050913          	addi	s2,a0,16
    80004146:	854a                	mv	a0,s2
    80004148:	00001097          	auipc	ra,0x1
    8000414c:	fa2080e7          	jalr	-94(ra) # 800050ea <holdingsleep>
    80004150:	cd19                	beqz	a0,8000416e <iunlock+0x3c>
    80004152:	449c                	lw	a5,8(s1)
    80004154:	00f05d63          	blez	a5,8000416e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004158:	854a                	mv	a0,s2
    8000415a:	00001097          	auipc	ra,0x1
    8000415e:	f4c080e7          	jalr	-180(ra) # 800050a6 <releasesleep>
}
    80004162:	60e2                	ld	ra,24(sp)
    80004164:	6442                	ld	s0,16(sp)
    80004166:	64a2                	ld	s1,8(sp)
    80004168:	6902                	ld	s2,0(sp)
    8000416a:	6105                	addi	sp,sp,32
    8000416c:	8082                	ret
    panic("iunlock");
    8000416e:	00006517          	auipc	a0,0x6
    80004172:	8b250513          	addi	a0,a0,-1870 # 80009a20 <syscalls+0x198>
    80004176:	ffffc097          	auipc	ra,0xffffc
    8000417a:	3b4080e7          	jalr	948(ra) # 8000052a <panic>

000000008000417e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000417e:	7179                	addi	sp,sp,-48
    80004180:	f406                	sd	ra,40(sp)
    80004182:	f022                	sd	s0,32(sp)
    80004184:	ec26                	sd	s1,24(sp)
    80004186:	e84a                	sd	s2,16(sp)
    80004188:	e44e                	sd	s3,8(sp)
    8000418a:	e052                	sd	s4,0(sp)
    8000418c:	1800                	addi	s0,sp,48
    8000418e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004190:	05050493          	addi	s1,a0,80
    80004194:	08050913          	addi	s2,a0,128
    80004198:	a021                	j	800041a0 <itrunc+0x22>
    8000419a:	0491                	addi	s1,s1,4
    8000419c:	01248d63          	beq	s1,s2,800041b6 <itrunc+0x38>
    if(ip->addrs[i]){
    800041a0:	408c                	lw	a1,0(s1)
    800041a2:	dde5                	beqz	a1,8000419a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800041a4:	0009a503          	lw	a0,0(s3)
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	90a080e7          	jalr	-1782(ra) # 80003ab2 <bfree>
      ip->addrs[i] = 0;
    800041b0:	0004a023          	sw	zero,0(s1)
    800041b4:	b7dd                	j	8000419a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800041b6:	0809a583          	lw	a1,128(s3)
    800041ba:	e185                	bnez	a1,800041da <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800041bc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800041c0:	854e                	mv	a0,s3
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	de4080e7          	jalr	-540(ra) # 80003fa6 <iupdate>
}
    800041ca:	70a2                	ld	ra,40(sp)
    800041cc:	7402                	ld	s0,32(sp)
    800041ce:	64e2                	ld	s1,24(sp)
    800041d0:	6942                	ld	s2,16(sp)
    800041d2:	69a2                	ld	s3,8(sp)
    800041d4:	6a02                	ld	s4,0(sp)
    800041d6:	6145                	addi	sp,sp,48
    800041d8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800041da:	0009a503          	lw	a0,0(s3)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	68e080e7          	jalr	1678(ra) # 8000386c <bread>
    800041e6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041e8:	05850493          	addi	s1,a0,88
    800041ec:	45850913          	addi	s2,a0,1112
    800041f0:	a021                	j	800041f8 <itrunc+0x7a>
    800041f2:	0491                	addi	s1,s1,4
    800041f4:	01248b63          	beq	s1,s2,8000420a <itrunc+0x8c>
      if(a[j])
    800041f8:	408c                	lw	a1,0(s1)
    800041fa:	dde5                	beqz	a1,800041f2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800041fc:	0009a503          	lw	a0,0(s3)
    80004200:	00000097          	auipc	ra,0x0
    80004204:	8b2080e7          	jalr	-1870(ra) # 80003ab2 <bfree>
    80004208:	b7ed                	j	800041f2 <itrunc+0x74>
    brelse(bp);
    8000420a:	8552                	mv	a0,s4
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	790080e7          	jalr	1936(ra) # 8000399c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004214:	0809a583          	lw	a1,128(s3)
    80004218:	0009a503          	lw	a0,0(s3)
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	896080e7          	jalr	-1898(ra) # 80003ab2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004224:	0809a023          	sw	zero,128(s3)
    80004228:	bf51                	j	800041bc <itrunc+0x3e>

000000008000422a <iput>:
{
    8000422a:	1101                	addi	sp,sp,-32
    8000422c:	ec06                	sd	ra,24(sp)
    8000422e:	e822                	sd	s0,16(sp)
    80004230:	e426                	sd	s1,8(sp)
    80004232:	e04a                	sd	s2,0(sp)
    80004234:	1000                	addi	s0,sp,32
    80004236:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004238:	00025517          	auipc	a0,0x25
    8000423c:	99050513          	addi	a0,a0,-1648 # 80028bc8 <itable>
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	982080e7          	jalr	-1662(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004248:	4498                	lw	a4,8(s1)
    8000424a:	4785                	li	a5,1
    8000424c:	02f70363          	beq	a4,a5,80004272 <iput+0x48>
  ip->ref--;
    80004250:	449c                	lw	a5,8(s1)
    80004252:	37fd                	addiw	a5,a5,-1
    80004254:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004256:	00025517          	auipc	a0,0x25
    8000425a:	97250513          	addi	a0,a0,-1678 # 80028bc8 <itable>
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	a2a080e7          	jalr	-1494(ra) # 80000c88 <release>
}
    80004266:	60e2                	ld	ra,24(sp)
    80004268:	6442                	ld	s0,16(sp)
    8000426a:	64a2                	ld	s1,8(sp)
    8000426c:	6902                	ld	s2,0(sp)
    8000426e:	6105                	addi	sp,sp,32
    80004270:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004272:	40bc                	lw	a5,64(s1)
    80004274:	dff1                	beqz	a5,80004250 <iput+0x26>
    80004276:	04a49783          	lh	a5,74(s1)
    8000427a:	fbf9                	bnez	a5,80004250 <iput+0x26>
    acquiresleep(&ip->lock);
    8000427c:	01048913          	addi	s2,s1,16
    80004280:	854a                	mv	a0,s2
    80004282:	00001097          	auipc	ra,0x1
    80004286:	dce080e7          	jalr	-562(ra) # 80005050 <acquiresleep>
    release(&itable.lock);
    8000428a:	00025517          	auipc	a0,0x25
    8000428e:	93e50513          	addi	a0,a0,-1730 # 80028bc8 <itable>
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	9f6080e7          	jalr	-1546(ra) # 80000c88 <release>
    itrunc(ip);
    8000429a:	8526                	mv	a0,s1
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	ee2080e7          	jalr	-286(ra) # 8000417e <itrunc>
    ip->type = 0;
    800042a4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800042a8:	8526                	mv	a0,s1
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	cfc080e7          	jalr	-772(ra) # 80003fa6 <iupdate>
    ip->valid = 0;
    800042b2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800042b6:	854a                	mv	a0,s2
    800042b8:	00001097          	auipc	ra,0x1
    800042bc:	dee080e7          	jalr	-530(ra) # 800050a6 <releasesleep>
    acquire(&itable.lock);
    800042c0:	00025517          	auipc	a0,0x25
    800042c4:	90850513          	addi	a0,a0,-1784 # 80028bc8 <itable>
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	8fa080e7          	jalr	-1798(ra) # 80000bc2 <acquire>
    800042d0:	b741                	j	80004250 <iput+0x26>

00000000800042d2 <iunlockput>:
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	1000                	addi	s0,sp,32
    800042dc:	84aa                	mv	s1,a0
  iunlock(ip);
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	e54080e7          	jalr	-428(ra) # 80004132 <iunlock>
  iput(ip);
    800042e6:	8526                	mv	a0,s1
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	f42080e7          	jalr	-190(ra) # 8000422a <iput>
}
    800042f0:	60e2                	ld	ra,24(sp)
    800042f2:	6442                	ld	s0,16(sp)
    800042f4:	64a2                	ld	s1,8(sp)
    800042f6:	6105                	addi	sp,sp,32
    800042f8:	8082                	ret

00000000800042fa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042fa:	1141                	addi	sp,sp,-16
    800042fc:	e422                	sd	s0,8(sp)
    800042fe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004300:	411c                	lw	a5,0(a0)
    80004302:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004304:	415c                	lw	a5,4(a0)
    80004306:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004308:	04451783          	lh	a5,68(a0)
    8000430c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004310:	04a51783          	lh	a5,74(a0)
    80004314:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004318:	04c56783          	lwu	a5,76(a0)
    8000431c:	e99c                	sd	a5,16(a1)
}
    8000431e:	6422                	ld	s0,8(sp)
    80004320:	0141                	addi	sp,sp,16
    80004322:	8082                	ret

0000000080004324 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004324:	457c                	lw	a5,76(a0)
    80004326:	0ed7e963          	bltu	a5,a3,80004418 <readi+0xf4>
{
    8000432a:	7159                	addi	sp,sp,-112
    8000432c:	f486                	sd	ra,104(sp)
    8000432e:	f0a2                	sd	s0,96(sp)
    80004330:	eca6                	sd	s1,88(sp)
    80004332:	e8ca                	sd	s2,80(sp)
    80004334:	e4ce                	sd	s3,72(sp)
    80004336:	e0d2                	sd	s4,64(sp)
    80004338:	fc56                	sd	s5,56(sp)
    8000433a:	f85a                	sd	s6,48(sp)
    8000433c:	f45e                	sd	s7,40(sp)
    8000433e:	f062                	sd	s8,32(sp)
    80004340:	ec66                	sd	s9,24(sp)
    80004342:	e86a                	sd	s10,16(sp)
    80004344:	e46e                	sd	s11,8(sp)
    80004346:	1880                	addi	s0,sp,112
    80004348:	8baa                	mv	s7,a0
    8000434a:	8c2e                	mv	s8,a1
    8000434c:	8ab2                	mv	s5,a2
    8000434e:	84b6                	mv	s1,a3
    80004350:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004352:	9f35                	addw	a4,a4,a3
    return 0;
    80004354:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004356:	0ad76063          	bltu	a4,a3,800043f6 <readi+0xd2>
  if(off + n > ip->size)
    8000435a:	00e7f463          	bgeu	a5,a4,80004362 <readi+0x3e>
    n = ip->size - off;
    8000435e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004362:	0a0b0963          	beqz	s6,80004414 <readi+0xf0>
    80004366:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004368:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000436c:	5cfd                	li	s9,-1
    8000436e:	a82d                	j	800043a8 <readi+0x84>
    80004370:	020a1d93          	slli	s11,s4,0x20
    80004374:	020ddd93          	srli	s11,s11,0x20
    80004378:	05890793          	addi	a5,s2,88
    8000437c:	86ee                	mv	a3,s11
    8000437e:	963e                	add	a2,a2,a5
    80004380:	85d6                	mv	a1,s5
    80004382:	8562                	mv	a0,s8
    80004384:	ffffe097          	auipc	ra,0xffffe
    80004388:	f82080e7          	jalr	-126(ra) # 80002306 <either_copyout>
    8000438c:	05950d63          	beq	a0,s9,800043e6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004390:	854a                	mv	a0,s2
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	60a080e7          	jalr	1546(ra) # 8000399c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000439a:	013a09bb          	addw	s3,s4,s3
    8000439e:	009a04bb          	addw	s1,s4,s1
    800043a2:	9aee                	add	s5,s5,s11
    800043a4:	0569f763          	bgeu	s3,s6,800043f2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043a8:	000ba903          	lw	s2,0(s7)
    800043ac:	00a4d59b          	srliw	a1,s1,0xa
    800043b0:	855e                	mv	a0,s7
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	8ae080e7          	jalr	-1874(ra) # 80003c60 <bmap>
    800043ba:	0005059b          	sext.w	a1,a0
    800043be:	854a                	mv	a0,s2
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	4ac080e7          	jalr	1196(ra) # 8000386c <bread>
    800043c8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043ca:	3ff4f613          	andi	a2,s1,1023
    800043ce:	40cd07bb          	subw	a5,s10,a2
    800043d2:	413b073b          	subw	a4,s6,s3
    800043d6:	8a3e                	mv	s4,a5
    800043d8:	2781                	sext.w	a5,a5
    800043da:	0007069b          	sext.w	a3,a4
    800043de:	f8f6f9e3          	bgeu	a3,a5,80004370 <readi+0x4c>
    800043e2:	8a3a                	mv	s4,a4
    800043e4:	b771                	j	80004370 <readi+0x4c>
      brelse(bp);
    800043e6:	854a                	mv	a0,s2
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	5b4080e7          	jalr	1460(ra) # 8000399c <brelse>
      tot = -1;
    800043f0:	59fd                	li	s3,-1
  }
  return tot;
    800043f2:	0009851b          	sext.w	a0,s3
}
    800043f6:	70a6                	ld	ra,104(sp)
    800043f8:	7406                	ld	s0,96(sp)
    800043fa:	64e6                	ld	s1,88(sp)
    800043fc:	6946                	ld	s2,80(sp)
    800043fe:	69a6                	ld	s3,72(sp)
    80004400:	6a06                	ld	s4,64(sp)
    80004402:	7ae2                	ld	s5,56(sp)
    80004404:	7b42                	ld	s6,48(sp)
    80004406:	7ba2                	ld	s7,40(sp)
    80004408:	7c02                	ld	s8,32(sp)
    8000440a:	6ce2                	ld	s9,24(sp)
    8000440c:	6d42                	ld	s10,16(sp)
    8000440e:	6da2                	ld	s11,8(sp)
    80004410:	6165                	addi	sp,sp,112
    80004412:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004414:	89da                	mv	s3,s6
    80004416:	bff1                	j	800043f2 <readi+0xce>
    return 0;
    80004418:	4501                	li	a0,0
}
    8000441a:	8082                	ret

000000008000441c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000441c:	457c                	lw	a5,76(a0)
    8000441e:	10d7e863          	bltu	a5,a3,8000452e <writei+0x112>
{
    80004422:	7159                	addi	sp,sp,-112
    80004424:	f486                	sd	ra,104(sp)
    80004426:	f0a2                	sd	s0,96(sp)
    80004428:	eca6                	sd	s1,88(sp)
    8000442a:	e8ca                	sd	s2,80(sp)
    8000442c:	e4ce                	sd	s3,72(sp)
    8000442e:	e0d2                	sd	s4,64(sp)
    80004430:	fc56                	sd	s5,56(sp)
    80004432:	f85a                	sd	s6,48(sp)
    80004434:	f45e                	sd	s7,40(sp)
    80004436:	f062                	sd	s8,32(sp)
    80004438:	ec66                	sd	s9,24(sp)
    8000443a:	e86a                	sd	s10,16(sp)
    8000443c:	e46e                	sd	s11,8(sp)
    8000443e:	1880                	addi	s0,sp,112
    80004440:	8b2a                	mv	s6,a0
    80004442:	8c2e                	mv	s8,a1
    80004444:	8ab2                	mv	s5,a2
    80004446:	8936                	mv	s2,a3
    80004448:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000444a:	00e687bb          	addw	a5,a3,a4
    8000444e:	0ed7e263          	bltu	a5,a3,80004532 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004452:	00043737          	lui	a4,0x43
    80004456:	0ef76063          	bltu	a4,a5,80004536 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000445a:	0c0b8863          	beqz	s7,8000452a <writei+0x10e>
    8000445e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004460:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004464:	5cfd                	li	s9,-1
    80004466:	a091                	j	800044aa <writei+0x8e>
    80004468:	02099d93          	slli	s11,s3,0x20
    8000446c:	020ddd93          	srli	s11,s11,0x20
    80004470:	05848793          	addi	a5,s1,88
    80004474:	86ee                	mv	a3,s11
    80004476:	8656                	mv	a2,s5
    80004478:	85e2                	mv	a1,s8
    8000447a:	953e                	add	a0,a0,a5
    8000447c:	ffffe097          	auipc	ra,0xffffe
    80004480:	ee0080e7          	jalr	-288(ra) # 8000235c <either_copyin>
    80004484:	07950263          	beq	a0,s9,800044e8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004488:	8526                	mv	a0,s1
    8000448a:	00001097          	auipc	ra,0x1
    8000448e:	aa6080e7          	jalr	-1370(ra) # 80004f30 <log_write>
    brelse(bp);
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	508080e7          	jalr	1288(ra) # 8000399c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000449c:	01498a3b          	addw	s4,s3,s4
    800044a0:	0129893b          	addw	s2,s3,s2
    800044a4:	9aee                	add	s5,s5,s11
    800044a6:	057a7663          	bgeu	s4,s7,800044f2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800044aa:	000b2483          	lw	s1,0(s6)
    800044ae:	00a9559b          	srliw	a1,s2,0xa
    800044b2:	855a                	mv	a0,s6
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	7ac080e7          	jalr	1964(ra) # 80003c60 <bmap>
    800044bc:	0005059b          	sext.w	a1,a0
    800044c0:	8526                	mv	a0,s1
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	3aa080e7          	jalr	938(ra) # 8000386c <bread>
    800044ca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044cc:	3ff97513          	andi	a0,s2,1023
    800044d0:	40ad07bb          	subw	a5,s10,a0
    800044d4:	414b873b          	subw	a4,s7,s4
    800044d8:	89be                	mv	s3,a5
    800044da:	2781                	sext.w	a5,a5
    800044dc:	0007069b          	sext.w	a3,a4
    800044e0:	f8f6f4e3          	bgeu	a3,a5,80004468 <writei+0x4c>
    800044e4:	89ba                	mv	s3,a4
    800044e6:	b749                	j	80004468 <writei+0x4c>
      brelse(bp);
    800044e8:	8526                	mv	a0,s1
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	4b2080e7          	jalr	1202(ra) # 8000399c <brelse>
  }

  if(off > ip->size)
    800044f2:	04cb2783          	lw	a5,76(s6)
    800044f6:	0127f463          	bgeu	a5,s2,800044fe <writei+0xe2>
    ip->size = off;
    800044fa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044fe:	855a                	mv	a0,s6
    80004500:	00000097          	auipc	ra,0x0
    80004504:	aa6080e7          	jalr	-1370(ra) # 80003fa6 <iupdate>

  return tot;
    80004508:	000a051b          	sext.w	a0,s4
}
    8000450c:	70a6                	ld	ra,104(sp)
    8000450e:	7406                	ld	s0,96(sp)
    80004510:	64e6                	ld	s1,88(sp)
    80004512:	6946                	ld	s2,80(sp)
    80004514:	69a6                	ld	s3,72(sp)
    80004516:	6a06                	ld	s4,64(sp)
    80004518:	7ae2                	ld	s5,56(sp)
    8000451a:	7b42                	ld	s6,48(sp)
    8000451c:	7ba2                	ld	s7,40(sp)
    8000451e:	7c02                	ld	s8,32(sp)
    80004520:	6ce2                	ld	s9,24(sp)
    80004522:	6d42                	ld	s10,16(sp)
    80004524:	6da2                	ld	s11,8(sp)
    80004526:	6165                	addi	sp,sp,112
    80004528:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000452a:	8a5e                	mv	s4,s7
    8000452c:	bfc9                	j	800044fe <writei+0xe2>
    return -1;
    8000452e:	557d                	li	a0,-1
}
    80004530:	8082                	ret
    return -1;
    80004532:	557d                	li	a0,-1
    80004534:	bfe1                	j	8000450c <writei+0xf0>
    return -1;
    80004536:	557d                	li	a0,-1
    80004538:	bfd1                	j	8000450c <writei+0xf0>

000000008000453a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000453a:	1141                	addi	sp,sp,-16
    8000453c:	e406                	sd	ra,8(sp)
    8000453e:	e022                	sd	s0,0(sp)
    80004540:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004542:	4639                	li	a2,14
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	864080e7          	jalr	-1948(ra) # 80000da8 <strncmp>
}
    8000454c:	60a2                	ld	ra,8(sp)
    8000454e:	6402                	ld	s0,0(sp)
    80004550:	0141                	addi	sp,sp,16
    80004552:	8082                	ret

0000000080004554 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004554:	7139                	addi	sp,sp,-64
    80004556:	fc06                	sd	ra,56(sp)
    80004558:	f822                	sd	s0,48(sp)
    8000455a:	f426                	sd	s1,40(sp)
    8000455c:	f04a                	sd	s2,32(sp)
    8000455e:	ec4e                	sd	s3,24(sp)
    80004560:	e852                	sd	s4,16(sp)
    80004562:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004564:	04451703          	lh	a4,68(a0)
    80004568:	4785                	li	a5,1
    8000456a:	00f71a63          	bne	a4,a5,8000457e <dirlookup+0x2a>
    8000456e:	892a                	mv	s2,a0
    80004570:	89ae                	mv	s3,a1
    80004572:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004574:	457c                	lw	a5,76(a0)
    80004576:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004578:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000457a:	e79d                	bnez	a5,800045a8 <dirlookup+0x54>
    8000457c:	a8a5                	j	800045f4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000457e:	00005517          	auipc	a0,0x5
    80004582:	4aa50513          	addi	a0,a0,1194 # 80009a28 <syscalls+0x1a0>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fa4080e7          	jalr	-92(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000458e:	00005517          	auipc	a0,0x5
    80004592:	4b250513          	addi	a0,a0,1202 # 80009a40 <syscalls+0x1b8>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	f94080e7          	jalr	-108(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000459e:	24c1                	addiw	s1,s1,16
    800045a0:	04c92783          	lw	a5,76(s2)
    800045a4:	04f4f763          	bgeu	s1,a5,800045f2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a8:	4741                	li	a4,16
    800045aa:	86a6                	mv	a3,s1
    800045ac:	fc040613          	addi	a2,s0,-64
    800045b0:	4581                	li	a1,0
    800045b2:	854a                	mv	a0,s2
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	d70080e7          	jalr	-656(ra) # 80004324 <readi>
    800045bc:	47c1                	li	a5,16
    800045be:	fcf518e3          	bne	a0,a5,8000458e <dirlookup+0x3a>
    if(de.inum == 0)
    800045c2:	fc045783          	lhu	a5,-64(s0)
    800045c6:	dfe1                	beqz	a5,8000459e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800045c8:	fc240593          	addi	a1,s0,-62
    800045cc:	854e                	mv	a0,s3
    800045ce:	00000097          	auipc	ra,0x0
    800045d2:	f6c080e7          	jalr	-148(ra) # 8000453a <namecmp>
    800045d6:	f561                	bnez	a0,8000459e <dirlookup+0x4a>
      if(poff)
    800045d8:	000a0463          	beqz	s4,800045e0 <dirlookup+0x8c>
        *poff = off;
    800045dc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045e0:	fc045583          	lhu	a1,-64(s0)
    800045e4:	00092503          	lw	a0,0(s2)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	754080e7          	jalr	1876(ra) # 80003d3c <iget>
    800045f0:	a011                	j	800045f4 <dirlookup+0xa0>
  return 0;
    800045f2:	4501                	li	a0,0
}
    800045f4:	70e2                	ld	ra,56(sp)
    800045f6:	7442                	ld	s0,48(sp)
    800045f8:	74a2                	ld	s1,40(sp)
    800045fa:	7902                	ld	s2,32(sp)
    800045fc:	69e2                	ld	s3,24(sp)
    800045fe:	6a42                	ld	s4,16(sp)
    80004600:	6121                	addi	sp,sp,64
    80004602:	8082                	ret

0000000080004604 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004604:	711d                	addi	sp,sp,-96
    80004606:	ec86                	sd	ra,88(sp)
    80004608:	e8a2                	sd	s0,80(sp)
    8000460a:	e4a6                	sd	s1,72(sp)
    8000460c:	e0ca                	sd	s2,64(sp)
    8000460e:	fc4e                	sd	s3,56(sp)
    80004610:	f852                	sd	s4,48(sp)
    80004612:	f456                	sd	s5,40(sp)
    80004614:	f05a                	sd	s6,32(sp)
    80004616:	ec5e                	sd	s7,24(sp)
    80004618:	e862                	sd	s8,16(sp)
    8000461a:	e466                	sd	s9,8(sp)
    8000461c:	1080                	addi	s0,sp,96
    8000461e:	84aa                	mv	s1,a0
    80004620:	8aae                	mv	s5,a1
    80004622:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004624:	00054703          	lbu	a4,0(a0)
    80004628:	02f00793          	li	a5,47
    8000462c:	02f70363          	beq	a4,a5,80004652 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004630:	ffffd097          	auipc	ra,0xffffd
    80004634:	3e6080e7          	jalr	998(ra) # 80001a16 <myproc>
    80004638:	15053503          	ld	a0,336(a0)
    8000463c:	00000097          	auipc	ra,0x0
    80004640:	9f6080e7          	jalr	-1546(ra) # 80004032 <idup>
    80004644:	89aa                	mv	s3,a0
  while(*path == '/')
    80004646:	02f00913          	li	s2,47
  len = path - s;
    8000464a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000464c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000464e:	4b85                	li	s7,1
    80004650:	a865                	j	80004708 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004652:	4585                	li	a1,1
    80004654:	4505                	li	a0,1
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	6e6080e7          	jalr	1766(ra) # 80003d3c <iget>
    8000465e:	89aa                	mv	s3,a0
    80004660:	b7dd                	j	80004646 <namex+0x42>
      iunlockput(ip);
    80004662:	854e                	mv	a0,s3
    80004664:	00000097          	auipc	ra,0x0
    80004668:	c6e080e7          	jalr	-914(ra) # 800042d2 <iunlockput>
      return 0;
    8000466c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000466e:	854e                	mv	a0,s3
    80004670:	60e6                	ld	ra,88(sp)
    80004672:	6446                	ld	s0,80(sp)
    80004674:	64a6                	ld	s1,72(sp)
    80004676:	6906                	ld	s2,64(sp)
    80004678:	79e2                	ld	s3,56(sp)
    8000467a:	7a42                	ld	s4,48(sp)
    8000467c:	7aa2                	ld	s5,40(sp)
    8000467e:	7b02                	ld	s6,32(sp)
    80004680:	6be2                	ld	s7,24(sp)
    80004682:	6c42                	ld	s8,16(sp)
    80004684:	6ca2                	ld	s9,8(sp)
    80004686:	6125                	addi	sp,sp,96
    80004688:	8082                	ret
      iunlock(ip);
    8000468a:	854e                	mv	a0,s3
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	aa6080e7          	jalr	-1370(ra) # 80004132 <iunlock>
      return ip;
    80004694:	bfe9                	j	8000466e <namex+0x6a>
      iunlockput(ip);
    80004696:	854e                	mv	a0,s3
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	c3a080e7          	jalr	-966(ra) # 800042d2 <iunlockput>
      return 0;
    800046a0:	89e6                	mv	s3,s9
    800046a2:	b7f1                	j	8000466e <namex+0x6a>
  len = path - s;
    800046a4:	40b48633          	sub	a2,s1,a1
    800046a8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800046ac:	099c5463          	bge	s8,s9,80004734 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800046b0:	4639                	li	a2,14
    800046b2:	8552                	mv	a0,s4
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	678080e7          	jalr	1656(ra) # 80000d2c <memmove>
  while(*path == '/')
    800046bc:	0004c783          	lbu	a5,0(s1)
    800046c0:	01279763          	bne	a5,s2,800046ce <namex+0xca>
    path++;
    800046c4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046c6:	0004c783          	lbu	a5,0(s1)
    800046ca:	ff278de3          	beq	a5,s2,800046c4 <namex+0xc0>
    ilock(ip);
    800046ce:	854e                	mv	a0,s3
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	9a0080e7          	jalr	-1632(ra) # 80004070 <ilock>
    if(ip->type != T_DIR){
    800046d8:	04499783          	lh	a5,68(s3)
    800046dc:	f97793e3          	bne	a5,s7,80004662 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800046e0:	000a8563          	beqz	s5,800046ea <namex+0xe6>
    800046e4:	0004c783          	lbu	a5,0(s1)
    800046e8:	d3cd                	beqz	a5,8000468a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046ea:	865a                	mv	a2,s6
    800046ec:	85d2                	mv	a1,s4
    800046ee:	854e                	mv	a0,s3
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	e64080e7          	jalr	-412(ra) # 80004554 <dirlookup>
    800046f8:	8caa                	mv	s9,a0
    800046fa:	dd51                	beqz	a0,80004696 <namex+0x92>
    iunlockput(ip);
    800046fc:	854e                	mv	a0,s3
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	bd4080e7          	jalr	-1068(ra) # 800042d2 <iunlockput>
    ip = next;
    80004706:	89e6                	mv	s3,s9
  while(*path == '/')
    80004708:	0004c783          	lbu	a5,0(s1)
    8000470c:	05279763          	bne	a5,s2,8000475a <namex+0x156>
    path++;
    80004710:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004712:	0004c783          	lbu	a5,0(s1)
    80004716:	ff278de3          	beq	a5,s2,80004710 <namex+0x10c>
  if(*path == 0)
    8000471a:	c79d                	beqz	a5,80004748 <namex+0x144>
    path++;
    8000471c:	85a6                	mv	a1,s1
  len = path - s;
    8000471e:	8cda                	mv	s9,s6
    80004720:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004722:	01278963          	beq	a5,s2,80004734 <namex+0x130>
    80004726:	dfbd                	beqz	a5,800046a4 <namex+0xa0>
    path++;
    80004728:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000472a:	0004c783          	lbu	a5,0(s1)
    8000472e:	ff279ce3          	bne	a5,s2,80004726 <namex+0x122>
    80004732:	bf8d                	j	800046a4 <namex+0xa0>
    memmove(name, s, len);
    80004734:	2601                	sext.w	a2,a2
    80004736:	8552                	mv	a0,s4
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	5f4080e7          	jalr	1524(ra) # 80000d2c <memmove>
    name[len] = 0;
    80004740:	9cd2                	add	s9,s9,s4
    80004742:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004746:	bf9d                	j	800046bc <namex+0xb8>
  if(nameiparent){
    80004748:	f20a83e3          	beqz	s5,8000466e <namex+0x6a>
    iput(ip);
    8000474c:	854e                	mv	a0,s3
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	adc080e7          	jalr	-1316(ra) # 8000422a <iput>
    return 0;
    80004756:	4981                	li	s3,0
    80004758:	bf19                	j	8000466e <namex+0x6a>
  if(*path == 0)
    8000475a:	d7fd                	beqz	a5,80004748 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000475c:	0004c783          	lbu	a5,0(s1)
    80004760:	85a6                	mv	a1,s1
    80004762:	b7d1                	j	80004726 <namex+0x122>

0000000080004764 <dirlink>:
{
    80004764:	7139                	addi	sp,sp,-64
    80004766:	fc06                	sd	ra,56(sp)
    80004768:	f822                	sd	s0,48(sp)
    8000476a:	f426                	sd	s1,40(sp)
    8000476c:	f04a                	sd	s2,32(sp)
    8000476e:	ec4e                	sd	s3,24(sp)
    80004770:	e852                	sd	s4,16(sp)
    80004772:	0080                	addi	s0,sp,64
    80004774:	892a                	mv	s2,a0
    80004776:	8a2e                	mv	s4,a1
    80004778:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000477a:	4601                	li	a2,0
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	dd8080e7          	jalr	-552(ra) # 80004554 <dirlookup>
    80004784:	e93d                	bnez	a0,800047fa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004786:	04c92483          	lw	s1,76(s2)
    8000478a:	c49d                	beqz	s1,800047b8 <dirlink+0x54>
    8000478c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000478e:	4741                	li	a4,16
    80004790:	86a6                	mv	a3,s1
    80004792:	fc040613          	addi	a2,s0,-64
    80004796:	4581                	li	a1,0
    80004798:	854a                	mv	a0,s2
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	b8a080e7          	jalr	-1142(ra) # 80004324 <readi>
    800047a2:	47c1                	li	a5,16
    800047a4:	06f51163          	bne	a0,a5,80004806 <dirlink+0xa2>
    if(de.inum == 0)
    800047a8:	fc045783          	lhu	a5,-64(s0)
    800047ac:	c791                	beqz	a5,800047b8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ae:	24c1                	addiw	s1,s1,16
    800047b0:	04c92783          	lw	a5,76(s2)
    800047b4:	fcf4ede3          	bltu	s1,a5,8000478e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800047b8:	4639                	li	a2,14
    800047ba:	85d2                	mv	a1,s4
    800047bc:	fc240513          	addi	a0,s0,-62
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	624080e7          	jalr	1572(ra) # 80000de4 <strncpy>
  de.inum = inum;
    800047c8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047cc:	4741                	li	a4,16
    800047ce:	86a6                	mv	a3,s1
    800047d0:	fc040613          	addi	a2,s0,-64
    800047d4:	4581                	li	a1,0
    800047d6:	854a                	mv	a0,s2
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	c44080e7          	jalr	-956(ra) # 8000441c <writei>
    800047e0:	872a                	mv	a4,a0
    800047e2:	47c1                	li	a5,16
  return 0;
    800047e4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047e6:	02f71863          	bne	a4,a5,80004816 <dirlink+0xb2>
}
    800047ea:	70e2                	ld	ra,56(sp)
    800047ec:	7442                	ld	s0,48(sp)
    800047ee:	74a2                	ld	s1,40(sp)
    800047f0:	7902                	ld	s2,32(sp)
    800047f2:	69e2                	ld	s3,24(sp)
    800047f4:	6a42                	ld	s4,16(sp)
    800047f6:	6121                	addi	sp,sp,64
    800047f8:	8082                	ret
    iput(ip);
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	a30080e7          	jalr	-1488(ra) # 8000422a <iput>
    return -1;
    80004802:	557d                	li	a0,-1
    80004804:	b7dd                	j	800047ea <dirlink+0x86>
      panic("dirlink read");
    80004806:	00005517          	auipc	a0,0x5
    8000480a:	24a50513          	addi	a0,a0,586 # 80009a50 <syscalls+0x1c8>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d1c080e7          	jalr	-740(ra) # 8000052a <panic>
    panic("dirlink");
    80004816:	00005517          	auipc	a0,0x5
    8000481a:	3c250513          	addi	a0,a0,962 # 80009bd8 <syscalls+0x350>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	d0c080e7          	jalr	-756(ra) # 8000052a <panic>

0000000080004826 <namei>:

struct inode*
namei(char *path)
{
    80004826:	1101                	addi	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000482e:	fe040613          	addi	a2,s0,-32
    80004832:	4581                	li	a1,0
    80004834:	00000097          	auipc	ra,0x0
    80004838:	dd0080e7          	jalr	-560(ra) # 80004604 <namex>
}
    8000483c:	60e2                	ld	ra,24(sp)
    8000483e:	6442                	ld	s0,16(sp)
    80004840:	6105                	addi	sp,sp,32
    80004842:	8082                	ret

0000000080004844 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004844:	1141                	addi	sp,sp,-16
    80004846:	e406                	sd	ra,8(sp)
    80004848:	e022                	sd	s0,0(sp)
    8000484a:	0800                	addi	s0,sp,16
    8000484c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000484e:	4585                	li	a1,1
    80004850:	00000097          	auipc	ra,0x0
    80004854:	db4080e7          	jalr	-588(ra) # 80004604 <namex>
}
    80004858:	60a2                	ld	ra,8(sp)
    8000485a:	6402                	ld	s0,0(sp)
    8000485c:	0141                	addi	sp,sp,16
    8000485e:	8082                	ret

0000000080004860 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004860:	1101                	addi	sp,sp,-32
    80004862:	ec22                	sd	s0,24(sp)
    80004864:	1000                	addi	s0,sp,32
    80004866:	872a                	mv	a4,a0
    80004868:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    8000486a:	00005797          	auipc	a5,0x5
    8000486e:	1f678793          	addi	a5,a5,502 # 80009a60 <syscalls+0x1d8>
    80004872:	6394                	ld	a3,0(a5)
    80004874:	fed43023          	sd	a3,-32(s0)
    80004878:	0087d683          	lhu	a3,8(a5)
    8000487c:	fed41423          	sh	a3,-24(s0)
    80004880:	00a7c783          	lbu	a5,10(a5)
    80004884:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004888:	87ae                	mv	a5,a1
    if(i<0){
    8000488a:	02074b63          	bltz	a4,800048c0 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    8000488e:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004890:	4629                	li	a2,10
        ++p;
    80004892:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004894:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004898:	feed                	bnez	a3,80004892 <itoa+0x32>
    *p = '\0';
    8000489a:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    8000489e:	4629                	li	a2,10
    800048a0:	17fd                	addi	a5,a5,-1
    800048a2:	02c766bb          	remw	a3,a4,a2
    800048a6:	ff040593          	addi	a1,s0,-16
    800048aa:	96ae                	add	a3,a3,a1
    800048ac:	ff06c683          	lbu	a3,-16(a3)
    800048b0:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800048b4:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800048b8:	f765                	bnez	a4,800048a0 <itoa+0x40>
    return b;
}
    800048ba:	6462                	ld	s0,24(sp)
    800048bc:	6105                	addi	sp,sp,32
    800048be:	8082                	ret
        *p++ = '-';
    800048c0:	00158793          	addi	a5,a1,1
    800048c4:	02d00693          	li	a3,45
    800048c8:	00d58023          	sb	a3,0(a1)
        i *= -1;
    800048cc:	40e0073b          	negw	a4,a4
    800048d0:	bf7d                	j	8000488e <itoa+0x2e>

00000000800048d2 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    800048d2:	711d                	addi	sp,sp,-96
    800048d4:	ec86                	sd	ra,88(sp)
    800048d6:	e8a2                	sd	s0,80(sp)
    800048d8:	e4a6                	sd	s1,72(sp)
    800048da:	e0ca                	sd	s2,64(sp)
    800048dc:	1080                	addi	s0,sp,96
    800048de:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800048e0:	4619                	li	a2,6
    800048e2:	00005597          	auipc	a1,0x5
    800048e6:	18e58593          	addi	a1,a1,398 # 80009a70 <syscalls+0x1e8>
    800048ea:	fd040513          	addi	a0,s0,-48
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	43e080e7          	jalr	1086(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    800048f6:	fd640593          	addi	a1,s0,-42
    800048fa:	5888                	lw	a0,48(s1)
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	f64080e7          	jalr	-156(ra) # 80004860 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004904:	1684b503          	ld	a0,360(s1)
    80004908:	16050763          	beqz	a0,80004a76 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000490c:	00001097          	auipc	ra,0x1
    80004910:	918080e7          	jalr	-1768(ra) # 80005224 <fileclose>

  begin_op();
    80004914:	00000097          	auipc	ra,0x0
    80004918:	444080e7          	jalr	1092(ra) # 80004d58 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000491c:	fb040593          	addi	a1,s0,-80
    80004920:	fd040513          	addi	a0,s0,-48
    80004924:	00000097          	auipc	ra,0x0
    80004928:	f20080e7          	jalr	-224(ra) # 80004844 <nameiparent>
    8000492c:	892a                	mv	s2,a0
    8000492e:	cd69                	beqz	a0,80004a08 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	740080e7          	jalr	1856(ra) # 80004070 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004938:	00005597          	auipc	a1,0x5
    8000493c:	14058593          	addi	a1,a1,320 # 80009a78 <syscalls+0x1f0>
    80004940:	fb040513          	addi	a0,s0,-80
    80004944:	00000097          	auipc	ra,0x0
    80004948:	bf6080e7          	jalr	-1034(ra) # 8000453a <namecmp>
    8000494c:	c57d                	beqz	a0,80004a3a <removeSwapFile+0x168>
    8000494e:	00005597          	auipc	a1,0x5
    80004952:	13258593          	addi	a1,a1,306 # 80009a80 <syscalls+0x1f8>
    80004956:	fb040513          	addi	a0,s0,-80
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	be0080e7          	jalr	-1056(ra) # 8000453a <namecmp>
    80004962:	cd61                	beqz	a0,80004a3a <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004964:	fac40613          	addi	a2,s0,-84
    80004968:	fb040593          	addi	a1,s0,-80
    8000496c:	854a                	mv	a0,s2
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	be6080e7          	jalr	-1050(ra) # 80004554 <dirlookup>
    80004976:	84aa                	mv	s1,a0
    80004978:	c169                	beqz	a0,80004a3a <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	6f6080e7          	jalr	1782(ra) # 80004070 <ilock>

  if(ip->nlink < 1)
    80004982:	04a49783          	lh	a5,74(s1)
    80004986:	08f05763          	blez	a5,80004a14 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000498a:	04449703          	lh	a4,68(s1)
    8000498e:	4785                	li	a5,1
    80004990:	08f70a63          	beq	a4,a5,80004a24 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004994:	4641                	li	a2,16
    80004996:	4581                	li	a1,0
    80004998:	fc040513          	addi	a0,s0,-64
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	334080e7          	jalr	820(ra) # 80000cd0 <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049a4:	4741                	li	a4,16
    800049a6:	fac42683          	lw	a3,-84(s0)
    800049aa:	fc040613          	addi	a2,s0,-64
    800049ae:	4581                	li	a1,0
    800049b0:	854a                	mv	a0,s2
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	a6a080e7          	jalr	-1430(ra) # 8000441c <writei>
    800049ba:	47c1                	li	a5,16
    800049bc:	08f51a63          	bne	a0,a5,80004a50 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800049c0:	04449703          	lh	a4,68(s1)
    800049c4:	4785                	li	a5,1
    800049c6:	08f70d63          	beq	a4,a5,80004a60 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800049ca:	854a                	mv	a0,s2
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	906080e7          	jalr	-1786(ra) # 800042d2 <iunlockput>

  ip->nlink--;
    800049d4:	04a4d783          	lhu	a5,74(s1)
    800049d8:	37fd                	addiw	a5,a5,-1
    800049da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800049de:	8526                	mv	a0,s1
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	5c6080e7          	jalr	1478(ra) # 80003fa6 <iupdate>
  iunlockput(ip);
    800049e8:	8526                	mv	a0,s1
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	8e8080e7          	jalr	-1816(ra) # 800042d2 <iunlockput>

  end_op();
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	3e6080e7          	jalr	998(ra) # 80004dd8 <end_op>

  return 0;
    800049fa:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    800049fc:	60e6                	ld	ra,88(sp)
    800049fe:	6446                	ld	s0,80(sp)
    80004a00:	64a6                	ld	s1,72(sp)
    80004a02:	6906                	ld	s2,64(sp)
    80004a04:	6125                	addi	sp,sp,96
    80004a06:	8082                	ret
    end_op();
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	3d0080e7          	jalr	976(ra) # 80004dd8 <end_op>
    return -1;
    80004a10:	557d                	li	a0,-1
    80004a12:	b7ed                	j	800049fc <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004a14:	00005517          	auipc	a0,0x5
    80004a18:	07450513          	addi	a0,a0,116 # 80009a88 <syscalls+0x200>
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	b0e080e7          	jalr	-1266(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004a24:	8526                	mv	a0,s1
    80004a26:	00002097          	auipc	ra,0x2
    80004a2a:	866080e7          	jalr	-1946(ra) # 8000628c <isdirempty>
    80004a2e:	f13d                	bnez	a0,80004994 <removeSwapFile+0xc2>
    iunlockput(ip);
    80004a30:	8526                	mv	a0,s1
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	8a0080e7          	jalr	-1888(ra) # 800042d2 <iunlockput>
    iunlockput(dp);
    80004a3a:	854a                	mv	a0,s2
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	896080e7          	jalr	-1898(ra) # 800042d2 <iunlockput>
    end_op();
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	394080e7          	jalr	916(ra) # 80004dd8 <end_op>
    return -1;
    80004a4c:	557d                	li	a0,-1
    80004a4e:	b77d                	j	800049fc <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004a50:	00005517          	auipc	a0,0x5
    80004a54:	05050513          	addi	a0,a0,80 # 80009aa0 <syscalls+0x218>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	ad2080e7          	jalr	-1326(ra) # 8000052a <panic>
    dp->nlink--;
    80004a60:	04a95783          	lhu	a5,74(s2)
    80004a64:	37fd                	addiw	a5,a5,-1
    80004a66:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	53a080e7          	jalr	1338(ra) # 80003fa6 <iupdate>
    80004a74:	bf99                	j	800049ca <removeSwapFile+0xf8>
    return -1;
    80004a76:	557d                	li	a0,-1
    80004a78:	b751                	j	800049fc <removeSwapFile+0x12a>

0000000080004a7a <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004a7a:	7179                	addi	sp,sp,-48
    80004a7c:	f406                	sd	ra,40(sp)
    80004a7e:	f022                	sd	s0,32(sp)
    80004a80:	ec26                	sd	s1,24(sp)
    80004a82:	e84a                	sd	s2,16(sp)
    80004a84:	1800                	addi	s0,sp,48
    80004a86:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004a88:	4619                	li	a2,6
    80004a8a:	00005597          	auipc	a1,0x5
    80004a8e:	fe658593          	addi	a1,a1,-26 # 80009a70 <syscalls+0x1e8>
    80004a92:	fd040513          	addi	a0,s0,-48
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	296080e7          	jalr	662(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    80004a9e:	fd640593          	addi	a1,s0,-42
    80004aa2:	5888                	lw	a0,48(s1)
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	dbc080e7          	jalr	-580(ra) # 80004860 <itoa>

  begin_op();
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	2ac080e7          	jalr	684(ra) # 80004d58 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004ab4:	4681                	li	a3,0
    80004ab6:	4601                	li	a2,0
    80004ab8:	4589                	li	a1,2
    80004aba:	fd040513          	addi	a0,s0,-48
    80004abe:	00002097          	auipc	ra,0x2
    80004ac2:	9c2080e7          	jalr	-1598(ra) # 80006480 <create>
    80004ac6:	892a                	mv	s2,a0
  iunlock(in);
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	66a080e7          	jalr	1642(ra) # 80004132 <iunlock>
  p->swapFile = filealloc();
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	698080e7          	jalr	1688(ra) # 80005168 <filealloc>
    80004ad8:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004adc:	cd1d                	beqz	a0,80004b1a <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004ade:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004ae2:	1684b703          	ld	a4,360(s1)
    80004ae6:	4789                	li	a5,2
    80004ae8:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004aea:	1684b703          	ld	a4,360(s1)
    80004aee:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004af2:	1684b703          	ld	a4,360(s1)
    80004af6:	4685                	li	a3,1
    80004af8:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004afc:	1684b703          	ld	a4,360(s1)
    80004b00:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	2d4080e7          	jalr	724(ra) # 80004dd8 <end_op>

    return 0;
}
    80004b0c:	4501                	li	a0,0
    80004b0e:	70a2                	ld	ra,40(sp)
    80004b10:	7402                	ld	s0,32(sp)
    80004b12:	64e2                	ld	s1,24(sp)
    80004b14:	6942                	ld	s2,16(sp)
    80004b16:	6145                	addi	sp,sp,48
    80004b18:	8082                	ret
    panic("no slot for files on /store");
    80004b1a:	00005517          	auipc	a0,0x5
    80004b1e:	f9650513          	addi	a0,a0,-106 # 80009ab0 <syscalls+0x228>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	a08080e7          	jalr	-1528(ra) # 8000052a <panic>

0000000080004b2a <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004b2a:	1141                	addi	sp,sp,-16
    80004b2c:	e406                	sd	ra,8(sp)
    80004b2e:	e022                	sd	s0,0(sp)
    80004b30:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004b32:	16853783          	ld	a5,360(a0)
    80004b36:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004b38:	8636                	mv	a2,a3
    80004b3a:	16853503          	ld	a0,360(a0)
    80004b3e:	00001097          	auipc	ra,0x1
    80004b42:	ad8080e7          	jalr	-1320(ra) # 80005616 <kfilewrite>
}
    80004b46:	60a2                	ld	ra,8(sp)
    80004b48:	6402                	ld	s0,0(sp)
    80004b4a:	0141                	addi	sp,sp,16
    80004b4c:	8082                	ret

0000000080004b4e <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004b4e:	1141                	addi	sp,sp,-16
    80004b50:	e406                	sd	ra,8(sp)
    80004b52:	e022                	sd	s0,0(sp)
    80004b54:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004b56:	16853783          	ld	a5,360(a0)
    80004b5a:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004b5c:	8636                	mv	a2,a3
    80004b5e:	16853503          	ld	a0,360(a0)
    80004b62:	00001097          	auipc	ra,0x1
    80004b66:	9f2080e7          	jalr	-1550(ra) # 80005554 <kfileread>
    80004b6a:	60a2                	ld	ra,8(sp)
    80004b6c:	6402                	ld	s0,0(sp)
    80004b6e:	0141                	addi	sp,sp,16
    80004b70:	8082                	ret

0000000080004b72 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b72:	1101                	addi	sp,sp,-32
    80004b74:	ec06                	sd	ra,24(sp)
    80004b76:	e822                	sd	s0,16(sp)
    80004b78:	e426                	sd	s1,8(sp)
    80004b7a:	e04a                	sd	s2,0(sp)
    80004b7c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b7e:	00026917          	auipc	s2,0x26
    80004b82:	af290913          	addi	s2,s2,-1294 # 8002a670 <log>
    80004b86:	01892583          	lw	a1,24(s2)
    80004b8a:	02892503          	lw	a0,40(s2)
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	cde080e7          	jalr	-802(ra) # 8000386c <bread>
    80004b96:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b98:	02c92683          	lw	a3,44(s2)
    80004b9c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b9e:	02d05863          	blez	a3,80004bce <write_head+0x5c>
    80004ba2:	00026797          	auipc	a5,0x26
    80004ba6:	afe78793          	addi	a5,a5,-1282 # 8002a6a0 <log+0x30>
    80004baa:	05c50713          	addi	a4,a0,92
    80004bae:	36fd                	addiw	a3,a3,-1
    80004bb0:	02069613          	slli	a2,a3,0x20
    80004bb4:	01e65693          	srli	a3,a2,0x1e
    80004bb8:	00026617          	auipc	a2,0x26
    80004bbc:	aec60613          	addi	a2,a2,-1300 # 8002a6a4 <log+0x34>
    80004bc0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004bc2:	4390                	lw	a2,0(a5)
    80004bc4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bc6:	0791                	addi	a5,a5,4
    80004bc8:	0711                	addi	a4,a4,4
    80004bca:	fed79ce3          	bne	a5,a3,80004bc2 <write_head+0x50>
  }
  bwrite(buf);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	d8e080e7          	jalr	-626(ra) # 8000395e <bwrite>
  brelse(buf);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	dc2080e7          	jalr	-574(ra) # 8000399c <brelse>
}
    80004be2:	60e2                	ld	ra,24(sp)
    80004be4:	6442                	ld	s0,16(sp)
    80004be6:	64a2                	ld	s1,8(sp)
    80004be8:	6902                	ld	s2,0(sp)
    80004bea:	6105                	addi	sp,sp,32
    80004bec:	8082                	ret

0000000080004bee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bee:	00026797          	auipc	a5,0x26
    80004bf2:	aae7a783          	lw	a5,-1362(a5) # 8002a69c <log+0x2c>
    80004bf6:	0af05d63          	blez	a5,80004cb0 <install_trans+0xc2>
{
    80004bfa:	7139                	addi	sp,sp,-64
    80004bfc:	fc06                	sd	ra,56(sp)
    80004bfe:	f822                	sd	s0,48(sp)
    80004c00:	f426                	sd	s1,40(sp)
    80004c02:	f04a                	sd	s2,32(sp)
    80004c04:	ec4e                	sd	s3,24(sp)
    80004c06:	e852                	sd	s4,16(sp)
    80004c08:	e456                	sd	s5,8(sp)
    80004c0a:	e05a                	sd	s6,0(sp)
    80004c0c:	0080                	addi	s0,sp,64
    80004c0e:	8b2a                	mv	s6,a0
    80004c10:	00026a97          	auipc	s5,0x26
    80004c14:	a90a8a93          	addi	s5,s5,-1392 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c18:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c1a:	00026997          	auipc	s3,0x26
    80004c1e:	a5698993          	addi	s3,s3,-1450 # 8002a670 <log>
    80004c22:	a00d                	j	80004c44 <install_trans+0x56>
    brelse(lbuf);
    80004c24:	854a                	mv	a0,s2
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	d76080e7          	jalr	-650(ra) # 8000399c <brelse>
    brelse(dbuf);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	d6c080e7          	jalr	-660(ra) # 8000399c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c38:	2a05                	addiw	s4,s4,1
    80004c3a:	0a91                	addi	s5,s5,4
    80004c3c:	02c9a783          	lw	a5,44(s3)
    80004c40:	04fa5e63          	bge	s4,a5,80004c9c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c44:	0189a583          	lw	a1,24(s3)
    80004c48:	014585bb          	addw	a1,a1,s4
    80004c4c:	2585                	addiw	a1,a1,1
    80004c4e:	0289a503          	lw	a0,40(s3)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	c1a080e7          	jalr	-998(ra) # 8000386c <bread>
    80004c5a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c5c:	000aa583          	lw	a1,0(s5)
    80004c60:	0289a503          	lw	a0,40(s3)
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	c08080e7          	jalr	-1016(ra) # 8000386c <bread>
    80004c6c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c6e:	40000613          	li	a2,1024
    80004c72:	05890593          	addi	a1,s2,88
    80004c76:	05850513          	addi	a0,a0,88
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	0b2080e7          	jalr	178(ra) # 80000d2c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c82:	8526                	mv	a0,s1
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	cda080e7          	jalr	-806(ra) # 8000395e <bwrite>
    if(recovering == 0)
    80004c8c:	f80b1ce3          	bnez	s6,80004c24 <install_trans+0x36>
      bunpin(dbuf);
    80004c90:	8526                	mv	a0,s1
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	de4080e7          	jalr	-540(ra) # 80003a76 <bunpin>
    80004c9a:	b769                	j	80004c24 <install_trans+0x36>
}
    80004c9c:	70e2                	ld	ra,56(sp)
    80004c9e:	7442                	ld	s0,48(sp)
    80004ca0:	74a2                	ld	s1,40(sp)
    80004ca2:	7902                	ld	s2,32(sp)
    80004ca4:	69e2                	ld	s3,24(sp)
    80004ca6:	6a42                	ld	s4,16(sp)
    80004ca8:	6aa2                	ld	s5,8(sp)
    80004caa:	6b02                	ld	s6,0(sp)
    80004cac:	6121                	addi	sp,sp,64
    80004cae:	8082                	ret
    80004cb0:	8082                	ret

0000000080004cb2 <initlog>:
{
    80004cb2:	7179                	addi	sp,sp,-48
    80004cb4:	f406                	sd	ra,40(sp)
    80004cb6:	f022                	sd	s0,32(sp)
    80004cb8:	ec26                	sd	s1,24(sp)
    80004cba:	e84a                	sd	s2,16(sp)
    80004cbc:	e44e                	sd	s3,8(sp)
    80004cbe:	1800                	addi	s0,sp,48
    80004cc0:	892a                	mv	s2,a0
    80004cc2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004cc4:	00026497          	auipc	s1,0x26
    80004cc8:	9ac48493          	addi	s1,s1,-1620 # 8002a670 <log>
    80004ccc:	00005597          	auipc	a1,0x5
    80004cd0:	e0458593          	addi	a1,a1,-508 # 80009ad0 <syscalls+0x248>
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	e5c080e7          	jalr	-420(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004cde:	0149a583          	lw	a1,20(s3)
    80004ce2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004ce4:	0109a783          	lw	a5,16(s3)
    80004ce8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004cea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004cee:	854a                	mv	a0,s2
    80004cf0:	fffff097          	auipc	ra,0xfffff
    80004cf4:	b7c080e7          	jalr	-1156(ra) # 8000386c <bread>
  log.lh.n = lh->n;
    80004cf8:	4d34                	lw	a3,88(a0)
    80004cfa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004cfc:	02d05663          	blez	a3,80004d28 <initlog+0x76>
    80004d00:	05c50793          	addi	a5,a0,92
    80004d04:	00026717          	auipc	a4,0x26
    80004d08:	99c70713          	addi	a4,a4,-1636 # 8002a6a0 <log+0x30>
    80004d0c:	36fd                	addiw	a3,a3,-1
    80004d0e:	02069613          	slli	a2,a3,0x20
    80004d12:	01e65693          	srli	a3,a2,0x1e
    80004d16:	06050613          	addi	a2,a0,96
    80004d1a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004d1c:	4390                	lw	a2,0(a5)
    80004d1e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d20:	0791                	addi	a5,a5,4
    80004d22:	0711                	addi	a4,a4,4
    80004d24:	fed79ce3          	bne	a5,a3,80004d1c <initlog+0x6a>
  brelse(buf);
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	c74080e7          	jalr	-908(ra) # 8000399c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d30:	4505                	li	a0,1
    80004d32:	00000097          	auipc	ra,0x0
    80004d36:	ebc080e7          	jalr	-324(ra) # 80004bee <install_trans>
  log.lh.n = 0;
    80004d3a:	00026797          	auipc	a5,0x26
    80004d3e:	9607a123          	sw	zero,-1694(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	e30080e7          	jalr	-464(ra) # 80004b72 <write_head>
}
    80004d4a:	70a2                	ld	ra,40(sp)
    80004d4c:	7402                	ld	s0,32(sp)
    80004d4e:	64e2                	ld	s1,24(sp)
    80004d50:	6942                	ld	s2,16(sp)
    80004d52:	69a2                	ld	s3,8(sp)
    80004d54:	6145                	addi	sp,sp,48
    80004d56:	8082                	ret

0000000080004d58 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d58:	1101                	addi	sp,sp,-32
    80004d5a:	ec06                	sd	ra,24(sp)
    80004d5c:	e822                	sd	s0,16(sp)
    80004d5e:	e426                	sd	s1,8(sp)
    80004d60:	e04a                	sd	s2,0(sp)
    80004d62:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d64:	00026517          	auipc	a0,0x26
    80004d68:	90c50513          	addi	a0,a0,-1780 # 8002a670 <log>
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	e56080e7          	jalr	-426(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004d74:	00026497          	auipc	s1,0x26
    80004d78:	8fc48493          	addi	s1,s1,-1796 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d7c:	4979                	li	s2,30
    80004d7e:	a039                	j	80004d8c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d80:	85a6                	mv	a1,s1
    80004d82:	8526                	mv	a0,s1
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	2b4080e7          	jalr	692(ra) # 80002038 <sleep>
    if(log.committing){
    80004d8c:	50dc                	lw	a5,36(s1)
    80004d8e:	fbed                	bnez	a5,80004d80 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d90:	509c                	lw	a5,32(s1)
    80004d92:	0017871b          	addiw	a4,a5,1
    80004d96:	0007069b          	sext.w	a3,a4
    80004d9a:	0027179b          	slliw	a5,a4,0x2
    80004d9e:	9fb9                	addw	a5,a5,a4
    80004da0:	0017979b          	slliw	a5,a5,0x1
    80004da4:	54d8                	lw	a4,44(s1)
    80004da6:	9fb9                	addw	a5,a5,a4
    80004da8:	00f95963          	bge	s2,a5,80004dba <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004dac:	85a6                	mv	a1,s1
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	288080e7          	jalr	648(ra) # 80002038 <sleep>
    80004db8:	bfd1                	j	80004d8c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004dba:	00026517          	auipc	a0,0x26
    80004dbe:	8b650513          	addi	a0,a0,-1866 # 8002a670 <log>
    80004dc2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	ec4080e7          	jalr	-316(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004dcc:	60e2                	ld	ra,24(sp)
    80004dce:	6442                	ld	s0,16(sp)
    80004dd0:	64a2                	ld	s1,8(sp)
    80004dd2:	6902                	ld	s2,0(sp)
    80004dd4:	6105                	addi	sp,sp,32
    80004dd6:	8082                	ret

0000000080004dd8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004dd8:	7139                	addi	sp,sp,-64
    80004dda:	fc06                	sd	ra,56(sp)
    80004ddc:	f822                	sd	s0,48(sp)
    80004dde:	f426                	sd	s1,40(sp)
    80004de0:	f04a                	sd	s2,32(sp)
    80004de2:	ec4e                	sd	s3,24(sp)
    80004de4:	e852                	sd	s4,16(sp)
    80004de6:	e456                	sd	s5,8(sp)
    80004de8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004dea:	00026497          	auipc	s1,0x26
    80004dee:	88648493          	addi	s1,s1,-1914 # 8002a670 <log>
    80004df2:	8526                	mv	a0,s1
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	dce080e7          	jalr	-562(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004dfc:	509c                	lw	a5,32(s1)
    80004dfe:	37fd                	addiw	a5,a5,-1
    80004e00:	0007891b          	sext.w	s2,a5
    80004e04:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004e06:	50dc                	lw	a5,36(s1)
    80004e08:	e7b9                	bnez	a5,80004e56 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004e0a:	04091e63          	bnez	s2,80004e66 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004e0e:	00026497          	auipc	s1,0x26
    80004e12:	86248493          	addi	s1,s1,-1950 # 8002a670 <log>
    80004e16:	4785                	li	a5,1
    80004e18:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	e6c080e7          	jalr	-404(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004e24:	54dc                	lw	a5,44(s1)
    80004e26:	06f04763          	bgtz	a5,80004e94 <end_op+0xbc>
    acquire(&log.lock);
    80004e2a:	00026497          	auipc	s1,0x26
    80004e2e:	84648493          	addi	s1,s1,-1978 # 8002a670 <log>
    80004e32:	8526                	mv	a0,s1
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	d8e080e7          	jalr	-626(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004e3c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e40:	8526                	mv	a0,s1
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	382080e7          	jalr	898(ra) # 800021c4 <wakeup>
    release(&log.lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e3c080e7          	jalr	-452(ra) # 80000c88 <release>
}
    80004e54:	a03d                	j	80004e82 <end_op+0xaa>
    panic("log.committing");
    80004e56:	00005517          	auipc	a0,0x5
    80004e5a:	c8250513          	addi	a0,a0,-894 # 80009ad8 <syscalls+0x250>
    80004e5e:	ffffb097          	auipc	ra,0xffffb
    80004e62:	6cc080e7          	jalr	1740(ra) # 8000052a <panic>
    wakeup(&log);
    80004e66:	00026497          	auipc	s1,0x26
    80004e6a:	80a48493          	addi	s1,s1,-2038 # 8002a670 <log>
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	354080e7          	jalr	852(ra) # 800021c4 <wakeup>
  release(&log.lock);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	e0e080e7          	jalr	-498(ra) # 80000c88 <release>
}
    80004e82:	70e2                	ld	ra,56(sp)
    80004e84:	7442                	ld	s0,48(sp)
    80004e86:	74a2                	ld	s1,40(sp)
    80004e88:	7902                	ld	s2,32(sp)
    80004e8a:	69e2                	ld	s3,24(sp)
    80004e8c:	6a42                	ld	s4,16(sp)
    80004e8e:	6aa2                	ld	s5,8(sp)
    80004e90:	6121                	addi	sp,sp,64
    80004e92:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e94:	00026a97          	auipc	s5,0x26
    80004e98:	80ca8a93          	addi	s5,s5,-2036 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e9c:	00025a17          	auipc	s4,0x25
    80004ea0:	7d4a0a13          	addi	s4,s4,2004 # 8002a670 <log>
    80004ea4:	018a2583          	lw	a1,24(s4)
    80004ea8:	012585bb          	addw	a1,a1,s2
    80004eac:	2585                	addiw	a1,a1,1
    80004eae:	028a2503          	lw	a0,40(s4)
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	9ba080e7          	jalr	-1606(ra) # 8000386c <bread>
    80004eba:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ebc:	000aa583          	lw	a1,0(s5)
    80004ec0:	028a2503          	lw	a0,40(s4)
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	9a8080e7          	jalr	-1624(ra) # 8000386c <bread>
    80004ecc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ece:	40000613          	li	a2,1024
    80004ed2:	05850593          	addi	a1,a0,88
    80004ed6:	05848513          	addi	a0,s1,88
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	e52080e7          	jalr	-430(ra) # 80000d2c <memmove>
    bwrite(to);  // write the log
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	a7a080e7          	jalr	-1414(ra) # 8000395e <bwrite>
    brelse(from);
    80004eec:	854e                	mv	a0,s3
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	aae080e7          	jalr	-1362(ra) # 8000399c <brelse>
    brelse(to);
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	aa4080e7          	jalr	-1372(ra) # 8000399c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f00:	2905                	addiw	s2,s2,1
    80004f02:	0a91                	addi	s5,s5,4
    80004f04:	02ca2783          	lw	a5,44(s4)
    80004f08:	f8f94ee3          	blt	s2,a5,80004ea4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	c66080e7          	jalr	-922(ra) # 80004b72 <write_head>
    install_trans(0); // Now install writes to home locations
    80004f14:	4501                	li	a0,0
    80004f16:	00000097          	auipc	ra,0x0
    80004f1a:	cd8080e7          	jalr	-808(ra) # 80004bee <install_trans>
    log.lh.n = 0;
    80004f1e:	00025797          	auipc	a5,0x25
    80004f22:	7607af23          	sw	zero,1918(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004f26:	00000097          	auipc	ra,0x0
    80004f2a:	c4c080e7          	jalr	-948(ra) # 80004b72 <write_head>
    80004f2e:	bdf5                	j	80004e2a <end_op+0x52>

0000000080004f30 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f30:	1101                	addi	sp,sp,-32
    80004f32:	ec06                	sd	ra,24(sp)
    80004f34:	e822                	sd	s0,16(sp)
    80004f36:	e426                	sd	s1,8(sp)
    80004f38:	e04a                	sd	s2,0(sp)
    80004f3a:	1000                	addi	s0,sp,32
    80004f3c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f3e:	00025917          	auipc	s2,0x25
    80004f42:	73290913          	addi	s2,s2,1842 # 8002a670 <log>
    80004f46:	854a                	mv	a0,s2
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	c7a080e7          	jalr	-902(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f50:	02c92603          	lw	a2,44(s2)
    80004f54:	47f5                	li	a5,29
    80004f56:	06c7c563          	blt	a5,a2,80004fc0 <log_write+0x90>
    80004f5a:	00025797          	auipc	a5,0x25
    80004f5e:	7327a783          	lw	a5,1842(a5) # 8002a68c <log+0x1c>
    80004f62:	37fd                	addiw	a5,a5,-1
    80004f64:	04f65e63          	bge	a2,a5,80004fc0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f68:	00025797          	auipc	a5,0x25
    80004f6c:	7287a783          	lw	a5,1832(a5) # 8002a690 <log+0x20>
    80004f70:	06f05063          	blez	a5,80004fd0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f74:	4781                	li	a5,0
    80004f76:	06c05563          	blez	a2,80004fe0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f7a:	44cc                	lw	a1,12(s1)
    80004f7c:	00025717          	auipc	a4,0x25
    80004f80:	72470713          	addi	a4,a4,1828 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f84:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f86:	4314                	lw	a3,0(a4)
    80004f88:	04b68c63          	beq	a3,a1,80004fe0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f8c:	2785                	addiw	a5,a5,1
    80004f8e:	0711                	addi	a4,a4,4
    80004f90:	fef61be3          	bne	a2,a5,80004f86 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f94:	0621                	addi	a2,a2,8
    80004f96:	060a                	slli	a2,a2,0x2
    80004f98:	00025797          	auipc	a5,0x25
    80004f9c:	6d878793          	addi	a5,a5,1752 # 8002a670 <log>
    80004fa0:	963e                	add	a2,a2,a5
    80004fa2:	44dc                	lw	a5,12(s1)
    80004fa4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	a92080e7          	jalr	-1390(ra) # 80003a3a <bpin>
    log.lh.n++;
    80004fb0:	00025717          	auipc	a4,0x25
    80004fb4:	6c070713          	addi	a4,a4,1728 # 8002a670 <log>
    80004fb8:	575c                	lw	a5,44(a4)
    80004fba:	2785                	addiw	a5,a5,1
    80004fbc:	d75c                	sw	a5,44(a4)
    80004fbe:	a835                	j	80004ffa <log_write+0xca>
    panic("too big a transaction");
    80004fc0:	00005517          	auipc	a0,0x5
    80004fc4:	b2850513          	addi	a0,a0,-1240 # 80009ae8 <syscalls+0x260>
    80004fc8:	ffffb097          	auipc	ra,0xffffb
    80004fcc:	562080e7          	jalr	1378(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004fd0:	00005517          	auipc	a0,0x5
    80004fd4:	b3050513          	addi	a0,a0,-1232 # 80009b00 <syscalls+0x278>
    80004fd8:	ffffb097          	auipc	ra,0xffffb
    80004fdc:	552080e7          	jalr	1362(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004fe0:	00878713          	addi	a4,a5,8
    80004fe4:	00271693          	slli	a3,a4,0x2
    80004fe8:	00025717          	auipc	a4,0x25
    80004fec:	68870713          	addi	a4,a4,1672 # 8002a670 <log>
    80004ff0:	9736                	add	a4,a4,a3
    80004ff2:	44d4                	lw	a3,12(s1)
    80004ff4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ff6:	faf608e3          	beq	a2,a5,80004fa6 <log_write+0x76>
  }
  release(&log.lock);
    80004ffa:	00025517          	auipc	a0,0x25
    80004ffe:	67650513          	addi	a0,a0,1654 # 8002a670 <log>
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c86080e7          	jalr	-890(ra) # 80000c88 <release>
}
    8000500a:	60e2                	ld	ra,24(sp)
    8000500c:	6442                	ld	s0,16(sp)
    8000500e:	64a2                	ld	s1,8(sp)
    80005010:	6902                	ld	s2,0(sp)
    80005012:	6105                	addi	sp,sp,32
    80005014:	8082                	ret

0000000080005016 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005016:	1101                	addi	sp,sp,-32
    80005018:	ec06                	sd	ra,24(sp)
    8000501a:	e822                	sd	s0,16(sp)
    8000501c:	e426                	sd	s1,8(sp)
    8000501e:	e04a                	sd	s2,0(sp)
    80005020:	1000                	addi	s0,sp,32
    80005022:	84aa                	mv	s1,a0
    80005024:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005026:	00005597          	auipc	a1,0x5
    8000502a:	afa58593          	addi	a1,a1,-1286 # 80009b20 <syscalls+0x298>
    8000502e:	0521                	addi	a0,a0,8
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	b02080e7          	jalr	-1278(ra) # 80000b32 <initlock>
  lk->name = name;
    80005038:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000503c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005040:	0204a423          	sw	zero,40(s1)
}
    80005044:	60e2                	ld	ra,24(sp)
    80005046:	6442                	ld	s0,16(sp)
    80005048:	64a2                	ld	s1,8(sp)
    8000504a:	6902                	ld	s2,0(sp)
    8000504c:	6105                	addi	sp,sp,32
    8000504e:	8082                	ret

0000000080005050 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005050:	1101                	addi	sp,sp,-32
    80005052:	ec06                	sd	ra,24(sp)
    80005054:	e822                	sd	s0,16(sp)
    80005056:	e426                	sd	s1,8(sp)
    80005058:	e04a                	sd	s2,0(sp)
    8000505a:	1000                	addi	s0,sp,32
    8000505c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000505e:	00850913          	addi	s2,a0,8
    80005062:	854a                	mv	a0,s2
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	b5e080e7          	jalr	-1186(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000506c:	409c                	lw	a5,0(s1)
    8000506e:	cb89                	beqz	a5,80005080 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005070:	85ca                	mv	a1,s2
    80005072:	8526                	mv	a0,s1
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	fc4080e7          	jalr	-60(ra) # 80002038 <sleep>
  while (lk->locked) {
    8000507c:	409c                	lw	a5,0(s1)
    8000507e:	fbed                	bnez	a5,80005070 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005080:	4785                	li	a5,1
    80005082:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	992080e7          	jalr	-1646(ra) # 80001a16 <myproc>
    8000508c:	591c                	lw	a5,48(a0)
    8000508e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005090:	854a                	mv	a0,s2
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	bf6080e7          	jalr	-1034(ra) # 80000c88 <release>
}
    8000509a:	60e2                	ld	ra,24(sp)
    8000509c:	6442                	ld	s0,16(sp)
    8000509e:	64a2                	ld	s1,8(sp)
    800050a0:	6902                	ld	s2,0(sp)
    800050a2:	6105                	addi	sp,sp,32
    800050a4:	8082                	ret

00000000800050a6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800050a6:	1101                	addi	sp,sp,-32
    800050a8:	ec06                	sd	ra,24(sp)
    800050aa:	e822                	sd	s0,16(sp)
    800050ac:	e426                	sd	s1,8(sp)
    800050ae:	e04a                	sd	s2,0(sp)
    800050b0:	1000                	addi	s0,sp,32
    800050b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050b4:	00850913          	addi	s2,a0,8
    800050b8:	854a                	mv	a0,s2
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	b08080e7          	jalr	-1272(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800050c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800050c6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800050ca:	8526                	mv	a0,s1
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	0f8080e7          	jalr	248(ra) # 800021c4 <wakeup>
  release(&lk->lk);
    800050d4:	854a                	mv	a0,s2
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	bb2080e7          	jalr	-1102(ra) # 80000c88 <release>
}
    800050de:	60e2                	ld	ra,24(sp)
    800050e0:	6442                	ld	s0,16(sp)
    800050e2:	64a2                	ld	s1,8(sp)
    800050e4:	6902                	ld	s2,0(sp)
    800050e6:	6105                	addi	sp,sp,32
    800050e8:	8082                	ret

00000000800050ea <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800050ea:	7179                	addi	sp,sp,-48
    800050ec:	f406                	sd	ra,40(sp)
    800050ee:	f022                	sd	s0,32(sp)
    800050f0:	ec26                	sd	s1,24(sp)
    800050f2:	e84a                	sd	s2,16(sp)
    800050f4:	e44e                	sd	s3,8(sp)
    800050f6:	1800                	addi	s0,sp,48
    800050f8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800050fa:	00850913          	addi	s2,a0,8
    800050fe:	854a                	mv	a0,s2
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	ac2080e7          	jalr	-1342(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005108:	409c                	lw	a5,0(s1)
    8000510a:	ef99                	bnez	a5,80005128 <holdingsleep+0x3e>
    8000510c:	4481                	li	s1,0
  release(&lk->lk);
    8000510e:	854a                	mv	a0,s2
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	b78080e7          	jalr	-1160(ra) # 80000c88 <release>
  return r;
}
    80005118:	8526                	mv	a0,s1
    8000511a:	70a2                	ld	ra,40(sp)
    8000511c:	7402                	ld	s0,32(sp)
    8000511e:	64e2                	ld	s1,24(sp)
    80005120:	6942                	ld	s2,16(sp)
    80005122:	69a2                	ld	s3,8(sp)
    80005124:	6145                	addi	sp,sp,48
    80005126:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005128:	0284a983          	lw	s3,40(s1)
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	8ea080e7          	jalr	-1814(ra) # 80001a16 <myproc>
    80005134:	5904                	lw	s1,48(a0)
    80005136:	413484b3          	sub	s1,s1,s3
    8000513a:	0014b493          	seqz	s1,s1
    8000513e:	bfc1                	j	8000510e <holdingsleep+0x24>

0000000080005140 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005140:	1141                	addi	sp,sp,-16
    80005142:	e406                	sd	ra,8(sp)
    80005144:	e022                	sd	s0,0(sp)
    80005146:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005148:	00005597          	auipc	a1,0x5
    8000514c:	9e858593          	addi	a1,a1,-1560 # 80009b30 <syscalls+0x2a8>
    80005150:	00025517          	auipc	a0,0x25
    80005154:	66850513          	addi	a0,a0,1640 # 8002a7b8 <ftable>
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	9da080e7          	jalr	-1574(ra) # 80000b32 <initlock>
}
    80005160:	60a2                	ld	ra,8(sp)
    80005162:	6402                	ld	s0,0(sp)
    80005164:	0141                	addi	sp,sp,16
    80005166:	8082                	ret

0000000080005168 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005168:	1101                	addi	sp,sp,-32
    8000516a:	ec06                	sd	ra,24(sp)
    8000516c:	e822                	sd	s0,16(sp)
    8000516e:	e426                	sd	s1,8(sp)
    80005170:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005172:	00025517          	auipc	a0,0x25
    80005176:	64650513          	addi	a0,a0,1606 # 8002a7b8 <ftable>
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	a48080e7          	jalr	-1464(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005182:	00025497          	auipc	s1,0x25
    80005186:	64e48493          	addi	s1,s1,1614 # 8002a7d0 <ftable+0x18>
    8000518a:	00026717          	auipc	a4,0x26
    8000518e:	5e670713          	addi	a4,a4,1510 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    80005192:	40dc                	lw	a5,4(s1)
    80005194:	cf99                	beqz	a5,800051b2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005196:	02848493          	addi	s1,s1,40
    8000519a:	fee49ce3          	bne	s1,a4,80005192 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000519e:	00025517          	auipc	a0,0x25
    800051a2:	61a50513          	addi	a0,a0,1562 # 8002a7b8 <ftable>
    800051a6:	ffffc097          	auipc	ra,0xffffc
    800051aa:	ae2080e7          	jalr	-1310(ra) # 80000c88 <release>
  return 0;
    800051ae:	4481                	li	s1,0
    800051b0:	a819                	j	800051c6 <filealloc+0x5e>
      f->ref = 1;
    800051b2:	4785                	li	a5,1
    800051b4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800051b6:	00025517          	auipc	a0,0x25
    800051ba:	60250513          	addi	a0,a0,1538 # 8002a7b8 <ftable>
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	aca080e7          	jalr	-1334(ra) # 80000c88 <release>
}
    800051c6:	8526                	mv	a0,s1
    800051c8:	60e2                	ld	ra,24(sp)
    800051ca:	6442                	ld	s0,16(sp)
    800051cc:	64a2                	ld	s1,8(sp)
    800051ce:	6105                	addi	sp,sp,32
    800051d0:	8082                	ret

00000000800051d2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800051d2:	1101                	addi	sp,sp,-32
    800051d4:	ec06                	sd	ra,24(sp)
    800051d6:	e822                	sd	s0,16(sp)
    800051d8:	e426                	sd	s1,8(sp)
    800051da:	1000                	addi	s0,sp,32
    800051dc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800051de:	00025517          	auipc	a0,0x25
    800051e2:	5da50513          	addi	a0,a0,1498 # 8002a7b8 <ftable>
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	9dc080e7          	jalr	-1572(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800051ee:	40dc                	lw	a5,4(s1)
    800051f0:	02f05263          	blez	a5,80005214 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800051f4:	2785                	addiw	a5,a5,1
    800051f6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800051f8:	00025517          	auipc	a0,0x25
    800051fc:	5c050513          	addi	a0,a0,1472 # 8002a7b8 <ftable>
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	a88080e7          	jalr	-1400(ra) # 80000c88 <release>
  return f;
}
    80005208:	8526                	mv	a0,s1
    8000520a:	60e2                	ld	ra,24(sp)
    8000520c:	6442                	ld	s0,16(sp)
    8000520e:	64a2                	ld	s1,8(sp)
    80005210:	6105                	addi	sp,sp,32
    80005212:	8082                	ret
    panic("filedup");
    80005214:	00005517          	auipc	a0,0x5
    80005218:	92450513          	addi	a0,a0,-1756 # 80009b38 <syscalls+0x2b0>
    8000521c:	ffffb097          	auipc	ra,0xffffb
    80005220:	30e080e7          	jalr	782(ra) # 8000052a <panic>

0000000080005224 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005224:	7139                	addi	sp,sp,-64
    80005226:	fc06                	sd	ra,56(sp)
    80005228:	f822                	sd	s0,48(sp)
    8000522a:	f426                	sd	s1,40(sp)
    8000522c:	f04a                	sd	s2,32(sp)
    8000522e:	ec4e                	sd	s3,24(sp)
    80005230:	e852                	sd	s4,16(sp)
    80005232:	e456                	sd	s5,8(sp)
    80005234:	0080                	addi	s0,sp,64
    80005236:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005238:	00025517          	auipc	a0,0x25
    8000523c:	58050513          	addi	a0,a0,1408 # 8002a7b8 <ftable>
    80005240:	ffffc097          	auipc	ra,0xffffc
    80005244:	982080e7          	jalr	-1662(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005248:	40dc                	lw	a5,4(s1)
    8000524a:	06f05163          	blez	a5,800052ac <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000524e:	37fd                	addiw	a5,a5,-1
    80005250:	0007871b          	sext.w	a4,a5
    80005254:	c0dc                	sw	a5,4(s1)
    80005256:	06e04363          	bgtz	a4,800052bc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000525a:	0004a903          	lw	s2,0(s1)
    8000525e:	0094ca83          	lbu	s5,9(s1)
    80005262:	0104ba03          	ld	s4,16(s1)
    80005266:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000526a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000526e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005272:	00025517          	auipc	a0,0x25
    80005276:	54650513          	addi	a0,a0,1350 # 8002a7b8 <ftable>
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	a0e080e7          	jalr	-1522(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    80005282:	4785                	li	a5,1
    80005284:	04f90d63          	beq	s2,a5,800052de <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005288:	3979                	addiw	s2,s2,-2
    8000528a:	4785                	li	a5,1
    8000528c:	0527e063          	bltu	a5,s2,800052cc <fileclose+0xa8>
    begin_op();
    80005290:	00000097          	auipc	ra,0x0
    80005294:	ac8080e7          	jalr	-1336(ra) # 80004d58 <begin_op>
    iput(ff.ip);
    80005298:	854e                	mv	a0,s3
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	f90080e7          	jalr	-112(ra) # 8000422a <iput>
    end_op();
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	b36080e7          	jalr	-1226(ra) # 80004dd8 <end_op>
    800052aa:	a00d                	j	800052cc <fileclose+0xa8>
    panic("fileclose");
    800052ac:	00005517          	auipc	a0,0x5
    800052b0:	89450513          	addi	a0,a0,-1900 # 80009b40 <syscalls+0x2b8>
    800052b4:	ffffb097          	auipc	ra,0xffffb
    800052b8:	276080e7          	jalr	630(ra) # 8000052a <panic>
    release(&ftable.lock);
    800052bc:	00025517          	auipc	a0,0x25
    800052c0:	4fc50513          	addi	a0,a0,1276 # 8002a7b8 <ftable>
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	9c4080e7          	jalr	-1596(ra) # 80000c88 <release>
  }
}
    800052cc:	70e2                	ld	ra,56(sp)
    800052ce:	7442                	ld	s0,48(sp)
    800052d0:	74a2                	ld	s1,40(sp)
    800052d2:	7902                	ld	s2,32(sp)
    800052d4:	69e2                	ld	s3,24(sp)
    800052d6:	6a42                	ld	s4,16(sp)
    800052d8:	6aa2                	ld	s5,8(sp)
    800052da:	6121                	addi	sp,sp,64
    800052dc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800052de:	85d6                	mv	a1,s5
    800052e0:	8552                	mv	a0,s4
    800052e2:	00000097          	auipc	ra,0x0
    800052e6:	542080e7          	jalr	1346(ra) # 80005824 <pipeclose>
    800052ea:	b7cd                	j	800052cc <fileclose+0xa8>

00000000800052ec <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800052ec:	715d                	addi	sp,sp,-80
    800052ee:	e486                	sd	ra,72(sp)
    800052f0:	e0a2                	sd	s0,64(sp)
    800052f2:	fc26                	sd	s1,56(sp)
    800052f4:	f84a                	sd	s2,48(sp)
    800052f6:	f44e                	sd	s3,40(sp)
    800052f8:	0880                	addi	s0,sp,80
    800052fa:	84aa                	mv	s1,a0
    800052fc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	718080e7          	jalr	1816(ra) # 80001a16 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005306:	409c                	lw	a5,0(s1)
    80005308:	37f9                	addiw	a5,a5,-2
    8000530a:	4705                	li	a4,1
    8000530c:	04f76763          	bltu	a4,a5,8000535a <filestat+0x6e>
    80005310:	892a                	mv	s2,a0
    ilock(f->ip);
    80005312:	6c88                	ld	a0,24(s1)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	d5c080e7          	jalr	-676(ra) # 80004070 <ilock>
    stati(f->ip, &st);
    8000531c:	fb840593          	addi	a1,s0,-72
    80005320:	6c88                	ld	a0,24(s1)
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	fd8080e7          	jalr	-40(ra) # 800042fa <stati>
    iunlock(f->ip);
    8000532a:	6c88                	ld	a0,24(s1)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	e06080e7          	jalr	-506(ra) # 80004132 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005334:	46e1                	li	a3,24
    80005336:	fb840613          	addi	a2,s0,-72
    8000533a:	85ce                	mv	a1,s3
    8000533c:	05093503          	ld	a0,80(s2)
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	396080e7          	jalr	918(ra) # 800016d6 <copyout>
    80005348:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000534c:	60a6                	ld	ra,72(sp)
    8000534e:	6406                	ld	s0,64(sp)
    80005350:	74e2                	ld	s1,56(sp)
    80005352:	7942                	ld	s2,48(sp)
    80005354:	79a2                	ld	s3,40(sp)
    80005356:	6161                	addi	sp,sp,80
    80005358:	8082                	ret
  return -1;
    8000535a:	557d                	li	a0,-1
    8000535c:	bfc5                	j	8000534c <filestat+0x60>

000000008000535e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000535e:	7179                	addi	sp,sp,-48
    80005360:	f406                	sd	ra,40(sp)
    80005362:	f022                	sd	s0,32(sp)
    80005364:	ec26                	sd	s1,24(sp)
    80005366:	e84a                	sd	s2,16(sp)
    80005368:	e44e                	sd	s3,8(sp)
    8000536a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000536c:	00854783          	lbu	a5,8(a0)
    80005370:	c3d5                	beqz	a5,80005414 <fileread+0xb6>
    80005372:	84aa                	mv	s1,a0
    80005374:	89ae                	mv	s3,a1
    80005376:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005378:	411c                	lw	a5,0(a0)
    8000537a:	4705                	li	a4,1
    8000537c:	04e78963          	beq	a5,a4,800053ce <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005380:	470d                	li	a4,3
    80005382:	04e78d63          	beq	a5,a4,800053dc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005386:	4709                	li	a4,2
    80005388:	06e79e63          	bne	a5,a4,80005404 <fileread+0xa6>
    ilock(f->ip);
    8000538c:	6d08                	ld	a0,24(a0)
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	ce2080e7          	jalr	-798(ra) # 80004070 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005396:	874a                	mv	a4,s2
    80005398:	5094                	lw	a3,32(s1)
    8000539a:	864e                	mv	a2,s3
    8000539c:	4585                	li	a1,1
    8000539e:	6c88                	ld	a0,24(s1)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	f84080e7          	jalr	-124(ra) # 80004324 <readi>
    800053a8:	892a                	mv	s2,a0
    800053aa:	00a05563          	blez	a0,800053b4 <fileread+0x56>
      f->off += r;
    800053ae:	509c                	lw	a5,32(s1)
    800053b0:	9fa9                	addw	a5,a5,a0
    800053b2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800053b4:	6c88                	ld	a0,24(s1)
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	d7c080e7          	jalr	-644(ra) # 80004132 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800053be:	854a                	mv	a0,s2
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	64e2                	ld	s1,24(sp)
    800053c6:	6942                	ld	s2,16(sp)
    800053c8:	69a2                	ld	s3,8(sp)
    800053ca:	6145                	addi	sp,sp,48
    800053cc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800053ce:	6908                	ld	a0,16(a0)
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	5b6080e7          	jalr	1462(ra) # 80005986 <piperead>
    800053d8:	892a                	mv	s2,a0
    800053da:	b7d5                	j	800053be <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800053dc:	02451783          	lh	a5,36(a0)
    800053e0:	03079693          	slli	a3,a5,0x30
    800053e4:	92c1                	srli	a3,a3,0x30
    800053e6:	4725                	li	a4,9
    800053e8:	02d76863          	bltu	a4,a3,80005418 <fileread+0xba>
    800053ec:	0792                	slli	a5,a5,0x4
    800053ee:	00025717          	auipc	a4,0x25
    800053f2:	32a70713          	addi	a4,a4,810 # 8002a718 <devsw>
    800053f6:	97ba                	add	a5,a5,a4
    800053f8:	639c                	ld	a5,0(a5)
    800053fa:	c38d                	beqz	a5,8000541c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800053fc:	4505                	li	a0,1
    800053fe:	9782                	jalr	a5
    80005400:	892a                	mv	s2,a0
    80005402:	bf75                	j	800053be <fileread+0x60>
    panic("fileread");
    80005404:	00004517          	auipc	a0,0x4
    80005408:	74c50513          	addi	a0,a0,1868 # 80009b50 <syscalls+0x2c8>
    8000540c:	ffffb097          	auipc	ra,0xffffb
    80005410:	11e080e7          	jalr	286(ra) # 8000052a <panic>
    return -1;
    80005414:	597d                	li	s2,-1
    80005416:	b765                	j	800053be <fileread+0x60>
      return -1;
    80005418:	597d                	li	s2,-1
    8000541a:	b755                	j	800053be <fileread+0x60>
    8000541c:	597d                	li	s2,-1
    8000541e:	b745                	j	800053be <fileread+0x60>

0000000080005420 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005420:	715d                	addi	sp,sp,-80
    80005422:	e486                	sd	ra,72(sp)
    80005424:	e0a2                	sd	s0,64(sp)
    80005426:	fc26                	sd	s1,56(sp)
    80005428:	f84a                	sd	s2,48(sp)
    8000542a:	f44e                	sd	s3,40(sp)
    8000542c:	f052                	sd	s4,32(sp)
    8000542e:	ec56                	sd	s5,24(sp)
    80005430:	e85a                	sd	s6,16(sp)
    80005432:	e45e                	sd	s7,8(sp)
    80005434:	e062                	sd	s8,0(sp)
    80005436:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005438:	00954783          	lbu	a5,9(a0)
    8000543c:	10078663          	beqz	a5,80005548 <filewrite+0x128>
    80005440:	892a                	mv	s2,a0
    80005442:	8aae                	mv	s5,a1
    80005444:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005446:	411c                	lw	a5,0(a0)
    80005448:	4705                	li	a4,1
    8000544a:	02e78263          	beq	a5,a4,8000546e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000544e:	470d                	li	a4,3
    80005450:	02e78663          	beq	a5,a4,8000547c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005454:	4709                	li	a4,2
    80005456:	0ee79163          	bne	a5,a4,80005538 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000545a:	0ac05d63          	blez	a2,80005514 <filewrite+0xf4>
    int i = 0;
    8000545e:	4981                	li	s3,0
    80005460:	6b05                	lui	s6,0x1
    80005462:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005466:	6b85                	lui	s7,0x1
    80005468:	c00b8b9b          	addiw	s7,s7,-1024
    8000546c:	a861                	j	80005504 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000546e:	6908                	ld	a0,16(a0)
    80005470:	00000097          	auipc	ra,0x0
    80005474:	424080e7          	jalr	1060(ra) # 80005894 <pipewrite>
    80005478:	8a2a                	mv	s4,a0
    8000547a:	a045                	j	8000551a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000547c:	02451783          	lh	a5,36(a0)
    80005480:	03079693          	slli	a3,a5,0x30
    80005484:	92c1                	srli	a3,a3,0x30
    80005486:	4725                	li	a4,9
    80005488:	0cd76263          	bltu	a4,a3,8000554c <filewrite+0x12c>
    8000548c:	0792                	slli	a5,a5,0x4
    8000548e:	00025717          	auipc	a4,0x25
    80005492:	28a70713          	addi	a4,a4,650 # 8002a718 <devsw>
    80005496:	97ba                	add	a5,a5,a4
    80005498:	679c                	ld	a5,8(a5)
    8000549a:	cbdd                	beqz	a5,80005550 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000549c:	4505                	li	a0,1
    8000549e:	9782                	jalr	a5
    800054a0:	8a2a                	mv	s4,a0
    800054a2:	a8a5                	j	8000551a <filewrite+0xfa>
    800054a4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	8b0080e7          	jalr	-1872(ra) # 80004d58 <begin_op>
      ilock(f->ip);
    800054b0:	01893503          	ld	a0,24(s2)
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	bbc080e7          	jalr	-1092(ra) # 80004070 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800054bc:	8762                	mv	a4,s8
    800054be:	02092683          	lw	a3,32(s2)
    800054c2:	01598633          	add	a2,s3,s5
    800054c6:	4585                	li	a1,1
    800054c8:	01893503          	ld	a0,24(s2)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	f50080e7          	jalr	-176(ra) # 8000441c <writei>
    800054d4:	84aa                	mv	s1,a0
    800054d6:	00a05763          	blez	a0,800054e4 <filewrite+0xc4>
        f->off += r;
    800054da:	02092783          	lw	a5,32(s2)
    800054de:	9fa9                	addw	a5,a5,a0
    800054e0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800054e4:	01893503          	ld	a0,24(s2)
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	c4a080e7          	jalr	-950(ra) # 80004132 <iunlock>
      end_op();
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	8e8080e7          	jalr	-1816(ra) # 80004dd8 <end_op>

      if(r != n1){
    800054f8:	009c1f63          	bne	s8,s1,80005516 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800054fc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005500:	0149db63          	bge	s3,s4,80005516 <filewrite+0xf6>
      int n1 = n - i;
    80005504:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005508:	84be                	mv	s1,a5
    8000550a:	2781                	sext.w	a5,a5
    8000550c:	f8fb5ce3          	bge	s6,a5,800054a4 <filewrite+0x84>
    80005510:	84de                	mv	s1,s7
    80005512:	bf49                	j	800054a4 <filewrite+0x84>
    int i = 0;
    80005514:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005516:	013a1f63          	bne	s4,s3,80005534 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000551a:	8552                	mv	a0,s4
    8000551c:	60a6                	ld	ra,72(sp)
    8000551e:	6406                	ld	s0,64(sp)
    80005520:	74e2                	ld	s1,56(sp)
    80005522:	7942                	ld	s2,48(sp)
    80005524:	79a2                	ld	s3,40(sp)
    80005526:	7a02                	ld	s4,32(sp)
    80005528:	6ae2                	ld	s5,24(sp)
    8000552a:	6b42                	ld	s6,16(sp)
    8000552c:	6ba2                	ld	s7,8(sp)
    8000552e:	6c02                	ld	s8,0(sp)
    80005530:	6161                	addi	sp,sp,80
    80005532:	8082                	ret
    ret = (i == n ? n : -1);
    80005534:	5a7d                	li	s4,-1
    80005536:	b7d5                	j	8000551a <filewrite+0xfa>
    panic("filewrite");
    80005538:	00004517          	auipc	a0,0x4
    8000553c:	62850513          	addi	a0,a0,1576 # 80009b60 <syscalls+0x2d8>
    80005540:	ffffb097          	auipc	ra,0xffffb
    80005544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
    return -1;
    80005548:	5a7d                	li	s4,-1
    8000554a:	bfc1                	j	8000551a <filewrite+0xfa>
      return -1;
    8000554c:	5a7d                	li	s4,-1
    8000554e:	b7f1                	j	8000551a <filewrite+0xfa>
    80005550:	5a7d                	li	s4,-1
    80005552:	b7e1                	j	8000551a <filewrite+0xfa>

0000000080005554 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005554:	7179                	addi	sp,sp,-48
    80005556:	f406                	sd	ra,40(sp)
    80005558:	f022                	sd	s0,32(sp)
    8000555a:	ec26                	sd	s1,24(sp)
    8000555c:	e84a                	sd	s2,16(sp)
    8000555e:	e44e                	sd	s3,8(sp)
    80005560:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005562:	00854783          	lbu	a5,8(a0)
    80005566:	c3d5                	beqz	a5,8000560a <kfileread+0xb6>
    80005568:	84aa                	mv	s1,a0
    8000556a:	89ae                	mv	s3,a1
    8000556c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000556e:	411c                	lw	a5,0(a0)
    80005570:	4705                	li	a4,1
    80005572:	04e78963          	beq	a5,a4,800055c4 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005576:	470d                	li	a4,3
    80005578:	04e78d63          	beq	a5,a4,800055d2 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000557c:	4709                	li	a4,2
    8000557e:	06e79e63          	bne	a5,a4,800055fa <kfileread+0xa6>
    ilock(f->ip);
    80005582:	6d08                	ld	a0,24(a0)
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	aec080e7          	jalr	-1300(ra) # 80004070 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    8000558c:	874a                	mv	a4,s2
    8000558e:	5094                	lw	a3,32(s1)
    80005590:	864e                	mv	a2,s3
    80005592:	4581                	li	a1,0
    80005594:	6c88                	ld	a0,24(s1)
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	d8e080e7          	jalr	-626(ra) # 80004324 <readi>
    8000559e:	892a                	mv	s2,a0
    800055a0:	00a05563          	blez	a0,800055aa <kfileread+0x56>
      f->off += r;
    800055a4:	509c                	lw	a5,32(s1)
    800055a6:	9fa9                	addw	a5,a5,a0
    800055a8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800055aa:	6c88                	ld	a0,24(s1)
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	b86080e7          	jalr	-1146(ra) # 80004132 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800055b4:	854a                	mv	a0,s2
    800055b6:	70a2                	ld	ra,40(sp)
    800055b8:	7402                	ld	s0,32(sp)
    800055ba:	64e2                	ld	s1,24(sp)
    800055bc:	6942                	ld	s2,16(sp)
    800055be:	69a2                	ld	s3,8(sp)
    800055c0:	6145                	addi	sp,sp,48
    800055c2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800055c4:	6908                	ld	a0,16(a0)
    800055c6:	00000097          	auipc	ra,0x0
    800055ca:	3c0080e7          	jalr	960(ra) # 80005986 <piperead>
    800055ce:	892a                	mv	s2,a0
    800055d0:	b7d5                	j	800055b4 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800055d2:	02451783          	lh	a5,36(a0)
    800055d6:	03079693          	slli	a3,a5,0x30
    800055da:	92c1                	srli	a3,a3,0x30
    800055dc:	4725                	li	a4,9
    800055de:	02d76863          	bltu	a4,a3,8000560e <kfileread+0xba>
    800055e2:	0792                	slli	a5,a5,0x4
    800055e4:	00025717          	auipc	a4,0x25
    800055e8:	13470713          	addi	a4,a4,308 # 8002a718 <devsw>
    800055ec:	97ba                	add	a5,a5,a4
    800055ee:	639c                	ld	a5,0(a5)
    800055f0:	c38d                	beqz	a5,80005612 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800055f2:	4505                	li	a0,1
    800055f4:	9782                	jalr	a5
    800055f6:	892a                	mv	s2,a0
    800055f8:	bf75                	j	800055b4 <kfileread+0x60>
    panic("fileread");
    800055fa:	00004517          	auipc	a0,0x4
    800055fe:	55650513          	addi	a0,a0,1366 # 80009b50 <syscalls+0x2c8>
    80005602:	ffffb097          	auipc	ra,0xffffb
    80005606:	f28080e7          	jalr	-216(ra) # 8000052a <panic>
    return -1;
    8000560a:	597d                	li	s2,-1
    8000560c:	b765                	j	800055b4 <kfileread+0x60>
      return -1;
    8000560e:	597d                	li	s2,-1
    80005610:	b755                	j	800055b4 <kfileread+0x60>
    80005612:	597d                	li	s2,-1
    80005614:	b745                	j	800055b4 <kfileread+0x60>

0000000080005616 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005616:	715d                	addi	sp,sp,-80
    80005618:	e486                	sd	ra,72(sp)
    8000561a:	e0a2                	sd	s0,64(sp)
    8000561c:	fc26                	sd	s1,56(sp)
    8000561e:	f84a                	sd	s2,48(sp)
    80005620:	f44e                	sd	s3,40(sp)
    80005622:	f052                	sd	s4,32(sp)
    80005624:	ec56                	sd	s5,24(sp)
    80005626:	e85a                	sd	s6,16(sp)
    80005628:	e45e                	sd	s7,8(sp)
    8000562a:	e062                	sd	s8,0(sp)
    8000562c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000562e:	00954783          	lbu	a5,9(a0)
    80005632:	10078663          	beqz	a5,8000573e <kfilewrite+0x128>
    80005636:	892a                	mv	s2,a0
    80005638:	8aae                	mv	s5,a1
    8000563a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000563c:	411c                	lw	a5,0(a0)
    8000563e:	4705                	li	a4,1
    80005640:	02e78263          	beq	a5,a4,80005664 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005644:	470d                	li	a4,3
    80005646:	02e78663          	beq	a5,a4,80005672 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000564a:	4709                	li	a4,2
    8000564c:	0ee79163          	bne	a5,a4,8000572e <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005650:	0ac05d63          	blez	a2,8000570a <kfilewrite+0xf4>
    int i = 0;
    80005654:	4981                	li	s3,0
    80005656:	6b05                	lui	s6,0x1
    80005658:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000565c:	6b85                	lui	s7,0x1
    8000565e:	c00b8b9b          	addiw	s7,s7,-1024
    80005662:	a861                	j	800056fa <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005664:	6908                	ld	a0,16(a0)
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	22e080e7          	jalr	558(ra) # 80005894 <pipewrite>
    8000566e:	8a2a                	mv	s4,a0
    80005670:	a045                	j	80005710 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005672:	02451783          	lh	a5,36(a0)
    80005676:	03079693          	slli	a3,a5,0x30
    8000567a:	92c1                	srli	a3,a3,0x30
    8000567c:	4725                	li	a4,9
    8000567e:	0cd76263          	bltu	a4,a3,80005742 <kfilewrite+0x12c>
    80005682:	0792                	slli	a5,a5,0x4
    80005684:	00025717          	auipc	a4,0x25
    80005688:	09470713          	addi	a4,a4,148 # 8002a718 <devsw>
    8000568c:	97ba                	add	a5,a5,a4
    8000568e:	679c                	ld	a5,8(a5)
    80005690:	cbdd                	beqz	a5,80005746 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005692:	4505                	li	a0,1
    80005694:	9782                	jalr	a5
    80005696:	8a2a                	mv	s4,a0
    80005698:	a8a5                	j	80005710 <kfilewrite+0xfa>
    8000569a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	6ba080e7          	jalr	1722(ra) # 80004d58 <begin_op>
      ilock(f->ip);
    800056a6:	01893503          	ld	a0,24(s2)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	9c6080e7          	jalr	-1594(ra) # 80004070 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800056b2:	8762                	mv	a4,s8
    800056b4:	02092683          	lw	a3,32(s2)
    800056b8:	01598633          	add	a2,s3,s5
    800056bc:	4581                	li	a1,0
    800056be:	01893503          	ld	a0,24(s2)
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	d5a080e7          	jalr	-678(ra) # 8000441c <writei>
    800056ca:	84aa                	mv	s1,a0
    800056cc:	00a05763          	blez	a0,800056da <kfilewrite+0xc4>
        f->off += r;
    800056d0:	02092783          	lw	a5,32(s2)
    800056d4:	9fa9                	addw	a5,a5,a0
    800056d6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800056da:	01893503          	ld	a0,24(s2)
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	a54080e7          	jalr	-1452(ra) # 80004132 <iunlock>
      end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	6f2080e7          	jalr	1778(ra) # 80004dd8 <end_op>

      if(r != n1){
    800056ee:	009c1f63          	bne	s8,s1,8000570c <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800056f2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800056f6:	0149db63          	bge	s3,s4,8000570c <kfilewrite+0xf6>
      int n1 = n - i;
    800056fa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800056fe:	84be                	mv	s1,a5
    80005700:	2781                	sext.w	a5,a5
    80005702:	f8fb5ce3          	bge	s6,a5,8000569a <kfilewrite+0x84>
    80005706:	84de                	mv	s1,s7
    80005708:	bf49                	j	8000569a <kfilewrite+0x84>
    int i = 0;
    8000570a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000570c:	013a1f63          	bne	s4,s3,8000572a <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005710:	8552                	mv	a0,s4
    80005712:	60a6                	ld	ra,72(sp)
    80005714:	6406                	ld	s0,64(sp)
    80005716:	74e2                	ld	s1,56(sp)
    80005718:	7942                	ld	s2,48(sp)
    8000571a:	79a2                	ld	s3,40(sp)
    8000571c:	7a02                	ld	s4,32(sp)
    8000571e:	6ae2                	ld	s5,24(sp)
    80005720:	6b42                	ld	s6,16(sp)
    80005722:	6ba2                	ld	s7,8(sp)
    80005724:	6c02                	ld	s8,0(sp)
    80005726:	6161                	addi	sp,sp,80
    80005728:	8082                	ret
    ret = (i == n ? n : -1);
    8000572a:	5a7d                	li	s4,-1
    8000572c:	b7d5                	j	80005710 <kfilewrite+0xfa>
    panic("filewrite");
    8000572e:	00004517          	auipc	a0,0x4
    80005732:	43250513          	addi	a0,a0,1074 # 80009b60 <syscalls+0x2d8>
    80005736:	ffffb097          	auipc	ra,0xffffb
    8000573a:	df4080e7          	jalr	-524(ra) # 8000052a <panic>
    return -1;
    8000573e:	5a7d                	li	s4,-1
    80005740:	bfc1                	j	80005710 <kfilewrite+0xfa>
      return -1;
    80005742:	5a7d                	li	s4,-1
    80005744:	b7f1                	j	80005710 <kfilewrite+0xfa>
    80005746:	5a7d                	li	s4,-1
    80005748:	b7e1                	j	80005710 <kfilewrite+0xfa>

000000008000574a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000574a:	7179                	addi	sp,sp,-48
    8000574c:	f406                	sd	ra,40(sp)
    8000574e:	f022                	sd	s0,32(sp)
    80005750:	ec26                	sd	s1,24(sp)
    80005752:	e84a                	sd	s2,16(sp)
    80005754:	e44e                	sd	s3,8(sp)
    80005756:	e052                	sd	s4,0(sp)
    80005758:	1800                	addi	s0,sp,48
    8000575a:	84aa                	mv	s1,a0
    8000575c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000575e:	0005b023          	sd	zero,0(a1)
    80005762:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	a02080e7          	jalr	-1534(ra) # 80005168 <filealloc>
    8000576e:	e088                	sd	a0,0(s1)
    80005770:	c551                	beqz	a0,800057fc <pipealloc+0xb2>
    80005772:	00000097          	auipc	ra,0x0
    80005776:	9f6080e7          	jalr	-1546(ra) # 80005168 <filealloc>
    8000577a:	00aa3023          	sd	a0,0(s4)
    8000577e:	c92d                	beqz	a0,800057f0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005780:	ffffb097          	auipc	ra,0xffffb
    80005784:	352080e7          	jalr	850(ra) # 80000ad2 <kalloc>
    80005788:	892a                	mv	s2,a0
    8000578a:	c125                	beqz	a0,800057ea <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000578c:	4985                	li	s3,1
    8000578e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005792:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005796:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000579a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000579e:	00004597          	auipc	a1,0x4
    800057a2:	3d258593          	addi	a1,a1,978 # 80009b70 <syscalls+0x2e8>
    800057a6:	ffffb097          	auipc	ra,0xffffb
    800057aa:	38c080e7          	jalr	908(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800057ae:	609c                	ld	a5,0(s1)
    800057b0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800057b4:	609c                	ld	a5,0(s1)
    800057b6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800057ba:	609c                	ld	a5,0(s1)
    800057bc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800057c0:	609c                	ld	a5,0(s1)
    800057c2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800057c6:	000a3783          	ld	a5,0(s4)
    800057ca:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800057ce:	000a3783          	ld	a5,0(s4)
    800057d2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800057d6:	000a3783          	ld	a5,0(s4)
    800057da:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800057de:	000a3783          	ld	a5,0(s4)
    800057e2:	0127b823          	sd	s2,16(a5)
  return 0;
    800057e6:	4501                	li	a0,0
    800057e8:	a025                	j	80005810 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800057ea:	6088                	ld	a0,0(s1)
    800057ec:	e501                	bnez	a0,800057f4 <pipealloc+0xaa>
    800057ee:	a039                	j	800057fc <pipealloc+0xb2>
    800057f0:	6088                	ld	a0,0(s1)
    800057f2:	c51d                	beqz	a0,80005820 <pipealloc+0xd6>
    fileclose(*f0);
    800057f4:	00000097          	auipc	ra,0x0
    800057f8:	a30080e7          	jalr	-1488(ra) # 80005224 <fileclose>
  if(*f1)
    800057fc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005800:	557d                	li	a0,-1
  if(*f1)
    80005802:	c799                	beqz	a5,80005810 <pipealloc+0xc6>
    fileclose(*f1);
    80005804:	853e                	mv	a0,a5
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	a1e080e7          	jalr	-1506(ra) # 80005224 <fileclose>
  return -1;
    8000580e:	557d                	li	a0,-1
}
    80005810:	70a2                	ld	ra,40(sp)
    80005812:	7402                	ld	s0,32(sp)
    80005814:	64e2                	ld	s1,24(sp)
    80005816:	6942                	ld	s2,16(sp)
    80005818:	69a2                	ld	s3,8(sp)
    8000581a:	6a02                	ld	s4,0(sp)
    8000581c:	6145                	addi	sp,sp,48
    8000581e:	8082                	ret
  return -1;
    80005820:	557d                	li	a0,-1
    80005822:	b7fd                	j	80005810 <pipealloc+0xc6>

0000000080005824 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005824:	1101                	addi	sp,sp,-32
    80005826:	ec06                	sd	ra,24(sp)
    80005828:	e822                	sd	s0,16(sp)
    8000582a:	e426                	sd	s1,8(sp)
    8000582c:	e04a                	sd	s2,0(sp)
    8000582e:	1000                	addi	s0,sp,32
    80005830:	84aa                	mv	s1,a0
    80005832:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	38e080e7          	jalr	910(ra) # 80000bc2 <acquire>
  if(writable){
    8000583c:	02090d63          	beqz	s2,80005876 <pipeclose+0x52>
    pi->writeopen = 0;
    80005840:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005844:	21848513          	addi	a0,s1,536
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	97c080e7          	jalr	-1668(ra) # 800021c4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005850:	2204b783          	ld	a5,544(s1)
    80005854:	eb95                	bnez	a5,80005888 <pipeclose+0x64>
    release(&pi->lock);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	430080e7          	jalr	1072(ra) # 80000c88 <release>
    kfree((char*)pi);
    80005860:	8526                	mv	a0,s1
    80005862:	ffffb097          	auipc	ra,0xffffb
    80005866:	174080e7          	jalr	372(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    8000586a:	60e2                	ld	ra,24(sp)
    8000586c:	6442                	ld	s0,16(sp)
    8000586e:	64a2                	ld	s1,8(sp)
    80005870:	6902                	ld	s2,0(sp)
    80005872:	6105                	addi	sp,sp,32
    80005874:	8082                	ret
    pi->readopen = 0;
    80005876:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000587a:	21c48513          	addi	a0,s1,540
    8000587e:	ffffd097          	auipc	ra,0xffffd
    80005882:	946080e7          	jalr	-1722(ra) # 800021c4 <wakeup>
    80005886:	b7e9                	j	80005850 <pipeclose+0x2c>
    release(&pi->lock);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	3fe080e7          	jalr	1022(ra) # 80000c88 <release>
}
    80005892:	bfe1                	j	8000586a <pipeclose+0x46>

0000000080005894 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005894:	711d                	addi	sp,sp,-96
    80005896:	ec86                	sd	ra,88(sp)
    80005898:	e8a2                	sd	s0,80(sp)
    8000589a:	e4a6                	sd	s1,72(sp)
    8000589c:	e0ca                	sd	s2,64(sp)
    8000589e:	fc4e                	sd	s3,56(sp)
    800058a0:	f852                	sd	s4,48(sp)
    800058a2:	f456                	sd	s5,40(sp)
    800058a4:	f05a                	sd	s6,32(sp)
    800058a6:	ec5e                	sd	s7,24(sp)
    800058a8:	e862                	sd	s8,16(sp)
    800058aa:	1080                	addi	s0,sp,96
    800058ac:	84aa                	mv	s1,a0
    800058ae:	8aae                	mv	s5,a1
    800058b0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800058b2:	ffffc097          	auipc	ra,0xffffc
    800058b6:	164080e7          	jalr	356(ra) # 80001a16 <myproc>
    800058ba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	304080e7          	jalr	772(ra) # 80000bc2 <acquire>
  while(i < n){
    800058c6:	0b405363          	blez	s4,8000596c <pipewrite+0xd8>
  int i = 0;
    800058ca:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800058cc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800058ce:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800058d2:	21c48b93          	addi	s7,s1,540
    800058d6:	a089                	j	80005918 <pipewrite+0x84>
      release(&pi->lock);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	3ae080e7          	jalr	942(ra) # 80000c88 <release>
      return -1;
    800058e2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800058e4:	854a                	mv	a0,s2
    800058e6:	60e6                	ld	ra,88(sp)
    800058e8:	6446                	ld	s0,80(sp)
    800058ea:	64a6                	ld	s1,72(sp)
    800058ec:	6906                	ld	s2,64(sp)
    800058ee:	79e2                	ld	s3,56(sp)
    800058f0:	7a42                	ld	s4,48(sp)
    800058f2:	7aa2                	ld	s5,40(sp)
    800058f4:	7b02                	ld	s6,32(sp)
    800058f6:	6be2                	ld	s7,24(sp)
    800058f8:	6c42                	ld	s8,16(sp)
    800058fa:	6125                	addi	sp,sp,96
    800058fc:	8082                	ret
      wakeup(&pi->nread);
    800058fe:	8562                	mv	a0,s8
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	8c4080e7          	jalr	-1852(ra) # 800021c4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005908:	85a6                	mv	a1,s1
    8000590a:	855e                	mv	a0,s7
    8000590c:	ffffc097          	auipc	ra,0xffffc
    80005910:	72c080e7          	jalr	1836(ra) # 80002038 <sleep>
  while(i < n){
    80005914:	05495d63          	bge	s2,s4,8000596e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005918:	2204a783          	lw	a5,544(s1)
    8000591c:	dfd5                	beqz	a5,800058d8 <pipewrite+0x44>
    8000591e:	0289a783          	lw	a5,40(s3)
    80005922:	fbdd                	bnez	a5,800058d8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005924:	2184a783          	lw	a5,536(s1)
    80005928:	21c4a703          	lw	a4,540(s1)
    8000592c:	2007879b          	addiw	a5,a5,512
    80005930:	fcf707e3          	beq	a4,a5,800058fe <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005934:	4685                	li	a3,1
    80005936:	01590633          	add	a2,s2,s5
    8000593a:	faf40593          	addi	a1,s0,-81
    8000593e:	0509b503          	ld	a0,80(s3)
    80005942:	ffffc097          	auipc	ra,0xffffc
    80005946:	e20080e7          	jalr	-480(ra) # 80001762 <copyin>
    8000594a:	03650263          	beq	a0,s6,8000596e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000594e:	21c4a783          	lw	a5,540(s1)
    80005952:	0017871b          	addiw	a4,a5,1
    80005956:	20e4ae23          	sw	a4,540(s1)
    8000595a:	1ff7f793          	andi	a5,a5,511
    8000595e:	97a6                	add	a5,a5,s1
    80005960:	faf44703          	lbu	a4,-81(s0)
    80005964:	00e78c23          	sb	a4,24(a5)
      i++;
    80005968:	2905                	addiw	s2,s2,1
    8000596a:	b76d                	j	80005914 <pipewrite+0x80>
  int i = 0;
    8000596c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000596e:	21848513          	addi	a0,s1,536
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	852080e7          	jalr	-1966(ra) # 800021c4 <wakeup>
  release(&pi->lock);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffb097          	auipc	ra,0xffffb
    80005980:	30c080e7          	jalr	780(ra) # 80000c88 <release>
  return i;
    80005984:	b785                	j	800058e4 <pipewrite+0x50>

0000000080005986 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005986:	715d                	addi	sp,sp,-80
    80005988:	e486                	sd	ra,72(sp)
    8000598a:	e0a2                	sd	s0,64(sp)
    8000598c:	fc26                	sd	s1,56(sp)
    8000598e:	f84a                	sd	s2,48(sp)
    80005990:	f44e                	sd	s3,40(sp)
    80005992:	f052                	sd	s4,32(sp)
    80005994:	ec56                	sd	s5,24(sp)
    80005996:	e85a                	sd	s6,16(sp)
    80005998:	0880                	addi	s0,sp,80
    8000599a:	84aa                	mv	s1,a0
    8000599c:	892e                	mv	s2,a1
    8000599e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800059a0:	ffffc097          	auipc	ra,0xffffc
    800059a4:	076080e7          	jalr	118(ra) # 80001a16 <myproc>
    800059a8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffb097          	auipc	ra,0xffffb
    800059b0:	216080e7          	jalr	534(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800059b4:	2184a703          	lw	a4,536(s1)
    800059b8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800059bc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800059c0:	02f71463          	bne	a4,a5,800059e8 <piperead+0x62>
    800059c4:	2244a783          	lw	a5,548(s1)
    800059c8:	c385                	beqz	a5,800059e8 <piperead+0x62>
    if(pr->killed){
    800059ca:	028a2783          	lw	a5,40(s4)
    800059ce:	ebc1                	bnez	a5,80005a5e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800059d0:	85a6                	mv	a1,s1
    800059d2:	854e                	mv	a0,s3
    800059d4:	ffffc097          	auipc	ra,0xffffc
    800059d8:	664080e7          	jalr	1636(ra) # 80002038 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800059dc:	2184a703          	lw	a4,536(s1)
    800059e0:	21c4a783          	lw	a5,540(s1)
    800059e4:	fef700e3          	beq	a4,a5,800059c4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800059e8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800059ea:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800059ec:	05505363          	blez	s5,80005a32 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800059f0:	2184a783          	lw	a5,536(s1)
    800059f4:	21c4a703          	lw	a4,540(s1)
    800059f8:	02f70d63          	beq	a4,a5,80005a32 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800059fc:	0017871b          	addiw	a4,a5,1
    80005a00:	20e4ac23          	sw	a4,536(s1)
    80005a04:	1ff7f793          	andi	a5,a5,511
    80005a08:	97a6                	add	a5,a5,s1
    80005a0a:	0187c783          	lbu	a5,24(a5)
    80005a0e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005a12:	4685                	li	a3,1
    80005a14:	fbf40613          	addi	a2,s0,-65
    80005a18:	85ca                	mv	a1,s2
    80005a1a:	050a3503          	ld	a0,80(s4)
    80005a1e:	ffffc097          	auipc	ra,0xffffc
    80005a22:	cb8080e7          	jalr	-840(ra) # 800016d6 <copyout>
    80005a26:	01650663          	beq	a0,s6,80005a32 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005a2a:	2985                	addiw	s3,s3,1
    80005a2c:	0905                	addi	s2,s2,1
    80005a2e:	fd3a91e3          	bne	s5,s3,800059f0 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005a32:	21c48513          	addi	a0,s1,540
    80005a36:	ffffc097          	auipc	ra,0xffffc
    80005a3a:	78e080e7          	jalr	1934(ra) # 800021c4 <wakeup>
  release(&pi->lock);
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffb097          	auipc	ra,0xffffb
    80005a44:	248080e7          	jalr	584(ra) # 80000c88 <release>
  return i;
}
    80005a48:	854e                	mv	a0,s3
    80005a4a:	60a6                	ld	ra,72(sp)
    80005a4c:	6406                	ld	s0,64(sp)
    80005a4e:	74e2                	ld	s1,56(sp)
    80005a50:	7942                	ld	s2,48(sp)
    80005a52:	79a2                	ld	s3,40(sp)
    80005a54:	7a02                	ld	s4,32(sp)
    80005a56:	6ae2                	ld	s5,24(sp)
    80005a58:	6b42                	ld	s6,16(sp)
    80005a5a:	6161                	addi	sp,sp,80
    80005a5c:	8082                	ret
      release(&pi->lock);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	228080e7          	jalr	552(ra) # 80000c88 <release>
      return -1;
    80005a68:	59fd                	li	s3,-1
    80005a6a:	bff9                	j	80005a48 <piperead+0xc2>

0000000080005a6c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005a6c:	bd010113          	addi	sp,sp,-1072
    80005a70:	42113423          	sd	ra,1064(sp)
    80005a74:	42813023          	sd	s0,1056(sp)
    80005a78:	40913c23          	sd	s1,1048(sp)
    80005a7c:	41213823          	sd	s2,1040(sp)
    80005a80:	41313423          	sd	s3,1032(sp)
    80005a84:	41413023          	sd	s4,1024(sp)
    80005a88:	3f513c23          	sd	s5,1016(sp)
    80005a8c:	3f613823          	sd	s6,1008(sp)
    80005a90:	3f713423          	sd	s7,1000(sp)
    80005a94:	3f813023          	sd	s8,992(sp)
    80005a98:	3d913c23          	sd	s9,984(sp)
    80005a9c:	3da13823          	sd	s10,976(sp)
    80005aa0:	3db13423          	sd	s11,968(sp)
    80005aa4:	43010413          	addi	s0,sp,1072
    80005aa8:	89aa                	mv	s3,a0
    80005aaa:	bea43023          	sd	a0,-1056(s0)
    80005aae:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005ab2:	ffffc097          	auipc	ra,0xffffc
    80005ab6:	f64080e7          	jalr	-156(ra) # 80001a16 <myproc>
    80005aba:	84aa                	mv	s1,a0
    80005abc:	c0a43423          	sd	a0,-1016(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_PSYC_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    80005ac0:	17050913          	addi	s2,a0,368
    80005ac4:	10000613          	li	a2,256
    80005ac8:	85ca                	mv	a1,s2
    80005aca:	d1040513          	addi	a0,s0,-752
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	25e080e7          	jalr	606(ra) # 80000d2c <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005ad6:	27048493          	addi	s1,s1,624
    80005ada:	10000613          	li	a2,256
    80005ade:	85a6                	mv	a1,s1
    80005ae0:	c1040513          	addi	a0,s0,-1008
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	248080e7          	jalr	584(ra) # 80000d2c <memmove>

  begin_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	26c080e7          	jalr	620(ra) # 80004d58 <begin_op>

  if((ip = namei(path)) == 0){
    80005af4:	854e                	mv	a0,s3
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	d30080e7          	jalr	-720(ra) # 80004826 <namei>
    80005afe:	c569                	beqz	a0,80005bc8 <exec+0x15c>
    80005b00:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	56e080e7          	jalr	1390(ra) # 80004070 <ilock>
  //ADDED Q1
  // TODO isSwapProc... is it equal to (p->pid != INIT_PID && p->pid != SHELL_PID)?
  // if(isSwapProc(p) && init_metadata(p) < 0){
  //   goto bad;
  // }
  if(relevant_metadata_proc(p)) {
    80005b0a:	c0843983          	ld	s3,-1016(s0)
    80005b0e:	854e                	mv	a0,s3
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	48e080e7          	jalr	1166(ra) # 80002f9e <relevant_metadata_proc>
    80005b18:	c901                	beqz	a0,80005b28 <exec+0xbc>
    if (init_metadata(p) < 0) {
    80005b1a:	854e                	mv	a0,s3
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	946080e7          	jalr	-1722(ra) # 80002462 <init_metadata>
    80005b24:	02054963          	bltz	a0,80005b56 <exec+0xea>
    goto bad;
    }
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005b28:	04000713          	li	a4,64
    80005b2c:	4681                	li	a3,0
    80005b2e:	e4840613          	addi	a2,s0,-440
    80005b32:	4581                	li	a1,0
    80005b34:	8552                	mv	a0,s4
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	7ee080e7          	jalr	2030(ra) # 80004324 <readi>
    80005b3e:	04000793          	li	a5,64
    80005b42:	00f51a63          	bne	a0,a5,80005b56 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005b46:	e4842703          	lw	a4,-440(s0)
    80005b4a:	464c47b7          	lui	a5,0x464c4
    80005b4e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005b52:	08f70163          	beq	a4,a5,80005bd4 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005b56:	10000613          	li	a2,256
    80005b5a:	d1040593          	addi	a1,s0,-752
    80005b5e:	854a                	mv	a0,s2
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	1cc080e7          	jalr	460(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005b68:	10000613          	li	a2,256
    80005b6c:	c1040593          	addi	a1,s0,-1008
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffb097          	auipc	ra,0xffffb
    80005b76:	1ba080e7          	jalr	442(ra) # 80000d2c <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005b7a:	8552                	mv	a0,s4
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	756080e7          	jalr	1878(ra) # 800042d2 <iunlockput>
    end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	254080e7          	jalr	596(ra) # 80004dd8 <end_op>
  }
  return -1;
    80005b8c:	557d                	li	a0,-1
}
    80005b8e:	42813083          	ld	ra,1064(sp)
    80005b92:	42013403          	ld	s0,1056(sp)
    80005b96:	41813483          	ld	s1,1048(sp)
    80005b9a:	41013903          	ld	s2,1040(sp)
    80005b9e:	40813983          	ld	s3,1032(sp)
    80005ba2:	40013a03          	ld	s4,1024(sp)
    80005ba6:	3f813a83          	ld	s5,1016(sp)
    80005baa:	3f013b03          	ld	s6,1008(sp)
    80005bae:	3e813b83          	ld	s7,1000(sp)
    80005bb2:	3e013c03          	ld	s8,992(sp)
    80005bb6:	3d813c83          	ld	s9,984(sp)
    80005bba:	3d013d03          	ld	s10,976(sp)
    80005bbe:	3c813d83          	ld	s11,968(sp)
    80005bc2:	43010113          	addi	sp,sp,1072
    80005bc6:	8082                	ret
    end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	210080e7          	jalr	528(ra) # 80004dd8 <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	bf75                	j	80005b8e <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005bd4:	c0843503          	ld	a0,-1016(s0)
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	f02080e7          	jalr	-254(ra) # 80001ada <proc_pagetable>
    80005be0:	8b2a                	mv	s6,a0
    80005be2:	d935                	beqz	a0,80005b56 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005be4:	e6842783          	lw	a5,-408(s0)
    80005be8:	e8045703          	lhu	a4,-384(s0)
    80005bec:	c735                	beqz	a4,80005c58 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005bee:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005bf0:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005bf4:	6a85                	lui	s5,0x1
    80005bf6:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005bfa:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005bfe:	6d85                	lui	s11,0x1
    80005c00:	7d7d                	lui	s10,0xfffff
    80005c02:	a4ad                	j	80005e6c <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005c04:	00004517          	auipc	a0,0x4
    80005c08:	f7450513          	addi	a0,a0,-140 # 80009b78 <syscalls+0x2f0>
    80005c0c:	ffffb097          	auipc	ra,0xffffb
    80005c10:	91e080e7          	jalr	-1762(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005c14:	874a                	mv	a4,s2
    80005c16:	009c86bb          	addw	a3,s9,s1
    80005c1a:	4581                	li	a1,0
    80005c1c:	8552                	mv	a0,s4
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	706080e7          	jalr	1798(ra) # 80004324 <readi>
    80005c26:	2501                	sext.w	a0,a0
    80005c28:	1aa91c63          	bne	s2,a0,80005de0 <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005c2c:	009d84bb          	addw	s1,s11,s1
    80005c30:	013d09bb          	addw	s3,s10,s3
    80005c34:	2174fc63          	bgeu	s1,s7,80005e4c <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005c38:	02049593          	slli	a1,s1,0x20
    80005c3c:	9181                	srli	a1,a1,0x20
    80005c3e:	95e2                	add	a1,a1,s8
    80005c40:	855a                	mv	a0,s6
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	41c080e7          	jalr	1052(ra) # 8000105e <walkaddr>
    80005c4a:	862a                	mv	a2,a0
    if(pa == 0)
    80005c4c:	dd45                	beqz	a0,80005c04 <exec+0x198>
      n = PGSIZE;
    80005c4e:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005c50:	fd59f2e3          	bgeu	s3,s5,80005c14 <exec+0x1a8>
      n = sz - i;
    80005c54:	894e                	mv	s2,s3
    80005c56:	bf7d                	j	80005c14 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005c58:	4481                	li	s1,0
  iunlockput(ip);
    80005c5a:	8552                	mv	a0,s4
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	676080e7          	jalr	1654(ra) # 800042d2 <iunlockput>
  end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	174080e7          	jalr	372(ra) # 80004dd8 <end_op>
  p = myproc();
    80005c6c:	ffffc097          	auipc	ra,0xffffc
    80005c70:	daa080e7          	jalr	-598(ra) # 80001a16 <myproc>
    80005c74:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005c78:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005c7c:	6785                	lui	a5,0x1
    80005c7e:	17fd                	addi	a5,a5,-1
    80005c80:	94be                	add	s1,s1,a5
    80005c82:	77fd                	lui	a5,0xfffff
    80005c84:	8fe5                	and	a5,a5,s1
    80005c86:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005c8a:	6609                	lui	a2,0x2
    80005c8c:	963e                	add	a2,a2,a5
    80005c8e:	85be                	mv	a1,a5
    80005c90:	855a                	mv	a0,s6
    80005c92:	ffffb097          	auipc	ra,0xffffb
    80005c96:	7d4080e7          	jalr	2004(ra) # 80001466 <uvmalloc>
    80005c9a:	8aaa                	mv	s5,a0
  ip = 0;
    80005c9c:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005c9e:	14050163          	beqz	a0,80005de0 <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005ca2:	75f9                	lui	a1,0xffffe
    80005ca4:	95aa                	add	a1,a1,a0
    80005ca6:	855a                	mv	a0,s6
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	9fc080e7          	jalr	-1540(ra) # 800016a4 <uvmclear>
  stackbase = sp - PGSIZE;
    80005cb0:	7bfd                	lui	s7,0xfffff
    80005cb2:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005cb4:	be843783          	ld	a5,-1048(s0)
    80005cb8:	6388                	ld	a0,0(a5)
    80005cba:	c925                	beqz	a0,80005d2a <exec+0x2be>
    80005cbc:	e8840993          	addi	s3,s0,-376
    80005cc0:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005cc4:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005cc6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005cc8:	ffffb097          	auipc	ra,0xffffb
    80005ccc:	18c080e7          	jalr	396(ra) # 80000e54 <strlen>
    80005cd0:	0015079b          	addiw	a5,a0,1
    80005cd4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005cd8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005cdc:	15796c63          	bltu	s2,s7,80005e34 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005ce0:	be843d03          	ld	s10,-1048(s0)
    80005ce4:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005ce8:	8552                	mv	a0,s4
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	16a080e7          	jalr	362(ra) # 80000e54 <strlen>
    80005cf2:	0015069b          	addiw	a3,a0,1
    80005cf6:	8652                	mv	a2,s4
    80005cf8:	85ca                	mv	a1,s2
    80005cfa:	855a                	mv	a0,s6
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	9da080e7          	jalr	-1574(ra) # 800016d6 <copyout>
    80005d04:	12054c63          	bltz	a0,80005e3c <exec+0x3d0>
    ustack[argc] = sp;
    80005d08:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005d0c:	0485                	addi	s1,s1,1
    80005d0e:	008d0793          	addi	a5,s10,8
    80005d12:	bef43423          	sd	a5,-1048(s0)
    80005d16:	008d3503          	ld	a0,8(s10)
    80005d1a:	c911                	beqz	a0,80005d2e <exec+0x2c2>
    if(argc >= MAXARG)
    80005d1c:	09a1                	addi	s3,s3,8
    80005d1e:	fb8995e3          	bne	s3,s8,80005cc8 <exec+0x25c>
  sz = sz1;
    80005d22:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d26:	4a01                	li	s4,0
    80005d28:	a865                	j	80005de0 <exec+0x374>
  sp = sz;
    80005d2a:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005d2c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005d2e:	00349793          	slli	a5,s1,0x3
    80005d32:	f9040713          	addi	a4,s0,-112
    80005d36:	97ba                	add	a5,a5,a4
    80005d38:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005d3c:	00148693          	addi	a3,s1,1
    80005d40:	068e                	slli	a3,a3,0x3
    80005d42:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005d46:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005d4a:	01797663          	bgeu	s2,s7,80005d56 <exec+0x2ea>
  sz = sz1;
    80005d4e:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d52:	4a01                	li	s4,0
    80005d54:	a071                	j	80005de0 <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005d56:	e8840613          	addi	a2,s0,-376
    80005d5a:	85ca                	mv	a1,s2
    80005d5c:	855a                	mv	a0,s6
    80005d5e:	ffffc097          	auipc	ra,0xffffc
    80005d62:	978080e7          	jalr	-1672(ra) # 800016d6 <copyout>
    80005d66:	0c054f63          	bltz	a0,80005e44 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005d6a:	c0843783          	ld	a5,-1016(s0)
    80005d6e:	6fbc                	ld	a5,88(a5)
    80005d70:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005d74:	be043783          	ld	a5,-1056(s0)
    80005d78:	0007c703          	lbu	a4,0(a5)
    80005d7c:	cf11                	beqz	a4,80005d98 <exec+0x32c>
    80005d7e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005d80:	02f00693          	li	a3,47
    80005d84:	a039                	j	80005d92 <exec+0x326>
      last = s+1;
    80005d86:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005d8a:	0785                	addi	a5,a5,1
    80005d8c:	fff7c703          	lbu	a4,-1(a5)
    80005d90:	c701                	beqz	a4,80005d98 <exec+0x32c>
    if(*s == '/')
    80005d92:	fed71ce3          	bne	a4,a3,80005d8a <exec+0x31e>
    80005d96:	bfc5                	j	80005d86 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005d98:	4641                	li	a2,16
    80005d9a:	be043583          	ld	a1,-1056(s0)
    80005d9e:	c0843983          	ld	s3,-1016(s0)
    80005da2:	15898513          	addi	a0,s3,344
    80005da6:	ffffb097          	auipc	ra,0xffffb
    80005daa:	07c080e7          	jalr	124(ra) # 80000e22 <safestrcpy>
  oldpagetable = p->pagetable;
    80005dae:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005db2:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005db6:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005dba:	0589b783          	ld	a5,88(s3)
    80005dbe:	e6043703          	ld	a4,-416(s0)
    80005dc2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005dc4:	0589b783          	ld	a5,88(s3)
    80005dc8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005dcc:	85e6                	mv	a1,s9
    80005dce:	ffffc097          	auipc	ra,0xffffc
    80005dd2:	da8080e7          	jalr	-600(ra) # 80001b76 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005dd6:	0004851b          	sext.w	a0,s1
    80005dda:	bb55                	j	80005b8e <exec+0x122>
    80005ddc:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005de0:	10000613          	li	a2,256
    80005de4:	d1040593          	addi	a1,s0,-752
    80005de8:	c0843483          	ld	s1,-1016(s0)
    80005dec:	17048513          	addi	a0,s1,368
    80005df0:	ffffb097          	auipc	ra,0xffffb
    80005df4:	f3c080e7          	jalr	-196(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005df8:	10000613          	li	a2,256
    80005dfc:	c1040593          	addi	a1,s0,-1008
    80005e00:	27048513          	addi	a0,s1,624
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	f28080e7          	jalr	-216(ra) # 80000d2c <memmove>
    proc_freepagetable(pagetable, sz);
    80005e0c:	bf043583          	ld	a1,-1040(s0)
    80005e10:	855a                	mv	a0,s6
    80005e12:	ffffc097          	auipc	ra,0xffffc
    80005e16:	d64080e7          	jalr	-668(ra) # 80001b76 <proc_freepagetable>
  if(ip){
    80005e1a:	d60a10e3          	bnez	s4,80005b7a <exec+0x10e>
  return -1;
    80005e1e:	557d                	li	a0,-1
    80005e20:	b3bd                	j	80005b8e <exec+0x122>
    80005e22:	be943823          	sd	s1,-1040(s0)
    80005e26:	bf6d                	j	80005de0 <exec+0x374>
    80005e28:	be943823          	sd	s1,-1040(s0)
    80005e2c:	bf55                	j	80005de0 <exec+0x374>
    80005e2e:	be943823          	sd	s1,-1040(s0)
    80005e32:	b77d                	j	80005de0 <exec+0x374>
  sz = sz1;
    80005e34:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005e38:	4a01                	li	s4,0
    80005e3a:	b75d                	j	80005de0 <exec+0x374>
  sz = sz1;
    80005e3c:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005e40:	4a01                	li	s4,0
    80005e42:	bf79                	j	80005de0 <exec+0x374>
  sz = sz1;
    80005e44:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005e48:	4a01                	li	s4,0
    80005e4a:	bf59                	j	80005de0 <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005e4c:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005e50:	c0043783          	ld	a5,-1024(s0)
    80005e54:	0017869b          	addiw	a3,a5,1
    80005e58:	c0d43023          	sd	a3,-1024(s0)
    80005e5c:	bf843783          	ld	a5,-1032(s0)
    80005e60:	0387879b          	addiw	a5,a5,56
    80005e64:	e8045703          	lhu	a4,-384(s0)
    80005e68:	dee6d9e3          	bge	a3,a4,80005c5a <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005e6c:	2781                	sext.w	a5,a5
    80005e6e:	bef43c23          	sd	a5,-1032(s0)
    80005e72:	03800713          	li	a4,56
    80005e76:	86be                	mv	a3,a5
    80005e78:	e1040613          	addi	a2,s0,-496
    80005e7c:	4581                	li	a1,0
    80005e7e:	8552                	mv	a0,s4
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	4a4080e7          	jalr	1188(ra) # 80004324 <readi>
    80005e88:	03800793          	li	a5,56
    80005e8c:	f4f518e3          	bne	a0,a5,80005ddc <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005e90:	e1042783          	lw	a5,-496(s0)
    80005e94:	4705                	li	a4,1
    80005e96:	fae79de3          	bne	a5,a4,80005e50 <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005e9a:	e3843603          	ld	a2,-456(s0)
    80005e9e:	e3043783          	ld	a5,-464(s0)
    80005ea2:	f8f660e3          	bltu	a2,a5,80005e22 <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005ea6:	e2043783          	ld	a5,-480(s0)
    80005eaa:	963e                	add	a2,a2,a5
    80005eac:	f6f66ee3          	bltu	a2,a5,80005e28 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005eb0:	85a6                	mv	a1,s1
    80005eb2:	855a                	mv	a0,s6
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	5b2080e7          	jalr	1458(ra) # 80001466 <uvmalloc>
    80005ebc:	bea43823          	sd	a0,-1040(s0)
    80005ec0:	d53d                	beqz	a0,80005e2e <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005ec2:	e2043c03          	ld	s8,-480(s0)
    80005ec6:	bd843783          	ld	a5,-1064(s0)
    80005eca:	00fc77b3          	and	a5,s8,a5
    80005ece:	fb89                	bnez	a5,80005de0 <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005ed0:	e1842c83          	lw	s9,-488(s0)
    80005ed4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005ed8:	f60b8ae3          	beqz	s7,80005e4c <exec+0x3e0>
    80005edc:	89de                	mv	s3,s7
    80005ede:	4481                	li	s1,0
    80005ee0:	bba1                	j	80005c38 <exec+0x1cc>

0000000080005ee2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005ee2:	7179                	addi	sp,sp,-48
    80005ee4:	f406                	sd	ra,40(sp)
    80005ee6:	f022                	sd	s0,32(sp)
    80005ee8:	ec26                	sd	s1,24(sp)
    80005eea:	e84a                	sd	s2,16(sp)
    80005eec:	1800                	addi	s0,sp,48
    80005eee:	892e                	mv	s2,a1
    80005ef0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005ef2:	fdc40593          	addi	a1,s0,-36
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	608080e7          	jalr	1544(ra) # 800034fe <argint>
    80005efe:	04054063          	bltz	a0,80005f3e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005f02:	fdc42703          	lw	a4,-36(s0)
    80005f06:	47bd                	li	a5,15
    80005f08:	02e7ed63          	bltu	a5,a4,80005f42 <argfd+0x60>
    80005f0c:	ffffc097          	auipc	ra,0xffffc
    80005f10:	b0a080e7          	jalr	-1270(ra) # 80001a16 <myproc>
    80005f14:	fdc42703          	lw	a4,-36(s0)
    80005f18:	01a70793          	addi	a5,a4,26
    80005f1c:	078e                	slli	a5,a5,0x3
    80005f1e:	953e                	add	a0,a0,a5
    80005f20:	611c                	ld	a5,0(a0)
    80005f22:	c395                	beqz	a5,80005f46 <argfd+0x64>
    return -1;
  if(pfd)
    80005f24:	00090463          	beqz	s2,80005f2c <argfd+0x4a>
    *pfd = fd;
    80005f28:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005f2c:	4501                	li	a0,0
  if(pf)
    80005f2e:	c091                	beqz	s1,80005f32 <argfd+0x50>
    *pf = f;
    80005f30:	e09c                	sd	a5,0(s1)
}
    80005f32:	70a2                	ld	ra,40(sp)
    80005f34:	7402                	ld	s0,32(sp)
    80005f36:	64e2                	ld	s1,24(sp)
    80005f38:	6942                	ld	s2,16(sp)
    80005f3a:	6145                	addi	sp,sp,48
    80005f3c:	8082                	ret
    return -1;
    80005f3e:	557d                	li	a0,-1
    80005f40:	bfcd                	j	80005f32 <argfd+0x50>
    return -1;
    80005f42:	557d                	li	a0,-1
    80005f44:	b7fd                	j	80005f32 <argfd+0x50>
    80005f46:	557d                	li	a0,-1
    80005f48:	b7ed                	j	80005f32 <argfd+0x50>

0000000080005f4a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005f4a:	1101                	addi	sp,sp,-32
    80005f4c:	ec06                	sd	ra,24(sp)
    80005f4e:	e822                	sd	s0,16(sp)
    80005f50:	e426                	sd	s1,8(sp)
    80005f52:	1000                	addi	s0,sp,32
    80005f54:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005f56:	ffffc097          	auipc	ra,0xffffc
    80005f5a:	ac0080e7          	jalr	-1344(ra) # 80001a16 <myproc>
    80005f5e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005f60:	0d050793          	addi	a5,a0,208
    80005f64:	4501                	li	a0,0
    80005f66:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005f68:	6398                	ld	a4,0(a5)
    80005f6a:	cb19                	beqz	a4,80005f80 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005f6c:	2505                	addiw	a0,a0,1
    80005f6e:	07a1                	addi	a5,a5,8
    80005f70:	fed51ce3          	bne	a0,a3,80005f68 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005f74:	557d                	li	a0,-1
}
    80005f76:	60e2                	ld	ra,24(sp)
    80005f78:	6442                	ld	s0,16(sp)
    80005f7a:	64a2                	ld	s1,8(sp)
    80005f7c:	6105                	addi	sp,sp,32
    80005f7e:	8082                	ret
      p->ofile[fd] = f;
    80005f80:	01a50793          	addi	a5,a0,26
    80005f84:	078e                	slli	a5,a5,0x3
    80005f86:	963e                	add	a2,a2,a5
    80005f88:	e204                	sd	s1,0(a2)
      return fd;
    80005f8a:	b7f5                	j	80005f76 <fdalloc+0x2c>

0000000080005f8c <sys_dup>:

uint64
sys_dup(void)
{
    80005f8c:	7179                	addi	sp,sp,-48
    80005f8e:	f406                	sd	ra,40(sp)
    80005f90:	f022                	sd	s0,32(sp)
    80005f92:	ec26                	sd	s1,24(sp)
    80005f94:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005f96:	fd840613          	addi	a2,s0,-40
    80005f9a:	4581                	li	a1,0
    80005f9c:	4501                	li	a0,0
    80005f9e:	00000097          	auipc	ra,0x0
    80005fa2:	f44080e7          	jalr	-188(ra) # 80005ee2 <argfd>
    return -1;
    80005fa6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005fa8:	02054363          	bltz	a0,80005fce <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005fac:	fd843503          	ld	a0,-40(s0)
    80005fb0:	00000097          	auipc	ra,0x0
    80005fb4:	f9a080e7          	jalr	-102(ra) # 80005f4a <fdalloc>
    80005fb8:	84aa                	mv	s1,a0
    return -1;
    80005fba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005fbc:	00054963          	bltz	a0,80005fce <sys_dup+0x42>
  filedup(f);
    80005fc0:	fd843503          	ld	a0,-40(s0)
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	20e080e7          	jalr	526(ra) # 800051d2 <filedup>
  return fd;
    80005fcc:	87a6                	mv	a5,s1
}
    80005fce:	853e                	mv	a0,a5
    80005fd0:	70a2                	ld	ra,40(sp)
    80005fd2:	7402                	ld	s0,32(sp)
    80005fd4:	64e2                	ld	s1,24(sp)
    80005fd6:	6145                	addi	sp,sp,48
    80005fd8:	8082                	ret

0000000080005fda <sys_read>:

uint64
sys_read(void)
{
    80005fda:	7179                	addi	sp,sp,-48
    80005fdc:	f406                	sd	ra,40(sp)
    80005fde:	f022                	sd	s0,32(sp)
    80005fe0:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fe2:	fe840613          	addi	a2,s0,-24
    80005fe6:	4581                	li	a1,0
    80005fe8:	4501                	li	a0,0
    80005fea:	00000097          	auipc	ra,0x0
    80005fee:	ef8080e7          	jalr	-264(ra) # 80005ee2 <argfd>
    return -1;
    80005ff2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ff4:	04054163          	bltz	a0,80006036 <sys_read+0x5c>
    80005ff8:	fe440593          	addi	a1,s0,-28
    80005ffc:	4509                	li	a0,2
    80005ffe:	ffffd097          	auipc	ra,0xffffd
    80006002:	500080e7          	jalr	1280(ra) # 800034fe <argint>
    return -1;
    80006006:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006008:	02054763          	bltz	a0,80006036 <sys_read+0x5c>
    8000600c:	fd840593          	addi	a1,s0,-40
    80006010:	4505                	li	a0,1
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	50e080e7          	jalr	1294(ra) # 80003520 <argaddr>
    return -1;
    8000601a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000601c:	00054d63          	bltz	a0,80006036 <sys_read+0x5c>
  return fileread(f, p, n);
    80006020:	fe442603          	lw	a2,-28(s0)
    80006024:	fd843583          	ld	a1,-40(s0)
    80006028:	fe843503          	ld	a0,-24(s0)
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	332080e7          	jalr	818(ra) # 8000535e <fileread>
    80006034:	87aa                	mv	a5,a0
}
    80006036:	853e                	mv	a0,a5
    80006038:	70a2                	ld	ra,40(sp)
    8000603a:	7402                	ld	s0,32(sp)
    8000603c:	6145                	addi	sp,sp,48
    8000603e:	8082                	ret

0000000080006040 <sys_write>:

uint64
sys_write(void)
{
    80006040:	7179                	addi	sp,sp,-48
    80006042:	f406                	sd	ra,40(sp)
    80006044:	f022                	sd	s0,32(sp)
    80006046:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006048:	fe840613          	addi	a2,s0,-24
    8000604c:	4581                	li	a1,0
    8000604e:	4501                	li	a0,0
    80006050:	00000097          	auipc	ra,0x0
    80006054:	e92080e7          	jalr	-366(ra) # 80005ee2 <argfd>
    return -1;
    80006058:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000605a:	04054163          	bltz	a0,8000609c <sys_write+0x5c>
    8000605e:	fe440593          	addi	a1,s0,-28
    80006062:	4509                	li	a0,2
    80006064:	ffffd097          	auipc	ra,0xffffd
    80006068:	49a080e7          	jalr	1178(ra) # 800034fe <argint>
    return -1;
    8000606c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000606e:	02054763          	bltz	a0,8000609c <sys_write+0x5c>
    80006072:	fd840593          	addi	a1,s0,-40
    80006076:	4505                	li	a0,1
    80006078:	ffffd097          	auipc	ra,0xffffd
    8000607c:	4a8080e7          	jalr	1192(ra) # 80003520 <argaddr>
    return -1;
    80006080:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006082:	00054d63          	bltz	a0,8000609c <sys_write+0x5c>

  return filewrite(f, p, n);
    80006086:	fe442603          	lw	a2,-28(s0)
    8000608a:	fd843583          	ld	a1,-40(s0)
    8000608e:	fe843503          	ld	a0,-24(s0)
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	38e080e7          	jalr	910(ra) # 80005420 <filewrite>
    8000609a:	87aa                	mv	a5,a0
}
    8000609c:	853e                	mv	a0,a5
    8000609e:	70a2                	ld	ra,40(sp)
    800060a0:	7402                	ld	s0,32(sp)
    800060a2:	6145                	addi	sp,sp,48
    800060a4:	8082                	ret

00000000800060a6 <sys_close>:

uint64
sys_close(void)
{
    800060a6:	1101                	addi	sp,sp,-32
    800060a8:	ec06                	sd	ra,24(sp)
    800060aa:	e822                	sd	s0,16(sp)
    800060ac:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    800060ae:	fe040613          	addi	a2,s0,-32
    800060b2:	fec40593          	addi	a1,s0,-20
    800060b6:	4501                	li	a0,0
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	e2a080e7          	jalr	-470(ra) # 80005ee2 <argfd>
    return -1;
    800060c0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800060c2:	02054463          	bltz	a0,800060ea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800060c6:	ffffc097          	auipc	ra,0xffffc
    800060ca:	950080e7          	jalr	-1712(ra) # 80001a16 <myproc>
    800060ce:	fec42783          	lw	a5,-20(s0)
    800060d2:	07e9                	addi	a5,a5,26
    800060d4:	078e                	slli	a5,a5,0x3
    800060d6:	97aa                	add	a5,a5,a0
    800060d8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800060dc:	fe043503          	ld	a0,-32(s0)
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	144080e7          	jalr	324(ra) # 80005224 <fileclose>
  return 0;
    800060e8:	4781                	li	a5,0
}
    800060ea:	853e                	mv	a0,a5
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	6105                	addi	sp,sp,32
    800060f2:	8082                	ret

00000000800060f4 <sys_fstat>:

uint64
sys_fstat(void)
{
    800060f4:	1101                	addi	sp,sp,-32
    800060f6:	ec06                	sd	ra,24(sp)
    800060f8:	e822                	sd	s0,16(sp)
    800060fa:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800060fc:	fe840613          	addi	a2,s0,-24
    80006100:	4581                	li	a1,0
    80006102:	4501                	li	a0,0
    80006104:	00000097          	auipc	ra,0x0
    80006108:	dde080e7          	jalr	-546(ra) # 80005ee2 <argfd>
    return -1;
    8000610c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000610e:	02054563          	bltz	a0,80006138 <sys_fstat+0x44>
    80006112:	fe040593          	addi	a1,s0,-32
    80006116:	4505                	li	a0,1
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	408080e7          	jalr	1032(ra) # 80003520 <argaddr>
    return -1;
    80006120:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006122:	00054b63          	bltz	a0,80006138 <sys_fstat+0x44>
  return filestat(f, st);
    80006126:	fe043583          	ld	a1,-32(s0)
    8000612a:	fe843503          	ld	a0,-24(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	1be080e7          	jalr	446(ra) # 800052ec <filestat>
    80006136:	87aa                	mv	a5,a0
}
    80006138:	853e                	mv	a0,a5
    8000613a:	60e2                	ld	ra,24(sp)
    8000613c:	6442                	ld	s0,16(sp)
    8000613e:	6105                	addi	sp,sp,32
    80006140:	8082                	ret

0000000080006142 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80006142:	7169                	addi	sp,sp,-304
    80006144:	f606                	sd	ra,296(sp)
    80006146:	f222                	sd	s0,288(sp)
    80006148:	ee26                	sd	s1,280(sp)
    8000614a:	ea4a                	sd	s2,272(sp)
    8000614c:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000614e:	08000613          	li	a2,128
    80006152:	ed040593          	addi	a1,s0,-304
    80006156:	4501                	li	a0,0
    80006158:	ffffd097          	auipc	ra,0xffffd
    8000615c:	3ea080e7          	jalr	1002(ra) # 80003542 <argstr>
    return -1;
    80006160:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006162:	10054e63          	bltz	a0,8000627e <sys_link+0x13c>
    80006166:	08000613          	li	a2,128
    8000616a:	f5040593          	addi	a1,s0,-176
    8000616e:	4505                	li	a0,1
    80006170:	ffffd097          	auipc	ra,0xffffd
    80006174:	3d2080e7          	jalr	978(ra) # 80003542 <argstr>
    return -1;
    80006178:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000617a:	10054263          	bltz	a0,8000627e <sys_link+0x13c>

  begin_op();
    8000617e:	fffff097          	auipc	ra,0xfffff
    80006182:	bda080e7          	jalr	-1062(ra) # 80004d58 <begin_op>
  if((ip = namei(old)) == 0){
    80006186:	ed040513          	addi	a0,s0,-304
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	69c080e7          	jalr	1692(ra) # 80004826 <namei>
    80006192:	84aa                	mv	s1,a0
    80006194:	c551                	beqz	a0,80006220 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80006196:	ffffe097          	auipc	ra,0xffffe
    8000619a:	eda080e7          	jalr	-294(ra) # 80004070 <ilock>
  if(ip->type == T_DIR){
    8000619e:	04449703          	lh	a4,68(s1)
    800061a2:	4785                	li	a5,1
    800061a4:	08f70463          	beq	a4,a5,8000622c <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    800061a8:	04a4d783          	lhu	a5,74(s1)
    800061ac:	2785                	addiw	a5,a5,1
    800061ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800061b2:	8526                	mv	a0,s1
    800061b4:	ffffe097          	auipc	ra,0xffffe
    800061b8:	df2080e7          	jalr	-526(ra) # 80003fa6 <iupdate>
  iunlock(ip);
    800061bc:	8526                	mv	a0,s1
    800061be:	ffffe097          	auipc	ra,0xffffe
    800061c2:	f74080e7          	jalr	-140(ra) # 80004132 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    800061c6:	fd040593          	addi	a1,s0,-48
    800061ca:	f5040513          	addi	a0,s0,-176
    800061ce:	ffffe097          	auipc	ra,0xffffe
    800061d2:	676080e7          	jalr	1654(ra) # 80004844 <nameiparent>
    800061d6:	892a                	mv	s2,a0
    800061d8:	c935                	beqz	a0,8000624c <sys_link+0x10a>
    goto bad;
  ilock(dp);
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	e96080e7          	jalr	-362(ra) # 80004070 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800061e2:	00092703          	lw	a4,0(s2)
    800061e6:	409c                	lw	a5,0(s1)
    800061e8:	04f71d63          	bne	a4,a5,80006242 <sys_link+0x100>
    800061ec:	40d0                	lw	a2,4(s1)
    800061ee:	fd040593          	addi	a1,s0,-48
    800061f2:	854a                	mv	a0,s2
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	570080e7          	jalr	1392(ra) # 80004764 <dirlink>
    800061fc:	04054363          	bltz	a0,80006242 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80006200:	854a                	mv	a0,s2
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	0d0080e7          	jalr	208(ra) # 800042d2 <iunlockput>
  iput(ip);
    8000620a:	8526                	mv	a0,s1
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	01e080e7          	jalr	30(ra) # 8000422a <iput>

  end_op();
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	bc4080e7          	jalr	-1084(ra) # 80004dd8 <end_op>

  return 0;
    8000621c:	4781                	li	a5,0
    8000621e:	a085                	j	8000627e <sys_link+0x13c>
    end_op();
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	bb8080e7          	jalr	-1096(ra) # 80004dd8 <end_op>
    return -1;
    80006228:	57fd                	li	a5,-1
    8000622a:	a891                	j	8000627e <sys_link+0x13c>
    iunlockput(ip);
    8000622c:	8526                	mv	a0,s1
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	0a4080e7          	jalr	164(ra) # 800042d2 <iunlockput>
    end_op();
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	ba2080e7          	jalr	-1118(ra) # 80004dd8 <end_op>
    return -1;
    8000623e:	57fd                	li	a5,-1
    80006240:	a83d                	j	8000627e <sys_link+0x13c>
    iunlockput(dp);
    80006242:	854a                	mv	a0,s2
    80006244:	ffffe097          	auipc	ra,0xffffe
    80006248:	08e080e7          	jalr	142(ra) # 800042d2 <iunlockput>

bad:
  ilock(ip);
    8000624c:	8526                	mv	a0,s1
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	e22080e7          	jalr	-478(ra) # 80004070 <ilock>
  ip->nlink--;
    80006256:	04a4d783          	lhu	a5,74(s1)
    8000625a:	37fd                	addiw	a5,a5,-1
    8000625c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006260:	8526                	mv	a0,s1
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	d44080e7          	jalr	-700(ra) # 80003fa6 <iupdate>
  iunlockput(ip);
    8000626a:	8526                	mv	a0,s1
    8000626c:	ffffe097          	auipc	ra,0xffffe
    80006270:	066080e7          	jalr	102(ra) # 800042d2 <iunlockput>
  end_op();
    80006274:	fffff097          	auipc	ra,0xfffff
    80006278:	b64080e7          	jalr	-1180(ra) # 80004dd8 <end_op>
  return -1;
    8000627c:	57fd                	li	a5,-1
}
    8000627e:	853e                	mv	a0,a5
    80006280:	70b2                	ld	ra,296(sp)
    80006282:	7412                	ld	s0,288(sp)
    80006284:	64f2                	ld	s1,280(sp)
    80006286:	6952                	ld	s2,272(sp)
    80006288:	6155                	addi	sp,sp,304
    8000628a:	8082                	ret

000000008000628c <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000628c:	4578                	lw	a4,76(a0)
    8000628e:	02000793          	li	a5,32
    80006292:	04e7fa63          	bgeu	a5,a4,800062e6 <isdirempty+0x5a>
{
    80006296:	7179                	addi	sp,sp,-48
    80006298:	f406                	sd	ra,40(sp)
    8000629a:	f022                	sd	s0,32(sp)
    8000629c:	ec26                	sd	s1,24(sp)
    8000629e:	e84a                	sd	s2,16(sp)
    800062a0:	1800                	addi	s0,sp,48
    800062a2:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062a4:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062a8:	4741                	li	a4,16
    800062aa:	86a6                	mv	a3,s1
    800062ac:	fd040613          	addi	a2,s0,-48
    800062b0:	4581                	li	a1,0
    800062b2:	854a                	mv	a0,s2
    800062b4:	ffffe097          	auipc	ra,0xffffe
    800062b8:	070080e7          	jalr	112(ra) # 80004324 <readi>
    800062bc:	47c1                	li	a5,16
    800062be:	00f51c63          	bne	a0,a5,800062d6 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800062c2:	fd045783          	lhu	a5,-48(s0)
    800062c6:	e395                	bnez	a5,800062ea <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062c8:	24c1                	addiw	s1,s1,16
    800062ca:	04c92783          	lw	a5,76(s2)
    800062ce:	fcf4ede3          	bltu	s1,a5,800062a8 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    800062d2:	4505                	li	a0,1
    800062d4:	a821                	j	800062ec <isdirempty+0x60>
      panic("isdirempty: readi");
    800062d6:	00004517          	auipc	a0,0x4
    800062da:	8c250513          	addi	a0,a0,-1854 # 80009b98 <syscalls+0x310>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	24c080e7          	jalr	588(ra) # 8000052a <panic>
  return 1;
    800062e6:	4505                	li	a0,1
}
    800062e8:	8082                	ret
      return 0;
    800062ea:	4501                	li	a0,0
}
    800062ec:	70a2                	ld	ra,40(sp)
    800062ee:	7402                	ld	s0,32(sp)
    800062f0:	64e2                	ld	s1,24(sp)
    800062f2:	6942                	ld	s2,16(sp)
    800062f4:	6145                	addi	sp,sp,48
    800062f6:	8082                	ret

00000000800062f8 <sys_unlink>:

uint64
sys_unlink(void)
{
    800062f8:	7155                	addi	sp,sp,-208
    800062fa:	e586                	sd	ra,200(sp)
    800062fc:	e1a2                	sd	s0,192(sp)
    800062fe:	fd26                	sd	s1,184(sp)
    80006300:	f94a                	sd	s2,176(sp)
    80006302:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006304:	08000613          	li	a2,128
    80006308:	f4040593          	addi	a1,s0,-192
    8000630c:	4501                	li	a0,0
    8000630e:	ffffd097          	auipc	ra,0xffffd
    80006312:	234080e7          	jalr	564(ra) # 80003542 <argstr>
    80006316:	16054363          	bltz	a0,8000647c <sys_unlink+0x184>
    return -1;

  begin_op();
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	a3e080e7          	jalr	-1474(ra) # 80004d58 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006322:	fc040593          	addi	a1,s0,-64
    80006326:	f4040513          	addi	a0,s0,-192
    8000632a:	ffffe097          	auipc	ra,0xffffe
    8000632e:	51a080e7          	jalr	1306(ra) # 80004844 <nameiparent>
    80006332:	84aa                	mv	s1,a0
    80006334:	c961                	beqz	a0,80006404 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006336:	ffffe097          	auipc	ra,0xffffe
    8000633a:	d3a080e7          	jalr	-710(ra) # 80004070 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000633e:	00003597          	auipc	a1,0x3
    80006342:	73a58593          	addi	a1,a1,1850 # 80009a78 <syscalls+0x1f0>
    80006346:	fc040513          	addi	a0,s0,-64
    8000634a:	ffffe097          	auipc	ra,0xffffe
    8000634e:	1f0080e7          	jalr	496(ra) # 8000453a <namecmp>
    80006352:	c175                	beqz	a0,80006436 <sys_unlink+0x13e>
    80006354:	00003597          	auipc	a1,0x3
    80006358:	72c58593          	addi	a1,a1,1836 # 80009a80 <syscalls+0x1f8>
    8000635c:	fc040513          	addi	a0,s0,-64
    80006360:	ffffe097          	auipc	ra,0xffffe
    80006364:	1da080e7          	jalr	474(ra) # 8000453a <namecmp>
    80006368:	c579                	beqz	a0,80006436 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    8000636a:	f3c40613          	addi	a2,s0,-196
    8000636e:	fc040593          	addi	a1,s0,-64
    80006372:	8526                	mv	a0,s1
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	1e0080e7          	jalr	480(ra) # 80004554 <dirlookup>
    8000637c:	892a                	mv	s2,a0
    8000637e:	cd45                	beqz	a0,80006436 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80006380:	ffffe097          	auipc	ra,0xffffe
    80006384:	cf0080e7          	jalr	-784(ra) # 80004070 <ilock>

  if(ip->nlink < 1)
    80006388:	04a91783          	lh	a5,74(s2)
    8000638c:	08f05263          	blez	a5,80006410 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006390:	04491703          	lh	a4,68(s2)
    80006394:	4785                	li	a5,1
    80006396:	08f70563          	beq	a4,a5,80006420 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    8000639a:	4641                	li	a2,16
    8000639c:	4581                	li	a1,0
    8000639e:	fd040513          	addi	a0,s0,-48
    800063a2:	ffffb097          	auipc	ra,0xffffb
    800063a6:	92e080e7          	jalr	-1746(ra) # 80000cd0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800063aa:	4741                	li	a4,16
    800063ac:	f3c42683          	lw	a3,-196(s0)
    800063b0:	fd040613          	addi	a2,s0,-48
    800063b4:	4581                	li	a1,0
    800063b6:	8526                	mv	a0,s1
    800063b8:	ffffe097          	auipc	ra,0xffffe
    800063bc:	064080e7          	jalr	100(ra) # 8000441c <writei>
    800063c0:	47c1                	li	a5,16
    800063c2:	08f51a63          	bne	a0,a5,80006456 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800063c6:	04491703          	lh	a4,68(s2)
    800063ca:	4785                	li	a5,1
    800063cc:	08f70d63          	beq	a4,a5,80006466 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800063d0:	8526                	mv	a0,s1
    800063d2:	ffffe097          	auipc	ra,0xffffe
    800063d6:	f00080e7          	jalr	-256(ra) # 800042d2 <iunlockput>

  ip->nlink--;
    800063da:	04a95783          	lhu	a5,74(s2)
    800063de:	37fd                	addiw	a5,a5,-1
    800063e0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800063e4:	854a                	mv	a0,s2
    800063e6:	ffffe097          	auipc	ra,0xffffe
    800063ea:	bc0080e7          	jalr	-1088(ra) # 80003fa6 <iupdate>
  iunlockput(ip);
    800063ee:	854a                	mv	a0,s2
    800063f0:	ffffe097          	auipc	ra,0xffffe
    800063f4:	ee2080e7          	jalr	-286(ra) # 800042d2 <iunlockput>

  end_op();
    800063f8:	fffff097          	auipc	ra,0xfffff
    800063fc:	9e0080e7          	jalr	-1568(ra) # 80004dd8 <end_op>

  return 0;
    80006400:	4501                	li	a0,0
    80006402:	a0a1                	j	8000644a <sys_unlink+0x152>
    end_op();
    80006404:	fffff097          	auipc	ra,0xfffff
    80006408:	9d4080e7          	jalr	-1580(ra) # 80004dd8 <end_op>
    return -1;
    8000640c:	557d                	li	a0,-1
    8000640e:	a835                	j	8000644a <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80006410:	00003517          	auipc	a0,0x3
    80006414:	67850513          	addi	a0,a0,1656 # 80009a88 <syscalls+0x200>
    80006418:	ffffa097          	auipc	ra,0xffffa
    8000641c:	112080e7          	jalr	274(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006420:	854a                	mv	a0,s2
    80006422:	00000097          	auipc	ra,0x0
    80006426:	e6a080e7          	jalr	-406(ra) # 8000628c <isdirempty>
    8000642a:	f925                	bnez	a0,8000639a <sys_unlink+0xa2>
    iunlockput(ip);
    8000642c:	854a                	mv	a0,s2
    8000642e:	ffffe097          	auipc	ra,0xffffe
    80006432:	ea4080e7          	jalr	-348(ra) # 800042d2 <iunlockput>

bad:
  iunlockput(dp);
    80006436:	8526                	mv	a0,s1
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	e9a080e7          	jalr	-358(ra) # 800042d2 <iunlockput>
  end_op();
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	998080e7          	jalr	-1640(ra) # 80004dd8 <end_op>
  return -1;
    80006448:	557d                	li	a0,-1
}
    8000644a:	60ae                	ld	ra,200(sp)
    8000644c:	640e                	ld	s0,192(sp)
    8000644e:	74ea                	ld	s1,184(sp)
    80006450:	794a                	ld	s2,176(sp)
    80006452:	6169                	addi	sp,sp,208
    80006454:	8082                	ret
    panic("unlink: writei");
    80006456:	00003517          	auipc	a0,0x3
    8000645a:	64a50513          	addi	a0,a0,1610 # 80009aa0 <syscalls+0x218>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0cc080e7          	jalr	204(ra) # 8000052a <panic>
    dp->nlink--;
    80006466:	04a4d783          	lhu	a5,74(s1)
    8000646a:	37fd                	addiw	a5,a5,-1
    8000646c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006470:	8526                	mv	a0,s1
    80006472:	ffffe097          	auipc	ra,0xffffe
    80006476:	b34080e7          	jalr	-1228(ra) # 80003fa6 <iupdate>
    8000647a:	bf99                	j	800063d0 <sys_unlink+0xd8>
    return -1;
    8000647c:	557d                	li	a0,-1
    8000647e:	b7f1                	j	8000644a <sys_unlink+0x152>

0000000080006480 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006480:	715d                	addi	sp,sp,-80
    80006482:	e486                	sd	ra,72(sp)
    80006484:	e0a2                	sd	s0,64(sp)
    80006486:	fc26                	sd	s1,56(sp)
    80006488:	f84a                	sd	s2,48(sp)
    8000648a:	f44e                	sd	s3,40(sp)
    8000648c:	f052                	sd	s4,32(sp)
    8000648e:	ec56                	sd	s5,24(sp)
    80006490:	0880                	addi	s0,sp,80
    80006492:	89ae                	mv	s3,a1
    80006494:	8ab2                	mv	s5,a2
    80006496:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006498:	fb040593          	addi	a1,s0,-80
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	3a8080e7          	jalr	936(ra) # 80004844 <nameiparent>
    800064a4:	892a                	mv	s2,a0
    800064a6:	12050e63          	beqz	a0,800065e2 <create+0x162>
    return 0;

  ilock(dp);
    800064aa:	ffffe097          	auipc	ra,0xffffe
    800064ae:	bc6080e7          	jalr	-1082(ra) # 80004070 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800064b2:	4601                	li	a2,0
    800064b4:	fb040593          	addi	a1,s0,-80
    800064b8:	854a                	mv	a0,s2
    800064ba:	ffffe097          	auipc	ra,0xffffe
    800064be:	09a080e7          	jalr	154(ra) # 80004554 <dirlookup>
    800064c2:	84aa                	mv	s1,a0
    800064c4:	c921                	beqz	a0,80006514 <create+0x94>
    iunlockput(dp);
    800064c6:	854a                	mv	a0,s2
    800064c8:	ffffe097          	auipc	ra,0xffffe
    800064cc:	e0a080e7          	jalr	-502(ra) # 800042d2 <iunlockput>
    ilock(ip);
    800064d0:	8526                	mv	a0,s1
    800064d2:	ffffe097          	auipc	ra,0xffffe
    800064d6:	b9e080e7          	jalr	-1122(ra) # 80004070 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800064da:	2981                	sext.w	s3,s3
    800064dc:	4789                	li	a5,2
    800064de:	02f99463          	bne	s3,a5,80006506 <create+0x86>
    800064e2:	0444d783          	lhu	a5,68(s1)
    800064e6:	37f9                	addiw	a5,a5,-2
    800064e8:	17c2                	slli	a5,a5,0x30
    800064ea:	93c1                	srli	a5,a5,0x30
    800064ec:	4705                	li	a4,1
    800064ee:	00f76c63          	bltu	a4,a5,80006506 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800064f2:	8526                	mv	a0,s1
    800064f4:	60a6                	ld	ra,72(sp)
    800064f6:	6406                	ld	s0,64(sp)
    800064f8:	74e2                	ld	s1,56(sp)
    800064fa:	7942                	ld	s2,48(sp)
    800064fc:	79a2                	ld	s3,40(sp)
    800064fe:	7a02                	ld	s4,32(sp)
    80006500:	6ae2                	ld	s5,24(sp)
    80006502:	6161                	addi	sp,sp,80
    80006504:	8082                	ret
    iunlockput(ip);
    80006506:	8526                	mv	a0,s1
    80006508:	ffffe097          	auipc	ra,0xffffe
    8000650c:	dca080e7          	jalr	-566(ra) # 800042d2 <iunlockput>
    return 0;
    80006510:	4481                	li	s1,0
    80006512:	b7c5                	j	800064f2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006514:	85ce                	mv	a1,s3
    80006516:	00092503          	lw	a0,0(s2)
    8000651a:	ffffe097          	auipc	ra,0xffffe
    8000651e:	9be080e7          	jalr	-1602(ra) # 80003ed8 <ialloc>
    80006522:	84aa                	mv	s1,a0
    80006524:	c521                	beqz	a0,8000656c <create+0xec>
  ilock(ip);
    80006526:	ffffe097          	auipc	ra,0xffffe
    8000652a:	b4a080e7          	jalr	-1206(ra) # 80004070 <ilock>
  ip->major = major;
    8000652e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006532:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006536:	4a05                	li	s4,1
    80006538:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000653c:	8526                	mv	a0,s1
    8000653e:	ffffe097          	auipc	ra,0xffffe
    80006542:	a68080e7          	jalr	-1432(ra) # 80003fa6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006546:	2981                	sext.w	s3,s3
    80006548:	03498a63          	beq	s3,s4,8000657c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000654c:	40d0                	lw	a2,4(s1)
    8000654e:	fb040593          	addi	a1,s0,-80
    80006552:	854a                	mv	a0,s2
    80006554:	ffffe097          	auipc	ra,0xffffe
    80006558:	210080e7          	jalr	528(ra) # 80004764 <dirlink>
    8000655c:	06054b63          	bltz	a0,800065d2 <create+0x152>
  iunlockput(dp);
    80006560:	854a                	mv	a0,s2
    80006562:	ffffe097          	auipc	ra,0xffffe
    80006566:	d70080e7          	jalr	-656(ra) # 800042d2 <iunlockput>
  return ip;
    8000656a:	b761                	j	800064f2 <create+0x72>
    panic("create: ialloc");
    8000656c:	00003517          	auipc	a0,0x3
    80006570:	64450513          	addi	a0,a0,1604 # 80009bb0 <syscalls+0x328>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	fb6080e7          	jalr	-74(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000657c:	04a95783          	lhu	a5,74(s2)
    80006580:	2785                	addiw	a5,a5,1
    80006582:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006586:	854a                	mv	a0,s2
    80006588:	ffffe097          	auipc	ra,0xffffe
    8000658c:	a1e080e7          	jalr	-1506(ra) # 80003fa6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006590:	40d0                	lw	a2,4(s1)
    80006592:	00003597          	auipc	a1,0x3
    80006596:	4e658593          	addi	a1,a1,1254 # 80009a78 <syscalls+0x1f0>
    8000659a:	8526                	mv	a0,s1
    8000659c:	ffffe097          	auipc	ra,0xffffe
    800065a0:	1c8080e7          	jalr	456(ra) # 80004764 <dirlink>
    800065a4:	00054f63          	bltz	a0,800065c2 <create+0x142>
    800065a8:	00492603          	lw	a2,4(s2)
    800065ac:	00003597          	auipc	a1,0x3
    800065b0:	4d458593          	addi	a1,a1,1236 # 80009a80 <syscalls+0x1f8>
    800065b4:	8526                	mv	a0,s1
    800065b6:	ffffe097          	auipc	ra,0xffffe
    800065ba:	1ae080e7          	jalr	430(ra) # 80004764 <dirlink>
    800065be:	f80557e3          	bgez	a0,8000654c <create+0xcc>
      panic("create dots");
    800065c2:	00003517          	auipc	a0,0x3
    800065c6:	5fe50513          	addi	a0,a0,1534 # 80009bc0 <syscalls+0x338>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f60080e7          	jalr	-160(ra) # 8000052a <panic>
    panic("create: dirlink");
    800065d2:	00003517          	auipc	a0,0x3
    800065d6:	5fe50513          	addi	a0,a0,1534 # 80009bd0 <syscalls+0x348>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f50080e7          	jalr	-176(ra) # 8000052a <panic>
    return 0;
    800065e2:	84aa                	mv	s1,a0
    800065e4:	b739                	j	800064f2 <create+0x72>

00000000800065e6 <sys_open>:

uint64
sys_open(void)
{
    800065e6:	7131                	addi	sp,sp,-192
    800065e8:	fd06                	sd	ra,184(sp)
    800065ea:	f922                	sd	s0,176(sp)
    800065ec:	f526                	sd	s1,168(sp)
    800065ee:	f14a                	sd	s2,160(sp)
    800065f0:	ed4e                	sd	s3,152(sp)
    800065f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800065f4:	08000613          	li	a2,128
    800065f8:	f5040593          	addi	a1,s0,-176
    800065fc:	4501                	li	a0,0
    800065fe:	ffffd097          	auipc	ra,0xffffd
    80006602:	f44080e7          	jalr	-188(ra) # 80003542 <argstr>
    return -1;
    80006606:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006608:	0c054163          	bltz	a0,800066ca <sys_open+0xe4>
    8000660c:	f4c40593          	addi	a1,s0,-180
    80006610:	4505                	li	a0,1
    80006612:	ffffd097          	auipc	ra,0xffffd
    80006616:	eec080e7          	jalr	-276(ra) # 800034fe <argint>
    8000661a:	0a054863          	bltz	a0,800066ca <sys_open+0xe4>

  begin_op();
    8000661e:	ffffe097          	auipc	ra,0xffffe
    80006622:	73a080e7          	jalr	1850(ra) # 80004d58 <begin_op>

  if(omode & O_CREATE){
    80006626:	f4c42783          	lw	a5,-180(s0)
    8000662a:	2007f793          	andi	a5,a5,512
    8000662e:	cbdd                	beqz	a5,800066e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006630:	4681                	li	a3,0
    80006632:	4601                	li	a2,0
    80006634:	4589                	li	a1,2
    80006636:	f5040513          	addi	a0,s0,-176
    8000663a:	00000097          	auipc	ra,0x0
    8000663e:	e46080e7          	jalr	-442(ra) # 80006480 <create>
    80006642:	892a                	mv	s2,a0
    if(ip == 0){
    80006644:	c959                	beqz	a0,800066da <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006646:	04491703          	lh	a4,68(s2)
    8000664a:	478d                	li	a5,3
    8000664c:	00f71763          	bne	a4,a5,8000665a <sys_open+0x74>
    80006650:	04695703          	lhu	a4,70(s2)
    80006654:	47a5                	li	a5,9
    80006656:	0ce7ec63          	bltu	a5,a4,8000672e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000665a:	fffff097          	auipc	ra,0xfffff
    8000665e:	b0e080e7          	jalr	-1266(ra) # 80005168 <filealloc>
    80006662:	89aa                	mv	s3,a0
    80006664:	10050263          	beqz	a0,80006768 <sys_open+0x182>
    80006668:	00000097          	auipc	ra,0x0
    8000666c:	8e2080e7          	jalr	-1822(ra) # 80005f4a <fdalloc>
    80006670:	84aa                	mv	s1,a0
    80006672:	0e054663          	bltz	a0,8000675e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006676:	04491703          	lh	a4,68(s2)
    8000667a:	478d                	li	a5,3
    8000667c:	0cf70463          	beq	a4,a5,80006744 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006680:	4789                	li	a5,2
    80006682:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006686:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000668a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000668e:	f4c42783          	lw	a5,-180(s0)
    80006692:	0017c713          	xori	a4,a5,1
    80006696:	8b05                	andi	a4,a4,1
    80006698:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000669c:	0037f713          	andi	a4,a5,3
    800066a0:	00e03733          	snez	a4,a4
    800066a4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800066a8:	4007f793          	andi	a5,a5,1024
    800066ac:	c791                	beqz	a5,800066b8 <sys_open+0xd2>
    800066ae:	04491703          	lh	a4,68(s2)
    800066b2:	4789                	li	a5,2
    800066b4:	08f70f63          	beq	a4,a5,80006752 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800066b8:	854a                	mv	a0,s2
    800066ba:	ffffe097          	auipc	ra,0xffffe
    800066be:	a78080e7          	jalr	-1416(ra) # 80004132 <iunlock>
  end_op();
    800066c2:	ffffe097          	auipc	ra,0xffffe
    800066c6:	716080e7          	jalr	1814(ra) # 80004dd8 <end_op>

  return fd;
}
    800066ca:	8526                	mv	a0,s1
    800066cc:	70ea                	ld	ra,184(sp)
    800066ce:	744a                	ld	s0,176(sp)
    800066d0:	74aa                	ld	s1,168(sp)
    800066d2:	790a                	ld	s2,160(sp)
    800066d4:	69ea                	ld	s3,152(sp)
    800066d6:	6129                	addi	sp,sp,192
    800066d8:	8082                	ret
      end_op();
    800066da:	ffffe097          	auipc	ra,0xffffe
    800066de:	6fe080e7          	jalr	1790(ra) # 80004dd8 <end_op>
      return -1;
    800066e2:	b7e5                	j	800066ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800066e4:	f5040513          	addi	a0,s0,-176
    800066e8:	ffffe097          	auipc	ra,0xffffe
    800066ec:	13e080e7          	jalr	318(ra) # 80004826 <namei>
    800066f0:	892a                	mv	s2,a0
    800066f2:	c905                	beqz	a0,80006722 <sys_open+0x13c>
    ilock(ip);
    800066f4:	ffffe097          	auipc	ra,0xffffe
    800066f8:	97c080e7          	jalr	-1668(ra) # 80004070 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800066fc:	04491703          	lh	a4,68(s2)
    80006700:	4785                	li	a5,1
    80006702:	f4f712e3          	bne	a4,a5,80006646 <sys_open+0x60>
    80006706:	f4c42783          	lw	a5,-180(s0)
    8000670a:	dba1                	beqz	a5,8000665a <sys_open+0x74>
      iunlockput(ip);
    8000670c:	854a                	mv	a0,s2
    8000670e:	ffffe097          	auipc	ra,0xffffe
    80006712:	bc4080e7          	jalr	-1084(ra) # 800042d2 <iunlockput>
      end_op();
    80006716:	ffffe097          	auipc	ra,0xffffe
    8000671a:	6c2080e7          	jalr	1730(ra) # 80004dd8 <end_op>
      return -1;
    8000671e:	54fd                	li	s1,-1
    80006720:	b76d                	j	800066ca <sys_open+0xe4>
      end_op();
    80006722:	ffffe097          	auipc	ra,0xffffe
    80006726:	6b6080e7          	jalr	1718(ra) # 80004dd8 <end_op>
      return -1;
    8000672a:	54fd                	li	s1,-1
    8000672c:	bf79                	j	800066ca <sys_open+0xe4>
    iunlockput(ip);
    8000672e:	854a                	mv	a0,s2
    80006730:	ffffe097          	auipc	ra,0xffffe
    80006734:	ba2080e7          	jalr	-1118(ra) # 800042d2 <iunlockput>
    end_op();
    80006738:	ffffe097          	auipc	ra,0xffffe
    8000673c:	6a0080e7          	jalr	1696(ra) # 80004dd8 <end_op>
    return -1;
    80006740:	54fd                	li	s1,-1
    80006742:	b761                	j	800066ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006744:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006748:	04691783          	lh	a5,70(s2)
    8000674c:	02f99223          	sh	a5,36(s3)
    80006750:	bf2d                	j	8000668a <sys_open+0xa4>
    itrunc(ip);
    80006752:	854a                	mv	a0,s2
    80006754:	ffffe097          	auipc	ra,0xffffe
    80006758:	a2a080e7          	jalr	-1494(ra) # 8000417e <itrunc>
    8000675c:	bfb1                	j	800066b8 <sys_open+0xd2>
      fileclose(f);
    8000675e:	854e                	mv	a0,s3
    80006760:	fffff097          	auipc	ra,0xfffff
    80006764:	ac4080e7          	jalr	-1340(ra) # 80005224 <fileclose>
    iunlockput(ip);
    80006768:	854a                	mv	a0,s2
    8000676a:	ffffe097          	auipc	ra,0xffffe
    8000676e:	b68080e7          	jalr	-1176(ra) # 800042d2 <iunlockput>
    end_op();
    80006772:	ffffe097          	auipc	ra,0xffffe
    80006776:	666080e7          	jalr	1638(ra) # 80004dd8 <end_op>
    return -1;
    8000677a:	54fd                	li	s1,-1
    8000677c:	b7b9                	j	800066ca <sys_open+0xe4>

000000008000677e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000677e:	7175                	addi	sp,sp,-144
    80006780:	e506                	sd	ra,136(sp)
    80006782:	e122                	sd	s0,128(sp)
    80006784:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006786:	ffffe097          	auipc	ra,0xffffe
    8000678a:	5d2080e7          	jalr	1490(ra) # 80004d58 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000678e:	08000613          	li	a2,128
    80006792:	f7040593          	addi	a1,s0,-144
    80006796:	4501                	li	a0,0
    80006798:	ffffd097          	auipc	ra,0xffffd
    8000679c:	daa080e7          	jalr	-598(ra) # 80003542 <argstr>
    800067a0:	02054963          	bltz	a0,800067d2 <sys_mkdir+0x54>
    800067a4:	4681                	li	a3,0
    800067a6:	4601                	li	a2,0
    800067a8:	4585                	li	a1,1
    800067aa:	f7040513          	addi	a0,s0,-144
    800067ae:	00000097          	auipc	ra,0x0
    800067b2:	cd2080e7          	jalr	-814(ra) # 80006480 <create>
    800067b6:	cd11                	beqz	a0,800067d2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800067b8:	ffffe097          	auipc	ra,0xffffe
    800067bc:	b1a080e7          	jalr	-1254(ra) # 800042d2 <iunlockput>
  end_op();
    800067c0:	ffffe097          	auipc	ra,0xffffe
    800067c4:	618080e7          	jalr	1560(ra) # 80004dd8 <end_op>
  return 0;
    800067c8:	4501                	li	a0,0
}
    800067ca:	60aa                	ld	ra,136(sp)
    800067cc:	640a                	ld	s0,128(sp)
    800067ce:	6149                	addi	sp,sp,144
    800067d0:	8082                	ret
    end_op();
    800067d2:	ffffe097          	auipc	ra,0xffffe
    800067d6:	606080e7          	jalr	1542(ra) # 80004dd8 <end_op>
    return -1;
    800067da:	557d                	li	a0,-1
    800067dc:	b7fd                	j	800067ca <sys_mkdir+0x4c>

00000000800067de <sys_mknod>:

uint64
sys_mknod(void)
{
    800067de:	7135                	addi	sp,sp,-160
    800067e0:	ed06                	sd	ra,152(sp)
    800067e2:	e922                	sd	s0,144(sp)
    800067e4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800067e6:	ffffe097          	auipc	ra,0xffffe
    800067ea:	572080e7          	jalr	1394(ra) # 80004d58 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800067ee:	08000613          	li	a2,128
    800067f2:	f7040593          	addi	a1,s0,-144
    800067f6:	4501                	li	a0,0
    800067f8:	ffffd097          	auipc	ra,0xffffd
    800067fc:	d4a080e7          	jalr	-694(ra) # 80003542 <argstr>
    80006800:	04054a63          	bltz	a0,80006854 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006804:	f6c40593          	addi	a1,s0,-148
    80006808:	4505                	li	a0,1
    8000680a:	ffffd097          	auipc	ra,0xffffd
    8000680e:	cf4080e7          	jalr	-780(ra) # 800034fe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006812:	04054163          	bltz	a0,80006854 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006816:	f6840593          	addi	a1,s0,-152
    8000681a:	4509                	li	a0,2
    8000681c:	ffffd097          	auipc	ra,0xffffd
    80006820:	ce2080e7          	jalr	-798(ra) # 800034fe <argint>
     argint(1, &major) < 0 ||
    80006824:	02054863          	bltz	a0,80006854 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006828:	f6841683          	lh	a3,-152(s0)
    8000682c:	f6c41603          	lh	a2,-148(s0)
    80006830:	458d                	li	a1,3
    80006832:	f7040513          	addi	a0,s0,-144
    80006836:	00000097          	auipc	ra,0x0
    8000683a:	c4a080e7          	jalr	-950(ra) # 80006480 <create>
     argint(2, &minor) < 0 ||
    8000683e:	c919                	beqz	a0,80006854 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006840:	ffffe097          	auipc	ra,0xffffe
    80006844:	a92080e7          	jalr	-1390(ra) # 800042d2 <iunlockput>
  end_op();
    80006848:	ffffe097          	auipc	ra,0xffffe
    8000684c:	590080e7          	jalr	1424(ra) # 80004dd8 <end_op>
  return 0;
    80006850:	4501                	li	a0,0
    80006852:	a031                	j	8000685e <sys_mknod+0x80>
    end_op();
    80006854:	ffffe097          	auipc	ra,0xffffe
    80006858:	584080e7          	jalr	1412(ra) # 80004dd8 <end_op>
    return -1;
    8000685c:	557d                	li	a0,-1
}
    8000685e:	60ea                	ld	ra,152(sp)
    80006860:	644a                	ld	s0,144(sp)
    80006862:	610d                	addi	sp,sp,160
    80006864:	8082                	ret

0000000080006866 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006866:	7135                	addi	sp,sp,-160
    80006868:	ed06                	sd	ra,152(sp)
    8000686a:	e922                	sd	s0,144(sp)
    8000686c:	e526                	sd	s1,136(sp)
    8000686e:	e14a                	sd	s2,128(sp)
    80006870:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006872:	ffffb097          	auipc	ra,0xffffb
    80006876:	1a4080e7          	jalr	420(ra) # 80001a16 <myproc>
    8000687a:	892a                	mv	s2,a0
  
  begin_op();
    8000687c:	ffffe097          	auipc	ra,0xffffe
    80006880:	4dc080e7          	jalr	1244(ra) # 80004d58 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006884:	08000613          	li	a2,128
    80006888:	f6040593          	addi	a1,s0,-160
    8000688c:	4501                	li	a0,0
    8000688e:	ffffd097          	auipc	ra,0xffffd
    80006892:	cb4080e7          	jalr	-844(ra) # 80003542 <argstr>
    80006896:	04054b63          	bltz	a0,800068ec <sys_chdir+0x86>
    8000689a:	f6040513          	addi	a0,s0,-160
    8000689e:	ffffe097          	auipc	ra,0xffffe
    800068a2:	f88080e7          	jalr	-120(ra) # 80004826 <namei>
    800068a6:	84aa                	mv	s1,a0
    800068a8:	c131                	beqz	a0,800068ec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800068aa:	ffffd097          	auipc	ra,0xffffd
    800068ae:	7c6080e7          	jalr	1990(ra) # 80004070 <ilock>
  if(ip->type != T_DIR){
    800068b2:	04449703          	lh	a4,68(s1)
    800068b6:	4785                	li	a5,1
    800068b8:	04f71063          	bne	a4,a5,800068f8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800068bc:	8526                	mv	a0,s1
    800068be:	ffffe097          	auipc	ra,0xffffe
    800068c2:	874080e7          	jalr	-1932(ra) # 80004132 <iunlock>
  iput(p->cwd);
    800068c6:	15093503          	ld	a0,336(s2)
    800068ca:	ffffe097          	auipc	ra,0xffffe
    800068ce:	960080e7          	jalr	-1696(ra) # 8000422a <iput>
  end_op();
    800068d2:	ffffe097          	auipc	ra,0xffffe
    800068d6:	506080e7          	jalr	1286(ra) # 80004dd8 <end_op>
  p->cwd = ip;
    800068da:	14993823          	sd	s1,336(s2)
  return 0;
    800068de:	4501                	li	a0,0
}
    800068e0:	60ea                	ld	ra,152(sp)
    800068e2:	644a                	ld	s0,144(sp)
    800068e4:	64aa                	ld	s1,136(sp)
    800068e6:	690a                	ld	s2,128(sp)
    800068e8:	610d                	addi	sp,sp,160
    800068ea:	8082                	ret
    end_op();
    800068ec:	ffffe097          	auipc	ra,0xffffe
    800068f0:	4ec080e7          	jalr	1260(ra) # 80004dd8 <end_op>
    return -1;
    800068f4:	557d                	li	a0,-1
    800068f6:	b7ed                	j	800068e0 <sys_chdir+0x7a>
    iunlockput(ip);
    800068f8:	8526                	mv	a0,s1
    800068fa:	ffffe097          	auipc	ra,0xffffe
    800068fe:	9d8080e7          	jalr	-1576(ra) # 800042d2 <iunlockput>
    end_op();
    80006902:	ffffe097          	auipc	ra,0xffffe
    80006906:	4d6080e7          	jalr	1238(ra) # 80004dd8 <end_op>
    return -1;
    8000690a:	557d                	li	a0,-1
    8000690c:	bfd1                	j	800068e0 <sys_chdir+0x7a>

000000008000690e <sys_exec>:

uint64
sys_exec(void)
{
    8000690e:	7145                	addi	sp,sp,-464
    80006910:	e786                	sd	ra,456(sp)
    80006912:	e3a2                	sd	s0,448(sp)
    80006914:	ff26                	sd	s1,440(sp)
    80006916:	fb4a                	sd	s2,432(sp)
    80006918:	f74e                	sd	s3,424(sp)
    8000691a:	f352                	sd	s4,416(sp)
    8000691c:	ef56                	sd	s5,408(sp)
    8000691e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006920:	08000613          	li	a2,128
    80006924:	f4040593          	addi	a1,s0,-192
    80006928:	4501                	li	a0,0
    8000692a:	ffffd097          	auipc	ra,0xffffd
    8000692e:	c18080e7          	jalr	-1000(ra) # 80003542 <argstr>
    return -1;
    80006932:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006934:	0c054a63          	bltz	a0,80006a08 <sys_exec+0xfa>
    80006938:	e3840593          	addi	a1,s0,-456
    8000693c:	4505                	li	a0,1
    8000693e:	ffffd097          	auipc	ra,0xffffd
    80006942:	be2080e7          	jalr	-1054(ra) # 80003520 <argaddr>
    80006946:	0c054163          	bltz	a0,80006a08 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000694a:	10000613          	li	a2,256
    8000694e:	4581                	li	a1,0
    80006950:	e4040513          	addi	a0,s0,-448
    80006954:	ffffa097          	auipc	ra,0xffffa
    80006958:	37c080e7          	jalr	892(ra) # 80000cd0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000695c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006960:	89a6                	mv	s3,s1
    80006962:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006964:	02000a13          	li	s4,32
    80006968:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000696c:	00391793          	slli	a5,s2,0x3
    80006970:	e3040593          	addi	a1,s0,-464
    80006974:	e3843503          	ld	a0,-456(s0)
    80006978:	953e                	add	a0,a0,a5
    8000697a:	ffffd097          	auipc	ra,0xffffd
    8000697e:	aea080e7          	jalr	-1302(ra) # 80003464 <fetchaddr>
    80006982:	02054a63          	bltz	a0,800069b6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006986:	e3043783          	ld	a5,-464(s0)
    8000698a:	c3b9                	beqz	a5,800069d0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000698c:	ffffa097          	auipc	ra,0xffffa
    80006990:	146080e7          	jalr	326(ra) # 80000ad2 <kalloc>
    80006994:	85aa                	mv	a1,a0
    80006996:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000699a:	cd11                	beqz	a0,800069b6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000699c:	6605                	lui	a2,0x1
    8000699e:	e3043503          	ld	a0,-464(s0)
    800069a2:	ffffd097          	auipc	ra,0xffffd
    800069a6:	b14080e7          	jalr	-1260(ra) # 800034b6 <fetchstr>
    800069aa:	00054663          	bltz	a0,800069b6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800069ae:	0905                	addi	s2,s2,1
    800069b0:	09a1                	addi	s3,s3,8
    800069b2:	fb491be3          	bne	s2,s4,80006968 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069b6:	10048913          	addi	s2,s1,256
    800069ba:	6088                	ld	a0,0(s1)
    800069bc:	c529                	beqz	a0,80006a06 <sys_exec+0xf8>
    kfree(argv[i]);
    800069be:	ffffa097          	auipc	ra,0xffffa
    800069c2:	018080e7          	jalr	24(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069c6:	04a1                	addi	s1,s1,8
    800069c8:	ff2499e3          	bne	s1,s2,800069ba <sys_exec+0xac>
  return -1;
    800069cc:	597d                	li	s2,-1
    800069ce:	a82d                	j	80006a08 <sys_exec+0xfa>
      argv[i] = 0;
    800069d0:	0a8e                	slli	s5,s5,0x3
    800069d2:	fc040793          	addi	a5,s0,-64
    800069d6:	9abe                	add	s5,s5,a5
    800069d8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800069dc:	e4040593          	addi	a1,s0,-448
    800069e0:	f4040513          	addi	a0,s0,-192
    800069e4:	fffff097          	auipc	ra,0xfffff
    800069e8:	088080e7          	jalr	136(ra) # 80005a6c <exec>
    800069ec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069ee:	10048993          	addi	s3,s1,256
    800069f2:	6088                	ld	a0,0(s1)
    800069f4:	c911                	beqz	a0,80006a08 <sys_exec+0xfa>
    kfree(argv[i]);
    800069f6:	ffffa097          	auipc	ra,0xffffa
    800069fa:	fe0080e7          	jalr	-32(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069fe:	04a1                	addi	s1,s1,8
    80006a00:	ff3499e3          	bne	s1,s3,800069f2 <sys_exec+0xe4>
    80006a04:	a011                	j	80006a08 <sys_exec+0xfa>
  return -1;
    80006a06:	597d                	li	s2,-1
}
    80006a08:	854a                	mv	a0,s2
    80006a0a:	60be                	ld	ra,456(sp)
    80006a0c:	641e                	ld	s0,448(sp)
    80006a0e:	74fa                	ld	s1,440(sp)
    80006a10:	795a                	ld	s2,432(sp)
    80006a12:	79ba                	ld	s3,424(sp)
    80006a14:	7a1a                	ld	s4,416(sp)
    80006a16:	6afa                	ld	s5,408(sp)
    80006a18:	6179                	addi	sp,sp,464
    80006a1a:	8082                	ret

0000000080006a1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80006a1c:	7139                	addi	sp,sp,-64
    80006a1e:	fc06                	sd	ra,56(sp)
    80006a20:	f822                	sd	s0,48(sp)
    80006a22:	f426                	sd	s1,40(sp)
    80006a24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006a26:	ffffb097          	auipc	ra,0xffffb
    80006a2a:	ff0080e7          	jalr	-16(ra) # 80001a16 <myproc>
    80006a2e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006a30:	fd840593          	addi	a1,s0,-40
    80006a34:	4501                	li	a0,0
    80006a36:	ffffd097          	auipc	ra,0xffffd
    80006a3a:	aea080e7          	jalr	-1302(ra) # 80003520 <argaddr>
    return -1;
    80006a3e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006a40:	0e054063          	bltz	a0,80006b20 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006a44:	fc840593          	addi	a1,s0,-56
    80006a48:	fd040513          	addi	a0,s0,-48
    80006a4c:	fffff097          	auipc	ra,0xfffff
    80006a50:	cfe080e7          	jalr	-770(ra) # 8000574a <pipealloc>
    return -1;
    80006a54:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006a56:	0c054563          	bltz	a0,80006b20 <sys_pipe+0x104>
  fd0 = -1;
    80006a5a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006a5e:	fd043503          	ld	a0,-48(s0)
    80006a62:	fffff097          	auipc	ra,0xfffff
    80006a66:	4e8080e7          	jalr	1256(ra) # 80005f4a <fdalloc>
    80006a6a:	fca42223          	sw	a0,-60(s0)
    80006a6e:	08054c63          	bltz	a0,80006b06 <sys_pipe+0xea>
    80006a72:	fc843503          	ld	a0,-56(s0)
    80006a76:	fffff097          	auipc	ra,0xfffff
    80006a7a:	4d4080e7          	jalr	1236(ra) # 80005f4a <fdalloc>
    80006a7e:	fca42023          	sw	a0,-64(s0)
    80006a82:	06054863          	bltz	a0,80006af2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006a86:	4691                	li	a3,4
    80006a88:	fc440613          	addi	a2,s0,-60
    80006a8c:	fd843583          	ld	a1,-40(s0)
    80006a90:	68a8                	ld	a0,80(s1)
    80006a92:	ffffb097          	auipc	ra,0xffffb
    80006a96:	c44080e7          	jalr	-956(ra) # 800016d6 <copyout>
    80006a9a:	02054063          	bltz	a0,80006aba <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006a9e:	4691                	li	a3,4
    80006aa0:	fc040613          	addi	a2,s0,-64
    80006aa4:	fd843583          	ld	a1,-40(s0)
    80006aa8:	0591                	addi	a1,a1,4
    80006aaa:	68a8                	ld	a0,80(s1)
    80006aac:	ffffb097          	auipc	ra,0xffffb
    80006ab0:	c2a080e7          	jalr	-982(ra) # 800016d6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006ab4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006ab6:	06055563          	bgez	a0,80006b20 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006aba:	fc442783          	lw	a5,-60(s0)
    80006abe:	07e9                	addi	a5,a5,26
    80006ac0:	078e                	slli	a5,a5,0x3
    80006ac2:	97a6                	add	a5,a5,s1
    80006ac4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006ac8:	fc042503          	lw	a0,-64(s0)
    80006acc:	0569                	addi	a0,a0,26
    80006ace:	050e                	slli	a0,a0,0x3
    80006ad0:	9526                	add	a0,a0,s1
    80006ad2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006ad6:	fd043503          	ld	a0,-48(s0)
    80006ada:	ffffe097          	auipc	ra,0xffffe
    80006ade:	74a080e7          	jalr	1866(ra) # 80005224 <fileclose>
    fileclose(wf);
    80006ae2:	fc843503          	ld	a0,-56(s0)
    80006ae6:	ffffe097          	auipc	ra,0xffffe
    80006aea:	73e080e7          	jalr	1854(ra) # 80005224 <fileclose>
    return -1;
    80006aee:	57fd                	li	a5,-1
    80006af0:	a805                	j	80006b20 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006af2:	fc442783          	lw	a5,-60(s0)
    80006af6:	0007c863          	bltz	a5,80006b06 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006afa:	01a78513          	addi	a0,a5,26
    80006afe:	050e                	slli	a0,a0,0x3
    80006b00:	9526                	add	a0,a0,s1
    80006b02:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006b06:	fd043503          	ld	a0,-48(s0)
    80006b0a:	ffffe097          	auipc	ra,0xffffe
    80006b0e:	71a080e7          	jalr	1818(ra) # 80005224 <fileclose>
    fileclose(wf);
    80006b12:	fc843503          	ld	a0,-56(s0)
    80006b16:	ffffe097          	auipc	ra,0xffffe
    80006b1a:	70e080e7          	jalr	1806(ra) # 80005224 <fileclose>
    return -1;
    80006b1e:	57fd                	li	a5,-1
}
    80006b20:	853e                	mv	a0,a5
    80006b22:	70e2                	ld	ra,56(sp)
    80006b24:	7442                	ld	s0,48(sp)
    80006b26:	74a2                	ld	s1,40(sp)
    80006b28:	6121                	addi	sp,sp,64
    80006b2a:	8082                	ret
    80006b2c:	0000                	unimp
	...

0000000080006b30 <kernelvec>:
    80006b30:	7111                	addi	sp,sp,-256
    80006b32:	e006                	sd	ra,0(sp)
    80006b34:	e40a                	sd	sp,8(sp)
    80006b36:	e80e                	sd	gp,16(sp)
    80006b38:	ec12                	sd	tp,24(sp)
    80006b3a:	f016                	sd	t0,32(sp)
    80006b3c:	f41a                	sd	t1,40(sp)
    80006b3e:	f81e                	sd	t2,48(sp)
    80006b40:	fc22                	sd	s0,56(sp)
    80006b42:	e0a6                	sd	s1,64(sp)
    80006b44:	e4aa                	sd	a0,72(sp)
    80006b46:	e8ae                	sd	a1,80(sp)
    80006b48:	ecb2                	sd	a2,88(sp)
    80006b4a:	f0b6                	sd	a3,96(sp)
    80006b4c:	f4ba                	sd	a4,104(sp)
    80006b4e:	f8be                	sd	a5,112(sp)
    80006b50:	fcc2                	sd	a6,120(sp)
    80006b52:	e146                	sd	a7,128(sp)
    80006b54:	e54a                	sd	s2,136(sp)
    80006b56:	e94e                	sd	s3,144(sp)
    80006b58:	ed52                	sd	s4,152(sp)
    80006b5a:	f156                	sd	s5,160(sp)
    80006b5c:	f55a                	sd	s6,168(sp)
    80006b5e:	f95e                	sd	s7,176(sp)
    80006b60:	fd62                	sd	s8,184(sp)
    80006b62:	e1e6                	sd	s9,192(sp)
    80006b64:	e5ea                	sd	s10,200(sp)
    80006b66:	e9ee                	sd	s11,208(sp)
    80006b68:	edf2                	sd	t3,216(sp)
    80006b6a:	f1f6                	sd	t4,224(sp)
    80006b6c:	f5fa                	sd	t5,232(sp)
    80006b6e:	f9fe                	sd	t6,240(sp)
    80006b70:	fc0fc0ef          	jal	ra,80003330 <kerneltrap>
    80006b74:	6082                	ld	ra,0(sp)
    80006b76:	6122                	ld	sp,8(sp)
    80006b78:	61c2                	ld	gp,16(sp)
    80006b7a:	7282                	ld	t0,32(sp)
    80006b7c:	7322                	ld	t1,40(sp)
    80006b7e:	73c2                	ld	t2,48(sp)
    80006b80:	7462                	ld	s0,56(sp)
    80006b82:	6486                	ld	s1,64(sp)
    80006b84:	6526                	ld	a0,72(sp)
    80006b86:	65c6                	ld	a1,80(sp)
    80006b88:	6666                	ld	a2,88(sp)
    80006b8a:	7686                	ld	a3,96(sp)
    80006b8c:	7726                	ld	a4,104(sp)
    80006b8e:	77c6                	ld	a5,112(sp)
    80006b90:	7866                	ld	a6,120(sp)
    80006b92:	688a                	ld	a7,128(sp)
    80006b94:	692a                	ld	s2,136(sp)
    80006b96:	69ca                	ld	s3,144(sp)
    80006b98:	6a6a                	ld	s4,152(sp)
    80006b9a:	7a8a                	ld	s5,160(sp)
    80006b9c:	7b2a                	ld	s6,168(sp)
    80006b9e:	7bca                	ld	s7,176(sp)
    80006ba0:	7c6a                	ld	s8,184(sp)
    80006ba2:	6c8e                	ld	s9,192(sp)
    80006ba4:	6d2e                	ld	s10,200(sp)
    80006ba6:	6dce                	ld	s11,208(sp)
    80006ba8:	6e6e                	ld	t3,216(sp)
    80006baa:	7e8e                	ld	t4,224(sp)
    80006bac:	7f2e                	ld	t5,232(sp)
    80006bae:	7fce                	ld	t6,240(sp)
    80006bb0:	6111                	addi	sp,sp,256
    80006bb2:	10200073          	sret
    80006bb6:	00000013          	nop
    80006bba:	00000013          	nop
    80006bbe:	0001                	nop

0000000080006bc0 <timervec>:
    80006bc0:	34051573          	csrrw	a0,mscratch,a0
    80006bc4:	e10c                	sd	a1,0(a0)
    80006bc6:	e510                	sd	a2,8(a0)
    80006bc8:	e914                	sd	a3,16(a0)
    80006bca:	6d0c                	ld	a1,24(a0)
    80006bcc:	7110                	ld	a2,32(a0)
    80006bce:	6194                	ld	a3,0(a1)
    80006bd0:	96b2                	add	a3,a3,a2
    80006bd2:	e194                	sd	a3,0(a1)
    80006bd4:	4589                	li	a1,2
    80006bd6:	14459073          	csrw	sip,a1
    80006bda:	6914                	ld	a3,16(a0)
    80006bdc:	6510                	ld	a2,8(a0)
    80006bde:	610c                	ld	a1,0(a0)
    80006be0:	34051573          	csrrw	a0,mscratch,a0
    80006be4:	30200073          	mret
	...

0000000080006bea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006bea:	1141                	addi	sp,sp,-16
    80006bec:	e422                	sd	s0,8(sp)
    80006bee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006bf0:	0c0007b7          	lui	a5,0xc000
    80006bf4:	4705                	li	a4,1
    80006bf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006bf8:	c3d8                	sw	a4,4(a5)
}
    80006bfa:	6422                	ld	s0,8(sp)
    80006bfc:	0141                	addi	sp,sp,16
    80006bfe:	8082                	ret

0000000080006c00 <plicinithart>:

void
plicinithart(void)
{
    80006c00:	1141                	addi	sp,sp,-16
    80006c02:	e406                	sd	ra,8(sp)
    80006c04:	e022                	sd	s0,0(sp)
    80006c06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006c08:	ffffb097          	auipc	ra,0xffffb
    80006c0c:	de2080e7          	jalr	-542(ra) # 800019ea <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006c10:	0085171b          	slliw	a4,a0,0x8
    80006c14:	0c0027b7          	lui	a5,0xc002
    80006c18:	97ba                	add	a5,a5,a4
    80006c1a:	40200713          	li	a4,1026
    80006c1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006c22:	00d5151b          	slliw	a0,a0,0xd
    80006c26:	0c2017b7          	lui	a5,0xc201
    80006c2a:	953e                	add	a0,a0,a5
    80006c2c:	00052023          	sw	zero,0(a0)
}
    80006c30:	60a2                	ld	ra,8(sp)
    80006c32:	6402                	ld	s0,0(sp)
    80006c34:	0141                	addi	sp,sp,16
    80006c36:	8082                	ret

0000000080006c38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006c38:	1141                	addi	sp,sp,-16
    80006c3a:	e406                	sd	ra,8(sp)
    80006c3c:	e022                	sd	s0,0(sp)
    80006c3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006c40:	ffffb097          	auipc	ra,0xffffb
    80006c44:	daa080e7          	jalr	-598(ra) # 800019ea <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006c48:	00d5179b          	slliw	a5,a0,0xd
    80006c4c:	0c201537          	lui	a0,0xc201
    80006c50:	953e                	add	a0,a0,a5
  return irq;
}
    80006c52:	4148                	lw	a0,4(a0)
    80006c54:	60a2                	ld	ra,8(sp)
    80006c56:	6402                	ld	s0,0(sp)
    80006c58:	0141                	addi	sp,sp,16
    80006c5a:	8082                	ret

0000000080006c5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006c5c:	1101                	addi	sp,sp,-32
    80006c5e:	ec06                	sd	ra,24(sp)
    80006c60:	e822                	sd	s0,16(sp)
    80006c62:	e426                	sd	s1,8(sp)
    80006c64:	1000                	addi	s0,sp,32
    80006c66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006c68:	ffffb097          	auipc	ra,0xffffb
    80006c6c:	d82080e7          	jalr	-638(ra) # 800019ea <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006c70:	00d5151b          	slliw	a0,a0,0xd
    80006c74:	0c2017b7          	lui	a5,0xc201
    80006c78:	97aa                	add	a5,a5,a0
    80006c7a:	c3c4                	sw	s1,4(a5)
}
    80006c7c:	60e2                	ld	ra,24(sp)
    80006c7e:	6442                	ld	s0,16(sp)
    80006c80:	64a2                	ld	s1,8(sp)
    80006c82:	6105                	addi	sp,sp,32
    80006c84:	8082                	ret

0000000080006c86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006c86:	1141                	addi	sp,sp,-16
    80006c88:	e406                	sd	ra,8(sp)
    80006c8a:	e022                	sd	s0,0(sp)
    80006c8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006c8e:	479d                	li	a5,7
    80006c90:	06a7c963          	blt	a5,a0,80006d02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006c94:	00025797          	auipc	a5,0x25
    80006c98:	36c78793          	addi	a5,a5,876 # 8002c000 <disk>
    80006c9c:	00a78733          	add	a4,a5,a0
    80006ca0:	6789                	lui	a5,0x2
    80006ca2:	97ba                	add	a5,a5,a4
    80006ca4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006ca8:	e7ad                	bnez	a5,80006d12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006caa:	00451793          	slli	a5,a0,0x4
    80006cae:	00027717          	auipc	a4,0x27
    80006cb2:	35270713          	addi	a4,a4,850 # 8002e000 <disk+0x2000>
    80006cb6:	6314                	ld	a3,0(a4)
    80006cb8:	96be                	add	a3,a3,a5
    80006cba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006cbe:	6314                	ld	a3,0(a4)
    80006cc0:	96be                	add	a3,a3,a5
    80006cc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006cc6:	6314                	ld	a3,0(a4)
    80006cc8:	96be                	add	a3,a3,a5
    80006cca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006cce:	6318                	ld	a4,0(a4)
    80006cd0:	97ba                	add	a5,a5,a4
    80006cd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006cd6:	00025797          	auipc	a5,0x25
    80006cda:	32a78793          	addi	a5,a5,810 # 8002c000 <disk>
    80006cde:	97aa                	add	a5,a5,a0
    80006ce0:	6509                	lui	a0,0x2
    80006ce2:	953e                	add	a0,a0,a5
    80006ce4:	4785                	li	a5,1
    80006ce6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006cea:	00027517          	auipc	a0,0x27
    80006cee:	32e50513          	addi	a0,a0,814 # 8002e018 <disk+0x2018>
    80006cf2:	ffffb097          	auipc	ra,0xffffb
    80006cf6:	4d2080e7          	jalr	1234(ra) # 800021c4 <wakeup>
}
    80006cfa:	60a2                	ld	ra,8(sp)
    80006cfc:	6402                	ld	s0,0(sp)
    80006cfe:	0141                	addi	sp,sp,16
    80006d00:	8082                	ret
    panic("free_desc 1");
    80006d02:	00003517          	auipc	a0,0x3
    80006d06:	ede50513          	addi	a0,a0,-290 # 80009be0 <syscalls+0x358>
    80006d0a:	ffffa097          	auipc	ra,0xffffa
    80006d0e:	820080e7          	jalr	-2016(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006d12:	00003517          	auipc	a0,0x3
    80006d16:	ede50513          	addi	a0,a0,-290 # 80009bf0 <syscalls+0x368>
    80006d1a:	ffffa097          	auipc	ra,0xffffa
    80006d1e:	810080e7          	jalr	-2032(ra) # 8000052a <panic>

0000000080006d22 <virtio_disk_init>:
{
    80006d22:	1101                	addi	sp,sp,-32
    80006d24:	ec06                	sd	ra,24(sp)
    80006d26:	e822                	sd	s0,16(sp)
    80006d28:	e426                	sd	s1,8(sp)
    80006d2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006d2c:	00003597          	auipc	a1,0x3
    80006d30:	ed458593          	addi	a1,a1,-300 # 80009c00 <syscalls+0x378>
    80006d34:	00027517          	auipc	a0,0x27
    80006d38:	3f450513          	addi	a0,a0,1012 # 8002e128 <disk+0x2128>
    80006d3c:	ffffa097          	auipc	ra,0xffffa
    80006d40:	df6080e7          	jalr	-522(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006d44:	100017b7          	lui	a5,0x10001
    80006d48:	4398                	lw	a4,0(a5)
    80006d4a:	2701                	sext.w	a4,a4
    80006d4c:	747277b7          	lui	a5,0x74727
    80006d50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006d54:	0ef71163          	bne	a4,a5,80006e36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006d58:	100017b7          	lui	a5,0x10001
    80006d5c:	43dc                	lw	a5,4(a5)
    80006d5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006d60:	4705                	li	a4,1
    80006d62:	0ce79a63          	bne	a5,a4,80006e36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006d66:	100017b7          	lui	a5,0x10001
    80006d6a:	479c                	lw	a5,8(a5)
    80006d6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006d6e:	4709                	li	a4,2
    80006d70:	0ce79363          	bne	a5,a4,80006e36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006d74:	100017b7          	lui	a5,0x10001
    80006d78:	47d8                	lw	a4,12(a5)
    80006d7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006d7c:	554d47b7          	lui	a5,0x554d4
    80006d80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006d84:	0af71963          	bne	a4,a5,80006e36 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d88:	100017b7          	lui	a5,0x10001
    80006d8c:	4705                	li	a4,1
    80006d8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d90:	470d                	li	a4,3
    80006d92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006d94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006d96:	c7ffe737          	lui	a4,0xc7ffe
    80006d9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006d9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006da0:	2701                	sext.w	a4,a4
    80006da2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006da4:	472d                	li	a4,11
    80006da6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006da8:	473d                	li	a4,15
    80006daa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006dac:	6705                	lui	a4,0x1
    80006dae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006db0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006db4:	5bdc                	lw	a5,52(a5)
    80006db6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006db8:	c7d9                	beqz	a5,80006e46 <virtio_disk_init+0x124>
  if(max < NUM)
    80006dba:	471d                	li	a4,7
    80006dbc:	08f77d63          	bgeu	a4,a5,80006e56 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006dc0:	100014b7          	lui	s1,0x10001
    80006dc4:	47a1                	li	a5,8
    80006dc6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006dc8:	6609                	lui	a2,0x2
    80006dca:	4581                	li	a1,0
    80006dcc:	00025517          	auipc	a0,0x25
    80006dd0:	23450513          	addi	a0,a0,564 # 8002c000 <disk>
    80006dd4:	ffffa097          	auipc	ra,0xffffa
    80006dd8:	efc080e7          	jalr	-260(ra) # 80000cd0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006ddc:	00025717          	auipc	a4,0x25
    80006de0:	22470713          	addi	a4,a4,548 # 8002c000 <disk>
    80006de4:	00c75793          	srli	a5,a4,0xc
    80006de8:	2781                	sext.w	a5,a5
    80006dea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006dec:	00027797          	auipc	a5,0x27
    80006df0:	21478793          	addi	a5,a5,532 # 8002e000 <disk+0x2000>
    80006df4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006df6:	00025717          	auipc	a4,0x25
    80006dfa:	28a70713          	addi	a4,a4,650 # 8002c080 <disk+0x80>
    80006dfe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006e00:	00026717          	auipc	a4,0x26
    80006e04:	20070713          	addi	a4,a4,512 # 8002d000 <disk+0x1000>
    80006e08:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006e0a:	4705                	li	a4,1
    80006e0c:	00e78c23          	sb	a4,24(a5)
    80006e10:	00e78ca3          	sb	a4,25(a5)
    80006e14:	00e78d23          	sb	a4,26(a5)
    80006e18:	00e78da3          	sb	a4,27(a5)
    80006e1c:	00e78e23          	sb	a4,28(a5)
    80006e20:	00e78ea3          	sb	a4,29(a5)
    80006e24:	00e78f23          	sb	a4,30(a5)
    80006e28:	00e78fa3          	sb	a4,31(a5)
}
    80006e2c:	60e2                	ld	ra,24(sp)
    80006e2e:	6442                	ld	s0,16(sp)
    80006e30:	64a2                	ld	s1,8(sp)
    80006e32:	6105                	addi	sp,sp,32
    80006e34:	8082                	ret
    panic("could not find virtio disk");
    80006e36:	00003517          	auipc	a0,0x3
    80006e3a:	dda50513          	addi	a0,a0,-550 # 80009c10 <syscalls+0x388>
    80006e3e:	ffff9097          	auipc	ra,0xffff9
    80006e42:	6ec080e7          	jalr	1772(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006e46:	00003517          	auipc	a0,0x3
    80006e4a:	dea50513          	addi	a0,a0,-534 # 80009c30 <syscalls+0x3a8>
    80006e4e:	ffff9097          	auipc	ra,0xffff9
    80006e52:	6dc080e7          	jalr	1756(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006e56:	00003517          	auipc	a0,0x3
    80006e5a:	dfa50513          	addi	a0,a0,-518 # 80009c50 <syscalls+0x3c8>
    80006e5e:	ffff9097          	auipc	ra,0xffff9
    80006e62:	6cc080e7          	jalr	1740(ra) # 8000052a <panic>

0000000080006e66 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006e66:	7119                	addi	sp,sp,-128
    80006e68:	fc86                	sd	ra,120(sp)
    80006e6a:	f8a2                	sd	s0,112(sp)
    80006e6c:	f4a6                	sd	s1,104(sp)
    80006e6e:	f0ca                	sd	s2,96(sp)
    80006e70:	ecce                	sd	s3,88(sp)
    80006e72:	e8d2                	sd	s4,80(sp)
    80006e74:	e4d6                	sd	s5,72(sp)
    80006e76:	e0da                	sd	s6,64(sp)
    80006e78:	fc5e                	sd	s7,56(sp)
    80006e7a:	f862                	sd	s8,48(sp)
    80006e7c:	f466                	sd	s9,40(sp)
    80006e7e:	f06a                	sd	s10,32(sp)
    80006e80:	ec6e                	sd	s11,24(sp)
    80006e82:	0100                	addi	s0,sp,128
    80006e84:	8aaa                	mv	s5,a0
    80006e86:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006e88:	00c52c83          	lw	s9,12(a0)
    80006e8c:	001c9c9b          	slliw	s9,s9,0x1
    80006e90:	1c82                	slli	s9,s9,0x20
    80006e92:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006e96:	00027517          	auipc	a0,0x27
    80006e9a:	29250513          	addi	a0,a0,658 # 8002e128 <disk+0x2128>
    80006e9e:	ffffa097          	auipc	ra,0xffffa
    80006ea2:	d24080e7          	jalr	-732(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006ea6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ea8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006eaa:	00025c17          	auipc	s8,0x25
    80006eae:	156c0c13          	addi	s8,s8,342 # 8002c000 <disk>
    80006eb2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006eb4:	4b0d                	li	s6,3
    80006eb6:	a0ad                	j	80006f20 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006eb8:	00fc0733          	add	a4,s8,a5
    80006ebc:	975e                	add	a4,a4,s7
    80006ebe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006ec2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006ec4:	0207c563          	bltz	a5,80006eee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006ec8:	2905                	addiw	s2,s2,1
    80006eca:	0611                	addi	a2,a2,4
    80006ecc:	19690d63          	beq	s2,s6,80007066 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006ed0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006ed2:	00027717          	auipc	a4,0x27
    80006ed6:	14670713          	addi	a4,a4,326 # 8002e018 <disk+0x2018>
    80006eda:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006edc:	00074683          	lbu	a3,0(a4)
    80006ee0:	fee1                	bnez	a3,80006eb8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ee2:	2785                	addiw	a5,a5,1
    80006ee4:	0705                	addi	a4,a4,1
    80006ee6:	fe979be3          	bne	a5,s1,80006edc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006eea:	57fd                	li	a5,-1
    80006eec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006eee:	01205d63          	blez	s2,80006f08 <virtio_disk_rw+0xa2>
    80006ef2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006ef4:	000a2503          	lw	a0,0(s4)
    80006ef8:	00000097          	auipc	ra,0x0
    80006efc:	d8e080e7          	jalr	-626(ra) # 80006c86 <free_desc>
      for(int j = 0; j < i; j++)
    80006f00:	2d85                	addiw	s11,s11,1
    80006f02:	0a11                	addi	s4,s4,4
    80006f04:	ffb918e3          	bne	s2,s11,80006ef4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006f08:	00027597          	auipc	a1,0x27
    80006f0c:	22058593          	addi	a1,a1,544 # 8002e128 <disk+0x2128>
    80006f10:	00027517          	auipc	a0,0x27
    80006f14:	10850513          	addi	a0,a0,264 # 8002e018 <disk+0x2018>
    80006f18:	ffffb097          	auipc	ra,0xffffb
    80006f1c:	120080e7          	jalr	288(ra) # 80002038 <sleep>
  for(int i = 0; i < 3; i++){
    80006f20:	f8040a13          	addi	s4,s0,-128
{
    80006f24:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006f26:	894e                	mv	s2,s3
    80006f28:	b765                	j	80006ed0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006f2a:	00027697          	auipc	a3,0x27
    80006f2e:	0d66b683          	ld	a3,214(a3) # 8002e000 <disk+0x2000>
    80006f32:	96ba                	add	a3,a3,a4
    80006f34:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006f38:	00025817          	auipc	a6,0x25
    80006f3c:	0c880813          	addi	a6,a6,200 # 8002c000 <disk>
    80006f40:	00027697          	auipc	a3,0x27
    80006f44:	0c068693          	addi	a3,a3,192 # 8002e000 <disk+0x2000>
    80006f48:	6290                	ld	a2,0(a3)
    80006f4a:	963a                	add	a2,a2,a4
    80006f4c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006f50:	0015e593          	ori	a1,a1,1
    80006f54:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006f58:	f8842603          	lw	a2,-120(s0)
    80006f5c:	628c                	ld	a1,0(a3)
    80006f5e:	972e                	add	a4,a4,a1
    80006f60:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006f64:	20050593          	addi	a1,a0,512
    80006f68:	0592                	slli	a1,a1,0x4
    80006f6a:	95c2                	add	a1,a1,a6
    80006f6c:	577d                	li	a4,-1
    80006f6e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006f72:	00461713          	slli	a4,a2,0x4
    80006f76:	6290                	ld	a2,0(a3)
    80006f78:	963a                	add	a2,a2,a4
    80006f7a:	03078793          	addi	a5,a5,48
    80006f7e:	97c2                	add	a5,a5,a6
    80006f80:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006f82:	629c                	ld	a5,0(a3)
    80006f84:	97ba                	add	a5,a5,a4
    80006f86:	4605                	li	a2,1
    80006f88:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006f8a:	629c                	ld	a5,0(a3)
    80006f8c:	97ba                	add	a5,a5,a4
    80006f8e:	4809                	li	a6,2
    80006f90:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006f94:	629c                	ld	a5,0(a3)
    80006f96:	973e                	add	a4,a4,a5
    80006f98:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006f9c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006fa0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006fa4:	6698                	ld	a4,8(a3)
    80006fa6:	00275783          	lhu	a5,2(a4)
    80006faa:	8b9d                	andi	a5,a5,7
    80006fac:	0786                	slli	a5,a5,0x1
    80006fae:	97ba                	add	a5,a5,a4
    80006fb0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006fb4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006fb8:	6698                	ld	a4,8(a3)
    80006fba:	00275783          	lhu	a5,2(a4)
    80006fbe:	2785                	addiw	a5,a5,1
    80006fc0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006fc4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006fc8:	100017b7          	lui	a5,0x10001
    80006fcc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006fd0:	004aa783          	lw	a5,4(s5)
    80006fd4:	02c79163          	bne	a5,a2,80006ff6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006fd8:	00027917          	auipc	s2,0x27
    80006fdc:	15090913          	addi	s2,s2,336 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006fe0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006fe2:	85ca                	mv	a1,s2
    80006fe4:	8556                	mv	a0,s5
    80006fe6:	ffffb097          	auipc	ra,0xffffb
    80006fea:	052080e7          	jalr	82(ra) # 80002038 <sleep>
  while(b->disk == 1) {
    80006fee:	004aa783          	lw	a5,4(s5)
    80006ff2:	fe9788e3          	beq	a5,s1,80006fe2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006ff6:	f8042903          	lw	s2,-128(s0)
    80006ffa:	20090793          	addi	a5,s2,512
    80006ffe:	00479713          	slli	a4,a5,0x4
    80007002:	00025797          	auipc	a5,0x25
    80007006:	ffe78793          	addi	a5,a5,-2 # 8002c000 <disk>
    8000700a:	97ba                	add	a5,a5,a4
    8000700c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007010:	00027997          	auipc	s3,0x27
    80007014:	ff098993          	addi	s3,s3,-16 # 8002e000 <disk+0x2000>
    80007018:	00491713          	slli	a4,s2,0x4
    8000701c:	0009b783          	ld	a5,0(s3)
    80007020:	97ba                	add	a5,a5,a4
    80007022:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007026:	854a                	mv	a0,s2
    80007028:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000702c:	00000097          	auipc	ra,0x0
    80007030:	c5a080e7          	jalr	-934(ra) # 80006c86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80007034:	8885                	andi	s1,s1,1
    80007036:	f0ed                	bnez	s1,80007018 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80007038:	00027517          	auipc	a0,0x27
    8000703c:	0f050513          	addi	a0,a0,240 # 8002e128 <disk+0x2128>
    80007040:	ffffa097          	auipc	ra,0xffffa
    80007044:	c48080e7          	jalr	-952(ra) # 80000c88 <release>
}
    80007048:	70e6                	ld	ra,120(sp)
    8000704a:	7446                	ld	s0,112(sp)
    8000704c:	74a6                	ld	s1,104(sp)
    8000704e:	7906                	ld	s2,96(sp)
    80007050:	69e6                	ld	s3,88(sp)
    80007052:	6a46                	ld	s4,80(sp)
    80007054:	6aa6                	ld	s5,72(sp)
    80007056:	6b06                	ld	s6,64(sp)
    80007058:	7be2                	ld	s7,56(sp)
    8000705a:	7c42                	ld	s8,48(sp)
    8000705c:	7ca2                	ld	s9,40(sp)
    8000705e:	7d02                	ld	s10,32(sp)
    80007060:	6de2                	ld	s11,24(sp)
    80007062:	6109                	addi	sp,sp,128
    80007064:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80007066:	f8042503          	lw	a0,-128(s0)
    8000706a:	20050793          	addi	a5,a0,512
    8000706e:	0792                	slli	a5,a5,0x4
  if(write)
    80007070:	00025817          	auipc	a6,0x25
    80007074:	f9080813          	addi	a6,a6,-112 # 8002c000 <disk>
    80007078:	00f80733          	add	a4,a6,a5
    8000707c:	01a036b3          	snez	a3,s10
    80007080:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80007084:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007088:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000708c:	7679                	lui	a2,0xffffe
    8000708e:	963e                	add	a2,a2,a5
    80007090:	00027697          	auipc	a3,0x27
    80007094:	f7068693          	addi	a3,a3,-144 # 8002e000 <disk+0x2000>
    80007098:	6298                	ld	a4,0(a3)
    8000709a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000709c:	0a878593          	addi	a1,a5,168
    800070a0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800070a2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800070a4:	6298                	ld	a4,0(a3)
    800070a6:	9732                	add	a4,a4,a2
    800070a8:	45c1                	li	a1,16
    800070aa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800070ac:	6298                	ld	a4,0(a3)
    800070ae:	9732                	add	a4,a4,a2
    800070b0:	4585                	li	a1,1
    800070b2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800070b6:	f8442703          	lw	a4,-124(s0)
    800070ba:	628c                	ld	a1,0(a3)
    800070bc:	962e                	add	a2,a2,a1
    800070be:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800070c2:	0712                	slli	a4,a4,0x4
    800070c4:	6290                	ld	a2,0(a3)
    800070c6:	963a                	add	a2,a2,a4
    800070c8:	058a8593          	addi	a1,s5,88
    800070cc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800070ce:	6294                	ld	a3,0(a3)
    800070d0:	96ba                	add	a3,a3,a4
    800070d2:	40000613          	li	a2,1024
    800070d6:	c690                	sw	a2,8(a3)
  if(write)
    800070d8:	e40d19e3          	bnez	s10,80006f2a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800070dc:	00027697          	auipc	a3,0x27
    800070e0:	f246b683          	ld	a3,-220(a3) # 8002e000 <disk+0x2000>
    800070e4:	96ba                	add	a3,a3,a4
    800070e6:	4609                	li	a2,2
    800070e8:	00c69623          	sh	a2,12(a3)
    800070ec:	b5b1                	j	80006f38 <virtio_disk_rw+0xd2>

00000000800070ee <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800070ee:	1101                	addi	sp,sp,-32
    800070f0:	ec06                	sd	ra,24(sp)
    800070f2:	e822                	sd	s0,16(sp)
    800070f4:	e426                	sd	s1,8(sp)
    800070f6:	e04a                	sd	s2,0(sp)
    800070f8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800070fa:	00027517          	auipc	a0,0x27
    800070fe:	02e50513          	addi	a0,a0,46 # 8002e128 <disk+0x2128>
    80007102:	ffffa097          	auipc	ra,0xffffa
    80007106:	ac0080e7          	jalr	-1344(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000710a:	10001737          	lui	a4,0x10001
    8000710e:	533c                	lw	a5,96(a4)
    80007110:	8b8d                	andi	a5,a5,3
    80007112:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007114:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007118:	00027797          	auipc	a5,0x27
    8000711c:	ee878793          	addi	a5,a5,-280 # 8002e000 <disk+0x2000>
    80007120:	6b94                	ld	a3,16(a5)
    80007122:	0207d703          	lhu	a4,32(a5)
    80007126:	0026d783          	lhu	a5,2(a3)
    8000712a:	06f70163          	beq	a4,a5,8000718c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000712e:	00025917          	auipc	s2,0x25
    80007132:	ed290913          	addi	s2,s2,-302 # 8002c000 <disk>
    80007136:	00027497          	auipc	s1,0x27
    8000713a:	eca48493          	addi	s1,s1,-310 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    8000713e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007142:	6898                	ld	a4,16(s1)
    80007144:	0204d783          	lhu	a5,32(s1)
    80007148:	8b9d                	andi	a5,a5,7
    8000714a:	078e                	slli	a5,a5,0x3
    8000714c:	97ba                	add	a5,a5,a4
    8000714e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007150:	20078713          	addi	a4,a5,512
    80007154:	0712                	slli	a4,a4,0x4
    80007156:	974a                	add	a4,a4,s2
    80007158:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000715c:	e731                	bnez	a4,800071a8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000715e:	20078793          	addi	a5,a5,512
    80007162:	0792                	slli	a5,a5,0x4
    80007164:	97ca                	add	a5,a5,s2
    80007166:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007168:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000716c:	ffffb097          	auipc	ra,0xffffb
    80007170:	058080e7          	jalr	88(ra) # 800021c4 <wakeup>

    disk.used_idx += 1;
    80007174:	0204d783          	lhu	a5,32(s1)
    80007178:	2785                	addiw	a5,a5,1
    8000717a:	17c2                	slli	a5,a5,0x30
    8000717c:	93c1                	srli	a5,a5,0x30
    8000717e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007182:	6898                	ld	a4,16(s1)
    80007184:	00275703          	lhu	a4,2(a4)
    80007188:	faf71be3          	bne	a4,a5,8000713e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000718c:	00027517          	auipc	a0,0x27
    80007190:	f9c50513          	addi	a0,a0,-100 # 8002e128 <disk+0x2128>
    80007194:	ffffa097          	auipc	ra,0xffffa
    80007198:	af4080e7          	jalr	-1292(ra) # 80000c88 <release>
}
    8000719c:	60e2                	ld	ra,24(sp)
    8000719e:	6442                	ld	s0,16(sp)
    800071a0:	64a2                	ld	s1,8(sp)
    800071a2:	6902                	ld	s2,0(sp)
    800071a4:	6105                	addi	sp,sp,32
    800071a6:	8082                	ret
      panic("virtio_disk_intr status");
    800071a8:	00003517          	auipc	a0,0x3
    800071ac:	ac850513          	addi	a0,a0,-1336 # 80009c70 <syscalls+0x3e8>
    800071b0:	ffff9097          	auipc	ra,0xffff9
    800071b4:	37a080e7          	jalr	890(ra) # 8000052a <panic>
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
