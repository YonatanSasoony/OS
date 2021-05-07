
user/_test_thread:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <func>:
#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000
#define NTHREADS 2
int shared = 0;
void func()
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    sleep(1);
   8:	4505                	li	a0,1
   a:	00000097          	auipc	ra,0x0
   e:	3f6080e7          	jalr	1014(ra) # 400 <sleep>
    // printf("woke up\n");
    shared++;
  12:	00001717          	auipc	a4,0x1
  16:	91670713          	addi	a4,a4,-1770 # 928 <shared>
  1a:	431c                	lw	a5,0(a4)
  1c:	2785                	addiw	a5,a5,1
  1e:	c31c                	sw	a5,0(a4)
    // printf("!!!!!!!!!!!!!!!!!!!!!!1\n");
    kthread_exit(7);
  20:	451d                	li	a0,7
  22:	00000097          	auipc	ra,0x0
  26:	416080e7          	jalr	1046(ra) # 438 <kthread_exit>
}
  2a:	60a2                	ld	ra,8(sp)
  2c:	6402                	ld	s0,0(sp)
  2e:	0141                	addi	sp,sp,16
  30:	8082                	ret

0000000000000032 <main>:

int main(int argc, char *argv[])
{
  32:	7139                	addi	sp,sp,-64
  34:	fc06                	sd	ra,56(sp)
  36:	f822                	sd	s0,48(sp)
  38:	f426                	sd	s1,40(sp)
  3a:	f04a                	sd	s2,32(sp)
  3c:	ec4e                	sd	s3,24(sp)
  3e:	e852                	sd	s4,16(sp)
  40:	0080                	addi	s0,sp,64
    int tids[NTHREADS];
    void *stacks[NTHREADS];
    for (int i = 0; i < NTHREADS; i++)
    {
        void *stack = malloc(STACK_SIZE);
  42:	6485                	lui	s1,0x1
  44:	fa048513          	addi	a0,s1,-96 # fa0 <__BSS_END__+0x658>
  48:	00000097          	auipc	ra,0x0
  4c:	7b8080e7          	jalr	1976(ra) # 800 <malloc>
  50:	892a                	mv	s2,a0
        tids[i] = kthread_create(func, stack);
  52:	85aa                	mv	a1,a0
  54:	00000517          	auipc	a0,0x0
  58:	fac50513          	addi	a0,a0,-84 # 0 <func>
  5c:	00000097          	auipc	ra,0x0
  60:	3cc080e7          	jalr	972(ra) # 428 <kthread_create>
  64:	8a2a                	mv	s4,a0
        void *stack = malloc(STACK_SIZE);
  66:	fa048513          	addi	a0,s1,-96
  6a:	00000097          	auipc	ra,0x0
  6e:	796080e7          	jalr	1942(ra) # 800 <malloc>
  72:	84aa                	mv	s1,a0
        tids[i] = kthread_create(func, stack);
  74:	85aa                	mv	a1,a0
  76:	00000517          	auipc	a0,0x0
  7a:	f8a50513          	addi	a0,a0,-118 # 0 <func>
  7e:	00000097          	auipc	ra,0x0
  82:	3aa080e7          	jalr	938(ra) # 428 <kthread_create>
  86:	89aa                	mv	s3,a0
    }

    for (int i = 0; i < NTHREADS; i++)
    {
        int status;
        kthread_join(tids[i], &status);
  88:	fcc40593          	addi	a1,s0,-52
  8c:	8552                	mv	a0,s4
  8e:	00000097          	auipc	ra,0x0
  92:	3b2080e7          	jalr	946(ra) # 440 <kthread_join>
        free(stacks[i]);
  96:	854a                	mv	a0,s2
  98:	00000097          	auipc	ra,0x0
  9c:	6e0080e7          	jalr	1760(ra) # 778 <free>
        printf("the status is: %d\n", status);
  a0:	fcc42583          	lw	a1,-52(s0)
  a4:	00001517          	auipc	a0,0x1
  a8:	84450513          	addi	a0,a0,-1980 # 8e8 <malloc+0xe8>
  ac:	00000097          	auipc	ra,0x0
  b0:	696080e7          	jalr	1686(ra) # 742 <printf>
        kthread_join(tids[i], &status);
  b4:	fcc40593          	addi	a1,s0,-52
  b8:	854e                	mv	a0,s3
  ba:	00000097          	auipc	ra,0x0
  be:	386080e7          	jalr	902(ra) # 440 <kthread_join>
        free(stacks[i]);
  c2:	8526                	mv	a0,s1
  c4:	00000097          	auipc	ra,0x0
  c8:	6b4080e7          	jalr	1716(ra) # 778 <free>
        printf("the status is: %d\n", status);
  cc:	fcc42583          	lw	a1,-52(s0)
  d0:	00001517          	auipc	a0,0x1
  d4:	81850513          	addi	a0,a0,-2024 # 8e8 <malloc+0xe8>
  d8:	00000097          	auipc	ra,0x0
  dc:	66a080e7          	jalr	1642(ra) # 742 <printf>
    }
    printf("%d\n", shared);
  e0:	00001597          	auipc	a1,0x1
  e4:	8485a583          	lw	a1,-1976(a1) # 928 <shared>
  e8:	00001517          	auipc	a0,0x1
  ec:	81850513          	addi	a0,a0,-2024 # 900 <malloc+0x100>
  f0:	00000097          	auipc	ra,0x0
  f4:	652080e7          	jalr	1618(ra) # 742 <printf>
    exit(0);
  f8:	4501                	li	a0,0
  fa:	00000097          	auipc	ra,0x0
  fe:	276080e7          	jalr	630(ra) # 370 <exit>

0000000000000102 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 102:	1141                	addi	sp,sp,-16
 104:	e422                	sd	s0,8(sp)
 106:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 108:	87aa                	mv	a5,a0
 10a:	0585                	addi	a1,a1,1
 10c:	0785                	addi	a5,a5,1
 10e:	fff5c703          	lbu	a4,-1(a1)
 112:	fee78fa3          	sb	a4,-1(a5)
 116:	fb75                	bnez	a4,10a <strcpy+0x8>
    ;
  return os;
}
 118:	6422                	ld	s0,8(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret

000000000000011e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 11e:	1141                	addi	sp,sp,-16
 120:	e422                	sd	s0,8(sp)
 122:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 124:	00054783          	lbu	a5,0(a0)
 128:	cb91                	beqz	a5,13c <strcmp+0x1e>
 12a:	0005c703          	lbu	a4,0(a1)
 12e:	00f71763          	bne	a4,a5,13c <strcmp+0x1e>
    p++, q++;
 132:	0505                	addi	a0,a0,1
 134:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 136:	00054783          	lbu	a5,0(a0)
 13a:	fbe5                	bnez	a5,12a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 13c:	0005c503          	lbu	a0,0(a1)
}
 140:	40a7853b          	subw	a0,a5,a0
 144:	6422                	ld	s0,8(sp)
 146:	0141                	addi	sp,sp,16
 148:	8082                	ret

000000000000014a <strlen>:

uint
strlen(const char *s)
{
 14a:	1141                	addi	sp,sp,-16
 14c:	e422                	sd	s0,8(sp)
 14e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 150:	00054783          	lbu	a5,0(a0)
 154:	cf91                	beqz	a5,170 <strlen+0x26>
 156:	0505                	addi	a0,a0,1
 158:	87aa                	mv	a5,a0
 15a:	4685                	li	a3,1
 15c:	9e89                	subw	a3,a3,a0
 15e:	00f6853b          	addw	a0,a3,a5
 162:	0785                	addi	a5,a5,1
 164:	fff7c703          	lbu	a4,-1(a5)
 168:	fb7d                	bnez	a4,15e <strlen+0x14>
    ;
  return n;
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret
  for(n = 0; s[n]; n++)
 170:	4501                	li	a0,0
 172:	bfe5                	j	16a <strlen+0x20>

0000000000000174 <memset>:

void*
memset(void *dst, int c, uint n)
{
 174:	1141                	addi	sp,sp,-16
 176:	e422                	sd	s0,8(sp)
 178:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 17a:	ca19                	beqz	a2,190 <memset+0x1c>
 17c:	87aa                	mv	a5,a0
 17e:	1602                	slli	a2,a2,0x20
 180:	9201                	srli	a2,a2,0x20
 182:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 186:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 18a:	0785                	addi	a5,a5,1
 18c:	fee79de3          	bne	a5,a4,186 <memset+0x12>
  }
  return dst;
}
 190:	6422                	ld	s0,8(sp)
 192:	0141                	addi	sp,sp,16
 194:	8082                	ret

0000000000000196 <strchr>:

char*
strchr(const char *s, char c)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 19c:	00054783          	lbu	a5,0(a0)
 1a0:	cb99                	beqz	a5,1b6 <strchr+0x20>
    if(*s == c)
 1a2:	00f58763          	beq	a1,a5,1b0 <strchr+0x1a>
  for(; *s; s++)
 1a6:	0505                	addi	a0,a0,1
 1a8:	00054783          	lbu	a5,0(a0)
 1ac:	fbfd                	bnez	a5,1a2 <strchr+0xc>
      return (char*)s;
  return 0;
 1ae:	4501                	li	a0,0
}
 1b0:	6422                	ld	s0,8(sp)
 1b2:	0141                	addi	sp,sp,16
 1b4:	8082                	ret
  return 0;
 1b6:	4501                	li	a0,0
 1b8:	bfe5                	j	1b0 <strchr+0x1a>

00000000000001ba <gets>:

char*
gets(char *buf, int max)
{
 1ba:	711d                	addi	sp,sp,-96
 1bc:	ec86                	sd	ra,88(sp)
 1be:	e8a2                	sd	s0,80(sp)
 1c0:	e4a6                	sd	s1,72(sp)
 1c2:	e0ca                	sd	s2,64(sp)
 1c4:	fc4e                	sd	s3,56(sp)
 1c6:	f852                	sd	s4,48(sp)
 1c8:	f456                	sd	s5,40(sp)
 1ca:	f05a                	sd	s6,32(sp)
 1cc:	ec5e                	sd	s7,24(sp)
 1ce:	1080                	addi	s0,sp,96
 1d0:	8baa                	mv	s7,a0
 1d2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1d4:	892a                	mv	s2,a0
 1d6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d8:	4aa9                	li	s5,10
 1da:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1dc:	89a6                	mv	s3,s1
 1de:	2485                	addiw	s1,s1,1
 1e0:	0344d863          	bge	s1,s4,210 <gets+0x56>
    cc = read(0, &c, 1);
 1e4:	4605                	li	a2,1
 1e6:	faf40593          	addi	a1,s0,-81
 1ea:	4501                	li	a0,0
 1ec:	00000097          	auipc	ra,0x0
 1f0:	19c080e7          	jalr	412(ra) # 388 <read>
    if(cc < 1)
 1f4:	00a05e63          	blez	a0,210 <gets+0x56>
    buf[i++] = c;
 1f8:	faf44783          	lbu	a5,-81(s0)
 1fc:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 200:	01578763          	beq	a5,s5,20e <gets+0x54>
 204:	0905                	addi	s2,s2,1
 206:	fd679be3          	bne	a5,s6,1dc <gets+0x22>
  for(i=0; i+1 < max; ){
 20a:	89a6                	mv	s3,s1
 20c:	a011                	j	210 <gets+0x56>
 20e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 210:	99de                	add	s3,s3,s7
 212:	00098023          	sb	zero,0(s3)
  return buf;
}
 216:	855e                	mv	a0,s7
 218:	60e6                	ld	ra,88(sp)
 21a:	6446                	ld	s0,80(sp)
 21c:	64a6                	ld	s1,72(sp)
 21e:	6906                	ld	s2,64(sp)
 220:	79e2                	ld	s3,56(sp)
 222:	7a42                	ld	s4,48(sp)
 224:	7aa2                	ld	s5,40(sp)
 226:	7b02                	ld	s6,32(sp)
 228:	6be2                	ld	s7,24(sp)
 22a:	6125                	addi	sp,sp,96
 22c:	8082                	ret

000000000000022e <stat>:

int
stat(const char *n, struct stat *st)
{
 22e:	1101                	addi	sp,sp,-32
 230:	ec06                	sd	ra,24(sp)
 232:	e822                	sd	s0,16(sp)
 234:	e426                	sd	s1,8(sp)
 236:	e04a                	sd	s2,0(sp)
 238:	1000                	addi	s0,sp,32
 23a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 23c:	4581                	li	a1,0
 23e:	00000097          	auipc	ra,0x0
 242:	172080e7          	jalr	370(ra) # 3b0 <open>
  if(fd < 0)
 246:	02054563          	bltz	a0,270 <stat+0x42>
 24a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 24c:	85ca                	mv	a1,s2
 24e:	00000097          	auipc	ra,0x0
 252:	17a080e7          	jalr	378(ra) # 3c8 <fstat>
 256:	892a                	mv	s2,a0
  close(fd);
 258:	8526                	mv	a0,s1
 25a:	00000097          	auipc	ra,0x0
 25e:	13e080e7          	jalr	318(ra) # 398 <close>
  return r;
}
 262:	854a                	mv	a0,s2
 264:	60e2                	ld	ra,24(sp)
 266:	6442                	ld	s0,16(sp)
 268:	64a2                	ld	s1,8(sp)
 26a:	6902                	ld	s2,0(sp)
 26c:	6105                	addi	sp,sp,32
 26e:	8082                	ret
    return -1;
 270:	597d                	li	s2,-1
 272:	bfc5                	j	262 <stat+0x34>

0000000000000274 <atoi>:

int
atoi(const char *s)
{
 274:	1141                	addi	sp,sp,-16
 276:	e422                	sd	s0,8(sp)
 278:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 27a:	00054603          	lbu	a2,0(a0)
 27e:	fd06079b          	addiw	a5,a2,-48
 282:	0ff7f793          	andi	a5,a5,255
 286:	4725                	li	a4,9
 288:	02f76963          	bltu	a4,a5,2ba <atoi+0x46>
 28c:	86aa                	mv	a3,a0
  n = 0;
 28e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 290:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 292:	0685                	addi	a3,a3,1
 294:	0025179b          	slliw	a5,a0,0x2
 298:	9fa9                	addw	a5,a5,a0
 29a:	0017979b          	slliw	a5,a5,0x1
 29e:	9fb1                	addw	a5,a5,a2
 2a0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2a4:	0006c603          	lbu	a2,0(a3)
 2a8:	fd06071b          	addiw	a4,a2,-48
 2ac:	0ff77713          	andi	a4,a4,255
 2b0:	fee5f1e3          	bgeu	a1,a4,292 <atoi+0x1e>
  return n;
}
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret
  n = 0;
 2ba:	4501                	li	a0,0
 2bc:	bfe5                	j	2b4 <atoi+0x40>

00000000000002be <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2be:	1141                	addi	sp,sp,-16
 2c0:	e422                	sd	s0,8(sp)
 2c2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2c4:	02b57463          	bgeu	a0,a1,2ec <memmove+0x2e>
    while(n-- > 0)
 2c8:	00c05f63          	blez	a2,2e6 <memmove+0x28>
 2cc:	1602                	slli	a2,a2,0x20
 2ce:	9201                	srli	a2,a2,0x20
 2d0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2d4:	872a                	mv	a4,a0
      *dst++ = *src++;
 2d6:	0585                	addi	a1,a1,1
 2d8:	0705                	addi	a4,a4,1
 2da:	fff5c683          	lbu	a3,-1(a1)
 2de:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2e2:	fee79ae3          	bne	a5,a4,2d6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret
    dst += n;
 2ec:	00c50733          	add	a4,a0,a2
    src += n;
 2f0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2f2:	fec05ae3          	blez	a2,2e6 <memmove+0x28>
 2f6:	fff6079b          	addiw	a5,a2,-1
 2fa:	1782                	slli	a5,a5,0x20
 2fc:	9381                	srli	a5,a5,0x20
 2fe:	fff7c793          	not	a5,a5
 302:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 304:	15fd                	addi	a1,a1,-1
 306:	177d                	addi	a4,a4,-1
 308:	0005c683          	lbu	a3,0(a1)
 30c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 310:	fee79ae3          	bne	a5,a4,304 <memmove+0x46>
 314:	bfc9                	j	2e6 <memmove+0x28>

0000000000000316 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 31c:	ca05                	beqz	a2,34c <memcmp+0x36>
 31e:	fff6069b          	addiw	a3,a2,-1
 322:	1682                	slli	a3,a3,0x20
 324:	9281                	srli	a3,a3,0x20
 326:	0685                	addi	a3,a3,1
 328:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 32a:	00054783          	lbu	a5,0(a0)
 32e:	0005c703          	lbu	a4,0(a1)
 332:	00e79863          	bne	a5,a4,342 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 336:	0505                	addi	a0,a0,1
    p2++;
 338:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 33a:	fed518e3          	bne	a0,a3,32a <memcmp+0x14>
  }
  return 0;
 33e:	4501                	li	a0,0
 340:	a019                	j	346 <memcmp+0x30>
      return *p1 - *p2;
 342:	40e7853b          	subw	a0,a5,a4
}
 346:	6422                	ld	s0,8(sp)
 348:	0141                	addi	sp,sp,16
 34a:	8082                	ret
  return 0;
 34c:	4501                	li	a0,0
 34e:	bfe5                	j	346 <memcmp+0x30>

0000000000000350 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 350:	1141                	addi	sp,sp,-16
 352:	e406                	sd	ra,8(sp)
 354:	e022                	sd	s0,0(sp)
 356:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 358:	00000097          	auipc	ra,0x0
 35c:	f66080e7          	jalr	-154(ra) # 2be <memmove>
}
 360:	60a2                	ld	ra,8(sp)
 362:	6402                	ld	s0,0(sp)
 364:	0141                	addi	sp,sp,16
 366:	8082                	ret

0000000000000368 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 368:	4885                	li	a7,1
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <exit>:
.global exit
exit:
 li a7, SYS_exit
 370:	4889                	li	a7,2
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <wait>:
.global wait
wait:
 li a7, SYS_wait
 378:	488d                	li	a7,3
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 380:	4891                	li	a7,4
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <read>:
.global read
read:
 li a7, SYS_read
 388:	4895                	li	a7,5
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <write>:
.global write
write:
 li a7, SYS_write
 390:	48c1                	li	a7,16
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <close>:
.global close
close:
 li a7, SYS_close
 398:	48d5                	li	a7,21
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3a0:	4899                	li	a7,6
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a8:	489d                	li	a7,7
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <open>:
.global open
open:
 li a7, SYS_open
 3b0:	48bd                	li	a7,15
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b8:	48c5                	li	a7,17
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3c0:	48c9                	li	a7,18
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c8:	48a1                	li	a7,8
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <link>:
.global link
link:
 li a7, SYS_link
 3d0:	48cd                	li	a7,19
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d8:	48d1                	li	a7,20
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3e0:	48a5                	li	a7,9
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e8:	48a9                	li	a7,10
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3f0:	48ad                	li	a7,11
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f8:	48b1                	li	a7,12
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 400:	48b5                	li	a7,13
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 408:	48b9                	li	a7,14
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 410:	48d9                	li	a7,22
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 418:	48dd                	li	a7,23
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 420:	48e1                	li	a7,24
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 428:	48e5                	li	a7,25
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 430:	48e9                	li	a7,26
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 438:	48ed                	li	a7,27
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 440:	48f1                	li	a7,28
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <bsem_alloc>:
.global bsem_alloc
bsem_alloc:
 li a7, SYS_bsem_alloc
 448:	48f5                	li	a7,29
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <bsem_free>:
.global bsem_free
bsem_free:
 li a7, SYS_bsem_free
 450:	48f9                	li	a7,30
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <bsem_down>:
.global bsem_down
bsem_down:
 li a7, SYS_bsem_down
 458:	48fd                	li	a7,31
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <bsem_up>:
.global bsem_up
bsem_up:
 li a7, SYS_bsem_up
 460:	02000893          	li	a7,32
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 46a:	1101                	addi	sp,sp,-32
 46c:	ec06                	sd	ra,24(sp)
 46e:	e822                	sd	s0,16(sp)
 470:	1000                	addi	s0,sp,32
 472:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 476:	4605                	li	a2,1
 478:	fef40593          	addi	a1,s0,-17
 47c:	00000097          	auipc	ra,0x0
 480:	f14080e7          	jalr	-236(ra) # 390 <write>
}
 484:	60e2                	ld	ra,24(sp)
 486:	6442                	ld	s0,16(sp)
 488:	6105                	addi	sp,sp,32
 48a:	8082                	ret

000000000000048c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 48c:	7139                	addi	sp,sp,-64
 48e:	fc06                	sd	ra,56(sp)
 490:	f822                	sd	s0,48(sp)
 492:	f426                	sd	s1,40(sp)
 494:	f04a                	sd	s2,32(sp)
 496:	ec4e                	sd	s3,24(sp)
 498:	0080                	addi	s0,sp,64
 49a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 49c:	c299                	beqz	a3,4a2 <printint+0x16>
 49e:	0805c863          	bltz	a1,52e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4a2:	2581                	sext.w	a1,a1
  neg = 0;
 4a4:	4881                	li	a7,0
 4a6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4aa:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4ac:	2601                	sext.w	a2,a2
 4ae:	00000517          	auipc	a0,0x0
 4b2:	46250513          	addi	a0,a0,1122 # 910 <digits>
 4b6:	883a                	mv	a6,a4
 4b8:	2705                	addiw	a4,a4,1
 4ba:	02c5f7bb          	remuw	a5,a1,a2
 4be:	1782                	slli	a5,a5,0x20
 4c0:	9381                	srli	a5,a5,0x20
 4c2:	97aa                	add	a5,a5,a0
 4c4:	0007c783          	lbu	a5,0(a5)
 4c8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4cc:	0005879b          	sext.w	a5,a1
 4d0:	02c5d5bb          	divuw	a1,a1,a2
 4d4:	0685                	addi	a3,a3,1
 4d6:	fec7f0e3          	bgeu	a5,a2,4b6 <printint+0x2a>
  if(neg)
 4da:	00088b63          	beqz	a7,4f0 <printint+0x64>
    buf[i++] = '-';
 4de:	fd040793          	addi	a5,s0,-48
 4e2:	973e                	add	a4,a4,a5
 4e4:	02d00793          	li	a5,45
 4e8:	fef70823          	sb	a5,-16(a4)
 4ec:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4f0:	02e05863          	blez	a4,520 <printint+0x94>
 4f4:	fc040793          	addi	a5,s0,-64
 4f8:	00e78933          	add	s2,a5,a4
 4fc:	fff78993          	addi	s3,a5,-1
 500:	99ba                	add	s3,s3,a4
 502:	377d                	addiw	a4,a4,-1
 504:	1702                	slli	a4,a4,0x20
 506:	9301                	srli	a4,a4,0x20
 508:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 50c:	fff94583          	lbu	a1,-1(s2)
 510:	8526                	mv	a0,s1
 512:	00000097          	auipc	ra,0x0
 516:	f58080e7          	jalr	-168(ra) # 46a <putc>
  while(--i >= 0)
 51a:	197d                	addi	s2,s2,-1
 51c:	ff3918e3          	bne	s2,s3,50c <printint+0x80>
}
 520:	70e2                	ld	ra,56(sp)
 522:	7442                	ld	s0,48(sp)
 524:	74a2                	ld	s1,40(sp)
 526:	7902                	ld	s2,32(sp)
 528:	69e2                	ld	s3,24(sp)
 52a:	6121                	addi	sp,sp,64
 52c:	8082                	ret
    x = -xx;
 52e:	40b005bb          	negw	a1,a1
    neg = 1;
 532:	4885                	li	a7,1
    x = -xx;
 534:	bf8d                	j	4a6 <printint+0x1a>

0000000000000536 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 536:	7119                	addi	sp,sp,-128
 538:	fc86                	sd	ra,120(sp)
 53a:	f8a2                	sd	s0,112(sp)
 53c:	f4a6                	sd	s1,104(sp)
 53e:	f0ca                	sd	s2,96(sp)
 540:	ecce                	sd	s3,88(sp)
 542:	e8d2                	sd	s4,80(sp)
 544:	e4d6                	sd	s5,72(sp)
 546:	e0da                	sd	s6,64(sp)
 548:	fc5e                	sd	s7,56(sp)
 54a:	f862                	sd	s8,48(sp)
 54c:	f466                	sd	s9,40(sp)
 54e:	f06a                	sd	s10,32(sp)
 550:	ec6e                	sd	s11,24(sp)
 552:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 554:	0005c903          	lbu	s2,0(a1)
 558:	18090f63          	beqz	s2,6f6 <vprintf+0x1c0>
 55c:	8aaa                	mv	s5,a0
 55e:	8b32                	mv	s6,a2
 560:	00158493          	addi	s1,a1,1
  state = 0;
 564:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 566:	02500a13          	li	s4,37
      if(c == 'd'){
 56a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 56e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 572:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 576:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 57a:	00000b97          	auipc	s7,0x0
 57e:	396b8b93          	addi	s7,s7,918 # 910 <digits>
 582:	a839                	j	5a0 <vprintf+0x6a>
        putc(fd, c);
 584:	85ca                	mv	a1,s2
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	ee2080e7          	jalr	-286(ra) # 46a <putc>
 590:	a019                	j	596 <vprintf+0x60>
    } else if(state == '%'){
 592:	01498f63          	beq	s3,s4,5b0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 596:	0485                	addi	s1,s1,1
 598:	fff4c903          	lbu	s2,-1(s1)
 59c:	14090d63          	beqz	s2,6f6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5a0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5a4:	fe0997e3          	bnez	s3,592 <vprintf+0x5c>
      if(c == '%'){
 5a8:	fd479ee3          	bne	a5,s4,584 <vprintf+0x4e>
        state = '%';
 5ac:	89be                	mv	s3,a5
 5ae:	b7e5                	j	596 <vprintf+0x60>
      if(c == 'd'){
 5b0:	05878063          	beq	a5,s8,5f0 <vprintf+0xba>
      } else if(c == 'l') {
 5b4:	05978c63          	beq	a5,s9,60c <vprintf+0xd6>
      } else if(c == 'x') {
 5b8:	07a78863          	beq	a5,s10,628 <vprintf+0xf2>
      } else if(c == 'p') {
 5bc:	09b78463          	beq	a5,s11,644 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5c0:	07300713          	li	a4,115
 5c4:	0ce78663          	beq	a5,a4,690 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5c8:	06300713          	li	a4,99
 5cc:	0ee78e63          	beq	a5,a4,6c8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5d0:	11478863          	beq	a5,s4,6e0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5d4:	85d2                	mv	a1,s4
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	e92080e7          	jalr	-366(ra) # 46a <putc>
        putc(fd, c);
 5e0:	85ca                	mv	a1,s2
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	e86080e7          	jalr	-378(ra) # 46a <putc>
      }
      state = 0;
 5ec:	4981                	li	s3,0
 5ee:	b765                	j	596 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5f0:	008b0913          	addi	s2,s6,8
 5f4:	4685                	li	a3,1
 5f6:	4629                	li	a2,10
 5f8:	000b2583          	lw	a1,0(s6)
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	e8e080e7          	jalr	-370(ra) # 48c <printint>
 606:	8b4a                	mv	s6,s2
      state = 0;
 608:	4981                	li	s3,0
 60a:	b771                	j	596 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 60c:	008b0913          	addi	s2,s6,8
 610:	4681                	li	a3,0
 612:	4629                	li	a2,10
 614:	000b2583          	lw	a1,0(s6)
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	e72080e7          	jalr	-398(ra) # 48c <printint>
 622:	8b4a                	mv	s6,s2
      state = 0;
 624:	4981                	li	s3,0
 626:	bf85                	j	596 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 628:	008b0913          	addi	s2,s6,8
 62c:	4681                	li	a3,0
 62e:	4641                	li	a2,16
 630:	000b2583          	lw	a1,0(s6)
 634:	8556                	mv	a0,s5
 636:	00000097          	auipc	ra,0x0
 63a:	e56080e7          	jalr	-426(ra) # 48c <printint>
 63e:	8b4a                	mv	s6,s2
      state = 0;
 640:	4981                	li	s3,0
 642:	bf91                	j	596 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 644:	008b0793          	addi	a5,s6,8
 648:	f8f43423          	sd	a5,-120(s0)
 64c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 650:	03000593          	li	a1,48
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	e14080e7          	jalr	-492(ra) # 46a <putc>
  putc(fd, 'x');
 65e:	85ea                	mv	a1,s10
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	e08080e7          	jalr	-504(ra) # 46a <putc>
 66a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 66c:	03c9d793          	srli	a5,s3,0x3c
 670:	97de                	add	a5,a5,s7
 672:	0007c583          	lbu	a1,0(a5)
 676:	8556                	mv	a0,s5
 678:	00000097          	auipc	ra,0x0
 67c:	df2080e7          	jalr	-526(ra) # 46a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 680:	0992                	slli	s3,s3,0x4
 682:	397d                	addiw	s2,s2,-1
 684:	fe0914e3          	bnez	s2,66c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 688:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 68c:	4981                	li	s3,0
 68e:	b721                	j	596 <vprintf+0x60>
        s = va_arg(ap, char*);
 690:	008b0993          	addi	s3,s6,8
 694:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 698:	02090163          	beqz	s2,6ba <vprintf+0x184>
        while(*s != 0){
 69c:	00094583          	lbu	a1,0(s2)
 6a0:	c9a1                	beqz	a1,6f0 <vprintf+0x1ba>
          putc(fd, *s);
 6a2:	8556                	mv	a0,s5
 6a4:	00000097          	auipc	ra,0x0
 6a8:	dc6080e7          	jalr	-570(ra) # 46a <putc>
          s++;
 6ac:	0905                	addi	s2,s2,1
        while(*s != 0){
 6ae:	00094583          	lbu	a1,0(s2)
 6b2:	f9e5                	bnez	a1,6a2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6b4:	8b4e                	mv	s6,s3
      state = 0;
 6b6:	4981                	li	s3,0
 6b8:	bdf9                	j	596 <vprintf+0x60>
          s = "(null)";
 6ba:	00000917          	auipc	s2,0x0
 6be:	24e90913          	addi	s2,s2,590 # 908 <malloc+0x108>
        while(*s != 0){
 6c2:	02800593          	li	a1,40
 6c6:	bff1                	j	6a2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6c8:	008b0913          	addi	s2,s6,8
 6cc:	000b4583          	lbu	a1,0(s6)
 6d0:	8556                	mv	a0,s5
 6d2:	00000097          	auipc	ra,0x0
 6d6:	d98080e7          	jalr	-616(ra) # 46a <putc>
 6da:	8b4a                	mv	s6,s2
      state = 0;
 6dc:	4981                	li	s3,0
 6de:	bd65                	j	596 <vprintf+0x60>
        putc(fd, c);
 6e0:	85d2                	mv	a1,s4
 6e2:	8556                	mv	a0,s5
 6e4:	00000097          	auipc	ra,0x0
 6e8:	d86080e7          	jalr	-634(ra) # 46a <putc>
      state = 0;
 6ec:	4981                	li	s3,0
 6ee:	b565                	j	596 <vprintf+0x60>
        s = va_arg(ap, char*);
 6f0:	8b4e                	mv	s6,s3
      state = 0;
 6f2:	4981                	li	s3,0
 6f4:	b54d                	j	596 <vprintf+0x60>
    }
  }
}
 6f6:	70e6                	ld	ra,120(sp)
 6f8:	7446                	ld	s0,112(sp)
 6fa:	74a6                	ld	s1,104(sp)
 6fc:	7906                	ld	s2,96(sp)
 6fe:	69e6                	ld	s3,88(sp)
 700:	6a46                	ld	s4,80(sp)
 702:	6aa6                	ld	s5,72(sp)
 704:	6b06                	ld	s6,64(sp)
 706:	7be2                	ld	s7,56(sp)
 708:	7c42                	ld	s8,48(sp)
 70a:	7ca2                	ld	s9,40(sp)
 70c:	7d02                	ld	s10,32(sp)
 70e:	6de2                	ld	s11,24(sp)
 710:	6109                	addi	sp,sp,128
 712:	8082                	ret

0000000000000714 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 714:	715d                	addi	sp,sp,-80
 716:	ec06                	sd	ra,24(sp)
 718:	e822                	sd	s0,16(sp)
 71a:	1000                	addi	s0,sp,32
 71c:	e010                	sd	a2,0(s0)
 71e:	e414                	sd	a3,8(s0)
 720:	e818                	sd	a4,16(s0)
 722:	ec1c                	sd	a5,24(s0)
 724:	03043023          	sd	a6,32(s0)
 728:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 72c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 730:	8622                	mv	a2,s0
 732:	00000097          	auipc	ra,0x0
 736:	e04080e7          	jalr	-508(ra) # 536 <vprintf>
}
 73a:	60e2                	ld	ra,24(sp)
 73c:	6442                	ld	s0,16(sp)
 73e:	6161                	addi	sp,sp,80
 740:	8082                	ret

0000000000000742 <printf>:

void
printf(const char *fmt, ...)
{
 742:	711d                	addi	sp,sp,-96
 744:	ec06                	sd	ra,24(sp)
 746:	e822                	sd	s0,16(sp)
 748:	1000                	addi	s0,sp,32
 74a:	e40c                	sd	a1,8(s0)
 74c:	e810                	sd	a2,16(s0)
 74e:	ec14                	sd	a3,24(s0)
 750:	f018                	sd	a4,32(s0)
 752:	f41c                	sd	a5,40(s0)
 754:	03043823          	sd	a6,48(s0)
 758:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 75c:	00840613          	addi	a2,s0,8
 760:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 764:	85aa                	mv	a1,a0
 766:	4505                	li	a0,1
 768:	00000097          	auipc	ra,0x0
 76c:	dce080e7          	jalr	-562(ra) # 536 <vprintf>
}
 770:	60e2                	ld	ra,24(sp)
 772:	6442                	ld	s0,16(sp)
 774:	6125                	addi	sp,sp,96
 776:	8082                	ret

0000000000000778 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 778:	1141                	addi	sp,sp,-16
 77a:	e422                	sd	s0,8(sp)
 77c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 77e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 782:	00000797          	auipc	a5,0x0
 786:	1ae7b783          	ld	a5,430(a5) # 930 <freep>
 78a:	a805                	j	7ba <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 78c:	4618                	lw	a4,8(a2)
 78e:	9db9                	addw	a1,a1,a4
 790:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 794:	6398                	ld	a4,0(a5)
 796:	6318                	ld	a4,0(a4)
 798:	fee53823          	sd	a4,-16(a0)
 79c:	a091                	j	7e0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 79e:	ff852703          	lw	a4,-8(a0)
 7a2:	9e39                	addw	a2,a2,a4
 7a4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7a6:	ff053703          	ld	a4,-16(a0)
 7aa:	e398                	sd	a4,0(a5)
 7ac:	a099                	j	7f2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ae:	6398                	ld	a4,0(a5)
 7b0:	00e7e463          	bltu	a5,a4,7b8 <free+0x40>
 7b4:	00e6ea63          	bltu	a3,a4,7c8 <free+0x50>
{
 7b8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ba:	fed7fae3          	bgeu	a5,a3,7ae <free+0x36>
 7be:	6398                	ld	a4,0(a5)
 7c0:	00e6e463          	bltu	a3,a4,7c8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c4:	fee7eae3          	bltu	a5,a4,7b8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7c8:	ff852583          	lw	a1,-8(a0)
 7cc:	6390                	ld	a2,0(a5)
 7ce:	02059813          	slli	a6,a1,0x20
 7d2:	01c85713          	srli	a4,a6,0x1c
 7d6:	9736                	add	a4,a4,a3
 7d8:	fae60ae3          	beq	a2,a4,78c <free+0x14>
    bp->s.ptr = p->s.ptr;
 7dc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7e0:	4790                	lw	a2,8(a5)
 7e2:	02061593          	slli	a1,a2,0x20
 7e6:	01c5d713          	srli	a4,a1,0x1c
 7ea:	973e                	add	a4,a4,a5
 7ec:	fae689e3          	beq	a3,a4,79e <free+0x26>
  } else
    p->s.ptr = bp;
 7f0:	e394                	sd	a3,0(a5)
  freep = p;
 7f2:	00000717          	auipc	a4,0x0
 7f6:	12f73f23          	sd	a5,318(a4) # 930 <freep>
}
 7fa:	6422                	ld	s0,8(sp)
 7fc:	0141                	addi	sp,sp,16
 7fe:	8082                	ret

0000000000000800 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 800:	7139                	addi	sp,sp,-64
 802:	fc06                	sd	ra,56(sp)
 804:	f822                	sd	s0,48(sp)
 806:	f426                	sd	s1,40(sp)
 808:	f04a                	sd	s2,32(sp)
 80a:	ec4e                	sd	s3,24(sp)
 80c:	e852                	sd	s4,16(sp)
 80e:	e456                	sd	s5,8(sp)
 810:	e05a                	sd	s6,0(sp)
 812:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 814:	02051493          	slli	s1,a0,0x20
 818:	9081                	srli	s1,s1,0x20
 81a:	04bd                	addi	s1,s1,15
 81c:	8091                	srli	s1,s1,0x4
 81e:	0014899b          	addiw	s3,s1,1
 822:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 824:	00000517          	auipc	a0,0x0
 828:	10c53503          	ld	a0,268(a0) # 930 <freep>
 82c:	c515                	beqz	a0,858 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 830:	4798                	lw	a4,8(a5)
 832:	02977f63          	bgeu	a4,s1,870 <malloc+0x70>
 836:	8a4e                	mv	s4,s3
 838:	0009871b          	sext.w	a4,s3
 83c:	6685                	lui	a3,0x1
 83e:	00d77363          	bgeu	a4,a3,844 <malloc+0x44>
 842:	6a05                	lui	s4,0x1
 844:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 848:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 84c:	00000917          	auipc	s2,0x0
 850:	0e490913          	addi	s2,s2,228 # 930 <freep>
  if(p == (char*)-1)
 854:	5afd                	li	s5,-1
 856:	a895                	j	8ca <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 858:	00000797          	auipc	a5,0x0
 85c:	0e078793          	addi	a5,a5,224 # 938 <base>
 860:	00000717          	auipc	a4,0x0
 864:	0cf73823          	sd	a5,208(a4) # 930 <freep>
 868:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 86a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 86e:	b7e1                	j	836 <malloc+0x36>
      if(p->s.size == nunits)
 870:	02e48c63          	beq	s1,a4,8a8 <malloc+0xa8>
        p->s.size -= nunits;
 874:	4137073b          	subw	a4,a4,s3
 878:	c798                	sw	a4,8(a5)
        p += p->s.size;
 87a:	02071693          	slli	a3,a4,0x20
 87e:	01c6d713          	srli	a4,a3,0x1c
 882:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 884:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 888:	00000717          	auipc	a4,0x0
 88c:	0aa73423          	sd	a0,168(a4) # 930 <freep>
      return (void*)(p + 1);
 890:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 894:	70e2                	ld	ra,56(sp)
 896:	7442                	ld	s0,48(sp)
 898:	74a2                	ld	s1,40(sp)
 89a:	7902                	ld	s2,32(sp)
 89c:	69e2                	ld	s3,24(sp)
 89e:	6a42                	ld	s4,16(sp)
 8a0:	6aa2                	ld	s5,8(sp)
 8a2:	6b02                	ld	s6,0(sp)
 8a4:	6121                	addi	sp,sp,64
 8a6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8a8:	6398                	ld	a4,0(a5)
 8aa:	e118                	sd	a4,0(a0)
 8ac:	bff1                	j	888 <malloc+0x88>
  hp->s.size = nu;
 8ae:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8b2:	0541                	addi	a0,a0,16
 8b4:	00000097          	auipc	ra,0x0
 8b8:	ec4080e7          	jalr	-316(ra) # 778 <free>
  return freep;
 8bc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8c0:	d971                	beqz	a0,894 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8c2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8c4:	4798                	lw	a4,8(a5)
 8c6:	fa9775e3          	bgeu	a4,s1,870 <malloc+0x70>
    if(p == freep)
 8ca:	00093703          	ld	a4,0(s2)
 8ce:	853e                	mv	a0,a5
 8d0:	fef719e3          	bne	a4,a5,8c2 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 8d4:	8552                	mv	a0,s4
 8d6:	00000097          	auipc	ra,0x0
 8da:	b22080e7          	jalr	-1246(ra) # 3f8 <sbrk>
  if(p == (char*)-1)
 8de:	fd5518e3          	bne	a0,s5,8ae <malloc+0xae>
        return 0;
 8e2:	4501                	li	a0,0
 8e4:	bf45                	j	894 <malloc+0x94>
