
user/_test_thread:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <func_for_compiler>:
#include "user/user.h"

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000

void func_for_compiler() {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    print("bla")
   8:	00001597          	auipc	a1,0x1
   c:	8c858593          	addi	a1,a1,-1848 # 8d0 <malloc+0xe6>
  10:	00001517          	auipc	a0,0x1
  14:	8c850513          	addi	a0,a0,-1848 # 8d8 <malloc+0xee>
  18:	00000097          	auipc	ra,0x0
  1c:	714080e7          	jalr	1812(ra) # 72c <printf>
}
  20:	60a2                	ld	ra,8(sp)
  22:	6402                	ld	s0,0(sp)
  24:	0141                	addi	sp,sp,16
  26:	8082                	ret

0000000000000028 <func>:

void func() {
  28:	1101                	addi	sp,sp,-32
  2a:	ec06                	sd	ra,24(sp)
  2c:	e822                	sd	s0,16(sp)
  2e:	e426                	sd	s1,8(sp)
  30:	1000                	addi	s0,sp,32
    int tid = kthread_id();
  32:	00000097          	auipc	ra,0x0
  36:	40a080e7          	jalr	1034(ra) # 43c <kthread_id>
  3a:	84aa                	mv	s1,a0
    printf("thread %d start\n", tid);
  3c:	85aa                	mv	a1,a0
  3e:	00001517          	auipc	a0,0x1
  42:	8a250513          	addi	a0,a0,-1886 # 8e0 <malloc+0xf6>
  46:	00000097          	auipc	ra,0x0
  4a:	6e6080e7          	jalr	1766(ra) # 72c <printf>
    sleep(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	3bc080e7          	jalr	956(ra) # 40c <sleep>
    printf("thread %d end\n", tid);
  58:	85a6                	mv	a1,s1
  5a:	00001517          	auipc	a0,0x1
  5e:	89e50513          	addi	a0,a0,-1890 # 8f8 <malloc+0x10e>
  62:	00000097          	auipc	ra,0x0
  66:	6ca080e7          	jalr	1738(ra) # 72c <printf>
    kthread_exit(tid);
  6a:	8526                	mv	a0,s1
  6c:	00000097          	auipc	ra,0x0
  70:	3d8080e7          	jalr	984(ra) # 444 <kthread_exit>
}
  74:	60e2                	ld	ra,24(sp)
  76:	6442                	ld	s0,16(sp)
  78:	64a2                	ld	s1,8(sp)
  7a:	6105                	addi	sp,sp,32
  7c:	8082                	ret

000000000000007e <main>:

int main(int argc, char *argv[])
{
  7e:	7179                	addi	sp,sp,-48
  80:	f406                	sd	ra,40(sp)
  82:	f022                	sd	s0,32(sp)
  84:	ec26                	sd	s1,24(sp)
  86:	e84a                	sd	s2,16(sp)
  88:	e44e                	sd	s3,8(sp)
  8a:	1800                	addi	s0,sp,48
    void* stack;

    printf("HELLO TEST THREAD\n");
  8c:	00001517          	auipc	a0,0x1
  90:	87c50513          	addi	a0,a0,-1924 # 908 <malloc+0x11e>
  94:	00000097          	auipc	ra,0x0
  98:	698080e7          	jalr	1688(ra) # 72c <printf>
    printf("address of func: %p\n", func);
  9c:	00000597          	auipc	a1,0x0
  a0:	f8c58593          	addi	a1,a1,-116 # 28 <func>
  a4:	00001517          	auipc	a0,0x1
  a8:	87c50513          	addi	a0,a0,-1924 # 920 <malloc+0x136>
  ac:	00000097          	auipc	ra,0x0
  b0:	680080e7          	jalr	1664(ra) # 72c <printf>
    printf("address of func_for_compiler: %p\n", func_for_compiler);
  b4:	00000597          	auipc	a1,0x0
  b8:	f4c58593          	addi	a1,a1,-180 # 0 <func_for_compiler>
  bc:	00001517          	auipc	a0,0x1
  c0:	87c50513          	addi	a0,a0,-1924 # 938 <malloc+0x14e>
  c4:	00000097          	auipc	ra,0x0
  c8:	668080e7          	jalr	1640(ra) # 72c <printf>
  cc:	4491                	li	s1,4
    
    for(int i=0; i<4; i++){
        stack = malloc(STACK_SIZE);
  ce:	6905                	lui	s2,0x1
  d0:	fa090913          	addi	s2,s2,-96 # fa0 <__BSS_END__+0x608>
        kthread_create(func, stack);
  d4:	00000997          	auipc	s3,0x0
  d8:	f5498993          	addi	s3,s3,-172 # 28 <func>
        stack = malloc(STACK_SIZE);
  dc:	854a                	mv	a0,s2
  de:	00000097          	auipc	ra,0x0
  e2:	70c080e7          	jalr	1804(ra) # 7ea <malloc>
  e6:	85aa                	mv	a1,a0
        kthread_create(func, stack);
  e8:	854e                	mv	a0,s3
  ea:	00000097          	auipc	ra,0x0
  ee:	34a080e7          	jalr	842(ra) # 434 <kthread_create>
    for(int i=0; i<4; i++){
  f2:	34fd                	addiw	s1,s1,-1
  f4:	f4e5                	bnez	s1,dc <main+0x5e>
    }

    sleep(10000);
  f6:	6509                	lui	a0,0x2
  f8:	71050513          	addi	a0,a0,1808 # 2710 <__global_pointer$+0x1597>
  fc:	00000097          	auipc	ra,0x0
 100:	310080e7          	jalr	784(ra) # 40c <sleep>

    exit(0);
 104:	4501                	li	a0,0
 106:	00000097          	auipc	ra,0x0
 10a:	276080e7          	jalr	630(ra) # 37c <exit>

000000000000010e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 10e:	1141                	addi	sp,sp,-16
 110:	e422                	sd	s0,8(sp)
 112:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 114:	87aa                	mv	a5,a0
 116:	0585                	addi	a1,a1,1
 118:	0785                	addi	a5,a5,1
 11a:	fff5c703          	lbu	a4,-1(a1)
 11e:	fee78fa3          	sb	a4,-1(a5)
 122:	fb75                	bnez	a4,116 <strcpy+0x8>
    ;
  return os;
}
 124:	6422                	ld	s0,8(sp)
 126:	0141                	addi	sp,sp,16
 128:	8082                	ret

000000000000012a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 12a:	1141                	addi	sp,sp,-16
 12c:	e422                	sd	s0,8(sp)
 12e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 130:	00054783          	lbu	a5,0(a0)
 134:	cb91                	beqz	a5,148 <strcmp+0x1e>
 136:	0005c703          	lbu	a4,0(a1)
 13a:	00f71763          	bne	a4,a5,148 <strcmp+0x1e>
    p++, q++;
 13e:	0505                	addi	a0,a0,1
 140:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 142:	00054783          	lbu	a5,0(a0)
 146:	fbe5                	bnez	a5,136 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 148:	0005c503          	lbu	a0,0(a1)
}
 14c:	40a7853b          	subw	a0,a5,a0
 150:	6422                	ld	s0,8(sp)
 152:	0141                	addi	sp,sp,16
 154:	8082                	ret

0000000000000156 <strlen>:

uint
strlen(const char *s)
{
 156:	1141                	addi	sp,sp,-16
 158:	e422                	sd	s0,8(sp)
 15a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 15c:	00054783          	lbu	a5,0(a0)
 160:	cf91                	beqz	a5,17c <strlen+0x26>
 162:	0505                	addi	a0,a0,1
 164:	87aa                	mv	a5,a0
 166:	4685                	li	a3,1
 168:	9e89                	subw	a3,a3,a0
 16a:	00f6853b          	addw	a0,a3,a5
 16e:	0785                	addi	a5,a5,1
 170:	fff7c703          	lbu	a4,-1(a5)
 174:	fb7d                	bnez	a4,16a <strlen+0x14>
    ;
  return n;
}
 176:	6422                	ld	s0,8(sp)
 178:	0141                	addi	sp,sp,16
 17a:	8082                	ret
  for(n = 0; s[n]; n++)
 17c:	4501                	li	a0,0
 17e:	bfe5                	j	176 <strlen+0x20>

0000000000000180 <memset>:

void*
memset(void *dst, int c, uint n)
{
 180:	1141                	addi	sp,sp,-16
 182:	e422                	sd	s0,8(sp)
 184:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 186:	ca19                	beqz	a2,19c <memset+0x1c>
 188:	87aa                	mv	a5,a0
 18a:	1602                	slli	a2,a2,0x20
 18c:	9201                	srli	a2,a2,0x20
 18e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 192:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 196:	0785                	addi	a5,a5,1
 198:	fee79de3          	bne	a5,a4,192 <memset+0x12>
  }
  return dst;
}
 19c:	6422                	ld	s0,8(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret

00000000000001a2 <strchr>:

char*
strchr(const char *s, char c)
{
 1a2:	1141                	addi	sp,sp,-16
 1a4:	e422                	sd	s0,8(sp)
 1a6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1a8:	00054783          	lbu	a5,0(a0)
 1ac:	cb99                	beqz	a5,1c2 <strchr+0x20>
    if(*s == c)
 1ae:	00f58763          	beq	a1,a5,1bc <strchr+0x1a>
  for(; *s; s++)
 1b2:	0505                	addi	a0,a0,1
 1b4:	00054783          	lbu	a5,0(a0)
 1b8:	fbfd                	bnez	a5,1ae <strchr+0xc>
      return (char*)s;
  return 0;
 1ba:	4501                	li	a0,0
}
 1bc:	6422                	ld	s0,8(sp)
 1be:	0141                	addi	sp,sp,16
 1c0:	8082                	ret
  return 0;
 1c2:	4501                	li	a0,0
 1c4:	bfe5                	j	1bc <strchr+0x1a>

00000000000001c6 <gets>:

char*
gets(char *buf, int max)
{
 1c6:	711d                	addi	sp,sp,-96
 1c8:	ec86                	sd	ra,88(sp)
 1ca:	e8a2                	sd	s0,80(sp)
 1cc:	e4a6                	sd	s1,72(sp)
 1ce:	e0ca                	sd	s2,64(sp)
 1d0:	fc4e                	sd	s3,56(sp)
 1d2:	f852                	sd	s4,48(sp)
 1d4:	f456                	sd	s5,40(sp)
 1d6:	f05a                	sd	s6,32(sp)
 1d8:	ec5e                	sd	s7,24(sp)
 1da:	1080                	addi	s0,sp,96
 1dc:	8baa                	mv	s7,a0
 1de:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1e0:	892a                	mv	s2,a0
 1e2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1e4:	4aa9                	li	s5,10
 1e6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1e8:	89a6                	mv	s3,s1
 1ea:	2485                	addiw	s1,s1,1
 1ec:	0344d863          	bge	s1,s4,21c <gets+0x56>
    cc = read(0, &c, 1);
 1f0:	4605                	li	a2,1
 1f2:	faf40593          	addi	a1,s0,-81
 1f6:	4501                	li	a0,0
 1f8:	00000097          	auipc	ra,0x0
 1fc:	19c080e7          	jalr	412(ra) # 394 <read>
    if(cc < 1)
 200:	00a05e63          	blez	a0,21c <gets+0x56>
    buf[i++] = c;
 204:	faf44783          	lbu	a5,-81(s0)
 208:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 20c:	01578763          	beq	a5,s5,21a <gets+0x54>
 210:	0905                	addi	s2,s2,1
 212:	fd679be3          	bne	a5,s6,1e8 <gets+0x22>
  for(i=0; i+1 < max; ){
 216:	89a6                	mv	s3,s1
 218:	a011                	j	21c <gets+0x56>
 21a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 21c:	99de                	add	s3,s3,s7
 21e:	00098023          	sb	zero,0(s3)
  return buf;
}
 222:	855e                	mv	a0,s7
 224:	60e6                	ld	ra,88(sp)
 226:	6446                	ld	s0,80(sp)
 228:	64a6                	ld	s1,72(sp)
 22a:	6906                	ld	s2,64(sp)
 22c:	79e2                	ld	s3,56(sp)
 22e:	7a42                	ld	s4,48(sp)
 230:	7aa2                	ld	s5,40(sp)
 232:	7b02                	ld	s6,32(sp)
 234:	6be2                	ld	s7,24(sp)
 236:	6125                	addi	sp,sp,96
 238:	8082                	ret

000000000000023a <stat>:

int
stat(const char *n, struct stat *st)
{
 23a:	1101                	addi	sp,sp,-32
 23c:	ec06                	sd	ra,24(sp)
 23e:	e822                	sd	s0,16(sp)
 240:	e426                	sd	s1,8(sp)
 242:	e04a                	sd	s2,0(sp)
 244:	1000                	addi	s0,sp,32
 246:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 248:	4581                	li	a1,0
 24a:	00000097          	auipc	ra,0x0
 24e:	172080e7          	jalr	370(ra) # 3bc <open>
  if(fd < 0)
 252:	02054563          	bltz	a0,27c <stat+0x42>
 256:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 258:	85ca                	mv	a1,s2
 25a:	00000097          	auipc	ra,0x0
 25e:	17a080e7          	jalr	378(ra) # 3d4 <fstat>
 262:	892a                	mv	s2,a0
  close(fd);
 264:	8526                	mv	a0,s1
 266:	00000097          	auipc	ra,0x0
 26a:	13e080e7          	jalr	318(ra) # 3a4 <close>
  return r;
}
 26e:	854a                	mv	a0,s2
 270:	60e2                	ld	ra,24(sp)
 272:	6442                	ld	s0,16(sp)
 274:	64a2                	ld	s1,8(sp)
 276:	6902                	ld	s2,0(sp)
 278:	6105                	addi	sp,sp,32
 27a:	8082                	ret
    return -1;
 27c:	597d                	li	s2,-1
 27e:	bfc5                	j	26e <stat+0x34>

0000000000000280 <atoi>:

int
atoi(const char *s)
{
 280:	1141                	addi	sp,sp,-16
 282:	e422                	sd	s0,8(sp)
 284:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 286:	00054603          	lbu	a2,0(a0)
 28a:	fd06079b          	addiw	a5,a2,-48
 28e:	0ff7f793          	andi	a5,a5,255
 292:	4725                	li	a4,9
 294:	02f76963          	bltu	a4,a5,2c6 <atoi+0x46>
 298:	86aa                	mv	a3,a0
  n = 0;
 29a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 29c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 29e:	0685                	addi	a3,a3,1
 2a0:	0025179b          	slliw	a5,a0,0x2
 2a4:	9fa9                	addw	a5,a5,a0
 2a6:	0017979b          	slliw	a5,a5,0x1
 2aa:	9fb1                	addw	a5,a5,a2
 2ac:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2b0:	0006c603          	lbu	a2,0(a3)
 2b4:	fd06071b          	addiw	a4,a2,-48
 2b8:	0ff77713          	andi	a4,a4,255
 2bc:	fee5f1e3          	bgeu	a1,a4,29e <atoi+0x1e>
  return n;
}
 2c0:	6422                	ld	s0,8(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret
  n = 0;
 2c6:	4501                	li	a0,0
 2c8:	bfe5                	j	2c0 <atoi+0x40>

00000000000002ca <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ca:	1141                	addi	sp,sp,-16
 2cc:	e422                	sd	s0,8(sp)
 2ce:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2d0:	02b57463          	bgeu	a0,a1,2f8 <memmove+0x2e>
    while(n-- > 0)
 2d4:	00c05f63          	blez	a2,2f2 <memmove+0x28>
 2d8:	1602                	slli	a2,a2,0x20
 2da:	9201                	srli	a2,a2,0x20
 2dc:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2e0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2e2:	0585                	addi	a1,a1,1
 2e4:	0705                	addi	a4,a4,1
 2e6:	fff5c683          	lbu	a3,-1(a1)
 2ea:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2ee:	fee79ae3          	bne	a5,a4,2e2 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2f2:	6422                	ld	s0,8(sp)
 2f4:	0141                	addi	sp,sp,16
 2f6:	8082                	ret
    dst += n;
 2f8:	00c50733          	add	a4,a0,a2
    src += n;
 2fc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2fe:	fec05ae3          	blez	a2,2f2 <memmove+0x28>
 302:	fff6079b          	addiw	a5,a2,-1
 306:	1782                	slli	a5,a5,0x20
 308:	9381                	srli	a5,a5,0x20
 30a:	fff7c793          	not	a5,a5
 30e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 310:	15fd                	addi	a1,a1,-1
 312:	177d                	addi	a4,a4,-1
 314:	0005c683          	lbu	a3,0(a1)
 318:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 31c:	fee79ae3          	bne	a5,a4,310 <memmove+0x46>
 320:	bfc9                	j	2f2 <memmove+0x28>

0000000000000322 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 322:	1141                	addi	sp,sp,-16
 324:	e422                	sd	s0,8(sp)
 326:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 328:	ca05                	beqz	a2,358 <memcmp+0x36>
 32a:	fff6069b          	addiw	a3,a2,-1
 32e:	1682                	slli	a3,a3,0x20
 330:	9281                	srli	a3,a3,0x20
 332:	0685                	addi	a3,a3,1
 334:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 336:	00054783          	lbu	a5,0(a0)
 33a:	0005c703          	lbu	a4,0(a1)
 33e:	00e79863          	bne	a5,a4,34e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 342:	0505                	addi	a0,a0,1
    p2++;
 344:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 346:	fed518e3          	bne	a0,a3,336 <memcmp+0x14>
  }
  return 0;
 34a:	4501                	li	a0,0
 34c:	a019                	j	352 <memcmp+0x30>
      return *p1 - *p2;
 34e:	40e7853b          	subw	a0,a5,a4
}
 352:	6422                	ld	s0,8(sp)
 354:	0141                	addi	sp,sp,16
 356:	8082                	ret
  return 0;
 358:	4501                	li	a0,0
 35a:	bfe5                	j	352 <memcmp+0x30>

000000000000035c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 35c:	1141                	addi	sp,sp,-16
 35e:	e406                	sd	ra,8(sp)
 360:	e022                	sd	s0,0(sp)
 362:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 364:	00000097          	auipc	ra,0x0
 368:	f66080e7          	jalr	-154(ra) # 2ca <memmove>
}
 36c:	60a2                	ld	ra,8(sp)
 36e:	6402                	ld	s0,0(sp)
 370:	0141                	addi	sp,sp,16
 372:	8082                	ret

0000000000000374 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 374:	4885                	li	a7,1
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <exit>:
.global exit
exit:
 li a7, SYS_exit
 37c:	4889                	li	a7,2
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <wait>:
.global wait
wait:
 li a7, SYS_wait
 384:	488d                	li	a7,3
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 38c:	4891                	li	a7,4
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <read>:
.global read
read:
 li a7, SYS_read
 394:	4895                	li	a7,5
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <write>:
.global write
write:
 li a7, SYS_write
 39c:	48c1                	li	a7,16
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <close>:
.global close
close:
 li a7, SYS_close
 3a4:	48d5                	li	a7,21
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <kill>:
.global kill
kill:
 li a7, SYS_kill
 3ac:	4899                	li	a7,6
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3b4:	489d                	li	a7,7
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <open>:
.global open
open:
 li a7, SYS_open
 3bc:	48bd                	li	a7,15
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3c4:	48c5                	li	a7,17
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3cc:	48c9                	li	a7,18
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3d4:	48a1                	li	a7,8
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <link>:
.global link
link:
 li a7, SYS_link
 3dc:	48cd                	li	a7,19
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3e4:	48d1                	li	a7,20
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3ec:	48a5                	li	a7,9
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3f4:	48a9                	li	a7,10
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3fc:	48ad                	li	a7,11
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 404:	48b1                	li	a7,12
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 40c:	48b5                	li	a7,13
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 414:	48b9                	li	a7,14
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 41c:	48d9                	li	a7,22
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 424:	48dd                	li	a7,23
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 42c:	48e1                	li	a7,24
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 434:	48e5                	li	a7,25
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 43c:	48e9                	li	a7,26
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 444:	48ed                	li	a7,27
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 44c:	48f1                	li	a7,28
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 454:	1101                	addi	sp,sp,-32
 456:	ec06                	sd	ra,24(sp)
 458:	e822                	sd	s0,16(sp)
 45a:	1000                	addi	s0,sp,32
 45c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 460:	4605                	li	a2,1
 462:	fef40593          	addi	a1,s0,-17
 466:	00000097          	auipc	ra,0x0
 46a:	f36080e7          	jalr	-202(ra) # 39c <write>
}
 46e:	60e2                	ld	ra,24(sp)
 470:	6442                	ld	s0,16(sp)
 472:	6105                	addi	sp,sp,32
 474:	8082                	ret

0000000000000476 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 476:	7139                	addi	sp,sp,-64
 478:	fc06                	sd	ra,56(sp)
 47a:	f822                	sd	s0,48(sp)
 47c:	f426                	sd	s1,40(sp)
 47e:	f04a                	sd	s2,32(sp)
 480:	ec4e                	sd	s3,24(sp)
 482:	0080                	addi	s0,sp,64
 484:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 486:	c299                	beqz	a3,48c <printint+0x16>
 488:	0805c863          	bltz	a1,518 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 48c:	2581                	sext.w	a1,a1
  neg = 0;
 48e:	4881                	li	a7,0
 490:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 494:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 496:	2601                	sext.w	a2,a2
 498:	00000517          	auipc	a0,0x0
 49c:	4d050513          	addi	a0,a0,1232 # 968 <digits>
 4a0:	883a                	mv	a6,a4
 4a2:	2705                	addiw	a4,a4,1
 4a4:	02c5f7bb          	remuw	a5,a1,a2
 4a8:	1782                	slli	a5,a5,0x20
 4aa:	9381                	srli	a5,a5,0x20
 4ac:	97aa                	add	a5,a5,a0
 4ae:	0007c783          	lbu	a5,0(a5)
 4b2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4b6:	0005879b          	sext.w	a5,a1
 4ba:	02c5d5bb          	divuw	a1,a1,a2
 4be:	0685                	addi	a3,a3,1
 4c0:	fec7f0e3          	bgeu	a5,a2,4a0 <printint+0x2a>
  if(neg)
 4c4:	00088b63          	beqz	a7,4da <printint+0x64>
    buf[i++] = '-';
 4c8:	fd040793          	addi	a5,s0,-48
 4cc:	973e                	add	a4,a4,a5
 4ce:	02d00793          	li	a5,45
 4d2:	fef70823          	sb	a5,-16(a4)
 4d6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4da:	02e05863          	blez	a4,50a <printint+0x94>
 4de:	fc040793          	addi	a5,s0,-64
 4e2:	00e78933          	add	s2,a5,a4
 4e6:	fff78993          	addi	s3,a5,-1
 4ea:	99ba                	add	s3,s3,a4
 4ec:	377d                	addiw	a4,a4,-1
 4ee:	1702                	slli	a4,a4,0x20
 4f0:	9301                	srli	a4,a4,0x20
 4f2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4f6:	fff94583          	lbu	a1,-1(s2)
 4fa:	8526                	mv	a0,s1
 4fc:	00000097          	auipc	ra,0x0
 500:	f58080e7          	jalr	-168(ra) # 454 <putc>
  while(--i >= 0)
 504:	197d                	addi	s2,s2,-1
 506:	ff3918e3          	bne	s2,s3,4f6 <printint+0x80>
}
 50a:	70e2                	ld	ra,56(sp)
 50c:	7442                	ld	s0,48(sp)
 50e:	74a2                	ld	s1,40(sp)
 510:	7902                	ld	s2,32(sp)
 512:	69e2                	ld	s3,24(sp)
 514:	6121                	addi	sp,sp,64
 516:	8082                	ret
    x = -xx;
 518:	40b005bb          	negw	a1,a1
    neg = 1;
 51c:	4885                	li	a7,1
    x = -xx;
 51e:	bf8d                	j	490 <printint+0x1a>

0000000000000520 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 520:	7119                	addi	sp,sp,-128
 522:	fc86                	sd	ra,120(sp)
 524:	f8a2                	sd	s0,112(sp)
 526:	f4a6                	sd	s1,104(sp)
 528:	f0ca                	sd	s2,96(sp)
 52a:	ecce                	sd	s3,88(sp)
 52c:	e8d2                	sd	s4,80(sp)
 52e:	e4d6                	sd	s5,72(sp)
 530:	e0da                	sd	s6,64(sp)
 532:	fc5e                	sd	s7,56(sp)
 534:	f862                	sd	s8,48(sp)
 536:	f466                	sd	s9,40(sp)
 538:	f06a                	sd	s10,32(sp)
 53a:	ec6e                	sd	s11,24(sp)
 53c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 53e:	0005c903          	lbu	s2,0(a1)
 542:	18090f63          	beqz	s2,6e0 <vprintf+0x1c0>
 546:	8aaa                	mv	s5,a0
 548:	8b32                	mv	s6,a2
 54a:	00158493          	addi	s1,a1,1
  state = 0;
 54e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 550:	02500a13          	li	s4,37
      if(c == 'd'){
 554:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 558:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 55c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 560:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 564:	00000b97          	auipc	s7,0x0
 568:	404b8b93          	addi	s7,s7,1028 # 968 <digits>
 56c:	a839                	j	58a <vprintf+0x6a>
        putc(fd, c);
 56e:	85ca                	mv	a1,s2
 570:	8556                	mv	a0,s5
 572:	00000097          	auipc	ra,0x0
 576:	ee2080e7          	jalr	-286(ra) # 454 <putc>
 57a:	a019                	j	580 <vprintf+0x60>
    } else if(state == '%'){
 57c:	01498f63          	beq	s3,s4,59a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 580:	0485                	addi	s1,s1,1
 582:	fff4c903          	lbu	s2,-1(s1)
 586:	14090d63          	beqz	s2,6e0 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 58a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 58e:	fe0997e3          	bnez	s3,57c <vprintf+0x5c>
      if(c == '%'){
 592:	fd479ee3          	bne	a5,s4,56e <vprintf+0x4e>
        state = '%';
 596:	89be                	mv	s3,a5
 598:	b7e5                	j	580 <vprintf+0x60>
      if(c == 'd'){
 59a:	05878063          	beq	a5,s8,5da <vprintf+0xba>
      } else if(c == 'l') {
 59e:	05978c63          	beq	a5,s9,5f6 <vprintf+0xd6>
      } else if(c == 'x') {
 5a2:	07a78863          	beq	a5,s10,612 <vprintf+0xf2>
      } else if(c == 'p') {
 5a6:	09b78463          	beq	a5,s11,62e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5aa:	07300713          	li	a4,115
 5ae:	0ce78663          	beq	a5,a4,67a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5b2:	06300713          	li	a4,99
 5b6:	0ee78e63          	beq	a5,a4,6b2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5ba:	11478863          	beq	a5,s4,6ca <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5be:	85d2                	mv	a1,s4
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	e92080e7          	jalr	-366(ra) # 454 <putc>
        putc(fd, c);
 5ca:	85ca                	mv	a1,s2
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e86080e7          	jalr	-378(ra) # 454 <putc>
      }
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	b765                	j	580 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5da:	008b0913          	addi	s2,s6,8
 5de:	4685                	li	a3,1
 5e0:	4629                	li	a2,10
 5e2:	000b2583          	lw	a1,0(s6)
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	e8e080e7          	jalr	-370(ra) # 476 <printint>
 5f0:	8b4a                	mv	s6,s2
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	b771                	j	580 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5f6:	008b0913          	addi	s2,s6,8
 5fa:	4681                	li	a3,0
 5fc:	4629                	li	a2,10
 5fe:	000b2583          	lw	a1,0(s6)
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	e72080e7          	jalr	-398(ra) # 476 <printint>
 60c:	8b4a                	mv	s6,s2
      state = 0;
 60e:	4981                	li	s3,0
 610:	bf85                	j	580 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 612:	008b0913          	addi	s2,s6,8
 616:	4681                	li	a3,0
 618:	4641                	li	a2,16
 61a:	000b2583          	lw	a1,0(s6)
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	e56080e7          	jalr	-426(ra) # 476 <printint>
 628:	8b4a                	mv	s6,s2
      state = 0;
 62a:	4981                	li	s3,0
 62c:	bf91                	j	580 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 62e:	008b0793          	addi	a5,s6,8
 632:	f8f43423          	sd	a5,-120(s0)
 636:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 63a:	03000593          	li	a1,48
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e14080e7          	jalr	-492(ra) # 454 <putc>
  putc(fd, 'x');
 648:	85ea                	mv	a1,s10
 64a:	8556                	mv	a0,s5
 64c:	00000097          	auipc	ra,0x0
 650:	e08080e7          	jalr	-504(ra) # 454 <putc>
 654:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 656:	03c9d793          	srli	a5,s3,0x3c
 65a:	97de                	add	a5,a5,s7
 65c:	0007c583          	lbu	a1,0(a5)
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	df2080e7          	jalr	-526(ra) # 454 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 66a:	0992                	slli	s3,s3,0x4
 66c:	397d                	addiw	s2,s2,-1
 66e:	fe0914e3          	bnez	s2,656 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 672:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 676:	4981                	li	s3,0
 678:	b721                	j	580 <vprintf+0x60>
        s = va_arg(ap, char*);
 67a:	008b0993          	addi	s3,s6,8
 67e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 682:	02090163          	beqz	s2,6a4 <vprintf+0x184>
        while(*s != 0){
 686:	00094583          	lbu	a1,0(s2)
 68a:	c9a1                	beqz	a1,6da <vprintf+0x1ba>
          putc(fd, *s);
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	dc6080e7          	jalr	-570(ra) # 454 <putc>
          s++;
 696:	0905                	addi	s2,s2,1
        while(*s != 0){
 698:	00094583          	lbu	a1,0(s2)
 69c:	f9e5                	bnez	a1,68c <vprintf+0x16c>
        s = va_arg(ap, char*);
 69e:	8b4e                	mv	s6,s3
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	bdf9                	j	580 <vprintf+0x60>
          s = "(null)";
 6a4:	00000917          	auipc	s2,0x0
 6a8:	2bc90913          	addi	s2,s2,700 # 960 <malloc+0x176>
        while(*s != 0){
 6ac:	02800593          	li	a1,40
 6b0:	bff1                	j	68c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6b2:	008b0913          	addi	s2,s6,8
 6b6:	000b4583          	lbu	a1,0(s6)
 6ba:	8556                	mv	a0,s5
 6bc:	00000097          	auipc	ra,0x0
 6c0:	d98080e7          	jalr	-616(ra) # 454 <putc>
 6c4:	8b4a                	mv	s6,s2
      state = 0;
 6c6:	4981                	li	s3,0
 6c8:	bd65                	j	580 <vprintf+0x60>
        putc(fd, c);
 6ca:	85d2                	mv	a1,s4
 6cc:	8556                	mv	a0,s5
 6ce:	00000097          	auipc	ra,0x0
 6d2:	d86080e7          	jalr	-634(ra) # 454 <putc>
      state = 0;
 6d6:	4981                	li	s3,0
 6d8:	b565                	j	580 <vprintf+0x60>
        s = va_arg(ap, char*);
 6da:	8b4e                	mv	s6,s3
      state = 0;
 6dc:	4981                	li	s3,0
 6de:	b54d                	j	580 <vprintf+0x60>
    }
  }
}
 6e0:	70e6                	ld	ra,120(sp)
 6e2:	7446                	ld	s0,112(sp)
 6e4:	74a6                	ld	s1,104(sp)
 6e6:	7906                	ld	s2,96(sp)
 6e8:	69e6                	ld	s3,88(sp)
 6ea:	6a46                	ld	s4,80(sp)
 6ec:	6aa6                	ld	s5,72(sp)
 6ee:	6b06                	ld	s6,64(sp)
 6f0:	7be2                	ld	s7,56(sp)
 6f2:	7c42                	ld	s8,48(sp)
 6f4:	7ca2                	ld	s9,40(sp)
 6f6:	7d02                	ld	s10,32(sp)
 6f8:	6de2                	ld	s11,24(sp)
 6fa:	6109                	addi	sp,sp,128
 6fc:	8082                	ret

00000000000006fe <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6fe:	715d                	addi	sp,sp,-80
 700:	ec06                	sd	ra,24(sp)
 702:	e822                	sd	s0,16(sp)
 704:	1000                	addi	s0,sp,32
 706:	e010                	sd	a2,0(s0)
 708:	e414                	sd	a3,8(s0)
 70a:	e818                	sd	a4,16(s0)
 70c:	ec1c                	sd	a5,24(s0)
 70e:	03043023          	sd	a6,32(s0)
 712:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 716:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 71a:	8622                	mv	a2,s0
 71c:	00000097          	auipc	ra,0x0
 720:	e04080e7          	jalr	-508(ra) # 520 <vprintf>
}
 724:	60e2                	ld	ra,24(sp)
 726:	6442                	ld	s0,16(sp)
 728:	6161                	addi	sp,sp,80
 72a:	8082                	ret

000000000000072c <printf>:

void
printf(const char *fmt, ...)
{
 72c:	711d                	addi	sp,sp,-96
 72e:	ec06                	sd	ra,24(sp)
 730:	e822                	sd	s0,16(sp)
 732:	1000                	addi	s0,sp,32
 734:	e40c                	sd	a1,8(s0)
 736:	e810                	sd	a2,16(s0)
 738:	ec14                	sd	a3,24(s0)
 73a:	f018                	sd	a4,32(s0)
 73c:	f41c                	sd	a5,40(s0)
 73e:	03043823          	sd	a6,48(s0)
 742:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 746:	00840613          	addi	a2,s0,8
 74a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 74e:	85aa                	mv	a1,a0
 750:	4505                	li	a0,1
 752:	00000097          	auipc	ra,0x0
 756:	dce080e7          	jalr	-562(ra) # 520 <vprintf>
}
 75a:	60e2                	ld	ra,24(sp)
 75c:	6442                	ld	s0,16(sp)
 75e:	6125                	addi	sp,sp,96
 760:	8082                	ret

0000000000000762 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 762:	1141                	addi	sp,sp,-16
 764:	e422                	sd	s0,8(sp)
 766:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 768:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 76c:	00000797          	auipc	a5,0x0
 770:	2147b783          	ld	a5,532(a5) # 980 <freep>
 774:	a805                	j	7a4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 776:	4618                	lw	a4,8(a2)
 778:	9db9                	addw	a1,a1,a4
 77a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 77e:	6398                	ld	a4,0(a5)
 780:	6318                	ld	a4,0(a4)
 782:	fee53823          	sd	a4,-16(a0)
 786:	a091                	j	7ca <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 788:	ff852703          	lw	a4,-8(a0)
 78c:	9e39                	addw	a2,a2,a4
 78e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 790:	ff053703          	ld	a4,-16(a0)
 794:	e398                	sd	a4,0(a5)
 796:	a099                	j	7dc <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 798:	6398                	ld	a4,0(a5)
 79a:	00e7e463          	bltu	a5,a4,7a2 <free+0x40>
 79e:	00e6ea63          	bltu	a3,a4,7b2 <free+0x50>
{
 7a2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7a4:	fed7fae3          	bgeu	a5,a3,798 <free+0x36>
 7a8:	6398                	ld	a4,0(a5)
 7aa:	00e6e463          	bltu	a3,a4,7b2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ae:	fee7eae3          	bltu	a5,a4,7a2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7b2:	ff852583          	lw	a1,-8(a0)
 7b6:	6390                	ld	a2,0(a5)
 7b8:	02059813          	slli	a6,a1,0x20
 7bc:	01c85713          	srli	a4,a6,0x1c
 7c0:	9736                	add	a4,a4,a3
 7c2:	fae60ae3          	beq	a2,a4,776 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7c6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7ca:	4790                	lw	a2,8(a5)
 7cc:	02061593          	slli	a1,a2,0x20
 7d0:	01c5d713          	srli	a4,a1,0x1c
 7d4:	973e                	add	a4,a4,a5
 7d6:	fae689e3          	beq	a3,a4,788 <free+0x26>
  } else
    p->s.ptr = bp;
 7da:	e394                	sd	a3,0(a5)
  freep = p;
 7dc:	00000717          	auipc	a4,0x0
 7e0:	1af73223          	sd	a5,420(a4) # 980 <freep>
}
 7e4:	6422                	ld	s0,8(sp)
 7e6:	0141                	addi	sp,sp,16
 7e8:	8082                	ret

00000000000007ea <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7ea:	7139                	addi	sp,sp,-64
 7ec:	fc06                	sd	ra,56(sp)
 7ee:	f822                	sd	s0,48(sp)
 7f0:	f426                	sd	s1,40(sp)
 7f2:	f04a                	sd	s2,32(sp)
 7f4:	ec4e                	sd	s3,24(sp)
 7f6:	e852                	sd	s4,16(sp)
 7f8:	e456                	sd	s5,8(sp)
 7fa:	e05a                	sd	s6,0(sp)
 7fc:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7fe:	02051493          	slli	s1,a0,0x20
 802:	9081                	srli	s1,s1,0x20
 804:	04bd                	addi	s1,s1,15
 806:	8091                	srli	s1,s1,0x4
 808:	0014899b          	addiw	s3,s1,1
 80c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 80e:	00000517          	auipc	a0,0x0
 812:	17253503          	ld	a0,370(a0) # 980 <freep>
 816:	c515                	beqz	a0,842 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 818:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 81a:	4798                	lw	a4,8(a5)
 81c:	02977f63          	bgeu	a4,s1,85a <malloc+0x70>
 820:	8a4e                	mv	s4,s3
 822:	0009871b          	sext.w	a4,s3
 826:	6685                	lui	a3,0x1
 828:	00d77363          	bgeu	a4,a3,82e <malloc+0x44>
 82c:	6a05                	lui	s4,0x1
 82e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 832:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 836:	00000917          	auipc	s2,0x0
 83a:	14a90913          	addi	s2,s2,330 # 980 <freep>
  if(p == (char*)-1)
 83e:	5afd                	li	s5,-1
 840:	a895                	j	8b4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 842:	00000797          	auipc	a5,0x0
 846:	14678793          	addi	a5,a5,326 # 988 <base>
 84a:	00000717          	auipc	a4,0x0
 84e:	12f73b23          	sd	a5,310(a4) # 980 <freep>
 852:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 854:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 858:	b7e1                	j	820 <malloc+0x36>
      if(p->s.size == nunits)
 85a:	02e48c63          	beq	s1,a4,892 <malloc+0xa8>
        p->s.size -= nunits;
 85e:	4137073b          	subw	a4,a4,s3
 862:	c798                	sw	a4,8(a5)
        p += p->s.size;
 864:	02071693          	slli	a3,a4,0x20
 868:	01c6d713          	srli	a4,a3,0x1c
 86c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 86e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 872:	00000717          	auipc	a4,0x0
 876:	10a73723          	sd	a0,270(a4) # 980 <freep>
      return (void*)(p + 1);
 87a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 87e:	70e2                	ld	ra,56(sp)
 880:	7442                	ld	s0,48(sp)
 882:	74a2                	ld	s1,40(sp)
 884:	7902                	ld	s2,32(sp)
 886:	69e2                	ld	s3,24(sp)
 888:	6a42                	ld	s4,16(sp)
 88a:	6aa2                	ld	s5,8(sp)
 88c:	6b02                	ld	s6,0(sp)
 88e:	6121                	addi	sp,sp,64
 890:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 892:	6398                	ld	a4,0(a5)
 894:	e118                	sd	a4,0(a0)
 896:	bff1                	j	872 <malloc+0x88>
  hp->s.size = nu;
 898:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 89c:	0541                	addi	a0,a0,16
 89e:	00000097          	auipc	ra,0x0
 8a2:	ec4080e7          	jalr	-316(ra) # 762 <free>
  return freep;
 8a6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8aa:	d971                	beqz	a0,87e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ac:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ae:	4798                	lw	a4,8(a5)
 8b0:	fa9775e3          	bgeu	a4,s1,85a <malloc+0x70>
    if(p == freep)
 8b4:	00093703          	ld	a4,0(s2)
 8b8:	853e                	mv	a0,a5
 8ba:	fef719e3          	bne	a4,a5,8ac <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 8be:	8552                	mv	a0,s4
 8c0:	00000097          	auipc	ra,0x0
 8c4:	b44080e7          	jalr	-1212(ra) # 404 <sbrk>
  if(p == (char*)-1)
 8c8:	fd5518e3          	bne	a0,s5,898 <malloc+0xae>
        return 0;
 8cc:	4501                	li	a0,0
 8ce:	bf45                	j	87e <malloc+0x94>
