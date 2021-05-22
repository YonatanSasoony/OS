
user/_test_task3:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sanity_test>:
#include "kernel/fcntl.h"

#define PG_SIZE 4096
#define MAX_PG_NUM 27

void sanity_test(){
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
    char *pages = malloc(PG_SIZE * MAX_PG_NUM);
  16:	656d                	lui	a0,0x1b
  18:	00001097          	auipc	ra,0x1
  1c:	9a6080e7          	jalr	-1626(ra) # 9be <malloc>
  20:	8baa                	mv	s7,a0
    printf("Allocated %d pages\n", MAX_PG_NUM);
  22:	45ed                	li	a1,27
  24:	00001517          	auipc	a0,0x1
  28:	a8450513          	addi	a0,a0,-1404 # aa8 <malloc+0xea>
  2c:	00001097          	auipc	ra,0x1
  30:	8d4080e7          	jalr	-1836(ra) # 900 <printf>

    for (int i = 0; i < MAX_PG_NUM; i++){
  34:	895e                	mv	s2,s7
    printf("Allocated %d pages\n", MAX_PG_NUM);
  36:	89de                	mv	s3,s7
    for (int i = 0; i < MAX_PG_NUM; i++){
  38:	4481                	li	s1,0
        printf("write to page %d: %d\n", i, i);
  3a:	00001b17          	auipc	s6,0x1
  3e:	a86b0b13          	addi	s6,s6,-1402 # ac0 <malloc+0x102>
    for (int i = 0; i < MAX_PG_NUM; i++){
  42:	6a85                	lui	s5,0x1
  44:	4a6d                	li	s4,27
        printf("write to page %d: %d\n", i, i);
  46:	8626                	mv	a2,s1
  48:	85a6                	mv	a1,s1
  4a:	855a                	mv	a0,s6
  4c:	00001097          	auipc	ra,0x1
  50:	8b4080e7          	jalr	-1868(ra) # 900 <printf>
        pages[i * PG_SIZE] = i;
  54:	00998023          	sb	s1,0(s3)
    for (int i = 0; i < MAX_PG_NUM; i++){
  58:	2485                	addiw	s1,s1,1
  5a:	99d6                	add	s3,s3,s5
  5c:	ff4495e3          	bne	s1,s4,46 <sanity_test+0x46>
    }

    for (int i = 0; i < MAX_PG_NUM; i++){
  60:	4481                	li	s1,0
        printf("read from page %d: %d\n", i, pages[i * PG_SIZE]);
  62:	00001a97          	auipc	s5,0x1
  66:	a76a8a93          	addi	s5,s5,-1418 # ad8 <malloc+0x11a>
    for (int i = 0; i < MAX_PG_NUM; i++){
  6a:	6a05                	lui	s4,0x1
  6c:	49ed                	li	s3,27
        printf("read from page %d: %d\n", i, pages[i * PG_SIZE]);
  6e:	00094603          	lbu	a2,0(s2)
  72:	85a6                	mv	a1,s1
  74:	8556                	mv	a0,s5
  76:	00001097          	auipc	ra,0x1
  7a:	88a080e7          	jalr	-1910(ra) # 900 <printf>
    for (int i = 0; i < MAX_PG_NUM; i++){
  7e:	2485                	addiw	s1,s1,1
  80:	9952                	add	s2,s2,s4
  82:	ff3496e3          	bne	s1,s3,6e <sanity_test+0x6e>
    }
    free(pages);
  86:	855e                	mv	a0,s7
  88:	00001097          	auipc	ra,0x1
  8c:	8ae080e7          	jalr	-1874(ra) # 936 <free>
}
  90:	60a6                	ld	ra,72(sp)
  92:	6406                	ld	s0,64(sp)
  94:	74e2                	ld	s1,56(sp)
  96:	7942                	ld	s2,48(sp)
  98:	79a2                	ld	s3,40(sp)
  9a:	7a02                	ld	s4,32(sp)
  9c:	6ae2                	ld	s5,24(sp)
  9e:	6b42                	ld	s6,16(sp)
  a0:	6ba2                	ld	s7,8(sp)
  a2:	6161                	addi	sp,sp,80
  a4:	8082                	ret

00000000000000a6 <NFUA_LAPA_tests>:

void NFUA_LAPA_tests(){
  a6:	1101                	addi	sp,sp,-32
  a8:	ec06                	sd	ra,24(sp)
  aa:	e822                	sd	s0,16(sp)
  ac:	e426                	sd	s1,8(sp)
  ae:	e04a                	sd	s2,0(sp)
  b0:	1000                	addi	s0,sp,32
    char *pages = malloc(PG_SIZE * 17);
  b2:	6545                	lui	a0,0x11
  b4:	00001097          	auipc	ra,0x1
  b8:	90a080e7          	jalr	-1782(ra) # 9be <malloc>
  bc:	892a                	mv	s2,a0
    for (int i = 0; i < 16; i++){
  be:	84aa                	mv	s1,a0
    char *pages = malloc(PG_SIZE * 17);
  c0:	872a                	mv	a4,a0
    for (int i = 0; i < 16; i++){
  c2:	4781                	li	a5,0
  c4:	6605                	lui	a2,0x1
  c6:	46c1                	li	a3,16
        pages[i * PG_SIZE] = i;
  c8:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 16; i++){
  cc:	2785                	addiw	a5,a5,1
  ce:	9732                	add	a4,a4,a2
  d0:	fed79ce3          	bne	a5,a3,c8 <NFUA_LAPA_tests+0x22>
    }
    sleep(2); // update age
  d4:	4509                	li	a0,2
  d6:	00000097          	auipc	ra,0x0
  da:	542080e7          	jalr	1346(ra) # 618 <sleep>
    for (int i = 0; i < 15; i++){
  de:	4781                	li	a5,0
  e0:	6685                	lui	a3,0x1
  e2:	473d                	li	a4,15
        pages[i * PG_SIZE] = i;
  e4:	00f48023          	sb	a5,0(s1)
    for (int i = 0; i < 15; i++){
  e8:	2785                	addiw	a5,a5,1
  ea:	94b6                	add	s1,s1,a3
  ec:	fee79ce3          	bne	a5,a4,e4 <NFUA_LAPA_tests+0x3e>
    }
    sleep(2); // update age
  f0:	4509                	li	a0,2
  f2:	00000097          	auipc	ra,0x0
  f6:	526080e7          	jalr	1318(ra) # 618 <sleep>
    pages[16 * PG_SIZE] = 16; // should replace page #15 - check kernel print
  fa:	67c1                	lui	a5,0x10
  fc:	993e                	add	s2,s2,a5
  fe:	47c1                	li	a5,16
 100:	00f90023          	sb	a5,0(s2)
}
 104:	60e2                	ld	ra,24(sp)
 106:	6442                	ld	s0,16(sp)
 108:	64a2                	ld	s1,8(sp)
 10a:	6902                	ld	s2,0(sp)
 10c:	6105                	addi	sp,sp,32
 10e:	8082                	ret

0000000000000110 <SCFIFO_test>:

void SCFIFO_test(){
 110:	1141                	addi	sp,sp,-16
 112:	e406                	sd	ra,8(sp)
 114:	e022                	sd	s0,0(sp)
 116:	0800                	addi	s0,sp,16
    char *pages = malloc(PG_SIZE * 18);
 118:	6549                	lui	a0,0x12
 11a:	00001097          	auipc	ra,0x1
 11e:	8a4080e7          	jalr	-1884(ra) # 9be <malloc>
    for (int i = 0; i < 16; i++){
 122:	872a                	mv	a4,a0
 124:	4781                	li	a5,0
 126:	6605                	lui	a2,0x1
 128:	46c1                	li	a3,16
        pages[i * PG_SIZE] = i;
 12a:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 16; i++){
 12e:	2785                	addiw	a5,a5,1
 130:	9732                	add	a4,a4,a2
 132:	fed79ce3          	bne	a5,a3,12a <SCFIFO_test+0x1a>
    }
    // RAM: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 15
    pages[16 * PG_SIZE] = 16;
 136:	67c1                	lui	a5,0x10
 138:	97aa                	add	a5,a5,a0
 13a:	4741                	li	a4,16
 13c:	00e78023          	sb	a4,0(a5) # 10000 <__global_pointer$+0xec1f>
    // RAM: 16 1 2 3 4 5 6 7 8 9 10 11 12 13 15
    pages[1 * PG_SIZE] = 1;
 140:	6785                	lui	a5,0x1
 142:	97aa                	add	a5,a5,a0
 144:	4705                	li	a4,1
 146:	00e78023          	sb	a4,0(a5) # 1000 <__BSS_END__+0x400>
    pages[17 * PG_SIZE] = 17; // should replace page #2 - check kernel print
 14a:	67c5                	lui	a5,0x11
 14c:	953e                	add	a0,a0,a5
 14e:	47c5                	li	a5,17
 150:	00f50023          	sb	a5,0(a0) # 12000 <__global_pointer$+0x10c1f>
}
 154:	60a2                	ld	ra,8(sp)
 156:	6402                	ld	s0,0(sp)
 158:	0141                	addi	sp,sp,16
 15a:	8082                	ret

000000000000015c <NONE_test>:

void NONE_test(){
 15c:	1141                	addi	sp,sp,-16
 15e:	e406                	sd	ra,8(sp)
 160:	e022                	sd	s0,0(sp)
 162:	0800                	addi	s0,sp,16
    char *pages = malloc(PG_SIZE * 17);
 164:	6545                	lui	a0,0x11
 166:	00001097          	auipc	ra,0x1
 16a:	858080e7          	jalr	-1960(ra) # 9be <malloc>
    for (int i = 0; i < 17; i++){
 16e:	872a                	mv	a4,a0
 170:	4781                	li	a5,0
 172:	6605                	lui	a2,0x1
 174:	46c5                	li	a3,17
        pages[i * PG_SIZE] = i;
 176:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 17; i++){
 17a:	2785                	addiw	a5,a5,1
 17c:	9732                	add	a4,a4,a2
 17e:	fed79ce3          	bne	a5,a3,176 <NONE_test+0x1a>
    }
    printf("pages[16 * PG_SIZE] = %d\n", pages[16 * PG_SIZE]); // should not be 16
 182:	67c1                	lui	a5,0x10
 184:	953e                	add	a0,a0,a5
 186:	00054583          	lbu	a1,0(a0) # 11000 <__global_pointer$+0xfc1f>
 18a:	00001517          	auipc	a0,0x1
 18e:	96650513          	addi	a0,a0,-1690 # af0 <malloc+0x132>
 192:	00000097          	auipc	ra,0x0
 196:	76e080e7          	jalr	1902(ra) # 900 <printf>
}
 19a:	60a2                	ld	ra,8(sp)
 19c:	6402                	ld	s0,0(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret

00000000000001a2 <fork_test>:

void fork_test(){
 1a2:	715d                	addi	sp,sp,-80
 1a4:	e486                	sd	ra,72(sp)
 1a6:	e0a2                	sd	s0,64(sp)
 1a8:	fc26                	sd	s1,56(sp)
 1aa:	f84a                	sd	s2,48(sp)
 1ac:	f44e                	sd	s3,40(sp)
 1ae:	f052                	sd	s4,32(sp)
 1b0:	ec56                	sd	s5,24(sp)
 1b2:	e85a                	sd	s6,16(sp)
 1b4:	0880                	addi	s0,sp,80
    char *pages = malloc(PG_SIZE * 17);
 1b6:	6545                	lui	a0,0x11
 1b8:	00001097          	auipc	ra,0x1
 1bc:	806080e7          	jalr	-2042(ra) # 9be <malloc>
 1c0:	89aa                	mv	s3,a0
 1c2:	872a                	mv	a4,a0
    for (int i = 0; i < 17; i++){
 1c4:	4781                	li	a5,0
 1c6:	6605                	lui	a2,0x1
 1c8:	46c5                	li	a3,17
        pages[i * PG_SIZE] = i;
 1ca:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 17; i++){
 1ce:	2785                	addiw	a5,a5,1
 1d0:	9732                	add	a4,a4,a2
 1d2:	fed79ce3          	bne	a5,a3,1ca <fork_test+0x28>
    }
    printf("\nEND OF SHTRUDELS\n");
 1d6:	00001517          	auipc	a0,0x1
 1da:	93a50513          	addi	a0,a0,-1734 # b10 <malloc+0x152>
 1de:	00000097          	auipc	ra,0x0
 1e2:	722080e7          	jalr	1826(ra) # 900 <printf>
 1e6:	894e                	mv	s2,s3
    for (int i = 0; i < 17; i++){
 1e8:	4481                	li	s1,0
        printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 1ea:	00001b17          	auipc	s6,0x1
 1ee:	93eb0b13          	addi	s6,s6,-1730 # b28 <malloc+0x16a>
    for (int i = 0; i < 17; i++){
 1f2:	6a85                	lui	s5,0x1
 1f4:	4a45                	li	s4,17
        printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 1f6:	00094603          	lbu	a2,0(s2)
 1fa:	85a6                	mv	a1,s1
 1fc:	855a                	mv	a0,s6
 1fe:	00000097          	auipc	ra,0x0
 202:	702080e7          	jalr	1794(ra) # 900 <printf>
    for (int i = 0; i < 17; i++){
 206:	2485                	addiw	s1,s1,1
 208:	9956                	add	s2,s2,s5
 20a:	ff4496e3          	bne	s1,s4,1f6 <fork_test+0x54>
    }
    printf("###FORKING###\n");
 20e:	00001517          	auipc	a0,0x1
 212:	93a50513          	addi	a0,a0,-1734 # b48 <malloc+0x18a>
 216:	00000097          	auipc	ra,0x0
 21a:	6ea080e7          	jalr	1770(ra) # 900 <printf>
    int pid = fork();
 21e:	00000097          	auipc	ra,0x0
 222:	362080e7          	jalr	866(ra) # 580 <fork>
 226:	84aa                	mv	s1,a0
    if(pid == 0){
 228:	ed05                	bnez	a0,260 <fork_test+0xbe>
        printf("###CHILD###\n");
 22a:	00001517          	auipc	a0,0x1
 22e:	92e50513          	addi	a0,a0,-1746 # b58 <malloc+0x19a>
 232:	00000097          	auipc	ra,0x0
 236:	6ce080e7          	jalr	1742(ra) # 900 <printf>
        for (int i = 0; i < 17; i++){
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 23a:	00001a97          	auipc	s5,0x1
 23e:	8eea8a93          	addi	s5,s5,-1810 # b28 <malloc+0x16a>
        for (int i = 0; i < 17; i++){
 242:	6a05                	lui	s4,0x1
 244:	4945                	li	s2,17
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 246:	0009c603          	lbu	a2,0(s3)
 24a:	85a6                	mv	a1,s1
 24c:	8556                	mv	a0,s5
 24e:	00000097          	auipc	ra,0x0
 252:	6b2080e7          	jalr	1714(ra) # 900 <printf>
        for (int i = 0; i < 17; i++){
 256:	2485                	addiw	s1,s1,1
 258:	99d2                	add	s3,s3,s4
 25a:	ff2496e3          	bne	s1,s2,246 <fork_test+0xa4>
 25e:	a039                	j	26c <fork_test+0xca>
        }
    }
    else{
        int status;
        wait(&status);
 260:	fbc40513          	addi	a0,s0,-68
 264:	00000097          	auipc	ra,0x0
 268:	32c080e7          	jalr	812(ra) # 590 <wait>
    }
}
 26c:	60a6                	ld	ra,72(sp)
 26e:	6406                	ld	s0,64(sp)
 270:	74e2                	ld	s1,56(sp)
 272:	7942                	ld	s2,48(sp)
 274:	79a2                	ld	s3,40(sp)
 276:	7a02                	ld	s4,32(sp)
 278:	6ae2                	ld	s5,24(sp)
 27a:	6b42                	ld	s6,16(sp)
 27c:	6161                	addi	sp,sp,80
 27e:	8082                	ret

0000000000000280 <exec_test>:

void exec_test(){
 280:	1101                	addi	sp,sp,-32
 282:	ec06                	sd	ra,24(sp)
 284:	e822                	sd	s0,16(sp)
 286:	e426                	sd	s1,8(sp)
 288:	1000                	addi	s0,sp,32
    char *pages = malloc(PG_SIZE * 17);
 28a:	6545                	lui	a0,0x11
 28c:	00000097          	auipc	ra,0x0
 290:	732080e7          	jalr	1842(ra) # 9be <malloc>
 294:	84aa                	mv	s1,a0
    for (int i = 0; i < 17; i++){
 296:	872a                	mv	a4,a0
 298:	4781                	li	a5,0
 29a:	6605                	lui	a2,0x1
 29c:	46c5                	li	a3,17
        pages[i * PG_SIZE] = i;
 29e:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 17; i++){
 2a2:	2785                	addiw	a5,a5,1
 2a4:	9732                	add	a4,a4,a2
 2a6:	fed79ce3          	bne	a5,a3,29e <exec_test+0x1e>
    }
    printf("exec output: %d\n", exec("exec_fail", 0)); // hope exec will fail and return -1
 2aa:	4581                	li	a1,0
 2ac:	00001517          	auipc	a0,0x1
 2b0:	8bc50513          	addi	a0,a0,-1860 # b68 <malloc+0x1aa>
 2b4:	00000097          	auipc	ra,0x0
 2b8:	30c080e7          	jalr	780(ra) # 5c0 <exec>
 2bc:	85aa                	mv	a1,a0
 2be:	00001517          	auipc	a0,0x1
 2c2:	8ba50513          	addi	a0,a0,-1862 # b78 <malloc+0x1ba>
 2c6:	00000097          	auipc	ra,0x0
 2ca:	63a080e7          	jalr	1594(ra) # 900 <printf>
    printf("pages[10 * PG_SIZE] = %d\n", pages[10 * PG_SIZE]); // should print 10
 2ce:	67a9                	lui	a5,0xa
 2d0:	94be                	add	s1,s1,a5
 2d2:	0004c583          	lbu	a1,0(s1)
 2d6:	00001517          	auipc	a0,0x1
 2da:	8ba50513          	addi	a0,a0,-1862 # b90 <malloc+0x1d2>
 2de:	00000097          	auipc	ra,0x0
 2e2:	622080e7          	jalr	1570(ra) # 900 <printf>
}
 2e6:	60e2                	ld	ra,24(sp)
 2e8:	6442                	ld	s0,16(sp)
 2ea:	64a2                	ld	s1,8(sp)
 2ec:	6105                	addi	sp,sp,32
 2ee:	8082                	ret

00000000000002f0 <main>:

int main()
{
 2f0:	1141                	addi	sp,sp,-16
 2f2:	e406                	sd	ra,8(sp)
 2f4:	e022                	sd	s0,0(sp)
 2f6:	0800                	addi	s0,sp,16
    printf("hello test_task3\n");
 2f8:	00001517          	auipc	a0,0x1
 2fc:	8b850513          	addi	a0,a0,-1864 # bb0 <malloc+0x1f2>
 300:	00000097          	auipc	ra,0x0
 304:	600080e7          	jalr	1536(ra) # 900 <printf>
    // userstarts should pass???
    //sanity_test();
    //NFUA_LAPA_tests();
    // SCFIFO_test();
    // NONE_test();
    fork_test();
 308:	00000097          	auipc	ra,0x0
 30c:	e9a080e7          	jalr	-358(ra) # 1a2 <fork_test>
   // exec_test();
    exit(0);
 310:	4501                	li	a0,0
 312:	00000097          	auipc	ra,0x0
 316:	276080e7          	jalr	630(ra) # 588 <exit>

000000000000031a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 31a:	1141                	addi	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 320:	87aa                	mv	a5,a0
 322:	0585                	addi	a1,a1,1
 324:	0785                	addi	a5,a5,1
 326:	fff5c703          	lbu	a4,-1(a1)
 32a:	fee78fa3          	sb	a4,-1(a5) # 9fff <__global_pointer$+0x8c1e>
 32e:	fb75                	bnez	a4,322 <strcpy+0x8>
    ;
  return os;
}
 330:	6422                	ld	s0,8(sp)
 332:	0141                	addi	sp,sp,16
 334:	8082                	ret

0000000000000336 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 336:	1141                	addi	sp,sp,-16
 338:	e422                	sd	s0,8(sp)
 33a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 33c:	00054783          	lbu	a5,0(a0)
 340:	cb91                	beqz	a5,354 <strcmp+0x1e>
 342:	0005c703          	lbu	a4,0(a1)
 346:	00f71763          	bne	a4,a5,354 <strcmp+0x1e>
    p++, q++;
 34a:	0505                	addi	a0,a0,1
 34c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 34e:	00054783          	lbu	a5,0(a0)
 352:	fbe5                	bnez	a5,342 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 354:	0005c503          	lbu	a0,0(a1)
}
 358:	40a7853b          	subw	a0,a5,a0
 35c:	6422                	ld	s0,8(sp)
 35e:	0141                	addi	sp,sp,16
 360:	8082                	ret

0000000000000362 <strlen>:

uint
strlen(const char *s)
{
 362:	1141                	addi	sp,sp,-16
 364:	e422                	sd	s0,8(sp)
 366:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 368:	00054783          	lbu	a5,0(a0)
 36c:	cf91                	beqz	a5,388 <strlen+0x26>
 36e:	0505                	addi	a0,a0,1
 370:	87aa                	mv	a5,a0
 372:	4685                	li	a3,1
 374:	9e89                	subw	a3,a3,a0
 376:	00f6853b          	addw	a0,a3,a5
 37a:	0785                	addi	a5,a5,1
 37c:	fff7c703          	lbu	a4,-1(a5)
 380:	fb7d                	bnez	a4,376 <strlen+0x14>
    ;
  return n;
}
 382:	6422                	ld	s0,8(sp)
 384:	0141                	addi	sp,sp,16
 386:	8082                	ret
  for(n = 0; s[n]; n++)
 388:	4501                	li	a0,0
 38a:	bfe5                	j	382 <strlen+0x20>

000000000000038c <memset>:

void*
memset(void *dst, int c, uint n)
{
 38c:	1141                	addi	sp,sp,-16
 38e:	e422                	sd	s0,8(sp)
 390:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 392:	ca19                	beqz	a2,3a8 <memset+0x1c>
 394:	87aa                	mv	a5,a0
 396:	1602                	slli	a2,a2,0x20
 398:	9201                	srli	a2,a2,0x20
 39a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 39e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3a2:	0785                	addi	a5,a5,1
 3a4:	fee79de3          	bne	a5,a4,39e <memset+0x12>
  }
  return dst;
}
 3a8:	6422                	ld	s0,8(sp)
 3aa:	0141                	addi	sp,sp,16
 3ac:	8082                	ret

00000000000003ae <strchr>:

char*
strchr(const char *s, char c)
{
 3ae:	1141                	addi	sp,sp,-16
 3b0:	e422                	sd	s0,8(sp)
 3b2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3b4:	00054783          	lbu	a5,0(a0)
 3b8:	cb99                	beqz	a5,3ce <strchr+0x20>
    if(*s == c)
 3ba:	00f58763          	beq	a1,a5,3c8 <strchr+0x1a>
  for(; *s; s++)
 3be:	0505                	addi	a0,a0,1
 3c0:	00054783          	lbu	a5,0(a0)
 3c4:	fbfd                	bnez	a5,3ba <strchr+0xc>
      return (char*)s;
  return 0;
 3c6:	4501                	li	a0,0
}
 3c8:	6422                	ld	s0,8(sp)
 3ca:	0141                	addi	sp,sp,16
 3cc:	8082                	ret
  return 0;
 3ce:	4501                	li	a0,0
 3d0:	bfe5                	j	3c8 <strchr+0x1a>

00000000000003d2 <gets>:

char*
gets(char *buf, int max)
{
 3d2:	711d                	addi	sp,sp,-96
 3d4:	ec86                	sd	ra,88(sp)
 3d6:	e8a2                	sd	s0,80(sp)
 3d8:	e4a6                	sd	s1,72(sp)
 3da:	e0ca                	sd	s2,64(sp)
 3dc:	fc4e                	sd	s3,56(sp)
 3de:	f852                	sd	s4,48(sp)
 3e0:	f456                	sd	s5,40(sp)
 3e2:	f05a                	sd	s6,32(sp)
 3e4:	ec5e                	sd	s7,24(sp)
 3e6:	1080                	addi	s0,sp,96
 3e8:	8baa                	mv	s7,a0
 3ea:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3ec:	892a                	mv	s2,a0
 3ee:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3f0:	4aa9                	li	s5,10
 3f2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3f4:	89a6                	mv	s3,s1
 3f6:	2485                	addiw	s1,s1,1
 3f8:	0344d863          	bge	s1,s4,428 <gets+0x56>
    cc = read(0, &c, 1);
 3fc:	4605                	li	a2,1
 3fe:	faf40593          	addi	a1,s0,-81
 402:	4501                	li	a0,0
 404:	00000097          	auipc	ra,0x0
 408:	19c080e7          	jalr	412(ra) # 5a0 <read>
    if(cc < 1)
 40c:	00a05e63          	blez	a0,428 <gets+0x56>
    buf[i++] = c;
 410:	faf44783          	lbu	a5,-81(s0)
 414:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 418:	01578763          	beq	a5,s5,426 <gets+0x54>
 41c:	0905                	addi	s2,s2,1
 41e:	fd679be3          	bne	a5,s6,3f4 <gets+0x22>
  for(i=0; i+1 < max; ){
 422:	89a6                	mv	s3,s1
 424:	a011                	j	428 <gets+0x56>
 426:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 428:	99de                	add	s3,s3,s7
 42a:	00098023          	sb	zero,0(s3)
  return buf;
}
 42e:	855e                	mv	a0,s7
 430:	60e6                	ld	ra,88(sp)
 432:	6446                	ld	s0,80(sp)
 434:	64a6                	ld	s1,72(sp)
 436:	6906                	ld	s2,64(sp)
 438:	79e2                	ld	s3,56(sp)
 43a:	7a42                	ld	s4,48(sp)
 43c:	7aa2                	ld	s5,40(sp)
 43e:	7b02                	ld	s6,32(sp)
 440:	6be2                	ld	s7,24(sp)
 442:	6125                	addi	sp,sp,96
 444:	8082                	ret

0000000000000446 <stat>:

int
stat(const char *n, struct stat *st)
{
 446:	1101                	addi	sp,sp,-32
 448:	ec06                	sd	ra,24(sp)
 44a:	e822                	sd	s0,16(sp)
 44c:	e426                	sd	s1,8(sp)
 44e:	e04a                	sd	s2,0(sp)
 450:	1000                	addi	s0,sp,32
 452:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 454:	4581                	li	a1,0
 456:	00000097          	auipc	ra,0x0
 45a:	172080e7          	jalr	370(ra) # 5c8 <open>
  if(fd < 0)
 45e:	02054563          	bltz	a0,488 <stat+0x42>
 462:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 464:	85ca                	mv	a1,s2
 466:	00000097          	auipc	ra,0x0
 46a:	17a080e7          	jalr	378(ra) # 5e0 <fstat>
 46e:	892a                	mv	s2,a0
  close(fd);
 470:	8526                	mv	a0,s1
 472:	00000097          	auipc	ra,0x0
 476:	13e080e7          	jalr	318(ra) # 5b0 <close>
  return r;
}
 47a:	854a                	mv	a0,s2
 47c:	60e2                	ld	ra,24(sp)
 47e:	6442                	ld	s0,16(sp)
 480:	64a2                	ld	s1,8(sp)
 482:	6902                	ld	s2,0(sp)
 484:	6105                	addi	sp,sp,32
 486:	8082                	ret
    return -1;
 488:	597d                	li	s2,-1
 48a:	bfc5                	j	47a <stat+0x34>

000000000000048c <atoi>:

int
atoi(const char *s)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e422                	sd	s0,8(sp)
 490:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 492:	00054603          	lbu	a2,0(a0)
 496:	fd06079b          	addiw	a5,a2,-48
 49a:	0ff7f793          	andi	a5,a5,255
 49e:	4725                	li	a4,9
 4a0:	02f76963          	bltu	a4,a5,4d2 <atoi+0x46>
 4a4:	86aa                	mv	a3,a0
  n = 0;
 4a6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4a8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4aa:	0685                	addi	a3,a3,1
 4ac:	0025179b          	slliw	a5,a0,0x2
 4b0:	9fa9                	addw	a5,a5,a0
 4b2:	0017979b          	slliw	a5,a5,0x1
 4b6:	9fb1                	addw	a5,a5,a2
 4b8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4bc:	0006c603          	lbu	a2,0(a3) # 1000 <__BSS_END__+0x400>
 4c0:	fd06071b          	addiw	a4,a2,-48
 4c4:	0ff77713          	andi	a4,a4,255
 4c8:	fee5f1e3          	bgeu	a1,a4,4aa <atoi+0x1e>
  return n;
}
 4cc:	6422                	ld	s0,8(sp)
 4ce:	0141                	addi	sp,sp,16
 4d0:	8082                	ret
  n = 0;
 4d2:	4501                	li	a0,0
 4d4:	bfe5                	j	4cc <atoi+0x40>

00000000000004d6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4d6:	1141                	addi	sp,sp,-16
 4d8:	e422                	sd	s0,8(sp)
 4da:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4dc:	02b57463          	bgeu	a0,a1,504 <memmove+0x2e>
    while(n-- > 0)
 4e0:	00c05f63          	blez	a2,4fe <memmove+0x28>
 4e4:	1602                	slli	a2,a2,0x20
 4e6:	9201                	srli	a2,a2,0x20
 4e8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4ec:	872a                	mv	a4,a0
      *dst++ = *src++;
 4ee:	0585                	addi	a1,a1,1
 4f0:	0705                	addi	a4,a4,1
 4f2:	fff5c683          	lbu	a3,-1(a1)
 4f6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4fa:	fee79ae3          	bne	a5,a4,4ee <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4fe:	6422                	ld	s0,8(sp)
 500:	0141                	addi	sp,sp,16
 502:	8082                	ret
    dst += n;
 504:	00c50733          	add	a4,a0,a2
    src += n;
 508:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 50a:	fec05ae3          	blez	a2,4fe <memmove+0x28>
 50e:	fff6079b          	addiw	a5,a2,-1
 512:	1782                	slli	a5,a5,0x20
 514:	9381                	srli	a5,a5,0x20
 516:	fff7c793          	not	a5,a5
 51a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 51c:	15fd                	addi	a1,a1,-1
 51e:	177d                	addi	a4,a4,-1
 520:	0005c683          	lbu	a3,0(a1)
 524:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 528:	fee79ae3          	bne	a5,a4,51c <memmove+0x46>
 52c:	bfc9                	j	4fe <memmove+0x28>

000000000000052e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 52e:	1141                	addi	sp,sp,-16
 530:	e422                	sd	s0,8(sp)
 532:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 534:	ca05                	beqz	a2,564 <memcmp+0x36>
 536:	fff6069b          	addiw	a3,a2,-1
 53a:	1682                	slli	a3,a3,0x20
 53c:	9281                	srli	a3,a3,0x20
 53e:	0685                	addi	a3,a3,1
 540:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 542:	00054783          	lbu	a5,0(a0)
 546:	0005c703          	lbu	a4,0(a1)
 54a:	00e79863          	bne	a5,a4,55a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 54e:	0505                	addi	a0,a0,1
    p2++;
 550:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 552:	fed518e3          	bne	a0,a3,542 <memcmp+0x14>
  }
  return 0;
 556:	4501                	li	a0,0
 558:	a019                	j	55e <memcmp+0x30>
      return *p1 - *p2;
 55a:	40e7853b          	subw	a0,a5,a4
}
 55e:	6422                	ld	s0,8(sp)
 560:	0141                	addi	sp,sp,16
 562:	8082                	ret
  return 0;
 564:	4501                	li	a0,0
 566:	bfe5                	j	55e <memcmp+0x30>

0000000000000568 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 568:	1141                	addi	sp,sp,-16
 56a:	e406                	sd	ra,8(sp)
 56c:	e022                	sd	s0,0(sp)
 56e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 570:	00000097          	auipc	ra,0x0
 574:	f66080e7          	jalr	-154(ra) # 4d6 <memmove>
}
 578:	60a2                	ld	ra,8(sp)
 57a:	6402                	ld	s0,0(sp)
 57c:	0141                	addi	sp,sp,16
 57e:	8082                	ret

0000000000000580 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 580:	4885                	li	a7,1
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <exit>:
.global exit
exit:
 li a7, SYS_exit
 588:	4889                	li	a7,2
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <wait>:
.global wait
wait:
 li a7, SYS_wait
 590:	488d                	li	a7,3
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 598:	4891                	li	a7,4
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <read>:
.global read
read:
 li a7, SYS_read
 5a0:	4895                	li	a7,5
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <write>:
.global write
write:
 li a7, SYS_write
 5a8:	48c1                	li	a7,16
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <close>:
.global close
close:
 li a7, SYS_close
 5b0:	48d5                	li	a7,21
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5b8:	4899                	li	a7,6
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5c0:	489d                	li	a7,7
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <open>:
.global open
open:
 li a7, SYS_open
 5c8:	48bd                	li	a7,15
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5d0:	48c5                	li	a7,17
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5d8:	48c9                	li	a7,18
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5e0:	48a1                	li	a7,8
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <link>:
.global link
link:
 li a7, SYS_link
 5e8:	48cd                	li	a7,19
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5f0:	48d1                	li	a7,20
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5f8:	48a5                	li	a7,9
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <dup>:
.global dup
dup:
 li a7, SYS_dup
 600:	48a9                	li	a7,10
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 608:	48ad                	li	a7,11
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 610:	48b1                	li	a7,12
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 618:	48b5                	li	a7,13
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 620:	48b9                	li	a7,14
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 628:	1101                	addi	sp,sp,-32
 62a:	ec06                	sd	ra,24(sp)
 62c:	e822                	sd	s0,16(sp)
 62e:	1000                	addi	s0,sp,32
 630:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 634:	4605                	li	a2,1
 636:	fef40593          	addi	a1,s0,-17
 63a:	00000097          	auipc	ra,0x0
 63e:	f6e080e7          	jalr	-146(ra) # 5a8 <write>
}
 642:	60e2                	ld	ra,24(sp)
 644:	6442                	ld	s0,16(sp)
 646:	6105                	addi	sp,sp,32
 648:	8082                	ret

000000000000064a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 64a:	7139                	addi	sp,sp,-64
 64c:	fc06                	sd	ra,56(sp)
 64e:	f822                	sd	s0,48(sp)
 650:	f426                	sd	s1,40(sp)
 652:	f04a                	sd	s2,32(sp)
 654:	ec4e                	sd	s3,24(sp)
 656:	0080                	addi	s0,sp,64
 658:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 65a:	c299                	beqz	a3,660 <printint+0x16>
 65c:	0805c863          	bltz	a1,6ec <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 660:	2581                	sext.w	a1,a1
  neg = 0;
 662:	4881                	li	a7,0
 664:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 668:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 66a:	2601                	sext.w	a2,a2
 66c:	00000517          	auipc	a0,0x0
 670:	56450513          	addi	a0,a0,1380 # bd0 <digits>
 674:	883a                	mv	a6,a4
 676:	2705                	addiw	a4,a4,1
 678:	02c5f7bb          	remuw	a5,a1,a2
 67c:	1782                	slli	a5,a5,0x20
 67e:	9381                	srli	a5,a5,0x20
 680:	97aa                	add	a5,a5,a0
 682:	0007c783          	lbu	a5,0(a5)
 686:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 68a:	0005879b          	sext.w	a5,a1
 68e:	02c5d5bb          	divuw	a1,a1,a2
 692:	0685                	addi	a3,a3,1
 694:	fec7f0e3          	bgeu	a5,a2,674 <printint+0x2a>
  if(neg)
 698:	00088b63          	beqz	a7,6ae <printint+0x64>
    buf[i++] = '-';
 69c:	fd040793          	addi	a5,s0,-48
 6a0:	973e                	add	a4,a4,a5
 6a2:	02d00793          	li	a5,45
 6a6:	fef70823          	sb	a5,-16(a4)
 6aa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6ae:	02e05863          	blez	a4,6de <printint+0x94>
 6b2:	fc040793          	addi	a5,s0,-64
 6b6:	00e78933          	add	s2,a5,a4
 6ba:	fff78993          	addi	s3,a5,-1
 6be:	99ba                	add	s3,s3,a4
 6c0:	377d                	addiw	a4,a4,-1
 6c2:	1702                	slli	a4,a4,0x20
 6c4:	9301                	srli	a4,a4,0x20
 6c6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ca:	fff94583          	lbu	a1,-1(s2)
 6ce:	8526                	mv	a0,s1
 6d0:	00000097          	auipc	ra,0x0
 6d4:	f58080e7          	jalr	-168(ra) # 628 <putc>
  while(--i >= 0)
 6d8:	197d                	addi	s2,s2,-1
 6da:	ff3918e3          	bne	s2,s3,6ca <printint+0x80>
}
 6de:	70e2                	ld	ra,56(sp)
 6e0:	7442                	ld	s0,48(sp)
 6e2:	74a2                	ld	s1,40(sp)
 6e4:	7902                	ld	s2,32(sp)
 6e6:	69e2                	ld	s3,24(sp)
 6e8:	6121                	addi	sp,sp,64
 6ea:	8082                	ret
    x = -xx;
 6ec:	40b005bb          	negw	a1,a1
    neg = 1;
 6f0:	4885                	li	a7,1
    x = -xx;
 6f2:	bf8d                	j	664 <printint+0x1a>

00000000000006f4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6f4:	7119                	addi	sp,sp,-128
 6f6:	fc86                	sd	ra,120(sp)
 6f8:	f8a2                	sd	s0,112(sp)
 6fa:	f4a6                	sd	s1,104(sp)
 6fc:	f0ca                	sd	s2,96(sp)
 6fe:	ecce                	sd	s3,88(sp)
 700:	e8d2                	sd	s4,80(sp)
 702:	e4d6                	sd	s5,72(sp)
 704:	e0da                	sd	s6,64(sp)
 706:	fc5e                	sd	s7,56(sp)
 708:	f862                	sd	s8,48(sp)
 70a:	f466                	sd	s9,40(sp)
 70c:	f06a                	sd	s10,32(sp)
 70e:	ec6e                	sd	s11,24(sp)
 710:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 712:	0005c903          	lbu	s2,0(a1)
 716:	18090f63          	beqz	s2,8b4 <vprintf+0x1c0>
 71a:	8aaa                	mv	s5,a0
 71c:	8b32                	mv	s6,a2
 71e:	00158493          	addi	s1,a1,1
  state = 0;
 722:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 724:	02500a13          	li	s4,37
      if(c == 'd'){
 728:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 72c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 730:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 734:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 738:	00000b97          	auipc	s7,0x0
 73c:	498b8b93          	addi	s7,s7,1176 # bd0 <digits>
 740:	a839                	j	75e <vprintf+0x6a>
        putc(fd, c);
 742:	85ca                	mv	a1,s2
 744:	8556                	mv	a0,s5
 746:	00000097          	auipc	ra,0x0
 74a:	ee2080e7          	jalr	-286(ra) # 628 <putc>
 74e:	a019                	j	754 <vprintf+0x60>
    } else if(state == '%'){
 750:	01498f63          	beq	s3,s4,76e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 754:	0485                	addi	s1,s1,1
 756:	fff4c903          	lbu	s2,-1(s1)
 75a:	14090d63          	beqz	s2,8b4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 75e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 762:	fe0997e3          	bnez	s3,750 <vprintf+0x5c>
      if(c == '%'){
 766:	fd479ee3          	bne	a5,s4,742 <vprintf+0x4e>
        state = '%';
 76a:	89be                	mv	s3,a5
 76c:	b7e5                	j	754 <vprintf+0x60>
      if(c == 'd'){
 76e:	05878063          	beq	a5,s8,7ae <vprintf+0xba>
      } else if(c == 'l') {
 772:	05978c63          	beq	a5,s9,7ca <vprintf+0xd6>
      } else if(c == 'x') {
 776:	07a78863          	beq	a5,s10,7e6 <vprintf+0xf2>
      } else if(c == 'p') {
 77a:	09b78463          	beq	a5,s11,802 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 77e:	07300713          	li	a4,115
 782:	0ce78663          	beq	a5,a4,84e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 786:	06300713          	li	a4,99
 78a:	0ee78e63          	beq	a5,a4,886 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 78e:	11478863          	beq	a5,s4,89e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 792:	85d2                	mv	a1,s4
 794:	8556                	mv	a0,s5
 796:	00000097          	auipc	ra,0x0
 79a:	e92080e7          	jalr	-366(ra) # 628 <putc>
        putc(fd, c);
 79e:	85ca                	mv	a1,s2
 7a0:	8556                	mv	a0,s5
 7a2:	00000097          	auipc	ra,0x0
 7a6:	e86080e7          	jalr	-378(ra) # 628 <putc>
      }
      state = 0;
 7aa:	4981                	li	s3,0
 7ac:	b765                	j	754 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7ae:	008b0913          	addi	s2,s6,8
 7b2:	4685                	li	a3,1
 7b4:	4629                	li	a2,10
 7b6:	000b2583          	lw	a1,0(s6)
 7ba:	8556                	mv	a0,s5
 7bc:	00000097          	auipc	ra,0x0
 7c0:	e8e080e7          	jalr	-370(ra) # 64a <printint>
 7c4:	8b4a                	mv	s6,s2
      state = 0;
 7c6:	4981                	li	s3,0
 7c8:	b771                	j	754 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7ca:	008b0913          	addi	s2,s6,8
 7ce:	4681                	li	a3,0
 7d0:	4629                	li	a2,10
 7d2:	000b2583          	lw	a1,0(s6)
 7d6:	8556                	mv	a0,s5
 7d8:	00000097          	auipc	ra,0x0
 7dc:	e72080e7          	jalr	-398(ra) # 64a <printint>
 7e0:	8b4a                	mv	s6,s2
      state = 0;
 7e2:	4981                	li	s3,0
 7e4:	bf85                	j	754 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7e6:	008b0913          	addi	s2,s6,8
 7ea:	4681                	li	a3,0
 7ec:	4641                	li	a2,16
 7ee:	000b2583          	lw	a1,0(s6)
 7f2:	8556                	mv	a0,s5
 7f4:	00000097          	auipc	ra,0x0
 7f8:	e56080e7          	jalr	-426(ra) # 64a <printint>
 7fc:	8b4a                	mv	s6,s2
      state = 0;
 7fe:	4981                	li	s3,0
 800:	bf91                	j	754 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 802:	008b0793          	addi	a5,s6,8
 806:	f8f43423          	sd	a5,-120(s0)
 80a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 80e:	03000593          	li	a1,48
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	e14080e7          	jalr	-492(ra) # 628 <putc>
  putc(fd, 'x');
 81c:	85ea                	mv	a1,s10
 81e:	8556                	mv	a0,s5
 820:	00000097          	auipc	ra,0x0
 824:	e08080e7          	jalr	-504(ra) # 628 <putc>
 828:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 82a:	03c9d793          	srli	a5,s3,0x3c
 82e:	97de                	add	a5,a5,s7
 830:	0007c583          	lbu	a1,0(a5)
 834:	8556                	mv	a0,s5
 836:	00000097          	auipc	ra,0x0
 83a:	df2080e7          	jalr	-526(ra) # 628 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 83e:	0992                	slli	s3,s3,0x4
 840:	397d                	addiw	s2,s2,-1
 842:	fe0914e3          	bnez	s2,82a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 846:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 84a:	4981                	li	s3,0
 84c:	b721                	j	754 <vprintf+0x60>
        s = va_arg(ap, char*);
 84e:	008b0993          	addi	s3,s6,8
 852:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 856:	02090163          	beqz	s2,878 <vprintf+0x184>
        while(*s != 0){
 85a:	00094583          	lbu	a1,0(s2)
 85e:	c9a1                	beqz	a1,8ae <vprintf+0x1ba>
          putc(fd, *s);
 860:	8556                	mv	a0,s5
 862:	00000097          	auipc	ra,0x0
 866:	dc6080e7          	jalr	-570(ra) # 628 <putc>
          s++;
 86a:	0905                	addi	s2,s2,1
        while(*s != 0){
 86c:	00094583          	lbu	a1,0(s2)
 870:	f9e5                	bnez	a1,860 <vprintf+0x16c>
        s = va_arg(ap, char*);
 872:	8b4e                	mv	s6,s3
      state = 0;
 874:	4981                	li	s3,0
 876:	bdf9                	j	754 <vprintf+0x60>
          s = "(null)";
 878:	00000917          	auipc	s2,0x0
 87c:	35090913          	addi	s2,s2,848 # bc8 <malloc+0x20a>
        while(*s != 0){
 880:	02800593          	li	a1,40
 884:	bff1                	j	860 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 886:	008b0913          	addi	s2,s6,8
 88a:	000b4583          	lbu	a1,0(s6)
 88e:	8556                	mv	a0,s5
 890:	00000097          	auipc	ra,0x0
 894:	d98080e7          	jalr	-616(ra) # 628 <putc>
 898:	8b4a                	mv	s6,s2
      state = 0;
 89a:	4981                	li	s3,0
 89c:	bd65                	j	754 <vprintf+0x60>
        putc(fd, c);
 89e:	85d2                	mv	a1,s4
 8a0:	8556                	mv	a0,s5
 8a2:	00000097          	auipc	ra,0x0
 8a6:	d86080e7          	jalr	-634(ra) # 628 <putc>
      state = 0;
 8aa:	4981                	li	s3,0
 8ac:	b565                	j	754 <vprintf+0x60>
        s = va_arg(ap, char*);
 8ae:	8b4e                	mv	s6,s3
      state = 0;
 8b0:	4981                	li	s3,0
 8b2:	b54d                	j	754 <vprintf+0x60>
    }
  }
}
 8b4:	70e6                	ld	ra,120(sp)
 8b6:	7446                	ld	s0,112(sp)
 8b8:	74a6                	ld	s1,104(sp)
 8ba:	7906                	ld	s2,96(sp)
 8bc:	69e6                	ld	s3,88(sp)
 8be:	6a46                	ld	s4,80(sp)
 8c0:	6aa6                	ld	s5,72(sp)
 8c2:	6b06                	ld	s6,64(sp)
 8c4:	7be2                	ld	s7,56(sp)
 8c6:	7c42                	ld	s8,48(sp)
 8c8:	7ca2                	ld	s9,40(sp)
 8ca:	7d02                	ld	s10,32(sp)
 8cc:	6de2                	ld	s11,24(sp)
 8ce:	6109                	addi	sp,sp,128
 8d0:	8082                	ret

00000000000008d2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8d2:	715d                	addi	sp,sp,-80
 8d4:	ec06                	sd	ra,24(sp)
 8d6:	e822                	sd	s0,16(sp)
 8d8:	1000                	addi	s0,sp,32
 8da:	e010                	sd	a2,0(s0)
 8dc:	e414                	sd	a3,8(s0)
 8de:	e818                	sd	a4,16(s0)
 8e0:	ec1c                	sd	a5,24(s0)
 8e2:	03043023          	sd	a6,32(s0)
 8e6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8ea:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8ee:	8622                	mv	a2,s0
 8f0:	00000097          	auipc	ra,0x0
 8f4:	e04080e7          	jalr	-508(ra) # 6f4 <vprintf>
}
 8f8:	60e2                	ld	ra,24(sp)
 8fa:	6442                	ld	s0,16(sp)
 8fc:	6161                	addi	sp,sp,80
 8fe:	8082                	ret

0000000000000900 <printf>:

void
printf(const char *fmt, ...)
{
 900:	711d                	addi	sp,sp,-96
 902:	ec06                	sd	ra,24(sp)
 904:	e822                	sd	s0,16(sp)
 906:	1000                	addi	s0,sp,32
 908:	e40c                	sd	a1,8(s0)
 90a:	e810                	sd	a2,16(s0)
 90c:	ec14                	sd	a3,24(s0)
 90e:	f018                	sd	a4,32(s0)
 910:	f41c                	sd	a5,40(s0)
 912:	03043823          	sd	a6,48(s0)
 916:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 91a:	00840613          	addi	a2,s0,8
 91e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 922:	85aa                	mv	a1,a0
 924:	4505                	li	a0,1
 926:	00000097          	auipc	ra,0x0
 92a:	dce080e7          	jalr	-562(ra) # 6f4 <vprintf>
}
 92e:	60e2                	ld	ra,24(sp)
 930:	6442                	ld	s0,16(sp)
 932:	6125                	addi	sp,sp,96
 934:	8082                	ret

0000000000000936 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 936:	1141                	addi	sp,sp,-16
 938:	e422                	sd	s0,8(sp)
 93a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 93c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 940:	00000797          	auipc	a5,0x0
 944:	2a87b783          	ld	a5,680(a5) # be8 <freep>
 948:	a805                	j	978 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 94a:	4618                	lw	a4,8(a2)
 94c:	9db9                	addw	a1,a1,a4
 94e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 952:	6398                	ld	a4,0(a5)
 954:	6318                	ld	a4,0(a4)
 956:	fee53823          	sd	a4,-16(a0)
 95a:	a091                	j	99e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 95c:	ff852703          	lw	a4,-8(a0)
 960:	9e39                	addw	a2,a2,a4
 962:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 964:	ff053703          	ld	a4,-16(a0)
 968:	e398                	sd	a4,0(a5)
 96a:	a099                	j	9b0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 96c:	6398                	ld	a4,0(a5)
 96e:	00e7e463          	bltu	a5,a4,976 <free+0x40>
 972:	00e6ea63          	bltu	a3,a4,986 <free+0x50>
{
 976:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 978:	fed7fae3          	bgeu	a5,a3,96c <free+0x36>
 97c:	6398                	ld	a4,0(a5)
 97e:	00e6e463          	bltu	a3,a4,986 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 982:	fee7eae3          	bltu	a5,a4,976 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 986:	ff852583          	lw	a1,-8(a0)
 98a:	6390                	ld	a2,0(a5)
 98c:	02059813          	slli	a6,a1,0x20
 990:	01c85713          	srli	a4,a6,0x1c
 994:	9736                	add	a4,a4,a3
 996:	fae60ae3          	beq	a2,a4,94a <free+0x14>
    bp->s.ptr = p->s.ptr;
 99a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 99e:	4790                	lw	a2,8(a5)
 9a0:	02061593          	slli	a1,a2,0x20
 9a4:	01c5d713          	srli	a4,a1,0x1c
 9a8:	973e                	add	a4,a4,a5
 9aa:	fae689e3          	beq	a3,a4,95c <free+0x26>
  } else
    p->s.ptr = bp;
 9ae:	e394                	sd	a3,0(a5)
  freep = p;
 9b0:	00000717          	auipc	a4,0x0
 9b4:	22f73c23          	sd	a5,568(a4) # be8 <freep>
}
 9b8:	6422                	ld	s0,8(sp)
 9ba:	0141                	addi	sp,sp,16
 9bc:	8082                	ret

00000000000009be <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9be:	7139                	addi	sp,sp,-64
 9c0:	fc06                	sd	ra,56(sp)
 9c2:	f822                	sd	s0,48(sp)
 9c4:	f426                	sd	s1,40(sp)
 9c6:	f04a                	sd	s2,32(sp)
 9c8:	ec4e                	sd	s3,24(sp)
 9ca:	e852                	sd	s4,16(sp)
 9cc:	e456                	sd	s5,8(sp)
 9ce:	e05a                	sd	s6,0(sp)
 9d0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9d2:	02051493          	slli	s1,a0,0x20
 9d6:	9081                	srli	s1,s1,0x20
 9d8:	04bd                	addi	s1,s1,15
 9da:	8091                	srli	s1,s1,0x4
 9dc:	0014899b          	addiw	s3,s1,1
 9e0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9e2:	00000517          	auipc	a0,0x0
 9e6:	20653503          	ld	a0,518(a0) # be8 <freep>
 9ea:	c515                	beqz	a0,a16 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9ec:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ee:	4798                	lw	a4,8(a5)
 9f0:	02977f63          	bgeu	a4,s1,a2e <malloc+0x70>
 9f4:	8a4e                	mv	s4,s3
 9f6:	0009871b          	sext.w	a4,s3
 9fa:	6685                	lui	a3,0x1
 9fc:	00d77363          	bgeu	a4,a3,a02 <malloc+0x44>
 a00:	6a05                	lui	s4,0x1
 a02:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a06:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a0a:	00000917          	auipc	s2,0x0
 a0e:	1de90913          	addi	s2,s2,478 # be8 <freep>
  if(p == (char*)-1)
 a12:	5afd                	li	s5,-1
 a14:	a895                	j	a88 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a16:	00000797          	auipc	a5,0x0
 a1a:	1da78793          	addi	a5,a5,474 # bf0 <base>
 a1e:	00000717          	auipc	a4,0x0
 a22:	1cf73523          	sd	a5,458(a4) # be8 <freep>
 a26:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a28:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a2c:	b7e1                	j	9f4 <malloc+0x36>
      if(p->s.size == nunits)
 a2e:	02e48c63          	beq	s1,a4,a66 <malloc+0xa8>
        p->s.size -= nunits;
 a32:	4137073b          	subw	a4,a4,s3
 a36:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a38:	02071693          	slli	a3,a4,0x20
 a3c:	01c6d713          	srli	a4,a3,0x1c
 a40:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a42:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a46:	00000717          	auipc	a4,0x0
 a4a:	1aa73123          	sd	a0,418(a4) # be8 <freep>
      return (void*)(p + 1);
 a4e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a52:	70e2                	ld	ra,56(sp)
 a54:	7442                	ld	s0,48(sp)
 a56:	74a2                	ld	s1,40(sp)
 a58:	7902                	ld	s2,32(sp)
 a5a:	69e2                	ld	s3,24(sp)
 a5c:	6a42                	ld	s4,16(sp)
 a5e:	6aa2                	ld	s5,8(sp)
 a60:	6b02                	ld	s6,0(sp)
 a62:	6121                	addi	sp,sp,64
 a64:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a66:	6398                	ld	a4,0(a5)
 a68:	e118                	sd	a4,0(a0)
 a6a:	bff1                	j	a46 <malloc+0x88>
  hp->s.size = nu;
 a6c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a70:	0541                	addi	a0,a0,16
 a72:	00000097          	auipc	ra,0x0
 a76:	ec4080e7          	jalr	-316(ra) # 936 <free>
  return freep;
 a7a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a7e:	d971                	beqz	a0,a52 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a80:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a82:	4798                	lw	a4,8(a5)
 a84:	fa9775e3          	bgeu	a4,s1,a2e <malloc+0x70>
    if(p == freep)
 a88:	00093703          	ld	a4,0(s2)
 a8c:	853e                	mv	a0,a5
 a8e:	fef719e3          	bne	a4,a5,a80 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a92:	8552                	mv	a0,s4
 a94:	00000097          	auipc	ra,0x0
 a98:	b7c080e7          	jalr	-1156(ra) # 610 <sbrk>
  if(p == (char*)-1)
 a9c:	fd5518e3          	bne	a0,s5,a6c <malloc+0xae>
        return 0;
 aa0:	4501                	li	a0,0
 aa2:	bf45                	j	a52 <malloc+0x94>
