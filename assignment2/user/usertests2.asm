
user/_usertests2:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
   6:	87aa                	mv	a5,a0
   8:	0585                	addi	a1,a1,1
   a:	0785                	addi	a5,a5,1
   c:	fff5c703          	lbu	a4,-1(a1)
  10:	fee78fa3          	sb	a4,-1(a5)
  14:	fb75                	bnez	a4,8 <strcpy+0x8>
    ;
  return os;
}
  16:	6422                	ld	s0,8(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret

000000000000001c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1c:	1141                	addi	sp,sp,-16
  1e:	e422                	sd	s0,8(sp)
  20:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  22:	00054783          	lbu	a5,0(a0)
  26:	cb91                	beqz	a5,3a <strcmp+0x1e>
  28:	0005c703          	lbu	a4,0(a1)
  2c:	00f71763          	bne	a4,a5,3a <strcmp+0x1e>
    p++, q++;
  30:	0505                	addi	a0,a0,1
  32:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  34:	00054783          	lbu	a5,0(a0)
  38:	fbe5                	bnez	a5,28 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  3a:	0005c503          	lbu	a0,0(a1)
}
  3e:	40a7853b          	subw	a0,a5,a0
  42:	6422                	ld	s0,8(sp)
  44:	0141                	addi	sp,sp,16
  46:	8082                	ret

0000000000000048 <strlen>:

uint
strlen(const char *s)
{
  48:	1141                	addi	sp,sp,-16
  4a:	e422                	sd	s0,8(sp)
  4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  4e:	00054783          	lbu	a5,0(a0)
  52:	cf91                	beqz	a5,6e <strlen+0x26>
  54:	0505                	addi	a0,a0,1
  56:	87aa                	mv	a5,a0
  58:	4685                	li	a3,1
  5a:	9e89                	subw	a3,a3,a0
  5c:	00f6853b          	addw	a0,a3,a5
  60:	0785                	addi	a5,a5,1
  62:	fff7c703          	lbu	a4,-1(a5)
  66:	fb7d                	bnez	a4,5c <strlen+0x14>
    ;
  return n;
}
  68:	6422                	ld	s0,8(sp)
  6a:	0141                	addi	sp,sp,16
  6c:	8082                	ret
  for(n = 0; s[n]; n++)
  6e:	4501                	li	a0,0
  70:	bfe5                	j	68 <strlen+0x20>

0000000000000072 <memset>:

void*
memset(void *dst, int c, uint n)
{
  72:	1141                	addi	sp,sp,-16
  74:	e422                	sd	s0,8(sp)
  76:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  78:	ca19                	beqz	a2,8e <memset+0x1c>
  7a:	87aa                	mv	a5,a0
  7c:	1602                	slli	a2,a2,0x20
  7e:	9201                	srli	a2,a2,0x20
  80:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  84:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  88:	0785                	addi	a5,a5,1
  8a:	fee79de3          	bne	a5,a4,84 <memset+0x12>
  }
  return dst;
}
  8e:	6422                	ld	s0,8(sp)
  90:	0141                	addi	sp,sp,16
  92:	8082                	ret

0000000000000094 <strchr>:

char*
strchr(const char *s, char c)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  for(; *s; s++)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	cb99                	beqz	a5,b4 <strchr+0x20>
    if(*s == c)
  a0:	00f58763          	beq	a1,a5,ae <strchr+0x1a>
  for(; *s; s++)
  a4:	0505                	addi	a0,a0,1
  a6:	00054783          	lbu	a5,0(a0)
  aa:	fbfd                	bnez	a5,a0 <strchr+0xc>
      return (char*)s;
  return 0;
  ac:	4501                	li	a0,0
}
  ae:	6422                	ld	s0,8(sp)
  b0:	0141                	addi	sp,sp,16
  b2:	8082                	ret
  return 0;
  b4:	4501                	li	a0,0
  b6:	bfe5                	j	ae <strchr+0x1a>

00000000000000b8 <gets>:

char*
gets(char *buf, int max)
{
  b8:	711d                	addi	sp,sp,-96
  ba:	ec86                	sd	ra,88(sp)
  bc:	e8a2                	sd	s0,80(sp)
  be:	e4a6                	sd	s1,72(sp)
  c0:	e0ca                	sd	s2,64(sp)
  c2:	fc4e                	sd	s3,56(sp)
  c4:	f852                	sd	s4,48(sp)
  c6:	f456                	sd	s5,40(sp)
  c8:	f05a                	sd	s6,32(sp)
  ca:	ec5e                	sd	s7,24(sp)
  cc:	1080                	addi	s0,sp,96
  ce:	8baa                	mv	s7,a0
  d0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
  d2:	892a                	mv	s2,a0
  d4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
  d6:	4aa9                	li	s5,10
  d8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
  da:	89a6                	mv	s3,s1
  dc:	2485                	addiw	s1,s1,1
  de:	0344d863          	bge	s1,s4,10e <gets+0x56>
    cc = read(0, &c, 1);
  e2:	4605                	li	a2,1
  e4:	faf40593          	addi	a1,s0,-81
  e8:	4501                	li	a0,0
  ea:	00000097          	auipc	ra,0x0
  ee:	19c080e7          	jalr	412(ra) # 286 <read>
    if(cc < 1)
  f2:	00a05e63          	blez	a0,10e <gets+0x56>
    buf[i++] = c;
  f6:	faf44783          	lbu	a5,-81(s0)
  fa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
  fe:	01578763          	beq	a5,s5,10c <gets+0x54>
 102:	0905                	addi	s2,s2,1
 104:	fd679be3          	bne	a5,s6,da <gets+0x22>
  for(i=0; i+1 < max; ){
 108:	89a6                	mv	s3,s1
 10a:	a011                	j	10e <gets+0x56>
 10c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 10e:	99de                	add	s3,s3,s7
 110:	00098023          	sb	zero,0(s3)
  return buf;
}
 114:	855e                	mv	a0,s7
 116:	60e6                	ld	ra,88(sp)
 118:	6446                	ld	s0,80(sp)
 11a:	64a6                	ld	s1,72(sp)
 11c:	6906                	ld	s2,64(sp)
 11e:	79e2                	ld	s3,56(sp)
 120:	7a42                	ld	s4,48(sp)
 122:	7aa2                	ld	s5,40(sp)
 124:	7b02                	ld	s6,32(sp)
 126:	6be2                	ld	s7,24(sp)
 128:	6125                	addi	sp,sp,96
 12a:	8082                	ret

000000000000012c <stat>:

int
stat(const char *n, struct stat *st)
{
 12c:	1101                	addi	sp,sp,-32
 12e:	ec06                	sd	ra,24(sp)
 130:	e822                	sd	s0,16(sp)
 132:	e426                	sd	s1,8(sp)
 134:	e04a                	sd	s2,0(sp)
 136:	1000                	addi	s0,sp,32
 138:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 13a:	4581                	li	a1,0
 13c:	00000097          	auipc	ra,0x0
 140:	172080e7          	jalr	370(ra) # 2ae <open>
  if(fd < 0)
 144:	02054563          	bltz	a0,16e <stat+0x42>
 148:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 14a:	85ca                	mv	a1,s2
 14c:	00000097          	auipc	ra,0x0
 150:	17a080e7          	jalr	378(ra) # 2c6 <fstat>
 154:	892a                	mv	s2,a0
  close(fd);
 156:	8526                	mv	a0,s1
 158:	00000097          	auipc	ra,0x0
 15c:	13e080e7          	jalr	318(ra) # 296 <close>
  return r;
}
 160:	854a                	mv	a0,s2
 162:	60e2                	ld	ra,24(sp)
 164:	6442                	ld	s0,16(sp)
 166:	64a2                	ld	s1,8(sp)
 168:	6902                	ld	s2,0(sp)
 16a:	6105                	addi	sp,sp,32
 16c:	8082                	ret
    return -1;
 16e:	597d                	li	s2,-1
 170:	bfc5                	j	160 <stat+0x34>

0000000000000172 <atoi>:

int
atoi(const char *s)
{
 172:	1141                	addi	sp,sp,-16
 174:	e422                	sd	s0,8(sp)
 176:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 178:	00054603          	lbu	a2,0(a0)
 17c:	fd06079b          	addiw	a5,a2,-48
 180:	0ff7f793          	andi	a5,a5,255
 184:	4725                	li	a4,9
 186:	02f76963          	bltu	a4,a5,1b8 <atoi+0x46>
 18a:	86aa                	mv	a3,a0
  n = 0;
 18c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 18e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 190:	0685                	addi	a3,a3,1
 192:	0025179b          	slliw	a5,a0,0x2
 196:	9fa9                	addw	a5,a5,a0
 198:	0017979b          	slliw	a5,a5,0x1
 19c:	9fb1                	addw	a5,a5,a2
 19e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1a2:	0006c603          	lbu	a2,0(a3)
 1a6:	fd06071b          	addiw	a4,a2,-48
 1aa:	0ff77713          	andi	a4,a4,255
 1ae:	fee5f1e3          	bgeu	a1,a4,190 <atoi+0x1e>
  return n;
}
 1b2:	6422                	ld	s0,8(sp)
 1b4:	0141                	addi	sp,sp,16
 1b6:	8082                	ret
  n = 0;
 1b8:	4501                	li	a0,0
 1ba:	bfe5                	j	1b2 <atoi+0x40>

00000000000001bc <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1bc:	1141                	addi	sp,sp,-16
 1be:	e422                	sd	s0,8(sp)
 1c0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1c2:	02b57463          	bgeu	a0,a1,1ea <memmove+0x2e>
    while(n-- > 0)
 1c6:	00c05f63          	blez	a2,1e4 <memmove+0x28>
 1ca:	1602                	slli	a2,a2,0x20
 1cc:	9201                	srli	a2,a2,0x20
 1ce:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 1d2:	872a                	mv	a4,a0
      *dst++ = *src++;
 1d4:	0585                	addi	a1,a1,1
 1d6:	0705                	addi	a4,a4,1
 1d8:	fff5c683          	lbu	a3,-1(a1)
 1dc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 1e0:	fee79ae3          	bne	a5,a4,1d4 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 1e4:	6422                	ld	s0,8(sp)
 1e6:	0141                	addi	sp,sp,16
 1e8:	8082                	ret
    dst += n;
 1ea:	00c50733          	add	a4,a0,a2
    src += n;
 1ee:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 1f0:	fec05ae3          	blez	a2,1e4 <memmove+0x28>
 1f4:	fff6079b          	addiw	a5,a2,-1
 1f8:	1782                	slli	a5,a5,0x20
 1fa:	9381                	srli	a5,a5,0x20
 1fc:	fff7c793          	not	a5,a5
 200:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 202:	15fd                	addi	a1,a1,-1
 204:	177d                	addi	a4,a4,-1
 206:	0005c683          	lbu	a3,0(a1)
 20a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 20e:	fee79ae3          	bne	a5,a4,202 <memmove+0x46>
 212:	bfc9                	j	1e4 <memmove+0x28>

0000000000000214 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 214:	1141                	addi	sp,sp,-16
 216:	e422                	sd	s0,8(sp)
 218:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 21a:	ca05                	beqz	a2,24a <memcmp+0x36>
 21c:	fff6069b          	addiw	a3,a2,-1
 220:	1682                	slli	a3,a3,0x20
 222:	9281                	srli	a3,a3,0x20
 224:	0685                	addi	a3,a3,1
 226:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 228:	00054783          	lbu	a5,0(a0)
 22c:	0005c703          	lbu	a4,0(a1)
 230:	00e79863          	bne	a5,a4,240 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 234:	0505                	addi	a0,a0,1
    p2++;
 236:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 238:	fed518e3          	bne	a0,a3,228 <memcmp+0x14>
  }
  return 0;
 23c:	4501                	li	a0,0
 23e:	a019                	j	244 <memcmp+0x30>
      return *p1 - *p2;
 240:	40e7853b          	subw	a0,a5,a4
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
  return 0;
 24a:	4501                	li	a0,0
 24c:	bfe5                	j	244 <memcmp+0x30>

000000000000024e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e406                	sd	ra,8(sp)
 252:	e022                	sd	s0,0(sp)
 254:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 256:	00000097          	auipc	ra,0x0
 25a:	f66080e7          	jalr	-154(ra) # 1bc <memmove>
}
 25e:	60a2                	ld	ra,8(sp)
 260:	6402                	ld	s0,0(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret

0000000000000266 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 266:	4885                	li	a7,1
 ecall
 268:	00000073          	ecall
 ret
 26c:	8082                	ret

000000000000026e <exit>:
.global exit
exit:
 li a7, SYS_exit
 26e:	4889                	li	a7,2
 ecall
 270:	00000073          	ecall
 ret
 274:	8082                	ret

0000000000000276 <wait>:
.global wait
wait:
 li a7, SYS_wait
 276:	488d                	li	a7,3
 ecall
 278:	00000073          	ecall
 ret
 27c:	8082                	ret

000000000000027e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 27e:	4891                	li	a7,4
 ecall
 280:	00000073          	ecall
 ret
 284:	8082                	ret

0000000000000286 <read>:
.global read
read:
 li a7, SYS_read
 286:	4895                	li	a7,5
 ecall
 288:	00000073          	ecall
 ret
 28c:	8082                	ret

000000000000028e <write>:
.global write
write:
 li a7, SYS_write
 28e:	48c1                	li	a7,16
 ecall
 290:	00000073          	ecall
 ret
 294:	8082                	ret

0000000000000296 <close>:
.global close
close:
 li a7, SYS_close
 296:	48d5                	li	a7,21
 ecall
 298:	00000073          	ecall
 ret
 29c:	8082                	ret

000000000000029e <kill>:
.global kill
kill:
 li a7, SYS_kill
 29e:	4899                	li	a7,6
 ecall
 2a0:	00000073          	ecall
 ret
 2a4:	8082                	ret

00000000000002a6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2a6:	489d                	li	a7,7
 ecall
 2a8:	00000073          	ecall
 ret
 2ac:	8082                	ret

00000000000002ae <open>:
.global open
open:
 li a7, SYS_open
 2ae:	48bd                	li	a7,15
 ecall
 2b0:	00000073          	ecall
 ret
 2b4:	8082                	ret

00000000000002b6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2b6:	48c5                	li	a7,17
 ecall
 2b8:	00000073          	ecall
 ret
 2bc:	8082                	ret

00000000000002be <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2be:	48c9                	li	a7,18
 ecall
 2c0:	00000073          	ecall
 ret
 2c4:	8082                	ret

00000000000002c6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2c6:	48a1                	li	a7,8
 ecall
 2c8:	00000073          	ecall
 ret
 2cc:	8082                	ret

00000000000002ce <link>:
.global link
link:
 li a7, SYS_link
 2ce:	48cd                	li	a7,19
 ecall
 2d0:	00000073          	ecall
 ret
 2d4:	8082                	ret

00000000000002d6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2d6:	48d1                	li	a7,20
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 2de:	48a5                	li	a7,9
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 2e6:	48a9                	li	a7,10
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 2ee:	48ad                	li	a7,11
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 2f6:	48b1                	li	a7,12
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 2fe:	48b5                	li	a7,13
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 306:	48b9                	li	a7,14
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 30e:	48d9                	li	a7,22
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 316:	48dd                	li	a7,23
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 31e:	48e1                	li	a7,24
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 326:	48e5                	li	a7,25
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 32e:	48e9                	li	a7,26
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 336:	48ed                	li	a7,27
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 33e:	48f1                	li	a7,28
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 346:	1101                	addi	sp,sp,-32
 348:	ec06                	sd	ra,24(sp)
 34a:	e822                	sd	s0,16(sp)
 34c:	1000                	addi	s0,sp,32
 34e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 352:	4605                	li	a2,1
 354:	fef40593          	addi	a1,s0,-17
 358:	00000097          	auipc	ra,0x0
 35c:	f36080e7          	jalr	-202(ra) # 28e <write>
}
 360:	60e2                	ld	ra,24(sp)
 362:	6442                	ld	s0,16(sp)
 364:	6105                	addi	sp,sp,32
 366:	8082                	ret

0000000000000368 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 368:	7139                	addi	sp,sp,-64
 36a:	fc06                	sd	ra,56(sp)
 36c:	f822                	sd	s0,48(sp)
 36e:	f426                	sd	s1,40(sp)
 370:	f04a                	sd	s2,32(sp)
 372:	ec4e                	sd	s3,24(sp)
 374:	0080                	addi	s0,sp,64
 376:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 378:	c299                	beqz	a3,37e <printint+0x16>
 37a:	0805c863          	bltz	a1,40a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 37e:	2581                	sext.w	a1,a1
  neg = 0;
 380:	4881                	li	a7,0
 382:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 386:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 388:	2601                	sext.w	a2,a2
 38a:	00000517          	auipc	a0,0x0
 38e:	44650513          	addi	a0,a0,1094 # 7d0 <digits>
 392:	883a                	mv	a6,a4
 394:	2705                	addiw	a4,a4,1
 396:	02c5f7bb          	remuw	a5,a1,a2
 39a:	1782                	slli	a5,a5,0x20
 39c:	9381                	srli	a5,a5,0x20
 39e:	97aa                	add	a5,a5,a0
 3a0:	0007c783          	lbu	a5,0(a5)
 3a4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3a8:	0005879b          	sext.w	a5,a1
 3ac:	02c5d5bb          	divuw	a1,a1,a2
 3b0:	0685                	addi	a3,a3,1
 3b2:	fec7f0e3          	bgeu	a5,a2,392 <printint+0x2a>
  if(neg)
 3b6:	00088b63          	beqz	a7,3cc <printint+0x64>
    buf[i++] = '-';
 3ba:	fd040793          	addi	a5,s0,-48
 3be:	973e                	add	a4,a4,a5
 3c0:	02d00793          	li	a5,45
 3c4:	fef70823          	sb	a5,-16(a4)
 3c8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3cc:	02e05863          	blez	a4,3fc <printint+0x94>
 3d0:	fc040793          	addi	a5,s0,-64
 3d4:	00e78933          	add	s2,a5,a4
 3d8:	fff78993          	addi	s3,a5,-1
 3dc:	99ba                	add	s3,s3,a4
 3de:	377d                	addiw	a4,a4,-1
 3e0:	1702                	slli	a4,a4,0x20
 3e2:	9301                	srli	a4,a4,0x20
 3e4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3e8:	fff94583          	lbu	a1,-1(s2)
 3ec:	8526                	mv	a0,s1
 3ee:	00000097          	auipc	ra,0x0
 3f2:	f58080e7          	jalr	-168(ra) # 346 <putc>
  while(--i >= 0)
 3f6:	197d                	addi	s2,s2,-1
 3f8:	ff3918e3          	bne	s2,s3,3e8 <printint+0x80>
}
 3fc:	70e2                	ld	ra,56(sp)
 3fe:	7442                	ld	s0,48(sp)
 400:	74a2                	ld	s1,40(sp)
 402:	7902                	ld	s2,32(sp)
 404:	69e2                	ld	s3,24(sp)
 406:	6121                	addi	sp,sp,64
 408:	8082                	ret
    x = -xx;
 40a:	40b005bb          	negw	a1,a1
    neg = 1;
 40e:	4885                	li	a7,1
    x = -xx;
 410:	bf8d                	j	382 <printint+0x1a>

0000000000000412 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 412:	7119                	addi	sp,sp,-128
 414:	fc86                	sd	ra,120(sp)
 416:	f8a2                	sd	s0,112(sp)
 418:	f4a6                	sd	s1,104(sp)
 41a:	f0ca                	sd	s2,96(sp)
 41c:	ecce                	sd	s3,88(sp)
 41e:	e8d2                	sd	s4,80(sp)
 420:	e4d6                	sd	s5,72(sp)
 422:	e0da                	sd	s6,64(sp)
 424:	fc5e                	sd	s7,56(sp)
 426:	f862                	sd	s8,48(sp)
 428:	f466                	sd	s9,40(sp)
 42a:	f06a                	sd	s10,32(sp)
 42c:	ec6e                	sd	s11,24(sp)
 42e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 430:	0005c903          	lbu	s2,0(a1)
 434:	18090f63          	beqz	s2,5d2 <vprintf+0x1c0>
 438:	8aaa                	mv	s5,a0
 43a:	8b32                	mv	s6,a2
 43c:	00158493          	addi	s1,a1,1
  state = 0;
 440:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 442:	02500a13          	li	s4,37
      if(c == 'd'){
 446:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 44a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 44e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 452:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 456:	00000b97          	auipc	s7,0x0
 45a:	37ab8b93          	addi	s7,s7,890 # 7d0 <digits>
 45e:	a839                	j	47c <vprintf+0x6a>
        putc(fd, c);
 460:	85ca                	mv	a1,s2
 462:	8556                	mv	a0,s5
 464:	00000097          	auipc	ra,0x0
 468:	ee2080e7          	jalr	-286(ra) # 346 <putc>
 46c:	a019                	j	472 <vprintf+0x60>
    } else if(state == '%'){
 46e:	01498f63          	beq	s3,s4,48c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 472:	0485                	addi	s1,s1,1
 474:	fff4c903          	lbu	s2,-1(s1)
 478:	14090d63          	beqz	s2,5d2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 47c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 480:	fe0997e3          	bnez	s3,46e <vprintf+0x5c>
      if(c == '%'){
 484:	fd479ee3          	bne	a5,s4,460 <vprintf+0x4e>
        state = '%';
 488:	89be                	mv	s3,a5
 48a:	b7e5                	j	472 <vprintf+0x60>
      if(c == 'd'){
 48c:	05878063          	beq	a5,s8,4cc <vprintf+0xba>
      } else if(c == 'l') {
 490:	05978c63          	beq	a5,s9,4e8 <vprintf+0xd6>
      } else if(c == 'x') {
 494:	07a78863          	beq	a5,s10,504 <vprintf+0xf2>
      } else if(c == 'p') {
 498:	09b78463          	beq	a5,s11,520 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 49c:	07300713          	li	a4,115
 4a0:	0ce78663          	beq	a5,a4,56c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4a4:	06300713          	li	a4,99
 4a8:	0ee78e63          	beq	a5,a4,5a4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4ac:	11478863          	beq	a5,s4,5bc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4b0:	85d2                	mv	a1,s4
 4b2:	8556                	mv	a0,s5
 4b4:	00000097          	auipc	ra,0x0
 4b8:	e92080e7          	jalr	-366(ra) # 346 <putc>
        putc(fd, c);
 4bc:	85ca                	mv	a1,s2
 4be:	8556                	mv	a0,s5
 4c0:	00000097          	auipc	ra,0x0
 4c4:	e86080e7          	jalr	-378(ra) # 346 <putc>
      }
      state = 0;
 4c8:	4981                	li	s3,0
 4ca:	b765                	j	472 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4cc:	008b0913          	addi	s2,s6,8
 4d0:	4685                	li	a3,1
 4d2:	4629                	li	a2,10
 4d4:	000b2583          	lw	a1,0(s6)
 4d8:	8556                	mv	a0,s5
 4da:	00000097          	auipc	ra,0x0
 4de:	e8e080e7          	jalr	-370(ra) # 368 <printint>
 4e2:	8b4a                	mv	s6,s2
      state = 0;
 4e4:	4981                	li	s3,0
 4e6:	b771                	j	472 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4e8:	008b0913          	addi	s2,s6,8
 4ec:	4681                	li	a3,0
 4ee:	4629                	li	a2,10
 4f0:	000b2583          	lw	a1,0(s6)
 4f4:	8556                	mv	a0,s5
 4f6:	00000097          	auipc	ra,0x0
 4fa:	e72080e7          	jalr	-398(ra) # 368 <printint>
 4fe:	8b4a                	mv	s6,s2
      state = 0;
 500:	4981                	li	s3,0
 502:	bf85                	j	472 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 504:	008b0913          	addi	s2,s6,8
 508:	4681                	li	a3,0
 50a:	4641                	li	a2,16
 50c:	000b2583          	lw	a1,0(s6)
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	e56080e7          	jalr	-426(ra) # 368 <printint>
 51a:	8b4a                	mv	s6,s2
      state = 0;
 51c:	4981                	li	s3,0
 51e:	bf91                	j	472 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 520:	008b0793          	addi	a5,s6,8
 524:	f8f43423          	sd	a5,-120(s0)
 528:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 52c:	03000593          	li	a1,48
 530:	8556                	mv	a0,s5
 532:	00000097          	auipc	ra,0x0
 536:	e14080e7          	jalr	-492(ra) # 346 <putc>
  putc(fd, 'x');
 53a:	85ea                	mv	a1,s10
 53c:	8556                	mv	a0,s5
 53e:	00000097          	auipc	ra,0x0
 542:	e08080e7          	jalr	-504(ra) # 346 <putc>
 546:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 548:	03c9d793          	srli	a5,s3,0x3c
 54c:	97de                	add	a5,a5,s7
 54e:	0007c583          	lbu	a1,0(a5)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	df2080e7          	jalr	-526(ra) # 346 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 55c:	0992                	slli	s3,s3,0x4
 55e:	397d                	addiw	s2,s2,-1
 560:	fe0914e3          	bnez	s2,548 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 564:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 568:	4981                	li	s3,0
 56a:	b721                	j	472 <vprintf+0x60>
        s = va_arg(ap, char*);
 56c:	008b0993          	addi	s3,s6,8
 570:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 574:	02090163          	beqz	s2,596 <vprintf+0x184>
        while(*s != 0){
 578:	00094583          	lbu	a1,0(s2)
 57c:	c9a1                	beqz	a1,5cc <vprintf+0x1ba>
          putc(fd, *s);
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	dc6080e7          	jalr	-570(ra) # 346 <putc>
          s++;
 588:	0905                	addi	s2,s2,1
        while(*s != 0){
 58a:	00094583          	lbu	a1,0(s2)
 58e:	f9e5                	bnez	a1,57e <vprintf+0x16c>
        s = va_arg(ap, char*);
 590:	8b4e                	mv	s6,s3
      state = 0;
 592:	4981                	li	s3,0
 594:	bdf9                	j	472 <vprintf+0x60>
          s = "(null)";
 596:	00000917          	auipc	s2,0x0
 59a:	23290913          	addi	s2,s2,562 # 7c8 <malloc+0xec>
        while(*s != 0){
 59e:	02800593          	li	a1,40
 5a2:	bff1                	j	57e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5a4:	008b0913          	addi	s2,s6,8
 5a8:	000b4583          	lbu	a1,0(s6)
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	d98080e7          	jalr	-616(ra) # 346 <putc>
 5b6:	8b4a                	mv	s6,s2
      state = 0;
 5b8:	4981                	li	s3,0
 5ba:	bd65                	j	472 <vprintf+0x60>
        putc(fd, c);
 5bc:	85d2                	mv	a1,s4
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	d86080e7          	jalr	-634(ra) # 346 <putc>
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b565                	j	472 <vprintf+0x60>
        s = va_arg(ap, char*);
 5cc:	8b4e                	mv	s6,s3
      state = 0;
 5ce:	4981                	li	s3,0
 5d0:	b54d                	j	472 <vprintf+0x60>
    }
  }
}
 5d2:	70e6                	ld	ra,120(sp)
 5d4:	7446                	ld	s0,112(sp)
 5d6:	74a6                	ld	s1,104(sp)
 5d8:	7906                	ld	s2,96(sp)
 5da:	69e6                	ld	s3,88(sp)
 5dc:	6a46                	ld	s4,80(sp)
 5de:	6aa6                	ld	s5,72(sp)
 5e0:	6b06                	ld	s6,64(sp)
 5e2:	7be2                	ld	s7,56(sp)
 5e4:	7c42                	ld	s8,48(sp)
 5e6:	7ca2                	ld	s9,40(sp)
 5e8:	7d02                	ld	s10,32(sp)
 5ea:	6de2                	ld	s11,24(sp)
 5ec:	6109                	addi	sp,sp,128
 5ee:	8082                	ret

00000000000005f0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5f0:	715d                	addi	sp,sp,-80
 5f2:	ec06                	sd	ra,24(sp)
 5f4:	e822                	sd	s0,16(sp)
 5f6:	1000                	addi	s0,sp,32
 5f8:	e010                	sd	a2,0(s0)
 5fa:	e414                	sd	a3,8(s0)
 5fc:	e818                	sd	a4,16(s0)
 5fe:	ec1c                	sd	a5,24(s0)
 600:	03043023          	sd	a6,32(s0)
 604:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 608:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 60c:	8622                	mv	a2,s0
 60e:	00000097          	auipc	ra,0x0
 612:	e04080e7          	jalr	-508(ra) # 412 <vprintf>
}
 616:	60e2                	ld	ra,24(sp)
 618:	6442                	ld	s0,16(sp)
 61a:	6161                	addi	sp,sp,80
 61c:	8082                	ret

000000000000061e <printf>:

void
printf(const char *fmt, ...)
{
 61e:	711d                	addi	sp,sp,-96
 620:	ec06                	sd	ra,24(sp)
 622:	e822                	sd	s0,16(sp)
 624:	1000                	addi	s0,sp,32
 626:	e40c                	sd	a1,8(s0)
 628:	e810                	sd	a2,16(s0)
 62a:	ec14                	sd	a3,24(s0)
 62c:	f018                	sd	a4,32(s0)
 62e:	f41c                	sd	a5,40(s0)
 630:	03043823          	sd	a6,48(s0)
 634:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 638:	00840613          	addi	a2,s0,8
 63c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 640:	85aa                	mv	a1,a0
 642:	4505                	li	a0,1
 644:	00000097          	auipc	ra,0x0
 648:	dce080e7          	jalr	-562(ra) # 412 <vprintf>
}
 64c:	60e2                	ld	ra,24(sp)
 64e:	6442                	ld	s0,16(sp)
 650:	6125                	addi	sp,sp,96
 652:	8082                	ret

0000000000000654 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 654:	1141                	addi	sp,sp,-16
 656:	e422                	sd	s0,8(sp)
 658:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 65a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 65e:	00000797          	auipc	a5,0x0
 662:	18a7b783          	ld	a5,394(a5) # 7e8 <freep>
 666:	a805                	j	696 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 668:	4618                	lw	a4,8(a2)
 66a:	9db9                	addw	a1,a1,a4
 66c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 670:	6398                	ld	a4,0(a5)
 672:	6318                	ld	a4,0(a4)
 674:	fee53823          	sd	a4,-16(a0)
 678:	a091                	j	6bc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 67a:	ff852703          	lw	a4,-8(a0)
 67e:	9e39                	addw	a2,a2,a4
 680:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 682:	ff053703          	ld	a4,-16(a0)
 686:	e398                	sd	a4,0(a5)
 688:	a099                	j	6ce <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68a:	6398                	ld	a4,0(a5)
 68c:	00e7e463          	bltu	a5,a4,694 <free+0x40>
 690:	00e6ea63          	bltu	a3,a4,6a4 <free+0x50>
{
 694:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 696:	fed7fae3          	bgeu	a5,a3,68a <free+0x36>
 69a:	6398                	ld	a4,0(a5)
 69c:	00e6e463          	bltu	a3,a4,6a4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a0:	fee7eae3          	bltu	a5,a4,694 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6a4:	ff852583          	lw	a1,-8(a0)
 6a8:	6390                	ld	a2,0(a5)
 6aa:	02059813          	slli	a6,a1,0x20
 6ae:	01c85713          	srli	a4,a6,0x1c
 6b2:	9736                	add	a4,a4,a3
 6b4:	fae60ae3          	beq	a2,a4,668 <free+0x14>
    bp->s.ptr = p->s.ptr;
 6b8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6bc:	4790                	lw	a2,8(a5)
 6be:	02061593          	slli	a1,a2,0x20
 6c2:	01c5d713          	srli	a4,a1,0x1c
 6c6:	973e                	add	a4,a4,a5
 6c8:	fae689e3          	beq	a3,a4,67a <free+0x26>
  } else
    p->s.ptr = bp;
 6cc:	e394                	sd	a3,0(a5)
  freep = p;
 6ce:	00000717          	auipc	a4,0x0
 6d2:	10f73d23          	sd	a5,282(a4) # 7e8 <freep>
}
 6d6:	6422                	ld	s0,8(sp)
 6d8:	0141                	addi	sp,sp,16
 6da:	8082                	ret

00000000000006dc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6dc:	7139                	addi	sp,sp,-64
 6de:	fc06                	sd	ra,56(sp)
 6e0:	f822                	sd	s0,48(sp)
 6e2:	f426                	sd	s1,40(sp)
 6e4:	f04a                	sd	s2,32(sp)
 6e6:	ec4e                	sd	s3,24(sp)
 6e8:	e852                	sd	s4,16(sp)
 6ea:	e456                	sd	s5,8(sp)
 6ec:	e05a                	sd	s6,0(sp)
 6ee:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f0:	02051493          	slli	s1,a0,0x20
 6f4:	9081                	srli	s1,s1,0x20
 6f6:	04bd                	addi	s1,s1,15
 6f8:	8091                	srli	s1,s1,0x4
 6fa:	0014899b          	addiw	s3,s1,1
 6fe:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 700:	00000517          	auipc	a0,0x0
 704:	0e853503          	ld	a0,232(a0) # 7e8 <freep>
 708:	c515                	beqz	a0,734 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 70c:	4798                	lw	a4,8(a5)
 70e:	02977f63          	bgeu	a4,s1,74c <malloc+0x70>
 712:	8a4e                	mv	s4,s3
 714:	0009871b          	sext.w	a4,s3
 718:	6685                	lui	a3,0x1
 71a:	00d77363          	bgeu	a4,a3,720 <malloc+0x44>
 71e:	6a05                	lui	s4,0x1
 720:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 724:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 728:	00000917          	auipc	s2,0x0
 72c:	0c090913          	addi	s2,s2,192 # 7e8 <freep>
  if(p == (char*)-1)
 730:	5afd                	li	s5,-1
 732:	a895                	j	7a6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 734:	00000797          	auipc	a5,0x0
 738:	0bc78793          	addi	a5,a5,188 # 7f0 <base>
 73c:	00000717          	auipc	a4,0x0
 740:	0af73623          	sd	a5,172(a4) # 7e8 <freep>
 744:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 746:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 74a:	b7e1                	j	712 <malloc+0x36>
      if(p->s.size == nunits)
 74c:	02e48c63          	beq	s1,a4,784 <malloc+0xa8>
        p->s.size -= nunits;
 750:	4137073b          	subw	a4,a4,s3
 754:	c798                	sw	a4,8(a5)
        p += p->s.size;
 756:	02071693          	slli	a3,a4,0x20
 75a:	01c6d713          	srli	a4,a3,0x1c
 75e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 760:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 764:	00000717          	auipc	a4,0x0
 768:	08a73223          	sd	a0,132(a4) # 7e8 <freep>
      return (void*)(p + 1);
 76c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 770:	70e2                	ld	ra,56(sp)
 772:	7442                	ld	s0,48(sp)
 774:	74a2                	ld	s1,40(sp)
 776:	7902                	ld	s2,32(sp)
 778:	69e2                	ld	s3,24(sp)
 77a:	6a42                	ld	s4,16(sp)
 77c:	6aa2                	ld	s5,8(sp)
 77e:	6b02                	ld	s6,0(sp)
 780:	6121                	addi	sp,sp,64
 782:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 784:	6398                	ld	a4,0(a5)
 786:	e118                	sd	a4,0(a0)
 788:	bff1                	j	764 <malloc+0x88>
  hp->s.size = nu;
 78a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 78e:	0541                	addi	a0,a0,16
 790:	00000097          	auipc	ra,0x0
 794:	ec4080e7          	jalr	-316(ra) # 654 <free>
  return freep;
 798:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 79c:	d971                	beqz	a0,770 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 79e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a0:	4798                	lw	a4,8(a5)
 7a2:	fa9775e3          	bgeu	a4,s1,74c <malloc+0x70>
    if(p == freep)
 7a6:	00093703          	ld	a4,0(s2)
 7aa:	853e                	mv	a0,a5
 7ac:	fef719e3          	bne	a4,a5,79e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7b0:	8552                	mv	a0,s4
 7b2:	00000097          	auipc	ra,0x0
 7b6:	b44080e7          	jalr	-1212(ra) # 2f6 <sbrk>
  if(p == (char*)-1)
 7ba:	fd5518e3          	bne	a0,s5,78a <malloc+0xae>
        return 0;
 7be:	4501                	li	a0,0
 7c0:	bf45                	j	770 <malloc+0x94>
