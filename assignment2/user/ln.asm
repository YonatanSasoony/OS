
user/_ln:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
  if(argc != 3){
   a:	478d                	li	a5,3
   c:	02f50063          	beq	a0,a5,2c <main+0x2c>
    fprintf(2, "Usage: ln old new\n");
  10:	00001597          	auipc	a1,0x1
  14:	81858593          	addi	a1,a1,-2024 # 828 <malloc+0xec>
  18:	4509                	li	a0,2
  1a:	00000097          	auipc	ra,0x0
  1e:	636080e7          	jalr	1590(ra) # 650 <fprintf>
    exit(1);
  22:	4505                	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	2aa080e7          	jalr	682(ra) # 2ce <exit>
  2c:	84ae                	mv	s1,a1
  }
  if(link(argv[1], argv[2]) < 0)
  2e:	698c                	ld	a1,16(a1)
  30:	6488                	ld	a0,8(s1)
  32:	00000097          	auipc	ra,0x0
  36:	2fc080e7          	jalr	764(ra) # 32e <link>
  3a:	00054763          	bltz	a0,48 <main+0x48>
    fprintf(2, "link %s %s: failed\n", argv[1], argv[2]);
  exit(0);
  3e:	4501                	li	a0,0
  40:	00000097          	auipc	ra,0x0
  44:	28e080e7          	jalr	654(ra) # 2ce <exit>
    fprintf(2, "link %s %s: failed\n", argv[1], argv[2]);
  48:	6894                	ld	a3,16(s1)
  4a:	6490                	ld	a2,8(s1)
  4c:	00000597          	auipc	a1,0x0
  50:	7f458593          	addi	a1,a1,2036 # 840 <malloc+0x104>
  54:	4509                	li	a0,2
  56:	00000097          	auipc	ra,0x0
  5a:	5fa080e7          	jalr	1530(ra) # 650 <fprintf>
  5e:	b7c5                	j	3e <main+0x3e>

0000000000000060 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  60:	1141                	addi	sp,sp,-16
  62:	e422                	sd	s0,8(sp)
  64:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  66:	87aa                	mv	a5,a0
  68:	0585                	addi	a1,a1,1
  6a:	0785                	addi	a5,a5,1
  6c:	fff5c703          	lbu	a4,-1(a1)
  70:	fee78fa3          	sb	a4,-1(a5)
  74:	fb75                	bnez	a4,68 <strcpy+0x8>
    ;
  return os;
}
  76:	6422                	ld	s0,8(sp)
  78:	0141                	addi	sp,sp,16
  7a:	8082                	ret

000000000000007c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  82:	00054783          	lbu	a5,0(a0)
  86:	cb91                	beqz	a5,9a <strcmp+0x1e>
  88:	0005c703          	lbu	a4,0(a1)
  8c:	00f71763          	bne	a4,a5,9a <strcmp+0x1e>
    p++, q++;
  90:	0505                	addi	a0,a0,1
  92:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  94:	00054783          	lbu	a5,0(a0)
  98:	fbe5                	bnez	a5,88 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  9a:	0005c503          	lbu	a0,0(a1)
}
  9e:	40a7853b          	subw	a0,a5,a0
  a2:	6422                	ld	s0,8(sp)
  a4:	0141                	addi	sp,sp,16
  a6:	8082                	ret

00000000000000a8 <strlen>:

uint
strlen(const char *s)
{
  a8:	1141                	addi	sp,sp,-16
  aa:	e422                	sd	s0,8(sp)
  ac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ae:	00054783          	lbu	a5,0(a0)
  b2:	cf91                	beqz	a5,ce <strlen+0x26>
  b4:	0505                	addi	a0,a0,1
  b6:	87aa                	mv	a5,a0
  b8:	4685                	li	a3,1
  ba:	9e89                	subw	a3,a3,a0
  bc:	00f6853b          	addw	a0,a3,a5
  c0:	0785                	addi	a5,a5,1
  c2:	fff7c703          	lbu	a4,-1(a5)
  c6:	fb7d                	bnez	a4,bc <strlen+0x14>
    ;
  return n;
}
  c8:	6422                	ld	s0,8(sp)
  ca:	0141                	addi	sp,sp,16
  cc:	8082                	ret
  for(n = 0; s[n]; n++)
  ce:	4501                	li	a0,0
  d0:	bfe5                	j	c8 <strlen+0x20>

00000000000000d2 <memset>:

void*
memset(void *dst, int c, uint n)
{
  d2:	1141                	addi	sp,sp,-16
  d4:	e422                	sd	s0,8(sp)
  d6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  d8:	ca19                	beqz	a2,ee <memset+0x1c>
  da:	87aa                	mv	a5,a0
  dc:	1602                	slli	a2,a2,0x20
  de:	9201                	srli	a2,a2,0x20
  e0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  e4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  e8:	0785                	addi	a5,a5,1
  ea:	fee79de3          	bne	a5,a4,e4 <memset+0x12>
  }
  return dst;
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	addi	sp,sp,16
  f2:	8082                	ret

00000000000000f4 <strchr>:

char*
strchr(const char *s, char c)
{
  f4:	1141                	addi	sp,sp,-16
  f6:	e422                	sd	s0,8(sp)
  f8:	0800                	addi	s0,sp,16
  for(; *s; s++)
  fa:	00054783          	lbu	a5,0(a0)
  fe:	cb99                	beqz	a5,114 <strchr+0x20>
    if(*s == c)
 100:	00f58763          	beq	a1,a5,10e <strchr+0x1a>
  for(; *s; s++)
 104:	0505                	addi	a0,a0,1
 106:	00054783          	lbu	a5,0(a0)
 10a:	fbfd                	bnez	a5,100 <strchr+0xc>
      return (char*)s;
  return 0;
 10c:	4501                	li	a0,0
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret
  return 0;
 114:	4501                	li	a0,0
 116:	bfe5                	j	10e <strchr+0x1a>

0000000000000118 <gets>:

char*
gets(char *buf, int max)
{
 118:	711d                	addi	sp,sp,-96
 11a:	ec86                	sd	ra,88(sp)
 11c:	e8a2                	sd	s0,80(sp)
 11e:	e4a6                	sd	s1,72(sp)
 120:	e0ca                	sd	s2,64(sp)
 122:	fc4e                	sd	s3,56(sp)
 124:	f852                	sd	s4,48(sp)
 126:	f456                	sd	s5,40(sp)
 128:	f05a                	sd	s6,32(sp)
 12a:	ec5e                	sd	s7,24(sp)
 12c:	1080                	addi	s0,sp,96
 12e:	8baa                	mv	s7,a0
 130:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 132:	892a                	mv	s2,a0
 134:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 136:	4aa9                	li	s5,10
 138:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 13a:	89a6                	mv	s3,s1
 13c:	2485                	addiw	s1,s1,1
 13e:	0344d863          	bge	s1,s4,16e <gets+0x56>
    cc = read(0, &c, 1);
 142:	4605                	li	a2,1
 144:	faf40593          	addi	a1,s0,-81
 148:	4501                	li	a0,0
 14a:	00000097          	auipc	ra,0x0
 14e:	19c080e7          	jalr	412(ra) # 2e6 <read>
    if(cc < 1)
 152:	00a05e63          	blez	a0,16e <gets+0x56>
    buf[i++] = c;
 156:	faf44783          	lbu	a5,-81(s0)
 15a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 15e:	01578763          	beq	a5,s5,16c <gets+0x54>
 162:	0905                	addi	s2,s2,1
 164:	fd679be3          	bne	a5,s6,13a <gets+0x22>
  for(i=0; i+1 < max; ){
 168:	89a6                	mv	s3,s1
 16a:	a011                	j	16e <gets+0x56>
 16c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 16e:	99de                	add	s3,s3,s7
 170:	00098023          	sb	zero,0(s3)
  return buf;
}
 174:	855e                	mv	a0,s7
 176:	60e6                	ld	ra,88(sp)
 178:	6446                	ld	s0,80(sp)
 17a:	64a6                	ld	s1,72(sp)
 17c:	6906                	ld	s2,64(sp)
 17e:	79e2                	ld	s3,56(sp)
 180:	7a42                	ld	s4,48(sp)
 182:	7aa2                	ld	s5,40(sp)
 184:	7b02                	ld	s6,32(sp)
 186:	6be2                	ld	s7,24(sp)
 188:	6125                	addi	sp,sp,96
 18a:	8082                	ret

000000000000018c <stat>:

int
stat(const char *n, struct stat *st)
{
 18c:	1101                	addi	sp,sp,-32
 18e:	ec06                	sd	ra,24(sp)
 190:	e822                	sd	s0,16(sp)
 192:	e426                	sd	s1,8(sp)
 194:	e04a                	sd	s2,0(sp)
 196:	1000                	addi	s0,sp,32
 198:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 19a:	4581                	li	a1,0
 19c:	00000097          	auipc	ra,0x0
 1a0:	172080e7          	jalr	370(ra) # 30e <open>
  if(fd < 0)
 1a4:	02054563          	bltz	a0,1ce <stat+0x42>
 1a8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1aa:	85ca                	mv	a1,s2
 1ac:	00000097          	auipc	ra,0x0
 1b0:	17a080e7          	jalr	378(ra) # 326 <fstat>
 1b4:	892a                	mv	s2,a0
  close(fd);
 1b6:	8526                	mv	a0,s1
 1b8:	00000097          	auipc	ra,0x0
 1bc:	13e080e7          	jalr	318(ra) # 2f6 <close>
  return r;
}
 1c0:	854a                	mv	a0,s2
 1c2:	60e2                	ld	ra,24(sp)
 1c4:	6442                	ld	s0,16(sp)
 1c6:	64a2                	ld	s1,8(sp)
 1c8:	6902                	ld	s2,0(sp)
 1ca:	6105                	addi	sp,sp,32
 1cc:	8082                	ret
    return -1;
 1ce:	597d                	li	s2,-1
 1d0:	bfc5                	j	1c0 <stat+0x34>

00000000000001d2 <atoi>:

int
atoi(const char *s)
{
 1d2:	1141                	addi	sp,sp,-16
 1d4:	e422                	sd	s0,8(sp)
 1d6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1d8:	00054603          	lbu	a2,0(a0)
 1dc:	fd06079b          	addiw	a5,a2,-48
 1e0:	0ff7f793          	andi	a5,a5,255
 1e4:	4725                	li	a4,9
 1e6:	02f76963          	bltu	a4,a5,218 <atoi+0x46>
 1ea:	86aa                	mv	a3,a0
  n = 0;
 1ec:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1ee:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1f0:	0685                	addi	a3,a3,1
 1f2:	0025179b          	slliw	a5,a0,0x2
 1f6:	9fa9                	addw	a5,a5,a0
 1f8:	0017979b          	slliw	a5,a5,0x1
 1fc:	9fb1                	addw	a5,a5,a2
 1fe:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 202:	0006c603          	lbu	a2,0(a3)
 206:	fd06071b          	addiw	a4,a2,-48
 20a:	0ff77713          	andi	a4,a4,255
 20e:	fee5f1e3          	bgeu	a1,a4,1f0 <atoi+0x1e>
  return n;
}
 212:	6422                	ld	s0,8(sp)
 214:	0141                	addi	sp,sp,16
 216:	8082                	ret
  n = 0;
 218:	4501                	li	a0,0
 21a:	bfe5                	j	212 <atoi+0x40>

000000000000021c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 21c:	1141                	addi	sp,sp,-16
 21e:	e422                	sd	s0,8(sp)
 220:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 222:	02b57463          	bgeu	a0,a1,24a <memmove+0x2e>
    while(n-- > 0)
 226:	00c05f63          	blez	a2,244 <memmove+0x28>
 22a:	1602                	slli	a2,a2,0x20
 22c:	9201                	srli	a2,a2,0x20
 22e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 232:	872a                	mv	a4,a0
      *dst++ = *src++;
 234:	0585                	addi	a1,a1,1
 236:	0705                	addi	a4,a4,1
 238:	fff5c683          	lbu	a3,-1(a1)
 23c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 240:	fee79ae3          	bne	a5,a4,234 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
    dst += n;
 24a:	00c50733          	add	a4,a0,a2
    src += n;
 24e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 250:	fec05ae3          	blez	a2,244 <memmove+0x28>
 254:	fff6079b          	addiw	a5,a2,-1
 258:	1782                	slli	a5,a5,0x20
 25a:	9381                	srli	a5,a5,0x20
 25c:	fff7c793          	not	a5,a5
 260:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 262:	15fd                	addi	a1,a1,-1
 264:	177d                	addi	a4,a4,-1
 266:	0005c683          	lbu	a3,0(a1)
 26a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 26e:	fee79ae3          	bne	a5,a4,262 <memmove+0x46>
 272:	bfc9                	j	244 <memmove+0x28>

0000000000000274 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 274:	1141                	addi	sp,sp,-16
 276:	e422                	sd	s0,8(sp)
 278:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 27a:	ca05                	beqz	a2,2aa <memcmp+0x36>
 27c:	fff6069b          	addiw	a3,a2,-1
 280:	1682                	slli	a3,a3,0x20
 282:	9281                	srli	a3,a3,0x20
 284:	0685                	addi	a3,a3,1
 286:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 288:	00054783          	lbu	a5,0(a0)
 28c:	0005c703          	lbu	a4,0(a1)
 290:	00e79863          	bne	a5,a4,2a0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 294:	0505                	addi	a0,a0,1
    p2++;
 296:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 298:	fed518e3          	bne	a0,a3,288 <memcmp+0x14>
  }
  return 0;
 29c:	4501                	li	a0,0
 29e:	a019                	j	2a4 <memcmp+0x30>
      return *p1 - *p2;
 2a0:	40e7853b          	subw	a0,a5,a4
}
 2a4:	6422                	ld	s0,8(sp)
 2a6:	0141                	addi	sp,sp,16
 2a8:	8082                	ret
  return 0;
 2aa:	4501                	li	a0,0
 2ac:	bfe5                	j	2a4 <memcmp+0x30>

00000000000002ae <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ae:	1141                	addi	sp,sp,-16
 2b0:	e406                	sd	ra,8(sp)
 2b2:	e022                	sd	s0,0(sp)
 2b4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b6:	00000097          	auipc	ra,0x0
 2ba:	f66080e7          	jalr	-154(ra) # 21c <memmove>
}
 2be:	60a2                	ld	ra,8(sp)
 2c0:	6402                	ld	s0,0(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret

00000000000002c6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c6:	4885                	li	a7,1
 ecall
 2c8:	00000073          	ecall
 ret
 2cc:	8082                	ret

00000000000002ce <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ce:	4889                	li	a7,2
 ecall
 2d0:	00000073          	ecall
 ret
 2d4:	8082                	ret

00000000000002d6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d6:	488d                	li	a7,3
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2de:	4891                	li	a7,4
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <read>:
.global read
read:
 li a7, SYS_read
 2e6:	4895                	li	a7,5
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <write>:
.global write
write:
 li a7, SYS_write
 2ee:	48c1                	li	a7,16
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <close>:
.global close
close:
 li a7, SYS_close
 2f6:	48d5                	li	a7,21
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <kill>:
.global kill
kill:
 li a7, SYS_kill
 2fe:	4899                	li	a7,6
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <exec>:
.global exec
exec:
 li a7, SYS_exec
 306:	489d                	li	a7,7
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <open>:
.global open
open:
 li a7, SYS_open
 30e:	48bd                	li	a7,15
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 316:	48c5                	li	a7,17
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 31e:	48c9                	li	a7,18
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 326:	48a1                	li	a7,8
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <link>:
.global link
link:
 li a7, SYS_link
 32e:	48cd                	li	a7,19
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 336:	48d1                	li	a7,20
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 33e:	48a5                	li	a7,9
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <dup>:
.global dup
dup:
 li a7, SYS_dup
 346:	48a9                	li	a7,10
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 34e:	48ad                	li	a7,11
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 356:	48b1                	li	a7,12
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 35e:	48b5                	li	a7,13
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 366:	48b9                	li	a7,14
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 36e:	48d9                	li	a7,22
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 376:	48dd                	li	a7,23
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 37e:	48e1                	li	a7,24
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 386:	48e5                	li	a7,25
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 38e:	48e9                	li	a7,26
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 396:	48ed                	li	a7,27
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 39e:	48f1                	li	a7,28
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3a6:	1101                	addi	sp,sp,-32
 3a8:	ec06                	sd	ra,24(sp)
 3aa:	e822                	sd	s0,16(sp)
 3ac:	1000                	addi	s0,sp,32
 3ae:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b2:	4605                	li	a2,1
 3b4:	fef40593          	addi	a1,s0,-17
 3b8:	00000097          	auipc	ra,0x0
 3bc:	f36080e7          	jalr	-202(ra) # 2ee <write>
}
 3c0:	60e2                	ld	ra,24(sp)
 3c2:	6442                	ld	s0,16(sp)
 3c4:	6105                	addi	sp,sp,32
 3c6:	8082                	ret

00000000000003c8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3c8:	7139                	addi	sp,sp,-64
 3ca:	fc06                	sd	ra,56(sp)
 3cc:	f822                	sd	s0,48(sp)
 3ce:	f426                	sd	s1,40(sp)
 3d0:	f04a                	sd	s2,32(sp)
 3d2:	ec4e                	sd	s3,24(sp)
 3d4:	0080                	addi	s0,sp,64
 3d6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3d8:	c299                	beqz	a3,3de <printint+0x16>
 3da:	0805c863          	bltz	a1,46a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3de:	2581                	sext.w	a1,a1
  neg = 0;
 3e0:	4881                	li	a7,0
 3e2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3e6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3e8:	2601                	sext.w	a2,a2
 3ea:	00000517          	auipc	a0,0x0
 3ee:	47650513          	addi	a0,a0,1142 # 860 <digits>
 3f2:	883a                	mv	a6,a4
 3f4:	2705                	addiw	a4,a4,1
 3f6:	02c5f7bb          	remuw	a5,a1,a2
 3fa:	1782                	slli	a5,a5,0x20
 3fc:	9381                	srli	a5,a5,0x20
 3fe:	97aa                	add	a5,a5,a0
 400:	0007c783          	lbu	a5,0(a5)
 404:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 408:	0005879b          	sext.w	a5,a1
 40c:	02c5d5bb          	divuw	a1,a1,a2
 410:	0685                	addi	a3,a3,1
 412:	fec7f0e3          	bgeu	a5,a2,3f2 <printint+0x2a>
  if(neg)
 416:	00088b63          	beqz	a7,42c <printint+0x64>
    buf[i++] = '-';
 41a:	fd040793          	addi	a5,s0,-48
 41e:	973e                	add	a4,a4,a5
 420:	02d00793          	li	a5,45
 424:	fef70823          	sb	a5,-16(a4)
 428:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 42c:	02e05863          	blez	a4,45c <printint+0x94>
 430:	fc040793          	addi	a5,s0,-64
 434:	00e78933          	add	s2,a5,a4
 438:	fff78993          	addi	s3,a5,-1
 43c:	99ba                	add	s3,s3,a4
 43e:	377d                	addiw	a4,a4,-1
 440:	1702                	slli	a4,a4,0x20
 442:	9301                	srli	a4,a4,0x20
 444:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 448:	fff94583          	lbu	a1,-1(s2)
 44c:	8526                	mv	a0,s1
 44e:	00000097          	auipc	ra,0x0
 452:	f58080e7          	jalr	-168(ra) # 3a6 <putc>
  while(--i >= 0)
 456:	197d                	addi	s2,s2,-1
 458:	ff3918e3          	bne	s2,s3,448 <printint+0x80>
}
 45c:	70e2                	ld	ra,56(sp)
 45e:	7442                	ld	s0,48(sp)
 460:	74a2                	ld	s1,40(sp)
 462:	7902                	ld	s2,32(sp)
 464:	69e2                	ld	s3,24(sp)
 466:	6121                	addi	sp,sp,64
 468:	8082                	ret
    x = -xx;
 46a:	40b005bb          	negw	a1,a1
    neg = 1;
 46e:	4885                	li	a7,1
    x = -xx;
 470:	bf8d                	j	3e2 <printint+0x1a>

0000000000000472 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 472:	7119                	addi	sp,sp,-128
 474:	fc86                	sd	ra,120(sp)
 476:	f8a2                	sd	s0,112(sp)
 478:	f4a6                	sd	s1,104(sp)
 47a:	f0ca                	sd	s2,96(sp)
 47c:	ecce                	sd	s3,88(sp)
 47e:	e8d2                	sd	s4,80(sp)
 480:	e4d6                	sd	s5,72(sp)
 482:	e0da                	sd	s6,64(sp)
 484:	fc5e                	sd	s7,56(sp)
 486:	f862                	sd	s8,48(sp)
 488:	f466                	sd	s9,40(sp)
 48a:	f06a                	sd	s10,32(sp)
 48c:	ec6e                	sd	s11,24(sp)
 48e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 490:	0005c903          	lbu	s2,0(a1)
 494:	18090f63          	beqz	s2,632 <vprintf+0x1c0>
 498:	8aaa                	mv	s5,a0
 49a:	8b32                	mv	s6,a2
 49c:	00158493          	addi	s1,a1,1
  state = 0;
 4a0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a2:	02500a13          	li	s4,37
      if(c == 'd'){
 4a6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4aa:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4ae:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4b2:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4b6:	00000b97          	auipc	s7,0x0
 4ba:	3aab8b93          	addi	s7,s7,938 # 860 <digits>
 4be:	a839                	j	4dc <vprintf+0x6a>
        putc(fd, c);
 4c0:	85ca                	mv	a1,s2
 4c2:	8556                	mv	a0,s5
 4c4:	00000097          	auipc	ra,0x0
 4c8:	ee2080e7          	jalr	-286(ra) # 3a6 <putc>
 4cc:	a019                	j	4d2 <vprintf+0x60>
    } else if(state == '%'){
 4ce:	01498f63          	beq	s3,s4,4ec <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4d2:	0485                	addi	s1,s1,1
 4d4:	fff4c903          	lbu	s2,-1(s1)
 4d8:	14090d63          	beqz	s2,632 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4dc:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4e0:	fe0997e3          	bnez	s3,4ce <vprintf+0x5c>
      if(c == '%'){
 4e4:	fd479ee3          	bne	a5,s4,4c0 <vprintf+0x4e>
        state = '%';
 4e8:	89be                	mv	s3,a5
 4ea:	b7e5                	j	4d2 <vprintf+0x60>
      if(c == 'd'){
 4ec:	05878063          	beq	a5,s8,52c <vprintf+0xba>
      } else if(c == 'l') {
 4f0:	05978c63          	beq	a5,s9,548 <vprintf+0xd6>
      } else if(c == 'x') {
 4f4:	07a78863          	beq	a5,s10,564 <vprintf+0xf2>
      } else if(c == 'p') {
 4f8:	09b78463          	beq	a5,s11,580 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4fc:	07300713          	li	a4,115
 500:	0ce78663          	beq	a5,a4,5cc <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 504:	06300713          	li	a4,99
 508:	0ee78e63          	beq	a5,a4,604 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 50c:	11478863          	beq	a5,s4,61c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 510:	85d2                	mv	a1,s4
 512:	8556                	mv	a0,s5
 514:	00000097          	auipc	ra,0x0
 518:	e92080e7          	jalr	-366(ra) # 3a6 <putc>
        putc(fd, c);
 51c:	85ca                	mv	a1,s2
 51e:	8556                	mv	a0,s5
 520:	00000097          	auipc	ra,0x0
 524:	e86080e7          	jalr	-378(ra) # 3a6 <putc>
      }
      state = 0;
 528:	4981                	li	s3,0
 52a:	b765                	j	4d2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 52c:	008b0913          	addi	s2,s6,8
 530:	4685                	li	a3,1
 532:	4629                	li	a2,10
 534:	000b2583          	lw	a1,0(s6)
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e8e080e7          	jalr	-370(ra) # 3c8 <printint>
 542:	8b4a                	mv	s6,s2
      state = 0;
 544:	4981                	li	s3,0
 546:	b771                	j	4d2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 548:	008b0913          	addi	s2,s6,8
 54c:	4681                	li	a3,0
 54e:	4629                	li	a2,10
 550:	000b2583          	lw	a1,0(s6)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e72080e7          	jalr	-398(ra) # 3c8 <printint>
 55e:	8b4a                	mv	s6,s2
      state = 0;
 560:	4981                	li	s3,0
 562:	bf85                	j	4d2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 564:	008b0913          	addi	s2,s6,8
 568:	4681                	li	a3,0
 56a:	4641                	li	a2,16
 56c:	000b2583          	lw	a1,0(s6)
 570:	8556                	mv	a0,s5
 572:	00000097          	auipc	ra,0x0
 576:	e56080e7          	jalr	-426(ra) # 3c8 <printint>
 57a:	8b4a                	mv	s6,s2
      state = 0;
 57c:	4981                	li	s3,0
 57e:	bf91                	j	4d2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 580:	008b0793          	addi	a5,s6,8
 584:	f8f43423          	sd	a5,-120(s0)
 588:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 58c:	03000593          	li	a1,48
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e14080e7          	jalr	-492(ra) # 3a6 <putc>
  putc(fd, 'x');
 59a:	85ea                	mv	a1,s10
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	e08080e7          	jalr	-504(ra) # 3a6 <putc>
 5a6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5a8:	03c9d793          	srli	a5,s3,0x3c
 5ac:	97de                	add	a5,a5,s7
 5ae:	0007c583          	lbu	a1,0(a5)
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	df2080e7          	jalr	-526(ra) # 3a6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5bc:	0992                	slli	s3,s3,0x4
 5be:	397d                	addiw	s2,s2,-1
 5c0:	fe0914e3          	bnez	s2,5a8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5c4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b721                	j	4d2 <vprintf+0x60>
        s = va_arg(ap, char*);
 5cc:	008b0993          	addi	s3,s6,8
 5d0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5d4:	02090163          	beqz	s2,5f6 <vprintf+0x184>
        while(*s != 0){
 5d8:	00094583          	lbu	a1,0(s2)
 5dc:	c9a1                	beqz	a1,62c <vprintf+0x1ba>
          putc(fd, *s);
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	dc6080e7          	jalr	-570(ra) # 3a6 <putc>
          s++;
 5e8:	0905                	addi	s2,s2,1
        while(*s != 0){
 5ea:	00094583          	lbu	a1,0(s2)
 5ee:	f9e5                	bnez	a1,5de <vprintf+0x16c>
        s = va_arg(ap, char*);
 5f0:	8b4e                	mv	s6,s3
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	bdf9                	j	4d2 <vprintf+0x60>
          s = "(null)";
 5f6:	00000917          	auipc	s2,0x0
 5fa:	26290913          	addi	s2,s2,610 # 858 <malloc+0x11c>
        while(*s != 0){
 5fe:	02800593          	li	a1,40
 602:	bff1                	j	5de <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 604:	008b0913          	addi	s2,s6,8
 608:	000b4583          	lbu	a1,0(s6)
 60c:	8556                	mv	a0,s5
 60e:	00000097          	auipc	ra,0x0
 612:	d98080e7          	jalr	-616(ra) # 3a6 <putc>
 616:	8b4a                	mv	s6,s2
      state = 0;
 618:	4981                	li	s3,0
 61a:	bd65                	j	4d2 <vprintf+0x60>
        putc(fd, c);
 61c:	85d2                	mv	a1,s4
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	d86080e7          	jalr	-634(ra) # 3a6 <putc>
      state = 0;
 628:	4981                	li	s3,0
 62a:	b565                	j	4d2 <vprintf+0x60>
        s = va_arg(ap, char*);
 62c:	8b4e                	mv	s6,s3
      state = 0;
 62e:	4981                	li	s3,0
 630:	b54d                	j	4d2 <vprintf+0x60>
    }
  }
}
 632:	70e6                	ld	ra,120(sp)
 634:	7446                	ld	s0,112(sp)
 636:	74a6                	ld	s1,104(sp)
 638:	7906                	ld	s2,96(sp)
 63a:	69e6                	ld	s3,88(sp)
 63c:	6a46                	ld	s4,80(sp)
 63e:	6aa6                	ld	s5,72(sp)
 640:	6b06                	ld	s6,64(sp)
 642:	7be2                	ld	s7,56(sp)
 644:	7c42                	ld	s8,48(sp)
 646:	7ca2                	ld	s9,40(sp)
 648:	7d02                	ld	s10,32(sp)
 64a:	6de2                	ld	s11,24(sp)
 64c:	6109                	addi	sp,sp,128
 64e:	8082                	ret

0000000000000650 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 650:	715d                	addi	sp,sp,-80
 652:	ec06                	sd	ra,24(sp)
 654:	e822                	sd	s0,16(sp)
 656:	1000                	addi	s0,sp,32
 658:	e010                	sd	a2,0(s0)
 65a:	e414                	sd	a3,8(s0)
 65c:	e818                	sd	a4,16(s0)
 65e:	ec1c                	sd	a5,24(s0)
 660:	03043023          	sd	a6,32(s0)
 664:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 668:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 66c:	8622                	mv	a2,s0
 66e:	00000097          	auipc	ra,0x0
 672:	e04080e7          	jalr	-508(ra) # 472 <vprintf>
}
 676:	60e2                	ld	ra,24(sp)
 678:	6442                	ld	s0,16(sp)
 67a:	6161                	addi	sp,sp,80
 67c:	8082                	ret

000000000000067e <printf>:

void
printf(const char *fmt, ...)
{
 67e:	711d                	addi	sp,sp,-96
 680:	ec06                	sd	ra,24(sp)
 682:	e822                	sd	s0,16(sp)
 684:	1000                	addi	s0,sp,32
 686:	e40c                	sd	a1,8(s0)
 688:	e810                	sd	a2,16(s0)
 68a:	ec14                	sd	a3,24(s0)
 68c:	f018                	sd	a4,32(s0)
 68e:	f41c                	sd	a5,40(s0)
 690:	03043823          	sd	a6,48(s0)
 694:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 698:	00840613          	addi	a2,s0,8
 69c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6a0:	85aa                	mv	a1,a0
 6a2:	4505                	li	a0,1
 6a4:	00000097          	auipc	ra,0x0
 6a8:	dce080e7          	jalr	-562(ra) # 472 <vprintf>
}
 6ac:	60e2                	ld	ra,24(sp)
 6ae:	6442                	ld	s0,16(sp)
 6b0:	6125                	addi	sp,sp,96
 6b2:	8082                	ret

00000000000006b4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b4:	1141                	addi	sp,sp,-16
 6b6:	e422                	sd	s0,8(sp)
 6b8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ba:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6be:	00000797          	auipc	a5,0x0
 6c2:	1ba7b783          	ld	a5,442(a5) # 878 <freep>
 6c6:	a805                	j	6f6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c8:	4618                	lw	a4,8(a2)
 6ca:	9db9                	addw	a1,a1,a4
 6cc:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6d0:	6398                	ld	a4,0(a5)
 6d2:	6318                	ld	a4,0(a4)
 6d4:	fee53823          	sd	a4,-16(a0)
 6d8:	a091                	j	71c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6da:	ff852703          	lw	a4,-8(a0)
 6de:	9e39                	addw	a2,a2,a4
 6e0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6e2:	ff053703          	ld	a4,-16(a0)
 6e6:	e398                	sd	a4,0(a5)
 6e8:	a099                	j	72e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ea:	6398                	ld	a4,0(a5)
 6ec:	00e7e463          	bltu	a5,a4,6f4 <free+0x40>
 6f0:	00e6ea63          	bltu	a3,a4,704 <free+0x50>
{
 6f4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f6:	fed7fae3          	bgeu	a5,a3,6ea <free+0x36>
 6fa:	6398                	ld	a4,0(a5)
 6fc:	00e6e463          	bltu	a3,a4,704 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 700:	fee7eae3          	bltu	a5,a4,6f4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 704:	ff852583          	lw	a1,-8(a0)
 708:	6390                	ld	a2,0(a5)
 70a:	02059813          	slli	a6,a1,0x20
 70e:	01c85713          	srli	a4,a6,0x1c
 712:	9736                	add	a4,a4,a3
 714:	fae60ae3          	beq	a2,a4,6c8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 718:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 71c:	4790                	lw	a2,8(a5)
 71e:	02061593          	slli	a1,a2,0x20
 722:	01c5d713          	srli	a4,a1,0x1c
 726:	973e                	add	a4,a4,a5
 728:	fae689e3          	beq	a3,a4,6da <free+0x26>
  } else
    p->s.ptr = bp;
 72c:	e394                	sd	a3,0(a5)
  freep = p;
 72e:	00000717          	auipc	a4,0x0
 732:	14f73523          	sd	a5,330(a4) # 878 <freep>
}
 736:	6422                	ld	s0,8(sp)
 738:	0141                	addi	sp,sp,16
 73a:	8082                	ret

000000000000073c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 73c:	7139                	addi	sp,sp,-64
 73e:	fc06                	sd	ra,56(sp)
 740:	f822                	sd	s0,48(sp)
 742:	f426                	sd	s1,40(sp)
 744:	f04a                	sd	s2,32(sp)
 746:	ec4e                	sd	s3,24(sp)
 748:	e852                	sd	s4,16(sp)
 74a:	e456                	sd	s5,8(sp)
 74c:	e05a                	sd	s6,0(sp)
 74e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 750:	02051493          	slli	s1,a0,0x20
 754:	9081                	srli	s1,s1,0x20
 756:	04bd                	addi	s1,s1,15
 758:	8091                	srli	s1,s1,0x4
 75a:	0014899b          	addiw	s3,s1,1
 75e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 760:	00000517          	auipc	a0,0x0
 764:	11853503          	ld	a0,280(a0) # 878 <freep>
 768:	c515                	beqz	a0,794 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 76a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 76c:	4798                	lw	a4,8(a5)
 76e:	02977f63          	bgeu	a4,s1,7ac <malloc+0x70>
 772:	8a4e                	mv	s4,s3
 774:	0009871b          	sext.w	a4,s3
 778:	6685                	lui	a3,0x1
 77a:	00d77363          	bgeu	a4,a3,780 <malloc+0x44>
 77e:	6a05                	lui	s4,0x1
 780:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 784:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 788:	00000917          	auipc	s2,0x0
 78c:	0f090913          	addi	s2,s2,240 # 878 <freep>
  if(p == (char*)-1)
 790:	5afd                	li	s5,-1
 792:	a895                	j	806 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 794:	00000797          	auipc	a5,0x0
 798:	0ec78793          	addi	a5,a5,236 # 880 <base>
 79c:	00000717          	auipc	a4,0x0
 7a0:	0cf73e23          	sd	a5,220(a4) # 878 <freep>
 7a4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7a6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7aa:	b7e1                	j	772 <malloc+0x36>
      if(p->s.size == nunits)
 7ac:	02e48c63          	beq	s1,a4,7e4 <malloc+0xa8>
        p->s.size -= nunits;
 7b0:	4137073b          	subw	a4,a4,s3
 7b4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7b6:	02071693          	slli	a3,a4,0x20
 7ba:	01c6d713          	srli	a4,a3,0x1c
 7be:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7c0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7c4:	00000717          	auipc	a4,0x0
 7c8:	0aa73a23          	sd	a0,180(a4) # 878 <freep>
      return (void*)(p + 1);
 7cc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7d0:	70e2                	ld	ra,56(sp)
 7d2:	7442                	ld	s0,48(sp)
 7d4:	74a2                	ld	s1,40(sp)
 7d6:	7902                	ld	s2,32(sp)
 7d8:	69e2                	ld	s3,24(sp)
 7da:	6a42                	ld	s4,16(sp)
 7dc:	6aa2                	ld	s5,8(sp)
 7de:	6b02                	ld	s6,0(sp)
 7e0:	6121                	addi	sp,sp,64
 7e2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7e4:	6398                	ld	a4,0(a5)
 7e6:	e118                	sd	a4,0(a0)
 7e8:	bff1                	j	7c4 <malloc+0x88>
  hp->s.size = nu;
 7ea:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ee:	0541                	addi	a0,a0,16
 7f0:	00000097          	auipc	ra,0x0
 7f4:	ec4080e7          	jalr	-316(ra) # 6b4 <free>
  return freep;
 7f8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7fc:	d971                	beqz	a0,7d0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7fe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 800:	4798                	lw	a4,8(a5)
 802:	fa9775e3          	bgeu	a4,s1,7ac <malloc+0x70>
    if(p == freep)
 806:	00093703          	ld	a4,0(s2)
 80a:	853e                	mv	a0,a5
 80c:	fef719e3          	bne	a4,a5,7fe <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 810:	8552                	mv	a0,s4
 812:	00000097          	auipc	ra,0x0
 816:	b44080e7          	jalr	-1212(ra) # 356 <sbrk>
  if(p == (char*)-1)
 81a:	fd5518e3          	bne	a0,s5,7ea <malloc+0xae>
        return 0;
 81e:	4501                	li	a0,0
 820:	bf45                	j	7d0 <malloc+0x94>
