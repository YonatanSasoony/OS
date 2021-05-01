
user/_wc:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <wc>:

char buf[512];

void
wc(int fd, char *name)
{
   0:	7119                	addi	sp,sp,-128
   2:	fc86                	sd	ra,120(sp)
   4:	f8a2                	sd	s0,112(sp)
   6:	f4a6                	sd	s1,104(sp)
   8:	f0ca                	sd	s2,96(sp)
   a:	ecce                	sd	s3,88(sp)
   c:	e8d2                	sd	s4,80(sp)
   e:	e4d6                	sd	s5,72(sp)
  10:	e0da                	sd	s6,64(sp)
  12:	fc5e                	sd	s7,56(sp)
  14:	f862                	sd	s8,48(sp)
  16:	f466                	sd	s9,40(sp)
  18:	f06a                	sd	s10,32(sp)
  1a:	ec6e                	sd	s11,24(sp)
  1c:	0100                	addi	s0,sp,128
  1e:	f8a43423          	sd	a0,-120(s0)
  22:	f8b43023          	sd	a1,-128(s0)
  int i, n;
  int l, w, c, inword;

  l = w = c = 0;
  inword = 0;
  26:	4981                	li	s3,0
  l = w = c = 0;
  28:	4c81                	li	s9,0
  2a:	4c01                	li	s8,0
  2c:	4b81                	li	s7,0
  2e:	00001d97          	auipc	s11,0x1
  32:	99bd8d93          	addi	s11,s11,-1637 # 9c9 <buf+0x1>
  while((n = read(fd, buf, sizeof(buf))) > 0){
    for(i=0; i<n; i++){
      c++;
      if(buf[i] == '\n')
  36:	4aa9                	li	s5,10
        l++;
      if(strchr(" \r\t\n\v", buf[i]))
  38:	00001a17          	auipc	s4,0x1
  3c:	920a0a13          	addi	s4,s4,-1760 # 958 <malloc+0xe6>
        inword = 0;
  40:	4b01                	li	s6,0
  while((n = read(fd, buf, sizeof(buf))) > 0){
  42:	a805                	j	72 <wc+0x72>
      if(strchr(" \r\t\n\v", buf[i]))
  44:	8552                	mv	a0,s4
  46:	00000097          	auipc	ra,0x0
  4a:	1e4080e7          	jalr	484(ra) # 22a <strchr>
  4e:	c919                	beqz	a0,64 <wc+0x64>
        inword = 0;
  50:	89da                	mv	s3,s6
    for(i=0; i<n; i++){
  52:	0485                	addi	s1,s1,1
  54:	01248d63          	beq	s1,s2,6e <wc+0x6e>
      if(buf[i] == '\n')
  58:	0004c583          	lbu	a1,0(s1)
  5c:	ff5594e3          	bne	a1,s5,44 <wc+0x44>
        l++;
  60:	2b85                	addiw	s7,s7,1
  62:	b7cd                	j	44 <wc+0x44>
      else if(!inword){
  64:	fe0997e3          	bnez	s3,52 <wc+0x52>
        w++;
  68:	2c05                	addiw	s8,s8,1
        inword = 1;
  6a:	4985                	li	s3,1
  6c:	b7dd                	j	52 <wc+0x52>
      c++;
  6e:	01ac8cbb          	addw	s9,s9,s10
  while((n = read(fd, buf, sizeof(buf))) > 0){
  72:	20000613          	li	a2,512
  76:	00001597          	auipc	a1,0x1
  7a:	95258593          	addi	a1,a1,-1710 # 9c8 <buf>
  7e:	f8843503          	ld	a0,-120(s0)
  82:	00000097          	auipc	ra,0x0
  86:	39a080e7          	jalr	922(ra) # 41c <read>
  8a:	00a05f63          	blez	a0,a8 <wc+0xa8>
    for(i=0; i<n; i++){
  8e:	00001497          	auipc	s1,0x1
  92:	93a48493          	addi	s1,s1,-1734 # 9c8 <buf>
  96:	00050d1b          	sext.w	s10,a0
  9a:	fff5091b          	addiw	s2,a0,-1
  9e:	1902                	slli	s2,s2,0x20
  a0:	02095913          	srli	s2,s2,0x20
  a4:	996e                	add	s2,s2,s11
  a6:	bf4d                	j	58 <wc+0x58>
      }
    }
  }
  if(n < 0){
  a8:	02054e63          	bltz	a0,e4 <wc+0xe4>
    printf("wc: read error\n");
    exit(1);
  }
  printf("%d %d %d %s\n", l, w, c, name);
  ac:	f8043703          	ld	a4,-128(s0)
  b0:	86e6                	mv	a3,s9
  b2:	8662                	mv	a2,s8
  b4:	85de                	mv	a1,s7
  b6:	00001517          	auipc	a0,0x1
  ba:	8ba50513          	addi	a0,a0,-1862 # 970 <malloc+0xfe>
  be:	00000097          	auipc	ra,0x0
  c2:	6f6080e7          	jalr	1782(ra) # 7b4 <printf>
}
  c6:	70e6                	ld	ra,120(sp)
  c8:	7446                	ld	s0,112(sp)
  ca:	74a6                	ld	s1,104(sp)
  cc:	7906                	ld	s2,96(sp)
  ce:	69e6                	ld	s3,88(sp)
  d0:	6a46                	ld	s4,80(sp)
  d2:	6aa6                	ld	s5,72(sp)
  d4:	6b06                	ld	s6,64(sp)
  d6:	7be2                	ld	s7,56(sp)
  d8:	7c42                	ld	s8,48(sp)
  da:	7ca2                	ld	s9,40(sp)
  dc:	7d02                	ld	s10,32(sp)
  de:	6de2                	ld	s11,24(sp)
  e0:	6109                	addi	sp,sp,128
  e2:	8082                	ret
    printf("wc: read error\n");
  e4:	00001517          	auipc	a0,0x1
  e8:	87c50513          	addi	a0,a0,-1924 # 960 <malloc+0xee>
  ec:	00000097          	auipc	ra,0x0
  f0:	6c8080e7          	jalr	1736(ra) # 7b4 <printf>
    exit(1);
  f4:	4505                	li	a0,1
  f6:	00000097          	auipc	ra,0x0
  fa:	30e080e7          	jalr	782(ra) # 404 <exit>

00000000000000fe <main>:

int
main(int argc, char *argv[])
{
  fe:	7179                	addi	sp,sp,-48
 100:	f406                	sd	ra,40(sp)
 102:	f022                	sd	s0,32(sp)
 104:	ec26                	sd	s1,24(sp)
 106:	e84a                	sd	s2,16(sp)
 108:	e44e                	sd	s3,8(sp)
 10a:	e052                	sd	s4,0(sp)
 10c:	1800                	addi	s0,sp,48
  int fd, i;

  if(argc <= 1){
 10e:	4785                	li	a5,1
 110:	04a7d763          	bge	a5,a0,15e <main+0x60>
 114:	00858493          	addi	s1,a1,8
 118:	ffe5099b          	addiw	s3,a0,-2
 11c:	02099793          	slli	a5,s3,0x20
 120:	01d7d993          	srli	s3,a5,0x1d
 124:	05c1                	addi	a1,a1,16
 126:	99ae                	add	s3,s3,a1
    wc(0, "");
    exit(0);
  }

  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
 128:	4581                	li	a1,0
 12a:	6088                	ld	a0,0(s1)
 12c:	00000097          	auipc	ra,0x0
 130:	318080e7          	jalr	792(ra) # 444 <open>
 134:	892a                	mv	s2,a0
 136:	04054263          	bltz	a0,17a <main+0x7c>
      printf("wc: cannot open %s\n", argv[i]);
      exit(1);
    }
    wc(fd, argv[i]);
 13a:	608c                	ld	a1,0(s1)
 13c:	00000097          	auipc	ra,0x0
 140:	ec4080e7          	jalr	-316(ra) # 0 <wc>
    close(fd);
 144:	854a                	mv	a0,s2
 146:	00000097          	auipc	ra,0x0
 14a:	2e6080e7          	jalr	742(ra) # 42c <close>
  for(i = 1; i < argc; i++){
 14e:	04a1                	addi	s1,s1,8
 150:	fd349ce3          	bne	s1,s3,128 <main+0x2a>
  }
  exit(0);
 154:	4501                	li	a0,0
 156:	00000097          	auipc	ra,0x0
 15a:	2ae080e7          	jalr	686(ra) # 404 <exit>
    wc(0, "");
 15e:	00001597          	auipc	a1,0x1
 162:	82258593          	addi	a1,a1,-2014 # 980 <malloc+0x10e>
 166:	4501                	li	a0,0
 168:	00000097          	auipc	ra,0x0
 16c:	e98080e7          	jalr	-360(ra) # 0 <wc>
    exit(0);
 170:	4501                	li	a0,0
 172:	00000097          	auipc	ra,0x0
 176:	292080e7          	jalr	658(ra) # 404 <exit>
      printf("wc: cannot open %s\n", argv[i]);
 17a:	608c                	ld	a1,0(s1)
 17c:	00001517          	auipc	a0,0x1
 180:	80c50513          	addi	a0,a0,-2036 # 988 <malloc+0x116>
 184:	00000097          	auipc	ra,0x0
 188:	630080e7          	jalr	1584(ra) # 7b4 <printf>
      exit(1);
 18c:	4505                	li	a0,1
 18e:	00000097          	auipc	ra,0x0
 192:	276080e7          	jalr	630(ra) # 404 <exit>

0000000000000196 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 19c:	87aa                	mv	a5,a0
 19e:	0585                	addi	a1,a1,1
 1a0:	0785                	addi	a5,a5,1
 1a2:	fff5c703          	lbu	a4,-1(a1)
 1a6:	fee78fa3          	sb	a4,-1(a5)
 1aa:	fb75                	bnez	a4,19e <strcpy+0x8>
    ;
  return os;
}
 1ac:	6422                	ld	s0,8(sp)
 1ae:	0141                	addi	sp,sp,16
 1b0:	8082                	ret

00000000000001b2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1b2:	1141                	addi	sp,sp,-16
 1b4:	e422                	sd	s0,8(sp)
 1b6:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1b8:	00054783          	lbu	a5,0(a0)
 1bc:	cb91                	beqz	a5,1d0 <strcmp+0x1e>
 1be:	0005c703          	lbu	a4,0(a1)
 1c2:	00f71763          	bne	a4,a5,1d0 <strcmp+0x1e>
    p++, q++;
 1c6:	0505                	addi	a0,a0,1
 1c8:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1ca:	00054783          	lbu	a5,0(a0)
 1ce:	fbe5                	bnez	a5,1be <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1d0:	0005c503          	lbu	a0,0(a1)
}
 1d4:	40a7853b          	subw	a0,a5,a0
 1d8:	6422                	ld	s0,8(sp)
 1da:	0141                	addi	sp,sp,16
 1dc:	8082                	ret

00000000000001de <strlen>:

uint
strlen(const char *s)
{
 1de:	1141                	addi	sp,sp,-16
 1e0:	e422                	sd	s0,8(sp)
 1e2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1e4:	00054783          	lbu	a5,0(a0)
 1e8:	cf91                	beqz	a5,204 <strlen+0x26>
 1ea:	0505                	addi	a0,a0,1
 1ec:	87aa                	mv	a5,a0
 1ee:	4685                	li	a3,1
 1f0:	9e89                	subw	a3,a3,a0
 1f2:	00f6853b          	addw	a0,a3,a5
 1f6:	0785                	addi	a5,a5,1
 1f8:	fff7c703          	lbu	a4,-1(a5)
 1fc:	fb7d                	bnez	a4,1f2 <strlen+0x14>
    ;
  return n;
}
 1fe:	6422                	ld	s0,8(sp)
 200:	0141                	addi	sp,sp,16
 202:	8082                	ret
  for(n = 0; s[n]; n++)
 204:	4501                	li	a0,0
 206:	bfe5                	j	1fe <strlen+0x20>

0000000000000208 <memset>:

void*
memset(void *dst, int c, uint n)
{
 208:	1141                	addi	sp,sp,-16
 20a:	e422                	sd	s0,8(sp)
 20c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 20e:	ca19                	beqz	a2,224 <memset+0x1c>
 210:	87aa                	mv	a5,a0
 212:	1602                	slli	a2,a2,0x20
 214:	9201                	srli	a2,a2,0x20
 216:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 21a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 21e:	0785                	addi	a5,a5,1
 220:	fee79de3          	bne	a5,a4,21a <memset+0x12>
  }
  return dst;
}
 224:	6422                	ld	s0,8(sp)
 226:	0141                	addi	sp,sp,16
 228:	8082                	ret

000000000000022a <strchr>:

char*
strchr(const char *s, char c)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e422                	sd	s0,8(sp)
 22e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 230:	00054783          	lbu	a5,0(a0)
 234:	cb99                	beqz	a5,24a <strchr+0x20>
    if(*s == c)
 236:	00f58763          	beq	a1,a5,244 <strchr+0x1a>
  for(; *s; s++)
 23a:	0505                	addi	a0,a0,1
 23c:	00054783          	lbu	a5,0(a0)
 240:	fbfd                	bnez	a5,236 <strchr+0xc>
      return (char*)s;
  return 0;
 242:	4501                	li	a0,0
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
  return 0;
 24a:	4501                	li	a0,0
 24c:	bfe5                	j	244 <strchr+0x1a>

000000000000024e <gets>:

char*
gets(char *buf, int max)
{
 24e:	711d                	addi	sp,sp,-96
 250:	ec86                	sd	ra,88(sp)
 252:	e8a2                	sd	s0,80(sp)
 254:	e4a6                	sd	s1,72(sp)
 256:	e0ca                	sd	s2,64(sp)
 258:	fc4e                	sd	s3,56(sp)
 25a:	f852                	sd	s4,48(sp)
 25c:	f456                	sd	s5,40(sp)
 25e:	f05a                	sd	s6,32(sp)
 260:	ec5e                	sd	s7,24(sp)
 262:	1080                	addi	s0,sp,96
 264:	8baa                	mv	s7,a0
 266:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 268:	892a                	mv	s2,a0
 26a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 26c:	4aa9                	li	s5,10
 26e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 270:	89a6                	mv	s3,s1
 272:	2485                	addiw	s1,s1,1
 274:	0344d863          	bge	s1,s4,2a4 <gets+0x56>
    cc = read(0, &c, 1);
 278:	4605                	li	a2,1
 27a:	faf40593          	addi	a1,s0,-81
 27e:	4501                	li	a0,0
 280:	00000097          	auipc	ra,0x0
 284:	19c080e7          	jalr	412(ra) # 41c <read>
    if(cc < 1)
 288:	00a05e63          	blez	a0,2a4 <gets+0x56>
    buf[i++] = c;
 28c:	faf44783          	lbu	a5,-81(s0)
 290:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 294:	01578763          	beq	a5,s5,2a2 <gets+0x54>
 298:	0905                	addi	s2,s2,1
 29a:	fd679be3          	bne	a5,s6,270 <gets+0x22>
  for(i=0; i+1 < max; ){
 29e:	89a6                	mv	s3,s1
 2a0:	a011                	j	2a4 <gets+0x56>
 2a2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2a4:	99de                	add	s3,s3,s7
 2a6:	00098023          	sb	zero,0(s3)
  return buf;
}
 2aa:	855e                	mv	a0,s7
 2ac:	60e6                	ld	ra,88(sp)
 2ae:	6446                	ld	s0,80(sp)
 2b0:	64a6                	ld	s1,72(sp)
 2b2:	6906                	ld	s2,64(sp)
 2b4:	79e2                	ld	s3,56(sp)
 2b6:	7a42                	ld	s4,48(sp)
 2b8:	7aa2                	ld	s5,40(sp)
 2ba:	7b02                	ld	s6,32(sp)
 2bc:	6be2                	ld	s7,24(sp)
 2be:	6125                	addi	sp,sp,96
 2c0:	8082                	ret

00000000000002c2 <stat>:

int
stat(const char *n, struct stat *st)
{
 2c2:	1101                	addi	sp,sp,-32
 2c4:	ec06                	sd	ra,24(sp)
 2c6:	e822                	sd	s0,16(sp)
 2c8:	e426                	sd	s1,8(sp)
 2ca:	e04a                	sd	s2,0(sp)
 2cc:	1000                	addi	s0,sp,32
 2ce:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2d0:	4581                	li	a1,0
 2d2:	00000097          	auipc	ra,0x0
 2d6:	172080e7          	jalr	370(ra) # 444 <open>
  if(fd < 0)
 2da:	02054563          	bltz	a0,304 <stat+0x42>
 2de:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2e0:	85ca                	mv	a1,s2
 2e2:	00000097          	auipc	ra,0x0
 2e6:	17a080e7          	jalr	378(ra) # 45c <fstat>
 2ea:	892a                	mv	s2,a0
  close(fd);
 2ec:	8526                	mv	a0,s1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	13e080e7          	jalr	318(ra) # 42c <close>
  return r;
}
 2f6:	854a                	mv	a0,s2
 2f8:	60e2                	ld	ra,24(sp)
 2fa:	6442                	ld	s0,16(sp)
 2fc:	64a2                	ld	s1,8(sp)
 2fe:	6902                	ld	s2,0(sp)
 300:	6105                	addi	sp,sp,32
 302:	8082                	ret
    return -1;
 304:	597d                	li	s2,-1
 306:	bfc5                	j	2f6 <stat+0x34>

0000000000000308 <atoi>:

int
atoi(const char *s)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 30e:	00054603          	lbu	a2,0(a0)
 312:	fd06079b          	addiw	a5,a2,-48
 316:	0ff7f793          	andi	a5,a5,255
 31a:	4725                	li	a4,9
 31c:	02f76963          	bltu	a4,a5,34e <atoi+0x46>
 320:	86aa                	mv	a3,a0
  n = 0;
 322:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 324:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 326:	0685                	addi	a3,a3,1
 328:	0025179b          	slliw	a5,a0,0x2
 32c:	9fa9                	addw	a5,a5,a0
 32e:	0017979b          	slliw	a5,a5,0x1
 332:	9fb1                	addw	a5,a5,a2
 334:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 338:	0006c603          	lbu	a2,0(a3)
 33c:	fd06071b          	addiw	a4,a2,-48
 340:	0ff77713          	andi	a4,a4,255
 344:	fee5f1e3          	bgeu	a1,a4,326 <atoi+0x1e>
  return n;
}
 348:	6422                	ld	s0,8(sp)
 34a:	0141                	addi	sp,sp,16
 34c:	8082                	ret
  n = 0;
 34e:	4501                	li	a0,0
 350:	bfe5                	j	348 <atoi+0x40>

0000000000000352 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 352:	1141                	addi	sp,sp,-16
 354:	e422                	sd	s0,8(sp)
 356:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 358:	02b57463          	bgeu	a0,a1,380 <memmove+0x2e>
    while(n-- > 0)
 35c:	00c05f63          	blez	a2,37a <memmove+0x28>
 360:	1602                	slli	a2,a2,0x20
 362:	9201                	srli	a2,a2,0x20
 364:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 368:	872a                	mv	a4,a0
      *dst++ = *src++;
 36a:	0585                	addi	a1,a1,1
 36c:	0705                	addi	a4,a4,1
 36e:	fff5c683          	lbu	a3,-1(a1)
 372:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 376:	fee79ae3          	bne	a5,a4,36a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 37a:	6422                	ld	s0,8(sp)
 37c:	0141                	addi	sp,sp,16
 37e:	8082                	ret
    dst += n;
 380:	00c50733          	add	a4,a0,a2
    src += n;
 384:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 386:	fec05ae3          	blez	a2,37a <memmove+0x28>
 38a:	fff6079b          	addiw	a5,a2,-1
 38e:	1782                	slli	a5,a5,0x20
 390:	9381                	srli	a5,a5,0x20
 392:	fff7c793          	not	a5,a5
 396:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 398:	15fd                	addi	a1,a1,-1
 39a:	177d                	addi	a4,a4,-1
 39c:	0005c683          	lbu	a3,0(a1)
 3a0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3a4:	fee79ae3          	bne	a5,a4,398 <memmove+0x46>
 3a8:	bfc9                	j	37a <memmove+0x28>

00000000000003aa <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3aa:	1141                	addi	sp,sp,-16
 3ac:	e422                	sd	s0,8(sp)
 3ae:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3b0:	ca05                	beqz	a2,3e0 <memcmp+0x36>
 3b2:	fff6069b          	addiw	a3,a2,-1
 3b6:	1682                	slli	a3,a3,0x20
 3b8:	9281                	srli	a3,a3,0x20
 3ba:	0685                	addi	a3,a3,1
 3bc:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3be:	00054783          	lbu	a5,0(a0)
 3c2:	0005c703          	lbu	a4,0(a1)
 3c6:	00e79863          	bne	a5,a4,3d6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ca:	0505                	addi	a0,a0,1
    p2++;
 3cc:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3ce:	fed518e3          	bne	a0,a3,3be <memcmp+0x14>
  }
  return 0;
 3d2:	4501                	li	a0,0
 3d4:	a019                	j	3da <memcmp+0x30>
      return *p1 - *p2;
 3d6:	40e7853b          	subw	a0,a5,a4
}
 3da:	6422                	ld	s0,8(sp)
 3dc:	0141                	addi	sp,sp,16
 3de:	8082                	ret
  return 0;
 3e0:	4501                	li	a0,0
 3e2:	bfe5                	j	3da <memcmp+0x30>

00000000000003e4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3e4:	1141                	addi	sp,sp,-16
 3e6:	e406                	sd	ra,8(sp)
 3e8:	e022                	sd	s0,0(sp)
 3ea:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3ec:	00000097          	auipc	ra,0x0
 3f0:	f66080e7          	jalr	-154(ra) # 352 <memmove>
}
 3f4:	60a2                	ld	ra,8(sp)
 3f6:	6402                	ld	s0,0(sp)
 3f8:	0141                	addi	sp,sp,16
 3fa:	8082                	ret

00000000000003fc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3fc:	4885                	li	a7,1
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <exit>:
.global exit
exit:
 li a7, SYS_exit
 404:	4889                	li	a7,2
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <wait>:
.global wait
wait:
 li a7, SYS_wait
 40c:	488d                	li	a7,3
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 414:	4891                	li	a7,4
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <read>:
.global read
read:
 li a7, SYS_read
 41c:	4895                	li	a7,5
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <write>:
.global write
write:
 li a7, SYS_write
 424:	48c1                	li	a7,16
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <close>:
.global close
close:
 li a7, SYS_close
 42c:	48d5                	li	a7,21
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <kill>:
.global kill
kill:
 li a7, SYS_kill
 434:	4899                	li	a7,6
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <exec>:
.global exec
exec:
 li a7, SYS_exec
 43c:	489d                	li	a7,7
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <open>:
.global open
open:
 li a7, SYS_open
 444:	48bd                	li	a7,15
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 44c:	48c5                	li	a7,17
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 454:	48c9                	li	a7,18
 ecall
 456:	00000073          	ecall
 ret
 45a:	8082                	ret

000000000000045c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 45c:	48a1                	li	a7,8
 ecall
 45e:	00000073          	ecall
 ret
 462:	8082                	ret

0000000000000464 <link>:
.global link
link:
 li a7, SYS_link
 464:	48cd                	li	a7,19
 ecall
 466:	00000073          	ecall
 ret
 46a:	8082                	ret

000000000000046c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 46c:	48d1                	li	a7,20
 ecall
 46e:	00000073          	ecall
 ret
 472:	8082                	ret

0000000000000474 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 474:	48a5                	li	a7,9
 ecall
 476:	00000073          	ecall
 ret
 47a:	8082                	ret

000000000000047c <dup>:
.global dup
dup:
 li a7, SYS_dup
 47c:	48a9                	li	a7,10
 ecall
 47e:	00000073          	ecall
 ret
 482:	8082                	ret

0000000000000484 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 484:	48ad                	li	a7,11
 ecall
 486:	00000073          	ecall
 ret
 48a:	8082                	ret

000000000000048c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 48c:	48b1                	li	a7,12
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 494:	48b5                	li	a7,13
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 49c:	48b9                	li	a7,14
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 4a4:	48d9                	li	a7,22
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 4ac:	48dd                	li	a7,23
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 4b4:	48e1                	li	a7,24
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 4bc:	48e5                	li	a7,25
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 4c4:	48e9                	li	a7,26
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 4cc:	48ed                	li	a7,27
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 4d4:	48f1                	li	a7,28
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4dc:	1101                	addi	sp,sp,-32
 4de:	ec06                	sd	ra,24(sp)
 4e0:	e822                	sd	s0,16(sp)
 4e2:	1000                	addi	s0,sp,32
 4e4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4e8:	4605                	li	a2,1
 4ea:	fef40593          	addi	a1,s0,-17
 4ee:	00000097          	auipc	ra,0x0
 4f2:	f36080e7          	jalr	-202(ra) # 424 <write>
}
 4f6:	60e2                	ld	ra,24(sp)
 4f8:	6442                	ld	s0,16(sp)
 4fa:	6105                	addi	sp,sp,32
 4fc:	8082                	ret

00000000000004fe <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4fe:	7139                	addi	sp,sp,-64
 500:	fc06                	sd	ra,56(sp)
 502:	f822                	sd	s0,48(sp)
 504:	f426                	sd	s1,40(sp)
 506:	f04a                	sd	s2,32(sp)
 508:	ec4e                	sd	s3,24(sp)
 50a:	0080                	addi	s0,sp,64
 50c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 50e:	c299                	beqz	a3,514 <printint+0x16>
 510:	0805c863          	bltz	a1,5a0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 514:	2581                	sext.w	a1,a1
  neg = 0;
 516:	4881                	li	a7,0
 518:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 51c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 51e:	2601                	sext.w	a2,a2
 520:	00000517          	auipc	a0,0x0
 524:	48850513          	addi	a0,a0,1160 # 9a8 <digits>
 528:	883a                	mv	a6,a4
 52a:	2705                	addiw	a4,a4,1
 52c:	02c5f7bb          	remuw	a5,a1,a2
 530:	1782                	slli	a5,a5,0x20
 532:	9381                	srli	a5,a5,0x20
 534:	97aa                	add	a5,a5,a0
 536:	0007c783          	lbu	a5,0(a5)
 53a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 53e:	0005879b          	sext.w	a5,a1
 542:	02c5d5bb          	divuw	a1,a1,a2
 546:	0685                	addi	a3,a3,1
 548:	fec7f0e3          	bgeu	a5,a2,528 <printint+0x2a>
  if(neg)
 54c:	00088b63          	beqz	a7,562 <printint+0x64>
    buf[i++] = '-';
 550:	fd040793          	addi	a5,s0,-48
 554:	973e                	add	a4,a4,a5
 556:	02d00793          	li	a5,45
 55a:	fef70823          	sb	a5,-16(a4)
 55e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 562:	02e05863          	blez	a4,592 <printint+0x94>
 566:	fc040793          	addi	a5,s0,-64
 56a:	00e78933          	add	s2,a5,a4
 56e:	fff78993          	addi	s3,a5,-1
 572:	99ba                	add	s3,s3,a4
 574:	377d                	addiw	a4,a4,-1
 576:	1702                	slli	a4,a4,0x20
 578:	9301                	srli	a4,a4,0x20
 57a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 57e:	fff94583          	lbu	a1,-1(s2)
 582:	8526                	mv	a0,s1
 584:	00000097          	auipc	ra,0x0
 588:	f58080e7          	jalr	-168(ra) # 4dc <putc>
  while(--i >= 0)
 58c:	197d                	addi	s2,s2,-1
 58e:	ff3918e3          	bne	s2,s3,57e <printint+0x80>
}
 592:	70e2                	ld	ra,56(sp)
 594:	7442                	ld	s0,48(sp)
 596:	74a2                	ld	s1,40(sp)
 598:	7902                	ld	s2,32(sp)
 59a:	69e2                	ld	s3,24(sp)
 59c:	6121                	addi	sp,sp,64
 59e:	8082                	ret
    x = -xx;
 5a0:	40b005bb          	negw	a1,a1
    neg = 1;
 5a4:	4885                	li	a7,1
    x = -xx;
 5a6:	bf8d                	j	518 <printint+0x1a>

00000000000005a8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5a8:	7119                	addi	sp,sp,-128
 5aa:	fc86                	sd	ra,120(sp)
 5ac:	f8a2                	sd	s0,112(sp)
 5ae:	f4a6                	sd	s1,104(sp)
 5b0:	f0ca                	sd	s2,96(sp)
 5b2:	ecce                	sd	s3,88(sp)
 5b4:	e8d2                	sd	s4,80(sp)
 5b6:	e4d6                	sd	s5,72(sp)
 5b8:	e0da                	sd	s6,64(sp)
 5ba:	fc5e                	sd	s7,56(sp)
 5bc:	f862                	sd	s8,48(sp)
 5be:	f466                	sd	s9,40(sp)
 5c0:	f06a                	sd	s10,32(sp)
 5c2:	ec6e                	sd	s11,24(sp)
 5c4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5c6:	0005c903          	lbu	s2,0(a1)
 5ca:	18090f63          	beqz	s2,768 <vprintf+0x1c0>
 5ce:	8aaa                	mv	s5,a0
 5d0:	8b32                	mv	s6,a2
 5d2:	00158493          	addi	s1,a1,1
  state = 0;
 5d6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5d8:	02500a13          	li	s4,37
      if(c == 'd'){
 5dc:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5e0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5e4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5e8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ec:	00000b97          	auipc	s7,0x0
 5f0:	3bcb8b93          	addi	s7,s7,956 # 9a8 <digits>
 5f4:	a839                	j	612 <vprintf+0x6a>
        putc(fd, c);
 5f6:	85ca                	mv	a1,s2
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	ee2080e7          	jalr	-286(ra) # 4dc <putc>
 602:	a019                	j	608 <vprintf+0x60>
    } else if(state == '%'){
 604:	01498f63          	beq	s3,s4,622 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 608:	0485                	addi	s1,s1,1
 60a:	fff4c903          	lbu	s2,-1(s1)
 60e:	14090d63          	beqz	s2,768 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 612:	0009079b          	sext.w	a5,s2
    if(state == 0){
 616:	fe0997e3          	bnez	s3,604 <vprintf+0x5c>
      if(c == '%'){
 61a:	fd479ee3          	bne	a5,s4,5f6 <vprintf+0x4e>
        state = '%';
 61e:	89be                	mv	s3,a5
 620:	b7e5                	j	608 <vprintf+0x60>
      if(c == 'd'){
 622:	05878063          	beq	a5,s8,662 <vprintf+0xba>
      } else if(c == 'l') {
 626:	05978c63          	beq	a5,s9,67e <vprintf+0xd6>
      } else if(c == 'x') {
 62a:	07a78863          	beq	a5,s10,69a <vprintf+0xf2>
      } else if(c == 'p') {
 62e:	09b78463          	beq	a5,s11,6b6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 632:	07300713          	li	a4,115
 636:	0ce78663          	beq	a5,a4,702 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 63a:	06300713          	li	a4,99
 63e:	0ee78e63          	beq	a5,a4,73a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 642:	11478863          	beq	a5,s4,752 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 646:	85d2                	mv	a1,s4
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	e92080e7          	jalr	-366(ra) # 4dc <putc>
        putc(fd, c);
 652:	85ca                	mv	a1,s2
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	e86080e7          	jalr	-378(ra) # 4dc <putc>
      }
      state = 0;
 65e:	4981                	li	s3,0
 660:	b765                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 662:	008b0913          	addi	s2,s6,8
 666:	4685                	li	a3,1
 668:	4629                	li	a2,10
 66a:	000b2583          	lw	a1,0(s6)
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	e8e080e7          	jalr	-370(ra) # 4fe <printint>
 678:	8b4a                	mv	s6,s2
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b771                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 67e:	008b0913          	addi	s2,s6,8
 682:	4681                	li	a3,0
 684:	4629                	li	a2,10
 686:	000b2583          	lw	a1,0(s6)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	e72080e7          	jalr	-398(ra) # 4fe <printint>
 694:	8b4a                	mv	s6,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	bf85                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 69a:	008b0913          	addi	s2,s6,8
 69e:	4681                	li	a3,0
 6a0:	4641                	li	a2,16
 6a2:	000b2583          	lw	a1,0(s6)
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	e56080e7          	jalr	-426(ra) # 4fe <printint>
 6b0:	8b4a                	mv	s6,s2
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	bf91                	j	608 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6b6:	008b0793          	addi	a5,s6,8
 6ba:	f8f43423          	sd	a5,-120(s0)
 6be:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6c2:	03000593          	li	a1,48
 6c6:	8556                	mv	a0,s5
 6c8:	00000097          	auipc	ra,0x0
 6cc:	e14080e7          	jalr	-492(ra) # 4dc <putc>
  putc(fd, 'x');
 6d0:	85ea                	mv	a1,s10
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e08080e7          	jalr	-504(ra) # 4dc <putc>
 6dc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6de:	03c9d793          	srli	a5,s3,0x3c
 6e2:	97de                	add	a5,a5,s7
 6e4:	0007c583          	lbu	a1,0(a5)
 6e8:	8556                	mv	a0,s5
 6ea:	00000097          	auipc	ra,0x0
 6ee:	df2080e7          	jalr	-526(ra) # 4dc <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6f2:	0992                	slli	s3,s3,0x4
 6f4:	397d                	addiw	s2,s2,-1
 6f6:	fe0914e3          	bnez	s2,6de <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6fa:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6fe:	4981                	li	s3,0
 700:	b721                	j	608 <vprintf+0x60>
        s = va_arg(ap, char*);
 702:	008b0993          	addi	s3,s6,8
 706:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 70a:	02090163          	beqz	s2,72c <vprintf+0x184>
        while(*s != 0){
 70e:	00094583          	lbu	a1,0(s2)
 712:	c9a1                	beqz	a1,762 <vprintf+0x1ba>
          putc(fd, *s);
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	dc6080e7          	jalr	-570(ra) # 4dc <putc>
          s++;
 71e:	0905                	addi	s2,s2,1
        while(*s != 0){
 720:	00094583          	lbu	a1,0(s2)
 724:	f9e5                	bnez	a1,714 <vprintf+0x16c>
        s = va_arg(ap, char*);
 726:	8b4e                	mv	s6,s3
      state = 0;
 728:	4981                	li	s3,0
 72a:	bdf9                	j	608 <vprintf+0x60>
          s = "(null)";
 72c:	00000917          	auipc	s2,0x0
 730:	27490913          	addi	s2,s2,628 # 9a0 <malloc+0x12e>
        while(*s != 0){
 734:	02800593          	li	a1,40
 738:	bff1                	j	714 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 73a:	008b0913          	addi	s2,s6,8
 73e:	000b4583          	lbu	a1,0(s6)
 742:	8556                	mv	a0,s5
 744:	00000097          	auipc	ra,0x0
 748:	d98080e7          	jalr	-616(ra) # 4dc <putc>
 74c:	8b4a                	mv	s6,s2
      state = 0;
 74e:	4981                	li	s3,0
 750:	bd65                	j	608 <vprintf+0x60>
        putc(fd, c);
 752:	85d2                	mv	a1,s4
 754:	8556                	mv	a0,s5
 756:	00000097          	auipc	ra,0x0
 75a:	d86080e7          	jalr	-634(ra) # 4dc <putc>
      state = 0;
 75e:	4981                	li	s3,0
 760:	b565                	j	608 <vprintf+0x60>
        s = va_arg(ap, char*);
 762:	8b4e                	mv	s6,s3
      state = 0;
 764:	4981                	li	s3,0
 766:	b54d                	j	608 <vprintf+0x60>
    }
  }
}
 768:	70e6                	ld	ra,120(sp)
 76a:	7446                	ld	s0,112(sp)
 76c:	74a6                	ld	s1,104(sp)
 76e:	7906                	ld	s2,96(sp)
 770:	69e6                	ld	s3,88(sp)
 772:	6a46                	ld	s4,80(sp)
 774:	6aa6                	ld	s5,72(sp)
 776:	6b06                	ld	s6,64(sp)
 778:	7be2                	ld	s7,56(sp)
 77a:	7c42                	ld	s8,48(sp)
 77c:	7ca2                	ld	s9,40(sp)
 77e:	7d02                	ld	s10,32(sp)
 780:	6de2                	ld	s11,24(sp)
 782:	6109                	addi	sp,sp,128
 784:	8082                	ret

0000000000000786 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 786:	715d                	addi	sp,sp,-80
 788:	ec06                	sd	ra,24(sp)
 78a:	e822                	sd	s0,16(sp)
 78c:	1000                	addi	s0,sp,32
 78e:	e010                	sd	a2,0(s0)
 790:	e414                	sd	a3,8(s0)
 792:	e818                	sd	a4,16(s0)
 794:	ec1c                	sd	a5,24(s0)
 796:	03043023          	sd	a6,32(s0)
 79a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 79e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7a2:	8622                	mv	a2,s0
 7a4:	00000097          	auipc	ra,0x0
 7a8:	e04080e7          	jalr	-508(ra) # 5a8 <vprintf>
}
 7ac:	60e2                	ld	ra,24(sp)
 7ae:	6442                	ld	s0,16(sp)
 7b0:	6161                	addi	sp,sp,80
 7b2:	8082                	ret

00000000000007b4 <printf>:

void
printf(const char *fmt, ...)
{
 7b4:	711d                	addi	sp,sp,-96
 7b6:	ec06                	sd	ra,24(sp)
 7b8:	e822                	sd	s0,16(sp)
 7ba:	1000                	addi	s0,sp,32
 7bc:	e40c                	sd	a1,8(s0)
 7be:	e810                	sd	a2,16(s0)
 7c0:	ec14                	sd	a3,24(s0)
 7c2:	f018                	sd	a4,32(s0)
 7c4:	f41c                	sd	a5,40(s0)
 7c6:	03043823          	sd	a6,48(s0)
 7ca:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7ce:	00840613          	addi	a2,s0,8
 7d2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7d6:	85aa                	mv	a1,a0
 7d8:	4505                	li	a0,1
 7da:	00000097          	auipc	ra,0x0
 7de:	dce080e7          	jalr	-562(ra) # 5a8 <vprintf>
}
 7e2:	60e2                	ld	ra,24(sp)
 7e4:	6442                	ld	s0,16(sp)
 7e6:	6125                	addi	sp,sp,96
 7e8:	8082                	ret

00000000000007ea <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ea:	1141                	addi	sp,sp,-16
 7ec:	e422                	sd	s0,8(sp)
 7ee:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7f0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f4:	00000797          	auipc	a5,0x0
 7f8:	1cc7b783          	ld	a5,460(a5) # 9c0 <freep>
 7fc:	a805                	j	82c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7fe:	4618                	lw	a4,8(a2)
 800:	9db9                	addw	a1,a1,a4
 802:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 806:	6398                	ld	a4,0(a5)
 808:	6318                	ld	a4,0(a4)
 80a:	fee53823          	sd	a4,-16(a0)
 80e:	a091                	j	852 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 810:	ff852703          	lw	a4,-8(a0)
 814:	9e39                	addw	a2,a2,a4
 816:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 818:	ff053703          	ld	a4,-16(a0)
 81c:	e398                	sd	a4,0(a5)
 81e:	a099                	j	864 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 820:	6398                	ld	a4,0(a5)
 822:	00e7e463          	bltu	a5,a4,82a <free+0x40>
 826:	00e6ea63          	bltu	a3,a4,83a <free+0x50>
{
 82a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 82c:	fed7fae3          	bgeu	a5,a3,820 <free+0x36>
 830:	6398                	ld	a4,0(a5)
 832:	00e6e463          	bltu	a3,a4,83a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 836:	fee7eae3          	bltu	a5,a4,82a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 83a:	ff852583          	lw	a1,-8(a0)
 83e:	6390                	ld	a2,0(a5)
 840:	02059813          	slli	a6,a1,0x20
 844:	01c85713          	srli	a4,a6,0x1c
 848:	9736                	add	a4,a4,a3
 84a:	fae60ae3          	beq	a2,a4,7fe <free+0x14>
    bp->s.ptr = p->s.ptr;
 84e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 852:	4790                	lw	a2,8(a5)
 854:	02061593          	slli	a1,a2,0x20
 858:	01c5d713          	srli	a4,a1,0x1c
 85c:	973e                	add	a4,a4,a5
 85e:	fae689e3          	beq	a3,a4,810 <free+0x26>
  } else
    p->s.ptr = bp;
 862:	e394                	sd	a3,0(a5)
  freep = p;
 864:	00000717          	auipc	a4,0x0
 868:	14f73e23          	sd	a5,348(a4) # 9c0 <freep>
}
 86c:	6422                	ld	s0,8(sp)
 86e:	0141                	addi	sp,sp,16
 870:	8082                	ret

0000000000000872 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 872:	7139                	addi	sp,sp,-64
 874:	fc06                	sd	ra,56(sp)
 876:	f822                	sd	s0,48(sp)
 878:	f426                	sd	s1,40(sp)
 87a:	f04a                	sd	s2,32(sp)
 87c:	ec4e                	sd	s3,24(sp)
 87e:	e852                	sd	s4,16(sp)
 880:	e456                	sd	s5,8(sp)
 882:	e05a                	sd	s6,0(sp)
 884:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 886:	02051493          	slli	s1,a0,0x20
 88a:	9081                	srli	s1,s1,0x20
 88c:	04bd                	addi	s1,s1,15
 88e:	8091                	srli	s1,s1,0x4
 890:	0014899b          	addiw	s3,s1,1
 894:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 896:	00000517          	auipc	a0,0x0
 89a:	12a53503          	ld	a0,298(a0) # 9c0 <freep>
 89e:	c515                	beqz	a0,8ca <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a2:	4798                	lw	a4,8(a5)
 8a4:	02977f63          	bgeu	a4,s1,8e2 <malloc+0x70>
 8a8:	8a4e                	mv	s4,s3
 8aa:	0009871b          	sext.w	a4,s3
 8ae:	6685                	lui	a3,0x1
 8b0:	00d77363          	bgeu	a4,a3,8b6 <malloc+0x44>
 8b4:	6a05                	lui	s4,0x1
 8b6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8ba:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8be:	00000917          	auipc	s2,0x0
 8c2:	10290913          	addi	s2,s2,258 # 9c0 <freep>
  if(p == (char*)-1)
 8c6:	5afd                	li	s5,-1
 8c8:	a895                	j	93c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 8ca:	00000797          	auipc	a5,0x0
 8ce:	2fe78793          	addi	a5,a5,766 # bc8 <base>
 8d2:	00000717          	auipc	a4,0x0
 8d6:	0ef73723          	sd	a5,238(a4) # 9c0 <freep>
 8da:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8dc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8e0:	b7e1                	j	8a8 <malloc+0x36>
      if(p->s.size == nunits)
 8e2:	02e48c63          	beq	s1,a4,91a <malloc+0xa8>
        p->s.size -= nunits;
 8e6:	4137073b          	subw	a4,a4,s3
 8ea:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8ec:	02071693          	slli	a3,a4,0x20
 8f0:	01c6d713          	srli	a4,a3,0x1c
 8f4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8f6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8fa:	00000717          	auipc	a4,0x0
 8fe:	0ca73323          	sd	a0,198(a4) # 9c0 <freep>
      return (void*)(p + 1);
 902:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 906:	70e2                	ld	ra,56(sp)
 908:	7442                	ld	s0,48(sp)
 90a:	74a2                	ld	s1,40(sp)
 90c:	7902                	ld	s2,32(sp)
 90e:	69e2                	ld	s3,24(sp)
 910:	6a42                	ld	s4,16(sp)
 912:	6aa2                	ld	s5,8(sp)
 914:	6b02                	ld	s6,0(sp)
 916:	6121                	addi	sp,sp,64
 918:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 91a:	6398                	ld	a4,0(a5)
 91c:	e118                	sd	a4,0(a0)
 91e:	bff1                	j	8fa <malloc+0x88>
  hp->s.size = nu;
 920:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 924:	0541                	addi	a0,a0,16
 926:	00000097          	auipc	ra,0x0
 92a:	ec4080e7          	jalr	-316(ra) # 7ea <free>
  return freep;
 92e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 932:	d971                	beqz	a0,906 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 934:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 936:	4798                	lw	a4,8(a5)
 938:	fa9775e3          	bgeu	a4,s1,8e2 <malloc+0x70>
    if(p == freep)
 93c:	00093703          	ld	a4,0(s2)
 940:	853e                	mv	a0,a5
 942:	fef719e3          	bne	a4,a5,934 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 946:	8552                	mv	a0,s4
 948:	00000097          	auipc	ra,0x0
 94c:	b44080e7          	jalr	-1212(ra) # 48c <sbrk>
  if(p == (char*)-1)
 950:	fd5518e3          	bne	a0,s5,920 <malloc+0xae>
        return 0;
 954:	4501                	li	a0,0
 956:	bf45                	j	906 <malloc+0x94>
