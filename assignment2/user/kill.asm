
user/_kill:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user/user.h"

// ADDED Q2.2.2 
int
main(int argc, char **argv)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  int i;

  if(argc < 3 || argc % 2 == 0){ // must have even parameters, including the 'kill' - odd
   e:	4789                	li	a5,2
  10:	04a7d863          	bge	a5,a0,60 <main+0x60>
  14:	0005079b          	sext.w	a5,a0
  18:	8905                	andi	a0,a0,1
  1a:	c139                	beqz	a0,60 <main+0x60>
    fprintf(2, "usage: kill pid1 signal1 pid2 signal2 ... pidN signalN \n");
    exit(1);
  }
  for(i=1; i<argc - 1 ; i+=2)
  1c:	00858493          	addi	s1,a1,8
  20:	ffd7899b          	addiw	s3,a5,-3
  24:	0019d99b          	srliw	s3,s3,0x1
  28:	0992                	slli	s3,s3,0x4
  2a:	05e1                	addi	a1,a1,24
  2c:	99ae                	add	s3,s3,a1
    kill(atoi(argv[i]), atoi(argv[i+1])); 
  2e:	6088                	ld	a0,0(s1)
  30:	00000097          	auipc	ra,0x0
  34:	1be080e7          	jalr	446(ra) # 1ee <atoi>
  38:	892a                	mv	s2,a0
  3a:	6488                	ld	a0,8(s1)
  3c:	00000097          	auipc	ra,0x0
  40:	1b2080e7          	jalr	434(ra) # 1ee <atoi>
  44:	85aa                	mv	a1,a0
  46:	854a                	mv	a0,s2
  48:	00000097          	auipc	ra,0x0
  4c:	2d2080e7          	jalr	722(ra) # 31a <kill>
  for(i=1; i<argc - 1 ; i+=2)
  50:	04c1                	addi	s1,s1,16
  52:	fd349ee3          	bne	s1,s3,2e <main+0x2e>
  exit(0);
  56:	4501                	li	a0,0
  58:	00000097          	auipc	ra,0x0
  5c:	292080e7          	jalr	658(ra) # 2ea <exit>
    fprintf(2, "usage: kill pid1 signal1 pid2 signal2 ... pidN signalN \n");
  60:	00000597          	auipc	a1,0x0
  64:	7e058593          	addi	a1,a1,2016 # 840 <malloc+0xe8>
  68:	4509                	li	a0,2
  6a:	00000097          	auipc	ra,0x0
  6e:	602080e7          	jalr	1538(ra) # 66c <fprintf>
    exit(1);
  72:	4505                	li	a0,1
  74:	00000097          	auipc	ra,0x0
  78:	276080e7          	jalr	630(ra) # 2ea <exit>

000000000000007c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  82:	87aa                	mv	a5,a0
  84:	0585                	addi	a1,a1,1
  86:	0785                	addi	a5,a5,1
  88:	fff5c703          	lbu	a4,-1(a1)
  8c:	fee78fa3          	sb	a4,-1(a5)
  90:	fb75                	bnez	a4,84 <strcpy+0x8>
    ;
  return os;
}
  92:	6422                	ld	s0,8(sp)
  94:	0141                	addi	sp,sp,16
  96:	8082                	ret

0000000000000098 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  98:	1141                	addi	sp,sp,-16
  9a:	e422                	sd	s0,8(sp)
  9c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  9e:	00054783          	lbu	a5,0(a0)
  a2:	cb91                	beqz	a5,b6 <strcmp+0x1e>
  a4:	0005c703          	lbu	a4,0(a1)
  a8:	00f71763          	bne	a4,a5,b6 <strcmp+0x1e>
    p++, q++;
  ac:	0505                	addi	a0,a0,1
  ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  b0:	00054783          	lbu	a5,0(a0)
  b4:	fbe5                	bnez	a5,a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b6:	0005c503          	lbu	a0,0(a1)
}
  ba:	40a7853b          	subw	a0,a5,a0
  be:	6422                	ld	s0,8(sp)
  c0:	0141                	addi	sp,sp,16
  c2:	8082                	ret

00000000000000c4 <strlen>:

uint
strlen(const char *s)
{
  c4:	1141                	addi	sp,sp,-16
  c6:	e422                	sd	s0,8(sp)
  c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ca:	00054783          	lbu	a5,0(a0)
  ce:	cf91                	beqz	a5,ea <strlen+0x26>
  d0:	0505                	addi	a0,a0,1
  d2:	87aa                	mv	a5,a0
  d4:	4685                	li	a3,1
  d6:	9e89                	subw	a3,a3,a0
  d8:	00f6853b          	addw	a0,a3,a5
  dc:	0785                	addi	a5,a5,1
  de:	fff7c703          	lbu	a4,-1(a5)
  e2:	fb7d                	bnez	a4,d8 <strlen+0x14>
    ;
  return n;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret
  for(n = 0; s[n]; n++)
  ea:	4501                	li	a0,0
  ec:	bfe5                	j	e4 <strlen+0x20>

00000000000000ee <memset>:

void*
memset(void *dst, int c, uint n)
{
  ee:	1141                	addi	sp,sp,-16
  f0:	e422                	sd	s0,8(sp)
  f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f4:	ca19                	beqz	a2,10a <memset+0x1c>
  f6:	87aa                	mv	a5,a0
  f8:	1602                	slli	a2,a2,0x20
  fa:	9201                	srli	a2,a2,0x20
  fc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 100:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 104:	0785                	addi	a5,a5,1
 106:	fee79de3          	bne	a5,a4,100 <memset+0x12>
  }
  return dst;
}
 10a:	6422                	ld	s0,8(sp)
 10c:	0141                	addi	sp,sp,16
 10e:	8082                	ret

0000000000000110 <strchr>:

char*
strchr(const char *s, char c)
{
 110:	1141                	addi	sp,sp,-16
 112:	e422                	sd	s0,8(sp)
 114:	0800                	addi	s0,sp,16
  for(; *s; s++)
 116:	00054783          	lbu	a5,0(a0)
 11a:	cb99                	beqz	a5,130 <strchr+0x20>
    if(*s == c)
 11c:	00f58763          	beq	a1,a5,12a <strchr+0x1a>
  for(; *s; s++)
 120:	0505                	addi	a0,a0,1
 122:	00054783          	lbu	a5,0(a0)
 126:	fbfd                	bnez	a5,11c <strchr+0xc>
      return (char*)s;
  return 0;
 128:	4501                	li	a0,0
}
 12a:	6422                	ld	s0,8(sp)
 12c:	0141                	addi	sp,sp,16
 12e:	8082                	ret
  return 0;
 130:	4501                	li	a0,0
 132:	bfe5                	j	12a <strchr+0x1a>

0000000000000134 <gets>:

char*
gets(char *buf, int max)
{
 134:	711d                	addi	sp,sp,-96
 136:	ec86                	sd	ra,88(sp)
 138:	e8a2                	sd	s0,80(sp)
 13a:	e4a6                	sd	s1,72(sp)
 13c:	e0ca                	sd	s2,64(sp)
 13e:	fc4e                	sd	s3,56(sp)
 140:	f852                	sd	s4,48(sp)
 142:	f456                	sd	s5,40(sp)
 144:	f05a                	sd	s6,32(sp)
 146:	ec5e                	sd	s7,24(sp)
 148:	1080                	addi	s0,sp,96
 14a:	8baa                	mv	s7,a0
 14c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14e:	892a                	mv	s2,a0
 150:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 152:	4aa9                	li	s5,10
 154:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 156:	89a6                	mv	s3,s1
 158:	2485                	addiw	s1,s1,1
 15a:	0344d863          	bge	s1,s4,18a <gets+0x56>
    cc = read(0, &c, 1);
 15e:	4605                	li	a2,1
 160:	faf40593          	addi	a1,s0,-81
 164:	4501                	li	a0,0
 166:	00000097          	auipc	ra,0x0
 16a:	19c080e7          	jalr	412(ra) # 302 <read>
    if(cc < 1)
 16e:	00a05e63          	blez	a0,18a <gets+0x56>
    buf[i++] = c;
 172:	faf44783          	lbu	a5,-81(s0)
 176:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 17a:	01578763          	beq	a5,s5,188 <gets+0x54>
 17e:	0905                	addi	s2,s2,1
 180:	fd679be3          	bne	a5,s6,156 <gets+0x22>
  for(i=0; i+1 < max; ){
 184:	89a6                	mv	s3,s1
 186:	a011                	j	18a <gets+0x56>
 188:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 18a:	99de                	add	s3,s3,s7
 18c:	00098023          	sb	zero,0(s3)
  return buf;
}
 190:	855e                	mv	a0,s7
 192:	60e6                	ld	ra,88(sp)
 194:	6446                	ld	s0,80(sp)
 196:	64a6                	ld	s1,72(sp)
 198:	6906                	ld	s2,64(sp)
 19a:	79e2                	ld	s3,56(sp)
 19c:	7a42                	ld	s4,48(sp)
 19e:	7aa2                	ld	s5,40(sp)
 1a0:	7b02                	ld	s6,32(sp)
 1a2:	6be2                	ld	s7,24(sp)
 1a4:	6125                	addi	sp,sp,96
 1a6:	8082                	ret

00000000000001a8 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a8:	1101                	addi	sp,sp,-32
 1aa:	ec06                	sd	ra,24(sp)
 1ac:	e822                	sd	s0,16(sp)
 1ae:	e426                	sd	s1,8(sp)
 1b0:	e04a                	sd	s2,0(sp)
 1b2:	1000                	addi	s0,sp,32
 1b4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b6:	4581                	li	a1,0
 1b8:	00000097          	auipc	ra,0x0
 1bc:	172080e7          	jalr	370(ra) # 32a <open>
  if(fd < 0)
 1c0:	02054563          	bltz	a0,1ea <stat+0x42>
 1c4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c6:	85ca                	mv	a1,s2
 1c8:	00000097          	auipc	ra,0x0
 1cc:	17a080e7          	jalr	378(ra) # 342 <fstat>
 1d0:	892a                	mv	s2,a0
  close(fd);
 1d2:	8526                	mv	a0,s1
 1d4:	00000097          	auipc	ra,0x0
 1d8:	13e080e7          	jalr	318(ra) # 312 <close>
  return r;
}
 1dc:	854a                	mv	a0,s2
 1de:	60e2                	ld	ra,24(sp)
 1e0:	6442                	ld	s0,16(sp)
 1e2:	64a2                	ld	s1,8(sp)
 1e4:	6902                	ld	s2,0(sp)
 1e6:	6105                	addi	sp,sp,32
 1e8:	8082                	ret
    return -1;
 1ea:	597d                	li	s2,-1
 1ec:	bfc5                	j	1dc <stat+0x34>

00000000000001ee <atoi>:

int
atoi(const char *s)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f4:	00054603          	lbu	a2,0(a0)
 1f8:	fd06079b          	addiw	a5,a2,-48
 1fc:	0ff7f793          	andi	a5,a5,255
 200:	4725                	li	a4,9
 202:	02f76963          	bltu	a4,a5,234 <atoi+0x46>
 206:	86aa                	mv	a3,a0
  n = 0;
 208:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 20a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 20c:	0685                	addi	a3,a3,1
 20e:	0025179b          	slliw	a5,a0,0x2
 212:	9fa9                	addw	a5,a5,a0
 214:	0017979b          	slliw	a5,a5,0x1
 218:	9fb1                	addw	a5,a5,a2
 21a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 21e:	0006c603          	lbu	a2,0(a3)
 222:	fd06071b          	addiw	a4,a2,-48
 226:	0ff77713          	andi	a4,a4,255
 22a:	fee5f1e3          	bgeu	a1,a4,20c <atoi+0x1e>
  return n;
}
 22e:	6422                	ld	s0,8(sp)
 230:	0141                	addi	sp,sp,16
 232:	8082                	ret
  n = 0;
 234:	4501                	li	a0,0
 236:	bfe5                	j	22e <atoi+0x40>

0000000000000238 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 238:	1141                	addi	sp,sp,-16
 23a:	e422                	sd	s0,8(sp)
 23c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 23e:	02b57463          	bgeu	a0,a1,266 <memmove+0x2e>
    while(n-- > 0)
 242:	00c05f63          	blez	a2,260 <memmove+0x28>
 246:	1602                	slli	a2,a2,0x20
 248:	9201                	srli	a2,a2,0x20
 24a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 24e:	872a                	mv	a4,a0
      *dst++ = *src++;
 250:	0585                	addi	a1,a1,1
 252:	0705                	addi	a4,a4,1
 254:	fff5c683          	lbu	a3,-1(a1)
 258:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 25c:	fee79ae3          	bne	a5,a4,250 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret
    dst += n;
 266:	00c50733          	add	a4,a0,a2
    src += n;
 26a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 26c:	fec05ae3          	blez	a2,260 <memmove+0x28>
 270:	fff6079b          	addiw	a5,a2,-1
 274:	1782                	slli	a5,a5,0x20
 276:	9381                	srli	a5,a5,0x20
 278:	fff7c793          	not	a5,a5
 27c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 27e:	15fd                	addi	a1,a1,-1
 280:	177d                	addi	a4,a4,-1
 282:	0005c683          	lbu	a3,0(a1)
 286:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 28a:	fee79ae3          	bne	a5,a4,27e <memmove+0x46>
 28e:	bfc9                	j	260 <memmove+0x28>

0000000000000290 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 290:	1141                	addi	sp,sp,-16
 292:	e422                	sd	s0,8(sp)
 294:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 296:	ca05                	beqz	a2,2c6 <memcmp+0x36>
 298:	fff6069b          	addiw	a3,a2,-1
 29c:	1682                	slli	a3,a3,0x20
 29e:	9281                	srli	a3,a3,0x20
 2a0:	0685                	addi	a3,a3,1
 2a2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2a4:	00054783          	lbu	a5,0(a0)
 2a8:	0005c703          	lbu	a4,0(a1)
 2ac:	00e79863          	bne	a5,a4,2bc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2b0:	0505                	addi	a0,a0,1
    p2++;
 2b2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2b4:	fed518e3          	bne	a0,a3,2a4 <memcmp+0x14>
  }
  return 0;
 2b8:	4501                	li	a0,0
 2ba:	a019                	j	2c0 <memcmp+0x30>
      return *p1 - *p2;
 2bc:	40e7853b          	subw	a0,a5,a4
}
 2c0:	6422                	ld	s0,8(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret
  return 0;
 2c6:	4501                	li	a0,0
 2c8:	bfe5                	j	2c0 <memcmp+0x30>

00000000000002ca <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ca:	1141                	addi	sp,sp,-16
 2cc:	e406                	sd	ra,8(sp)
 2ce:	e022                	sd	s0,0(sp)
 2d0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2d2:	00000097          	auipc	ra,0x0
 2d6:	f66080e7          	jalr	-154(ra) # 238 <memmove>
}
 2da:	60a2                	ld	ra,8(sp)
 2dc:	6402                	ld	s0,0(sp)
 2de:	0141                	addi	sp,sp,16
 2e0:	8082                	ret

00000000000002e2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2e2:	4885                	li	a7,1
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ea:	4889                	li	a7,2
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2f2:	488d                	li	a7,3
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2fa:	4891                	li	a7,4
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <read>:
.global read
read:
 li a7, SYS_read
 302:	4895                	li	a7,5
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <write>:
.global write
write:
 li a7, SYS_write
 30a:	48c1                	li	a7,16
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <close>:
.global close
close:
 li a7, SYS_close
 312:	48d5                	li	a7,21
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <kill>:
.global kill
kill:
 li a7, SYS_kill
 31a:	4899                	li	a7,6
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <exec>:
.global exec
exec:
 li a7, SYS_exec
 322:	489d                	li	a7,7
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <open>:
.global open
open:
 li a7, SYS_open
 32a:	48bd                	li	a7,15
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 332:	48c5                	li	a7,17
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 33a:	48c9                	li	a7,18
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 342:	48a1                	li	a7,8
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <link>:
.global link
link:
 li a7, SYS_link
 34a:	48cd                	li	a7,19
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 352:	48d1                	li	a7,20
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 35a:	48a5                	li	a7,9
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <dup>:
.global dup
dup:
 li a7, SYS_dup
 362:	48a9                	li	a7,10
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 36a:	48ad                	li	a7,11
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 372:	48b1                	li	a7,12
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 37a:	48b5                	li	a7,13
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 382:	48b9                	li	a7,14
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 38a:	48d9                	li	a7,22
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 392:	48dd                	li	a7,23
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 39a:	48e1                	li	a7,24
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 3a2:	48e5                	li	a7,25
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 3aa:	48e9                	li	a7,26
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 3b2:	48ed                	li	a7,27
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 3ba:	48f1                	li	a7,28
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c2:	1101                	addi	sp,sp,-32
 3c4:	ec06                	sd	ra,24(sp)
 3c6:	e822                	sd	s0,16(sp)
 3c8:	1000                	addi	s0,sp,32
 3ca:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ce:	4605                	li	a2,1
 3d0:	fef40593          	addi	a1,s0,-17
 3d4:	00000097          	auipc	ra,0x0
 3d8:	f36080e7          	jalr	-202(ra) # 30a <write>
}
 3dc:	60e2                	ld	ra,24(sp)
 3de:	6442                	ld	s0,16(sp)
 3e0:	6105                	addi	sp,sp,32
 3e2:	8082                	ret

00000000000003e4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e4:	7139                	addi	sp,sp,-64
 3e6:	fc06                	sd	ra,56(sp)
 3e8:	f822                	sd	s0,48(sp)
 3ea:	f426                	sd	s1,40(sp)
 3ec:	f04a                	sd	s2,32(sp)
 3ee:	ec4e                	sd	s3,24(sp)
 3f0:	0080                	addi	s0,sp,64
 3f2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3f4:	c299                	beqz	a3,3fa <printint+0x16>
 3f6:	0805c863          	bltz	a1,486 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3fa:	2581                	sext.w	a1,a1
  neg = 0;
 3fc:	4881                	li	a7,0
 3fe:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 402:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 404:	2601                	sext.w	a2,a2
 406:	00000517          	auipc	a0,0x0
 40a:	48250513          	addi	a0,a0,1154 # 888 <digits>
 40e:	883a                	mv	a6,a4
 410:	2705                	addiw	a4,a4,1
 412:	02c5f7bb          	remuw	a5,a1,a2
 416:	1782                	slli	a5,a5,0x20
 418:	9381                	srli	a5,a5,0x20
 41a:	97aa                	add	a5,a5,a0
 41c:	0007c783          	lbu	a5,0(a5)
 420:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 424:	0005879b          	sext.w	a5,a1
 428:	02c5d5bb          	divuw	a1,a1,a2
 42c:	0685                	addi	a3,a3,1
 42e:	fec7f0e3          	bgeu	a5,a2,40e <printint+0x2a>
  if(neg)
 432:	00088b63          	beqz	a7,448 <printint+0x64>
    buf[i++] = '-';
 436:	fd040793          	addi	a5,s0,-48
 43a:	973e                	add	a4,a4,a5
 43c:	02d00793          	li	a5,45
 440:	fef70823          	sb	a5,-16(a4)
 444:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 448:	02e05863          	blez	a4,478 <printint+0x94>
 44c:	fc040793          	addi	a5,s0,-64
 450:	00e78933          	add	s2,a5,a4
 454:	fff78993          	addi	s3,a5,-1
 458:	99ba                	add	s3,s3,a4
 45a:	377d                	addiw	a4,a4,-1
 45c:	1702                	slli	a4,a4,0x20
 45e:	9301                	srli	a4,a4,0x20
 460:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 464:	fff94583          	lbu	a1,-1(s2)
 468:	8526                	mv	a0,s1
 46a:	00000097          	auipc	ra,0x0
 46e:	f58080e7          	jalr	-168(ra) # 3c2 <putc>
  while(--i >= 0)
 472:	197d                	addi	s2,s2,-1
 474:	ff3918e3          	bne	s2,s3,464 <printint+0x80>
}
 478:	70e2                	ld	ra,56(sp)
 47a:	7442                	ld	s0,48(sp)
 47c:	74a2                	ld	s1,40(sp)
 47e:	7902                	ld	s2,32(sp)
 480:	69e2                	ld	s3,24(sp)
 482:	6121                	addi	sp,sp,64
 484:	8082                	ret
    x = -xx;
 486:	40b005bb          	negw	a1,a1
    neg = 1;
 48a:	4885                	li	a7,1
    x = -xx;
 48c:	bf8d                	j	3fe <printint+0x1a>

000000000000048e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 48e:	7119                	addi	sp,sp,-128
 490:	fc86                	sd	ra,120(sp)
 492:	f8a2                	sd	s0,112(sp)
 494:	f4a6                	sd	s1,104(sp)
 496:	f0ca                	sd	s2,96(sp)
 498:	ecce                	sd	s3,88(sp)
 49a:	e8d2                	sd	s4,80(sp)
 49c:	e4d6                	sd	s5,72(sp)
 49e:	e0da                	sd	s6,64(sp)
 4a0:	fc5e                	sd	s7,56(sp)
 4a2:	f862                	sd	s8,48(sp)
 4a4:	f466                	sd	s9,40(sp)
 4a6:	f06a                	sd	s10,32(sp)
 4a8:	ec6e                	sd	s11,24(sp)
 4aa:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ac:	0005c903          	lbu	s2,0(a1)
 4b0:	18090f63          	beqz	s2,64e <vprintf+0x1c0>
 4b4:	8aaa                	mv	s5,a0
 4b6:	8b32                	mv	s6,a2
 4b8:	00158493          	addi	s1,a1,1
  state = 0;
 4bc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4be:	02500a13          	li	s4,37
      if(c == 'd'){
 4c2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4c6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4ca:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4ce:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4d2:	00000b97          	auipc	s7,0x0
 4d6:	3b6b8b93          	addi	s7,s7,950 # 888 <digits>
 4da:	a839                	j	4f8 <vprintf+0x6a>
        putc(fd, c);
 4dc:	85ca                	mv	a1,s2
 4de:	8556                	mv	a0,s5
 4e0:	00000097          	auipc	ra,0x0
 4e4:	ee2080e7          	jalr	-286(ra) # 3c2 <putc>
 4e8:	a019                	j	4ee <vprintf+0x60>
    } else if(state == '%'){
 4ea:	01498f63          	beq	s3,s4,508 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4ee:	0485                	addi	s1,s1,1
 4f0:	fff4c903          	lbu	s2,-1(s1)
 4f4:	14090d63          	beqz	s2,64e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4f8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4fc:	fe0997e3          	bnez	s3,4ea <vprintf+0x5c>
      if(c == '%'){
 500:	fd479ee3          	bne	a5,s4,4dc <vprintf+0x4e>
        state = '%';
 504:	89be                	mv	s3,a5
 506:	b7e5                	j	4ee <vprintf+0x60>
      if(c == 'd'){
 508:	05878063          	beq	a5,s8,548 <vprintf+0xba>
      } else if(c == 'l') {
 50c:	05978c63          	beq	a5,s9,564 <vprintf+0xd6>
      } else if(c == 'x') {
 510:	07a78863          	beq	a5,s10,580 <vprintf+0xf2>
      } else if(c == 'p') {
 514:	09b78463          	beq	a5,s11,59c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 518:	07300713          	li	a4,115
 51c:	0ce78663          	beq	a5,a4,5e8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 520:	06300713          	li	a4,99
 524:	0ee78e63          	beq	a5,a4,620 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 528:	11478863          	beq	a5,s4,638 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 52c:	85d2                	mv	a1,s4
 52e:	8556                	mv	a0,s5
 530:	00000097          	auipc	ra,0x0
 534:	e92080e7          	jalr	-366(ra) # 3c2 <putc>
        putc(fd, c);
 538:	85ca                	mv	a1,s2
 53a:	8556                	mv	a0,s5
 53c:	00000097          	auipc	ra,0x0
 540:	e86080e7          	jalr	-378(ra) # 3c2 <putc>
      }
      state = 0;
 544:	4981                	li	s3,0
 546:	b765                	j	4ee <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 548:	008b0913          	addi	s2,s6,8
 54c:	4685                	li	a3,1
 54e:	4629                	li	a2,10
 550:	000b2583          	lw	a1,0(s6)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e8e080e7          	jalr	-370(ra) # 3e4 <printint>
 55e:	8b4a                	mv	s6,s2
      state = 0;
 560:	4981                	li	s3,0
 562:	b771                	j	4ee <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 564:	008b0913          	addi	s2,s6,8
 568:	4681                	li	a3,0
 56a:	4629                	li	a2,10
 56c:	000b2583          	lw	a1,0(s6)
 570:	8556                	mv	a0,s5
 572:	00000097          	auipc	ra,0x0
 576:	e72080e7          	jalr	-398(ra) # 3e4 <printint>
 57a:	8b4a                	mv	s6,s2
      state = 0;
 57c:	4981                	li	s3,0
 57e:	bf85                	j	4ee <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 580:	008b0913          	addi	s2,s6,8
 584:	4681                	li	a3,0
 586:	4641                	li	a2,16
 588:	000b2583          	lw	a1,0(s6)
 58c:	8556                	mv	a0,s5
 58e:	00000097          	auipc	ra,0x0
 592:	e56080e7          	jalr	-426(ra) # 3e4 <printint>
 596:	8b4a                	mv	s6,s2
      state = 0;
 598:	4981                	li	s3,0
 59a:	bf91                	j	4ee <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 59c:	008b0793          	addi	a5,s6,8
 5a0:	f8f43423          	sd	a5,-120(s0)
 5a4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a8:	03000593          	li	a1,48
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	e14080e7          	jalr	-492(ra) # 3c2 <putc>
  putc(fd, 'x');
 5b6:	85ea                	mv	a1,s10
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	e08080e7          	jalr	-504(ra) # 3c2 <putc>
 5c2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c4:	03c9d793          	srli	a5,s3,0x3c
 5c8:	97de                	add	a5,a5,s7
 5ca:	0007c583          	lbu	a1,0(a5)
 5ce:	8556                	mv	a0,s5
 5d0:	00000097          	auipc	ra,0x0
 5d4:	df2080e7          	jalr	-526(ra) # 3c2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d8:	0992                	slli	s3,s3,0x4
 5da:	397d                	addiw	s2,s2,-1
 5dc:	fe0914e3          	bnez	s2,5c4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5e0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5e4:	4981                	li	s3,0
 5e6:	b721                	j	4ee <vprintf+0x60>
        s = va_arg(ap, char*);
 5e8:	008b0993          	addi	s3,s6,8
 5ec:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5f0:	02090163          	beqz	s2,612 <vprintf+0x184>
        while(*s != 0){
 5f4:	00094583          	lbu	a1,0(s2)
 5f8:	c9a1                	beqz	a1,648 <vprintf+0x1ba>
          putc(fd, *s);
 5fa:	8556                	mv	a0,s5
 5fc:	00000097          	auipc	ra,0x0
 600:	dc6080e7          	jalr	-570(ra) # 3c2 <putc>
          s++;
 604:	0905                	addi	s2,s2,1
        while(*s != 0){
 606:	00094583          	lbu	a1,0(s2)
 60a:	f9e5                	bnez	a1,5fa <vprintf+0x16c>
        s = va_arg(ap, char*);
 60c:	8b4e                	mv	s6,s3
      state = 0;
 60e:	4981                	li	s3,0
 610:	bdf9                	j	4ee <vprintf+0x60>
          s = "(null)";
 612:	00000917          	auipc	s2,0x0
 616:	26e90913          	addi	s2,s2,622 # 880 <malloc+0x128>
        while(*s != 0){
 61a:	02800593          	li	a1,40
 61e:	bff1                	j	5fa <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 620:	008b0913          	addi	s2,s6,8
 624:	000b4583          	lbu	a1,0(s6)
 628:	8556                	mv	a0,s5
 62a:	00000097          	auipc	ra,0x0
 62e:	d98080e7          	jalr	-616(ra) # 3c2 <putc>
 632:	8b4a                	mv	s6,s2
      state = 0;
 634:	4981                	li	s3,0
 636:	bd65                	j	4ee <vprintf+0x60>
        putc(fd, c);
 638:	85d2                	mv	a1,s4
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	d86080e7          	jalr	-634(ra) # 3c2 <putc>
      state = 0;
 644:	4981                	li	s3,0
 646:	b565                	j	4ee <vprintf+0x60>
        s = va_arg(ap, char*);
 648:	8b4e                	mv	s6,s3
      state = 0;
 64a:	4981                	li	s3,0
 64c:	b54d                	j	4ee <vprintf+0x60>
    }
  }
}
 64e:	70e6                	ld	ra,120(sp)
 650:	7446                	ld	s0,112(sp)
 652:	74a6                	ld	s1,104(sp)
 654:	7906                	ld	s2,96(sp)
 656:	69e6                	ld	s3,88(sp)
 658:	6a46                	ld	s4,80(sp)
 65a:	6aa6                	ld	s5,72(sp)
 65c:	6b06                	ld	s6,64(sp)
 65e:	7be2                	ld	s7,56(sp)
 660:	7c42                	ld	s8,48(sp)
 662:	7ca2                	ld	s9,40(sp)
 664:	7d02                	ld	s10,32(sp)
 666:	6de2                	ld	s11,24(sp)
 668:	6109                	addi	sp,sp,128
 66a:	8082                	ret

000000000000066c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 66c:	715d                	addi	sp,sp,-80
 66e:	ec06                	sd	ra,24(sp)
 670:	e822                	sd	s0,16(sp)
 672:	1000                	addi	s0,sp,32
 674:	e010                	sd	a2,0(s0)
 676:	e414                	sd	a3,8(s0)
 678:	e818                	sd	a4,16(s0)
 67a:	ec1c                	sd	a5,24(s0)
 67c:	03043023          	sd	a6,32(s0)
 680:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 684:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 688:	8622                	mv	a2,s0
 68a:	00000097          	auipc	ra,0x0
 68e:	e04080e7          	jalr	-508(ra) # 48e <vprintf>
}
 692:	60e2                	ld	ra,24(sp)
 694:	6442                	ld	s0,16(sp)
 696:	6161                	addi	sp,sp,80
 698:	8082                	ret

000000000000069a <printf>:

void
printf(const char *fmt, ...)
{
 69a:	711d                	addi	sp,sp,-96
 69c:	ec06                	sd	ra,24(sp)
 69e:	e822                	sd	s0,16(sp)
 6a0:	1000                	addi	s0,sp,32
 6a2:	e40c                	sd	a1,8(s0)
 6a4:	e810                	sd	a2,16(s0)
 6a6:	ec14                	sd	a3,24(s0)
 6a8:	f018                	sd	a4,32(s0)
 6aa:	f41c                	sd	a5,40(s0)
 6ac:	03043823          	sd	a6,48(s0)
 6b0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6b4:	00840613          	addi	a2,s0,8
 6b8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6bc:	85aa                	mv	a1,a0
 6be:	4505                	li	a0,1
 6c0:	00000097          	auipc	ra,0x0
 6c4:	dce080e7          	jalr	-562(ra) # 48e <vprintf>
}
 6c8:	60e2                	ld	ra,24(sp)
 6ca:	6442                	ld	s0,16(sp)
 6cc:	6125                	addi	sp,sp,96
 6ce:	8082                	ret

00000000000006d0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6d0:	1141                	addi	sp,sp,-16
 6d2:	e422                	sd	s0,8(sp)
 6d4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6da:	00000797          	auipc	a5,0x0
 6de:	1c67b783          	ld	a5,454(a5) # 8a0 <freep>
 6e2:	a805                	j	712 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6e4:	4618                	lw	a4,8(a2)
 6e6:	9db9                	addw	a1,a1,a4
 6e8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ec:	6398                	ld	a4,0(a5)
 6ee:	6318                	ld	a4,0(a4)
 6f0:	fee53823          	sd	a4,-16(a0)
 6f4:	a091                	j	738 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6f6:	ff852703          	lw	a4,-8(a0)
 6fa:	9e39                	addw	a2,a2,a4
 6fc:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6fe:	ff053703          	ld	a4,-16(a0)
 702:	e398                	sd	a4,0(a5)
 704:	a099                	j	74a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 706:	6398                	ld	a4,0(a5)
 708:	00e7e463          	bltu	a5,a4,710 <free+0x40>
 70c:	00e6ea63          	bltu	a3,a4,720 <free+0x50>
{
 710:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 712:	fed7fae3          	bgeu	a5,a3,706 <free+0x36>
 716:	6398                	ld	a4,0(a5)
 718:	00e6e463          	bltu	a3,a4,720 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71c:	fee7eae3          	bltu	a5,a4,710 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 720:	ff852583          	lw	a1,-8(a0)
 724:	6390                	ld	a2,0(a5)
 726:	02059813          	slli	a6,a1,0x20
 72a:	01c85713          	srli	a4,a6,0x1c
 72e:	9736                	add	a4,a4,a3
 730:	fae60ae3          	beq	a2,a4,6e4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 734:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 738:	4790                	lw	a2,8(a5)
 73a:	02061593          	slli	a1,a2,0x20
 73e:	01c5d713          	srli	a4,a1,0x1c
 742:	973e                	add	a4,a4,a5
 744:	fae689e3          	beq	a3,a4,6f6 <free+0x26>
  } else
    p->s.ptr = bp;
 748:	e394                	sd	a3,0(a5)
  freep = p;
 74a:	00000717          	auipc	a4,0x0
 74e:	14f73b23          	sd	a5,342(a4) # 8a0 <freep>
}
 752:	6422                	ld	s0,8(sp)
 754:	0141                	addi	sp,sp,16
 756:	8082                	ret

0000000000000758 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 758:	7139                	addi	sp,sp,-64
 75a:	fc06                	sd	ra,56(sp)
 75c:	f822                	sd	s0,48(sp)
 75e:	f426                	sd	s1,40(sp)
 760:	f04a                	sd	s2,32(sp)
 762:	ec4e                	sd	s3,24(sp)
 764:	e852                	sd	s4,16(sp)
 766:	e456                	sd	s5,8(sp)
 768:	e05a                	sd	s6,0(sp)
 76a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 76c:	02051493          	slli	s1,a0,0x20
 770:	9081                	srli	s1,s1,0x20
 772:	04bd                	addi	s1,s1,15
 774:	8091                	srli	s1,s1,0x4
 776:	0014899b          	addiw	s3,s1,1
 77a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 77c:	00000517          	auipc	a0,0x0
 780:	12453503          	ld	a0,292(a0) # 8a0 <freep>
 784:	c515                	beqz	a0,7b0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 786:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 788:	4798                	lw	a4,8(a5)
 78a:	02977f63          	bgeu	a4,s1,7c8 <malloc+0x70>
 78e:	8a4e                	mv	s4,s3
 790:	0009871b          	sext.w	a4,s3
 794:	6685                	lui	a3,0x1
 796:	00d77363          	bgeu	a4,a3,79c <malloc+0x44>
 79a:	6a05                	lui	s4,0x1
 79c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7a0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7a4:	00000917          	auipc	s2,0x0
 7a8:	0fc90913          	addi	s2,s2,252 # 8a0 <freep>
  if(p == (char*)-1)
 7ac:	5afd                	li	s5,-1
 7ae:	a895                	j	822 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7b0:	00000797          	auipc	a5,0x0
 7b4:	0f878793          	addi	a5,a5,248 # 8a8 <base>
 7b8:	00000717          	auipc	a4,0x0
 7bc:	0ef73423          	sd	a5,232(a4) # 8a0 <freep>
 7c0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7c2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7c6:	b7e1                	j	78e <malloc+0x36>
      if(p->s.size == nunits)
 7c8:	02e48c63          	beq	s1,a4,800 <malloc+0xa8>
        p->s.size -= nunits;
 7cc:	4137073b          	subw	a4,a4,s3
 7d0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7d2:	02071693          	slli	a3,a4,0x20
 7d6:	01c6d713          	srli	a4,a3,0x1c
 7da:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7dc:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7e0:	00000717          	auipc	a4,0x0
 7e4:	0ca73023          	sd	a0,192(a4) # 8a0 <freep>
      return (void*)(p + 1);
 7e8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ec:	70e2                	ld	ra,56(sp)
 7ee:	7442                	ld	s0,48(sp)
 7f0:	74a2                	ld	s1,40(sp)
 7f2:	7902                	ld	s2,32(sp)
 7f4:	69e2                	ld	s3,24(sp)
 7f6:	6a42                	ld	s4,16(sp)
 7f8:	6aa2                	ld	s5,8(sp)
 7fa:	6b02                	ld	s6,0(sp)
 7fc:	6121                	addi	sp,sp,64
 7fe:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 800:	6398                	ld	a4,0(a5)
 802:	e118                	sd	a4,0(a0)
 804:	bff1                	j	7e0 <malloc+0x88>
  hp->s.size = nu;
 806:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 80a:	0541                	addi	a0,a0,16
 80c:	00000097          	auipc	ra,0x0
 810:	ec4080e7          	jalr	-316(ra) # 6d0 <free>
  return freep;
 814:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 818:	d971                	beqz	a0,7ec <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 81a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 81c:	4798                	lw	a4,8(a5)
 81e:	fa9775e3          	bgeu	a4,s1,7c8 <malloc+0x70>
    if(p == freep)
 822:	00093703          	ld	a4,0(s2)
 826:	853e                	mv	a0,a5
 828:	fef719e3          	bne	a4,a5,81a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 82c:	8552                	mv	a0,s4
 82e:	00000097          	auipc	ra,0x0
 832:	b44080e7          	jalr	-1212(ra) # 372 <sbrk>
  if(p == (char*)-1)
 836:	fd5518e3          	bne	a0,s5,806 <malloc+0xae>
        return 0;
 83a:	4501                	li	a0,0
 83c:	bf45                	j	7ec <malloc+0x94>
