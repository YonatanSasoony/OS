
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
  1c:	996080e7          	jalr	-1642(ra) # 9ae <malloc>
  20:	8baa                	mv	s7,a0
    printf("Allocated %d pages\n", MAX_PG_NUM);
  22:	45ed                	li	a1,27
  24:	00001517          	auipc	a0,0x1
  28:	a7450513          	addi	a0,a0,-1420 # a98 <malloc+0xea>
  2c:	00001097          	auipc	ra,0x1
  30:	8c4080e7          	jalr	-1852(ra) # 8f0 <printf>

    for (int i = 0; i < MAX_PG_NUM; i++){
  34:	895e                	mv	s2,s7
    printf("Allocated %d pages\n", MAX_PG_NUM);
  36:	89de                	mv	s3,s7
    for (int i = 0; i < MAX_PG_NUM; i++){
  38:	4481                	li	s1,0
        printf("write to page %d: %d\n", i, i);
  3a:	00001b17          	auipc	s6,0x1
  3e:	a76b0b13          	addi	s6,s6,-1418 # ab0 <malloc+0x102>
    for (int i = 0; i < MAX_PG_NUM; i++){
  42:	6a85                	lui	s5,0x1
  44:	4a6d                	li	s4,27
        printf("write to page %d: %d\n", i, i);
  46:	8626                	mv	a2,s1
  48:	85a6                	mv	a1,s1
  4a:	855a                	mv	a0,s6
  4c:	00001097          	auipc	ra,0x1
  50:	8a4080e7          	jalr	-1884(ra) # 8f0 <printf>
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
  66:	a66a8a93          	addi	s5,s5,-1434 # ac8 <malloc+0x11a>
    for (int i = 0; i < MAX_PG_NUM; i++){
  6a:	6a05                	lui	s4,0x1
  6c:	49ed                	li	s3,27
        printf("read from page %d: %d\n", i, pages[i * PG_SIZE]);
  6e:	00094603          	lbu	a2,0(s2)
  72:	85a6                	mv	a1,s1
  74:	8556                	mv	a0,s5
  76:	00001097          	auipc	ra,0x1
  7a:	87a080e7          	jalr	-1926(ra) # 8f0 <printf>
    for (int i = 0; i < MAX_PG_NUM; i++){
  7e:	2485                	addiw	s1,s1,1
  80:	9952                	add	s2,s2,s4
  82:	ff3496e3          	bne	s1,s3,6e <sanity_test+0x6e>
    }
    free(pages);
  86:	855e                	mv	a0,s7
  88:	00001097          	auipc	ra,0x1
  8c:	89e080e7          	jalr	-1890(ra) # 926 <free>
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
  b8:	8fa080e7          	jalr	-1798(ra) # 9ae <malloc>
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
  da:	532080e7          	jalr	1330(ra) # 608 <sleep>
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
  f6:	516080e7          	jalr	1302(ra) # 608 <sleep>
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
 11e:	894080e7          	jalr	-1900(ra) # 9ae <malloc>
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
 13c:	00e78023          	sb	a4,0(a5) # 10000 <__global_pointer$+0xec47>
    // RAM: 16 1 2 3 4 5 6 7 8 9 10 11 12 13 15
    pages[1 * PG_SIZE] = 1;
 140:	6785                	lui	a5,0x1
 142:	97aa                	add	a5,a5,a0
 144:	4705                	li	a4,1
 146:	00e78023          	sb	a4,0(a5) # 1000 <__BSS_END__+0x428>
    pages[17 * PG_SIZE] = 17; // should replace page #2 - check kernel print
 14a:	67c5                	lui	a5,0x11
 14c:	953e                	add	a0,a0,a5
 14e:	47c5                	li	a5,17
 150:	00f50023          	sb	a5,0(a0) # 12000 <__global_pointer$+0x10c47>
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
 16a:	848080e7          	jalr	-1976(ra) # 9ae <malloc>
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
 186:	00054583          	lbu	a1,0(a0) # 11000 <__global_pointer$+0xfc47>
 18a:	00001517          	auipc	a0,0x1
 18e:	95650513          	addi	a0,a0,-1706 # ae0 <malloc+0x132>
 192:	00000097          	auipc	ra,0x0
 196:	75e080e7          	jalr	1886(ra) # 8f0 <printf>
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
 1b8:	00000097          	auipc	ra,0x0
 1bc:	7f6080e7          	jalr	2038(ra) # 9ae <malloc>
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
 1d6:	894e                	mv	s2,s3
    }
    for (int i = 0; i < 17; i++){
 1d8:	4481                	li	s1,0
        printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 1da:	00001b17          	auipc	s6,0x1
 1de:	926b0b13          	addi	s6,s6,-1754 # b00 <malloc+0x152>
    for (int i = 0; i < 17; i++){
 1e2:	6a85                	lui	s5,0x1
 1e4:	4a45                	li	s4,17
        printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 1e6:	00094603          	lbu	a2,0(s2)
 1ea:	85a6                	mv	a1,s1
 1ec:	855a                	mv	a0,s6
 1ee:	00000097          	auipc	ra,0x0
 1f2:	702080e7          	jalr	1794(ra) # 8f0 <printf>
    for (int i = 0; i < 17; i++){
 1f6:	2485                	addiw	s1,s1,1
 1f8:	9956                	add	s2,s2,s5
 1fa:	ff4496e3          	bne	s1,s4,1e6 <fork_test+0x44>
    }
    printf("###FORKING###\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	92250513          	addi	a0,a0,-1758 # b20 <malloc+0x172>
 206:	00000097          	auipc	ra,0x0
 20a:	6ea080e7          	jalr	1770(ra) # 8f0 <printf>
    int pid = fork();
 20e:	00000097          	auipc	ra,0x0
 212:	362080e7          	jalr	866(ra) # 570 <fork>
 216:	84aa                	mv	s1,a0
    if(pid == 0){
 218:	ed05                	bnez	a0,250 <fork_test+0xae>
        printf("###CHILD###\n");
 21a:	00001517          	auipc	a0,0x1
 21e:	91650513          	addi	a0,a0,-1770 # b30 <malloc+0x182>
 222:	00000097          	auipc	ra,0x0
 226:	6ce080e7          	jalr	1742(ra) # 8f0 <printf>
        for (int i = 0; i < 17; i++){
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 22a:	00001a97          	auipc	s5,0x1
 22e:	8d6a8a93          	addi	s5,s5,-1834 # b00 <malloc+0x152>
        for (int i = 0; i < 17; i++){
 232:	6a05                	lui	s4,0x1
 234:	4945                	li	s2,17
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 236:	0009c603          	lbu	a2,0(s3)
 23a:	85a6                	mv	a1,s1
 23c:	8556                	mv	a0,s5
 23e:	00000097          	auipc	ra,0x0
 242:	6b2080e7          	jalr	1714(ra) # 8f0 <printf>
        for (int i = 0; i < 17; i++){
 246:	2485                	addiw	s1,s1,1
 248:	99d2                	add	s3,s3,s4
 24a:	ff2496e3          	bne	s1,s2,236 <fork_test+0x94>
 24e:	a039                	j	25c <fork_test+0xba>
        }
    }
    else{
        int status;
        wait(&status);
 250:	fbc40513          	addi	a0,s0,-68
 254:	00000097          	auipc	ra,0x0
 258:	32c080e7          	jalr	812(ra) # 580 <wait>
    }
}
 25c:	60a6                	ld	ra,72(sp)
 25e:	6406                	ld	s0,64(sp)
 260:	74e2                	ld	s1,56(sp)
 262:	7942                	ld	s2,48(sp)
 264:	79a2                	ld	s3,40(sp)
 266:	7a02                	ld	s4,32(sp)
 268:	6ae2                	ld	s5,24(sp)
 26a:	6b42                	ld	s6,16(sp)
 26c:	6161                	addi	sp,sp,80
 26e:	8082                	ret

0000000000000270 <exec_test>:

void exec_test(){
 270:	1101                	addi	sp,sp,-32
 272:	ec06                	sd	ra,24(sp)
 274:	e822                	sd	s0,16(sp)
 276:	e426                	sd	s1,8(sp)
 278:	1000                	addi	s0,sp,32
    char *pages = malloc(PG_SIZE * 17);
 27a:	6545                	lui	a0,0x11
 27c:	00000097          	auipc	ra,0x0
 280:	732080e7          	jalr	1842(ra) # 9ae <malloc>
 284:	84aa                	mv	s1,a0
    for (int i = 0; i < 17; i++){
 286:	872a                	mv	a4,a0
 288:	4781                	li	a5,0
 28a:	6605                	lui	a2,0x1
 28c:	46c5                	li	a3,17
        pages[i * PG_SIZE] = i;
 28e:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 17; i++){
 292:	2785                	addiw	a5,a5,1
 294:	9732                	add	a4,a4,a2
 296:	fed79ce3          	bne	a5,a3,28e <exec_test+0x1e>
    }
    printf("exec output: %d\n", exec("exec_fail", 0)); // hope exec will fail and return -1
 29a:	4581                	li	a1,0
 29c:	00001517          	auipc	a0,0x1
 2a0:	8a450513          	addi	a0,a0,-1884 # b40 <malloc+0x192>
 2a4:	00000097          	auipc	ra,0x0
 2a8:	30c080e7          	jalr	780(ra) # 5b0 <exec>
 2ac:	85aa                	mv	a1,a0
 2ae:	00001517          	auipc	a0,0x1
 2b2:	8a250513          	addi	a0,a0,-1886 # b50 <malloc+0x1a2>
 2b6:	00000097          	auipc	ra,0x0
 2ba:	63a080e7          	jalr	1594(ra) # 8f0 <printf>
    printf("pages[10 * PG_SIZE] = %d\n", pages[10 * PG_SIZE]); // should print 10
 2be:	67a9                	lui	a5,0xa
 2c0:	94be                	add	s1,s1,a5
 2c2:	0004c583          	lbu	a1,0(s1)
 2c6:	00001517          	auipc	a0,0x1
 2ca:	8a250513          	addi	a0,a0,-1886 # b68 <malloc+0x1ba>
 2ce:	00000097          	auipc	ra,0x0
 2d2:	622080e7          	jalr	1570(ra) # 8f0 <printf>
}
 2d6:	60e2                	ld	ra,24(sp)
 2d8:	6442                	ld	s0,16(sp)
 2da:	64a2                	ld	s1,8(sp)
 2dc:	6105                	addi	sp,sp,32
 2de:	8082                	ret

00000000000002e0 <main>:

int main()
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e406                	sd	ra,8(sp)
 2e4:	e022                	sd	s0,0(sp)
 2e6:	0800                	addi	s0,sp,16
    printf("hello test_task3\n");
 2e8:	00001517          	auipc	a0,0x1
 2ec:	8a050513          	addi	a0,a0,-1888 # b88 <malloc+0x1da>
 2f0:	00000097          	auipc	ra,0x0
 2f4:	600080e7          	jalr	1536(ra) # 8f0 <printf>
    //sanity_test();
    //NFUA_LAPA_tests();
    // SCFIFO_test();
    // NONE_test();
    //fork_test();
    exec_test();
 2f8:	00000097          	auipc	ra,0x0
 2fc:	f78080e7          	jalr	-136(ra) # 270 <exec_test>
    exit(0);
 300:	4501                	li	a0,0
 302:	00000097          	auipc	ra,0x0
 306:	276080e7          	jalr	630(ra) # 578 <exit>

000000000000030a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e422                	sd	s0,8(sp)
 30e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 310:	87aa                	mv	a5,a0
 312:	0585                	addi	a1,a1,1
 314:	0785                	addi	a5,a5,1
 316:	fff5c703          	lbu	a4,-1(a1)
 31a:	fee78fa3          	sb	a4,-1(a5) # 9fff <__global_pointer$+0x8c46>
 31e:	fb75                	bnez	a4,312 <strcpy+0x8>
    ;
  return os;
}
 320:	6422                	ld	s0,8(sp)
 322:	0141                	addi	sp,sp,16
 324:	8082                	ret

0000000000000326 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 326:	1141                	addi	sp,sp,-16
 328:	e422                	sd	s0,8(sp)
 32a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 32c:	00054783          	lbu	a5,0(a0)
 330:	cb91                	beqz	a5,344 <strcmp+0x1e>
 332:	0005c703          	lbu	a4,0(a1)
 336:	00f71763          	bne	a4,a5,344 <strcmp+0x1e>
    p++, q++;
 33a:	0505                	addi	a0,a0,1
 33c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 33e:	00054783          	lbu	a5,0(a0)
 342:	fbe5                	bnez	a5,332 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 344:	0005c503          	lbu	a0,0(a1)
}
 348:	40a7853b          	subw	a0,a5,a0
 34c:	6422                	ld	s0,8(sp)
 34e:	0141                	addi	sp,sp,16
 350:	8082                	ret

0000000000000352 <strlen>:

uint
strlen(const char *s)
{
 352:	1141                	addi	sp,sp,-16
 354:	e422                	sd	s0,8(sp)
 356:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 358:	00054783          	lbu	a5,0(a0)
 35c:	cf91                	beqz	a5,378 <strlen+0x26>
 35e:	0505                	addi	a0,a0,1
 360:	87aa                	mv	a5,a0
 362:	4685                	li	a3,1
 364:	9e89                	subw	a3,a3,a0
 366:	00f6853b          	addw	a0,a3,a5
 36a:	0785                	addi	a5,a5,1
 36c:	fff7c703          	lbu	a4,-1(a5)
 370:	fb7d                	bnez	a4,366 <strlen+0x14>
    ;
  return n;
}
 372:	6422                	ld	s0,8(sp)
 374:	0141                	addi	sp,sp,16
 376:	8082                	ret
  for(n = 0; s[n]; n++)
 378:	4501                	li	a0,0
 37a:	bfe5                	j	372 <strlen+0x20>

000000000000037c <memset>:

void*
memset(void *dst, int c, uint n)
{
 37c:	1141                	addi	sp,sp,-16
 37e:	e422                	sd	s0,8(sp)
 380:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 382:	ca19                	beqz	a2,398 <memset+0x1c>
 384:	87aa                	mv	a5,a0
 386:	1602                	slli	a2,a2,0x20
 388:	9201                	srli	a2,a2,0x20
 38a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 38e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 392:	0785                	addi	a5,a5,1
 394:	fee79de3          	bne	a5,a4,38e <memset+0x12>
  }
  return dst;
}
 398:	6422                	ld	s0,8(sp)
 39a:	0141                	addi	sp,sp,16
 39c:	8082                	ret

000000000000039e <strchr>:

char*
strchr(const char *s, char c)
{
 39e:	1141                	addi	sp,sp,-16
 3a0:	e422                	sd	s0,8(sp)
 3a2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3a4:	00054783          	lbu	a5,0(a0)
 3a8:	cb99                	beqz	a5,3be <strchr+0x20>
    if(*s == c)
 3aa:	00f58763          	beq	a1,a5,3b8 <strchr+0x1a>
  for(; *s; s++)
 3ae:	0505                	addi	a0,a0,1
 3b0:	00054783          	lbu	a5,0(a0)
 3b4:	fbfd                	bnez	a5,3aa <strchr+0xc>
      return (char*)s;
  return 0;
 3b6:	4501                	li	a0,0
}
 3b8:	6422                	ld	s0,8(sp)
 3ba:	0141                	addi	sp,sp,16
 3bc:	8082                	ret
  return 0;
 3be:	4501                	li	a0,0
 3c0:	bfe5                	j	3b8 <strchr+0x1a>

00000000000003c2 <gets>:

char*
gets(char *buf, int max)
{
 3c2:	711d                	addi	sp,sp,-96
 3c4:	ec86                	sd	ra,88(sp)
 3c6:	e8a2                	sd	s0,80(sp)
 3c8:	e4a6                	sd	s1,72(sp)
 3ca:	e0ca                	sd	s2,64(sp)
 3cc:	fc4e                	sd	s3,56(sp)
 3ce:	f852                	sd	s4,48(sp)
 3d0:	f456                	sd	s5,40(sp)
 3d2:	f05a                	sd	s6,32(sp)
 3d4:	ec5e                	sd	s7,24(sp)
 3d6:	1080                	addi	s0,sp,96
 3d8:	8baa                	mv	s7,a0
 3da:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3dc:	892a                	mv	s2,a0
 3de:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3e0:	4aa9                	li	s5,10
 3e2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3e4:	89a6                	mv	s3,s1
 3e6:	2485                	addiw	s1,s1,1
 3e8:	0344d863          	bge	s1,s4,418 <gets+0x56>
    cc = read(0, &c, 1);
 3ec:	4605                	li	a2,1
 3ee:	faf40593          	addi	a1,s0,-81
 3f2:	4501                	li	a0,0
 3f4:	00000097          	auipc	ra,0x0
 3f8:	19c080e7          	jalr	412(ra) # 590 <read>
    if(cc < 1)
 3fc:	00a05e63          	blez	a0,418 <gets+0x56>
    buf[i++] = c;
 400:	faf44783          	lbu	a5,-81(s0)
 404:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 408:	01578763          	beq	a5,s5,416 <gets+0x54>
 40c:	0905                	addi	s2,s2,1
 40e:	fd679be3          	bne	a5,s6,3e4 <gets+0x22>
  for(i=0; i+1 < max; ){
 412:	89a6                	mv	s3,s1
 414:	a011                	j	418 <gets+0x56>
 416:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 418:	99de                	add	s3,s3,s7
 41a:	00098023          	sb	zero,0(s3)
  return buf;
}
 41e:	855e                	mv	a0,s7
 420:	60e6                	ld	ra,88(sp)
 422:	6446                	ld	s0,80(sp)
 424:	64a6                	ld	s1,72(sp)
 426:	6906                	ld	s2,64(sp)
 428:	79e2                	ld	s3,56(sp)
 42a:	7a42                	ld	s4,48(sp)
 42c:	7aa2                	ld	s5,40(sp)
 42e:	7b02                	ld	s6,32(sp)
 430:	6be2                	ld	s7,24(sp)
 432:	6125                	addi	sp,sp,96
 434:	8082                	ret

0000000000000436 <stat>:

int
stat(const char *n, struct stat *st)
{
 436:	1101                	addi	sp,sp,-32
 438:	ec06                	sd	ra,24(sp)
 43a:	e822                	sd	s0,16(sp)
 43c:	e426                	sd	s1,8(sp)
 43e:	e04a                	sd	s2,0(sp)
 440:	1000                	addi	s0,sp,32
 442:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 444:	4581                	li	a1,0
 446:	00000097          	auipc	ra,0x0
 44a:	172080e7          	jalr	370(ra) # 5b8 <open>
  if(fd < 0)
 44e:	02054563          	bltz	a0,478 <stat+0x42>
 452:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 454:	85ca                	mv	a1,s2
 456:	00000097          	auipc	ra,0x0
 45a:	17a080e7          	jalr	378(ra) # 5d0 <fstat>
 45e:	892a                	mv	s2,a0
  close(fd);
 460:	8526                	mv	a0,s1
 462:	00000097          	auipc	ra,0x0
 466:	13e080e7          	jalr	318(ra) # 5a0 <close>
  return r;
}
 46a:	854a                	mv	a0,s2
 46c:	60e2                	ld	ra,24(sp)
 46e:	6442                	ld	s0,16(sp)
 470:	64a2                	ld	s1,8(sp)
 472:	6902                	ld	s2,0(sp)
 474:	6105                	addi	sp,sp,32
 476:	8082                	ret
    return -1;
 478:	597d                	li	s2,-1
 47a:	bfc5                	j	46a <stat+0x34>

000000000000047c <atoi>:

int
atoi(const char *s)
{
 47c:	1141                	addi	sp,sp,-16
 47e:	e422                	sd	s0,8(sp)
 480:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 482:	00054603          	lbu	a2,0(a0)
 486:	fd06079b          	addiw	a5,a2,-48
 48a:	0ff7f793          	andi	a5,a5,255
 48e:	4725                	li	a4,9
 490:	02f76963          	bltu	a4,a5,4c2 <atoi+0x46>
 494:	86aa                	mv	a3,a0
  n = 0;
 496:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 498:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 49a:	0685                	addi	a3,a3,1
 49c:	0025179b          	slliw	a5,a0,0x2
 4a0:	9fa9                	addw	a5,a5,a0
 4a2:	0017979b          	slliw	a5,a5,0x1
 4a6:	9fb1                	addw	a5,a5,a2
 4a8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4ac:	0006c603          	lbu	a2,0(a3) # 1000 <__BSS_END__+0x428>
 4b0:	fd06071b          	addiw	a4,a2,-48
 4b4:	0ff77713          	andi	a4,a4,255
 4b8:	fee5f1e3          	bgeu	a1,a4,49a <atoi+0x1e>
  return n;
}
 4bc:	6422                	ld	s0,8(sp)
 4be:	0141                	addi	sp,sp,16
 4c0:	8082                	ret
  n = 0;
 4c2:	4501                	li	a0,0
 4c4:	bfe5                	j	4bc <atoi+0x40>

00000000000004c6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4c6:	1141                	addi	sp,sp,-16
 4c8:	e422                	sd	s0,8(sp)
 4ca:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4cc:	02b57463          	bgeu	a0,a1,4f4 <memmove+0x2e>
    while(n-- > 0)
 4d0:	00c05f63          	blez	a2,4ee <memmove+0x28>
 4d4:	1602                	slli	a2,a2,0x20
 4d6:	9201                	srli	a2,a2,0x20
 4d8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4dc:	872a                	mv	a4,a0
      *dst++ = *src++;
 4de:	0585                	addi	a1,a1,1
 4e0:	0705                	addi	a4,a4,1
 4e2:	fff5c683          	lbu	a3,-1(a1)
 4e6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4ea:	fee79ae3          	bne	a5,a4,4de <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4ee:	6422                	ld	s0,8(sp)
 4f0:	0141                	addi	sp,sp,16
 4f2:	8082                	ret
    dst += n;
 4f4:	00c50733          	add	a4,a0,a2
    src += n;
 4f8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4fa:	fec05ae3          	blez	a2,4ee <memmove+0x28>
 4fe:	fff6079b          	addiw	a5,a2,-1
 502:	1782                	slli	a5,a5,0x20
 504:	9381                	srli	a5,a5,0x20
 506:	fff7c793          	not	a5,a5
 50a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 50c:	15fd                	addi	a1,a1,-1
 50e:	177d                	addi	a4,a4,-1
 510:	0005c683          	lbu	a3,0(a1)
 514:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 518:	fee79ae3          	bne	a5,a4,50c <memmove+0x46>
 51c:	bfc9                	j	4ee <memmove+0x28>

000000000000051e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 51e:	1141                	addi	sp,sp,-16
 520:	e422                	sd	s0,8(sp)
 522:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 524:	ca05                	beqz	a2,554 <memcmp+0x36>
 526:	fff6069b          	addiw	a3,a2,-1
 52a:	1682                	slli	a3,a3,0x20
 52c:	9281                	srli	a3,a3,0x20
 52e:	0685                	addi	a3,a3,1
 530:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 532:	00054783          	lbu	a5,0(a0)
 536:	0005c703          	lbu	a4,0(a1)
 53a:	00e79863          	bne	a5,a4,54a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 53e:	0505                	addi	a0,a0,1
    p2++;
 540:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 542:	fed518e3          	bne	a0,a3,532 <memcmp+0x14>
  }
  return 0;
 546:	4501                	li	a0,0
 548:	a019                	j	54e <memcmp+0x30>
      return *p1 - *p2;
 54a:	40e7853b          	subw	a0,a5,a4
}
 54e:	6422                	ld	s0,8(sp)
 550:	0141                	addi	sp,sp,16
 552:	8082                	ret
  return 0;
 554:	4501                	li	a0,0
 556:	bfe5                	j	54e <memcmp+0x30>

0000000000000558 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 558:	1141                	addi	sp,sp,-16
 55a:	e406                	sd	ra,8(sp)
 55c:	e022                	sd	s0,0(sp)
 55e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 560:	00000097          	auipc	ra,0x0
 564:	f66080e7          	jalr	-154(ra) # 4c6 <memmove>
}
 568:	60a2                	ld	ra,8(sp)
 56a:	6402                	ld	s0,0(sp)
 56c:	0141                	addi	sp,sp,16
 56e:	8082                	ret

0000000000000570 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 570:	4885                	li	a7,1
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <exit>:
.global exit
exit:
 li a7, SYS_exit
 578:	4889                	li	a7,2
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <wait>:
.global wait
wait:
 li a7, SYS_wait
 580:	488d                	li	a7,3
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 588:	4891                	li	a7,4
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <read>:
.global read
read:
 li a7, SYS_read
 590:	4895                	li	a7,5
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <write>:
.global write
write:
 li a7, SYS_write
 598:	48c1                	li	a7,16
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <close>:
.global close
close:
 li a7, SYS_close
 5a0:	48d5                	li	a7,21
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5a8:	4899                	li	a7,6
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5b0:	489d                	li	a7,7
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <open>:
.global open
open:
 li a7, SYS_open
 5b8:	48bd                	li	a7,15
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5c0:	48c5                	li	a7,17
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5c8:	48c9                	li	a7,18
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5d0:	48a1                	li	a7,8
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <link>:
.global link
link:
 li a7, SYS_link
 5d8:	48cd                	li	a7,19
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5e0:	48d1                	li	a7,20
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5e8:	48a5                	li	a7,9
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5f0:	48a9                	li	a7,10
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5f8:	48ad                	li	a7,11
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 600:	48b1                	li	a7,12
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 608:	48b5                	li	a7,13
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 610:	48b9                	li	a7,14
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 618:	1101                	addi	sp,sp,-32
 61a:	ec06                	sd	ra,24(sp)
 61c:	e822                	sd	s0,16(sp)
 61e:	1000                	addi	s0,sp,32
 620:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 624:	4605                	li	a2,1
 626:	fef40593          	addi	a1,s0,-17
 62a:	00000097          	auipc	ra,0x0
 62e:	f6e080e7          	jalr	-146(ra) # 598 <write>
}
 632:	60e2                	ld	ra,24(sp)
 634:	6442                	ld	s0,16(sp)
 636:	6105                	addi	sp,sp,32
 638:	8082                	ret

000000000000063a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 63a:	7139                	addi	sp,sp,-64
 63c:	fc06                	sd	ra,56(sp)
 63e:	f822                	sd	s0,48(sp)
 640:	f426                	sd	s1,40(sp)
 642:	f04a                	sd	s2,32(sp)
 644:	ec4e                	sd	s3,24(sp)
 646:	0080                	addi	s0,sp,64
 648:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 64a:	c299                	beqz	a3,650 <printint+0x16>
 64c:	0805c863          	bltz	a1,6dc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 650:	2581                	sext.w	a1,a1
  neg = 0;
 652:	4881                	li	a7,0
 654:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 658:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 65a:	2601                	sext.w	a2,a2
 65c:	00000517          	auipc	a0,0x0
 660:	54c50513          	addi	a0,a0,1356 # ba8 <digits>
 664:	883a                	mv	a6,a4
 666:	2705                	addiw	a4,a4,1
 668:	02c5f7bb          	remuw	a5,a1,a2
 66c:	1782                	slli	a5,a5,0x20
 66e:	9381                	srli	a5,a5,0x20
 670:	97aa                	add	a5,a5,a0
 672:	0007c783          	lbu	a5,0(a5)
 676:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 67a:	0005879b          	sext.w	a5,a1
 67e:	02c5d5bb          	divuw	a1,a1,a2
 682:	0685                	addi	a3,a3,1
 684:	fec7f0e3          	bgeu	a5,a2,664 <printint+0x2a>
  if(neg)
 688:	00088b63          	beqz	a7,69e <printint+0x64>
    buf[i++] = '-';
 68c:	fd040793          	addi	a5,s0,-48
 690:	973e                	add	a4,a4,a5
 692:	02d00793          	li	a5,45
 696:	fef70823          	sb	a5,-16(a4)
 69a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 69e:	02e05863          	blez	a4,6ce <printint+0x94>
 6a2:	fc040793          	addi	a5,s0,-64
 6a6:	00e78933          	add	s2,a5,a4
 6aa:	fff78993          	addi	s3,a5,-1
 6ae:	99ba                	add	s3,s3,a4
 6b0:	377d                	addiw	a4,a4,-1
 6b2:	1702                	slli	a4,a4,0x20
 6b4:	9301                	srli	a4,a4,0x20
 6b6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ba:	fff94583          	lbu	a1,-1(s2)
 6be:	8526                	mv	a0,s1
 6c0:	00000097          	auipc	ra,0x0
 6c4:	f58080e7          	jalr	-168(ra) # 618 <putc>
  while(--i >= 0)
 6c8:	197d                	addi	s2,s2,-1
 6ca:	ff3918e3          	bne	s2,s3,6ba <printint+0x80>
}
 6ce:	70e2                	ld	ra,56(sp)
 6d0:	7442                	ld	s0,48(sp)
 6d2:	74a2                	ld	s1,40(sp)
 6d4:	7902                	ld	s2,32(sp)
 6d6:	69e2                	ld	s3,24(sp)
 6d8:	6121                	addi	sp,sp,64
 6da:	8082                	ret
    x = -xx;
 6dc:	40b005bb          	negw	a1,a1
    neg = 1;
 6e0:	4885                	li	a7,1
    x = -xx;
 6e2:	bf8d                	j	654 <printint+0x1a>

00000000000006e4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6e4:	7119                	addi	sp,sp,-128
 6e6:	fc86                	sd	ra,120(sp)
 6e8:	f8a2                	sd	s0,112(sp)
 6ea:	f4a6                	sd	s1,104(sp)
 6ec:	f0ca                	sd	s2,96(sp)
 6ee:	ecce                	sd	s3,88(sp)
 6f0:	e8d2                	sd	s4,80(sp)
 6f2:	e4d6                	sd	s5,72(sp)
 6f4:	e0da                	sd	s6,64(sp)
 6f6:	fc5e                	sd	s7,56(sp)
 6f8:	f862                	sd	s8,48(sp)
 6fa:	f466                	sd	s9,40(sp)
 6fc:	f06a                	sd	s10,32(sp)
 6fe:	ec6e                	sd	s11,24(sp)
 700:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 702:	0005c903          	lbu	s2,0(a1)
 706:	18090f63          	beqz	s2,8a4 <vprintf+0x1c0>
 70a:	8aaa                	mv	s5,a0
 70c:	8b32                	mv	s6,a2
 70e:	00158493          	addi	s1,a1,1
  state = 0;
 712:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 714:	02500a13          	li	s4,37
      if(c == 'd'){
 718:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 71c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 720:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 724:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 728:	00000b97          	auipc	s7,0x0
 72c:	480b8b93          	addi	s7,s7,1152 # ba8 <digits>
 730:	a839                	j	74e <vprintf+0x6a>
        putc(fd, c);
 732:	85ca                	mv	a1,s2
 734:	8556                	mv	a0,s5
 736:	00000097          	auipc	ra,0x0
 73a:	ee2080e7          	jalr	-286(ra) # 618 <putc>
 73e:	a019                	j	744 <vprintf+0x60>
    } else if(state == '%'){
 740:	01498f63          	beq	s3,s4,75e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 744:	0485                	addi	s1,s1,1
 746:	fff4c903          	lbu	s2,-1(s1)
 74a:	14090d63          	beqz	s2,8a4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 74e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 752:	fe0997e3          	bnez	s3,740 <vprintf+0x5c>
      if(c == '%'){
 756:	fd479ee3          	bne	a5,s4,732 <vprintf+0x4e>
        state = '%';
 75a:	89be                	mv	s3,a5
 75c:	b7e5                	j	744 <vprintf+0x60>
      if(c == 'd'){
 75e:	05878063          	beq	a5,s8,79e <vprintf+0xba>
      } else if(c == 'l') {
 762:	05978c63          	beq	a5,s9,7ba <vprintf+0xd6>
      } else if(c == 'x') {
 766:	07a78863          	beq	a5,s10,7d6 <vprintf+0xf2>
      } else if(c == 'p') {
 76a:	09b78463          	beq	a5,s11,7f2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 76e:	07300713          	li	a4,115
 772:	0ce78663          	beq	a5,a4,83e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 776:	06300713          	li	a4,99
 77a:	0ee78e63          	beq	a5,a4,876 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 77e:	11478863          	beq	a5,s4,88e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 782:	85d2                	mv	a1,s4
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	e92080e7          	jalr	-366(ra) # 618 <putc>
        putc(fd, c);
 78e:	85ca                	mv	a1,s2
 790:	8556                	mv	a0,s5
 792:	00000097          	auipc	ra,0x0
 796:	e86080e7          	jalr	-378(ra) # 618 <putc>
      }
      state = 0;
 79a:	4981                	li	s3,0
 79c:	b765                	j	744 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 79e:	008b0913          	addi	s2,s6,8
 7a2:	4685                	li	a3,1
 7a4:	4629                	li	a2,10
 7a6:	000b2583          	lw	a1,0(s6)
 7aa:	8556                	mv	a0,s5
 7ac:	00000097          	auipc	ra,0x0
 7b0:	e8e080e7          	jalr	-370(ra) # 63a <printint>
 7b4:	8b4a                	mv	s6,s2
      state = 0;
 7b6:	4981                	li	s3,0
 7b8:	b771                	j	744 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7ba:	008b0913          	addi	s2,s6,8
 7be:	4681                	li	a3,0
 7c0:	4629                	li	a2,10
 7c2:	000b2583          	lw	a1,0(s6)
 7c6:	8556                	mv	a0,s5
 7c8:	00000097          	auipc	ra,0x0
 7cc:	e72080e7          	jalr	-398(ra) # 63a <printint>
 7d0:	8b4a                	mv	s6,s2
      state = 0;
 7d2:	4981                	li	s3,0
 7d4:	bf85                	j	744 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7d6:	008b0913          	addi	s2,s6,8
 7da:	4681                	li	a3,0
 7dc:	4641                	li	a2,16
 7de:	000b2583          	lw	a1,0(s6)
 7e2:	8556                	mv	a0,s5
 7e4:	00000097          	auipc	ra,0x0
 7e8:	e56080e7          	jalr	-426(ra) # 63a <printint>
 7ec:	8b4a                	mv	s6,s2
      state = 0;
 7ee:	4981                	li	s3,0
 7f0:	bf91                	j	744 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7f2:	008b0793          	addi	a5,s6,8
 7f6:	f8f43423          	sd	a5,-120(s0)
 7fa:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7fe:	03000593          	li	a1,48
 802:	8556                	mv	a0,s5
 804:	00000097          	auipc	ra,0x0
 808:	e14080e7          	jalr	-492(ra) # 618 <putc>
  putc(fd, 'x');
 80c:	85ea                	mv	a1,s10
 80e:	8556                	mv	a0,s5
 810:	00000097          	auipc	ra,0x0
 814:	e08080e7          	jalr	-504(ra) # 618 <putc>
 818:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 81a:	03c9d793          	srli	a5,s3,0x3c
 81e:	97de                	add	a5,a5,s7
 820:	0007c583          	lbu	a1,0(a5)
 824:	8556                	mv	a0,s5
 826:	00000097          	auipc	ra,0x0
 82a:	df2080e7          	jalr	-526(ra) # 618 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 82e:	0992                	slli	s3,s3,0x4
 830:	397d                	addiw	s2,s2,-1
 832:	fe0914e3          	bnez	s2,81a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 836:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 83a:	4981                	li	s3,0
 83c:	b721                	j	744 <vprintf+0x60>
        s = va_arg(ap, char*);
 83e:	008b0993          	addi	s3,s6,8
 842:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 846:	02090163          	beqz	s2,868 <vprintf+0x184>
        while(*s != 0){
 84a:	00094583          	lbu	a1,0(s2)
 84e:	c9a1                	beqz	a1,89e <vprintf+0x1ba>
          putc(fd, *s);
 850:	8556                	mv	a0,s5
 852:	00000097          	auipc	ra,0x0
 856:	dc6080e7          	jalr	-570(ra) # 618 <putc>
          s++;
 85a:	0905                	addi	s2,s2,1
        while(*s != 0){
 85c:	00094583          	lbu	a1,0(s2)
 860:	f9e5                	bnez	a1,850 <vprintf+0x16c>
        s = va_arg(ap, char*);
 862:	8b4e                	mv	s6,s3
      state = 0;
 864:	4981                	li	s3,0
 866:	bdf9                	j	744 <vprintf+0x60>
          s = "(null)";
 868:	00000917          	auipc	s2,0x0
 86c:	33890913          	addi	s2,s2,824 # ba0 <malloc+0x1f2>
        while(*s != 0){
 870:	02800593          	li	a1,40
 874:	bff1                	j	850 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 876:	008b0913          	addi	s2,s6,8
 87a:	000b4583          	lbu	a1,0(s6)
 87e:	8556                	mv	a0,s5
 880:	00000097          	auipc	ra,0x0
 884:	d98080e7          	jalr	-616(ra) # 618 <putc>
 888:	8b4a                	mv	s6,s2
      state = 0;
 88a:	4981                	li	s3,0
 88c:	bd65                	j	744 <vprintf+0x60>
        putc(fd, c);
 88e:	85d2                	mv	a1,s4
 890:	8556                	mv	a0,s5
 892:	00000097          	auipc	ra,0x0
 896:	d86080e7          	jalr	-634(ra) # 618 <putc>
      state = 0;
 89a:	4981                	li	s3,0
 89c:	b565                	j	744 <vprintf+0x60>
        s = va_arg(ap, char*);
 89e:	8b4e                	mv	s6,s3
      state = 0;
 8a0:	4981                	li	s3,0
 8a2:	b54d                	j	744 <vprintf+0x60>
    }
  }
}
 8a4:	70e6                	ld	ra,120(sp)
 8a6:	7446                	ld	s0,112(sp)
 8a8:	74a6                	ld	s1,104(sp)
 8aa:	7906                	ld	s2,96(sp)
 8ac:	69e6                	ld	s3,88(sp)
 8ae:	6a46                	ld	s4,80(sp)
 8b0:	6aa6                	ld	s5,72(sp)
 8b2:	6b06                	ld	s6,64(sp)
 8b4:	7be2                	ld	s7,56(sp)
 8b6:	7c42                	ld	s8,48(sp)
 8b8:	7ca2                	ld	s9,40(sp)
 8ba:	7d02                	ld	s10,32(sp)
 8bc:	6de2                	ld	s11,24(sp)
 8be:	6109                	addi	sp,sp,128
 8c0:	8082                	ret

00000000000008c2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8c2:	715d                	addi	sp,sp,-80
 8c4:	ec06                	sd	ra,24(sp)
 8c6:	e822                	sd	s0,16(sp)
 8c8:	1000                	addi	s0,sp,32
 8ca:	e010                	sd	a2,0(s0)
 8cc:	e414                	sd	a3,8(s0)
 8ce:	e818                	sd	a4,16(s0)
 8d0:	ec1c                	sd	a5,24(s0)
 8d2:	03043023          	sd	a6,32(s0)
 8d6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8da:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8de:	8622                	mv	a2,s0
 8e0:	00000097          	auipc	ra,0x0
 8e4:	e04080e7          	jalr	-508(ra) # 6e4 <vprintf>
}
 8e8:	60e2                	ld	ra,24(sp)
 8ea:	6442                	ld	s0,16(sp)
 8ec:	6161                	addi	sp,sp,80
 8ee:	8082                	ret

00000000000008f0 <printf>:

void
printf(const char *fmt, ...)
{
 8f0:	711d                	addi	sp,sp,-96
 8f2:	ec06                	sd	ra,24(sp)
 8f4:	e822                	sd	s0,16(sp)
 8f6:	1000                	addi	s0,sp,32
 8f8:	e40c                	sd	a1,8(s0)
 8fa:	e810                	sd	a2,16(s0)
 8fc:	ec14                	sd	a3,24(s0)
 8fe:	f018                	sd	a4,32(s0)
 900:	f41c                	sd	a5,40(s0)
 902:	03043823          	sd	a6,48(s0)
 906:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 90a:	00840613          	addi	a2,s0,8
 90e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 912:	85aa                	mv	a1,a0
 914:	4505                	li	a0,1
 916:	00000097          	auipc	ra,0x0
 91a:	dce080e7          	jalr	-562(ra) # 6e4 <vprintf>
}
 91e:	60e2                	ld	ra,24(sp)
 920:	6442                	ld	s0,16(sp)
 922:	6125                	addi	sp,sp,96
 924:	8082                	ret

0000000000000926 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 926:	1141                	addi	sp,sp,-16
 928:	e422                	sd	s0,8(sp)
 92a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 92c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 930:	00000797          	auipc	a5,0x0
 934:	2907b783          	ld	a5,656(a5) # bc0 <freep>
 938:	a805                	j	968 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 93a:	4618                	lw	a4,8(a2)
 93c:	9db9                	addw	a1,a1,a4
 93e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 942:	6398                	ld	a4,0(a5)
 944:	6318                	ld	a4,0(a4)
 946:	fee53823          	sd	a4,-16(a0)
 94a:	a091                	j	98e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 94c:	ff852703          	lw	a4,-8(a0)
 950:	9e39                	addw	a2,a2,a4
 952:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 954:	ff053703          	ld	a4,-16(a0)
 958:	e398                	sd	a4,0(a5)
 95a:	a099                	j	9a0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 95c:	6398                	ld	a4,0(a5)
 95e:	00e7e463          	bltu	a5,a4,966 <free+0x40>
 962:	00e6ea63          	bltu	a3,a4,976 <free+0x50>
{
 966:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 968:	fed7fae3          	bgeu	a5,a3,95c <free+0x36>
 96c:	6398                	ld	a4,0(a5)
 96e:	00e6e463          	bltu	a3,a4,976 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 972:	fee7eae3          	bltu	a5,a4,966 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 976:	ff852583          	lw	a1,-8(a0)
 97a:	6390                	ld	a2,0(a5)
 97c:	02059813          	slli	a6,a1,0x20
 980:	01c85713          	srli	a4,a6,0x1c
 984:	9736                	add	a4,a4,a3
 986:	fae60ae3          	beq	a2,a4,93a <free+0x14>
    bp->s.ptr = p->s.ptr;
 98a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 98e:	4790                	lw	a2,8(a5)
 990:	02061593          	slli	a1,a2,0x20
 994:	01c5d713          	srli	a4,a1,0x1c
 998:	973e                	add	a4,a4,a5
 99a:	fae689e3          	beq	a3,a4,94c <free+0x26>
  } else
    p->s.ptr = bp;
 99e:	e394                	sd	a3,0(a5)
  freep = p;
 9a0:	00000717          	auipc	a4,0x0
 9a4:	22f73023          	sd	a5,544(a4) # bc0 <freep>
}
 9a8:	6422                	ld	s0,8(sp)
 9aa:	0141                	addi	sp,sp,16
 9ac:	8082                	ret

00000000000009ae <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9ae:	7139                	addi	sp,sp,-64
 9b0:	fc06                	sd	ra,56(sp)
 9b2:	f822                	sd	s0,48(sp)
 9b4:	f426                	sd	s1,40(sp)
 9b6:	f04a                	sd	s2,32(sp)
 9b8:	ec4e                	sd	s3,24(sp)
 9ba:	e852                	sd	s4,16(sp)
 9bc:	e456                	sd	s5,8(sp)
 9be:	e05a                	sd	s6,0(sp)
 9c0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9c2:	02051493          	slli	s1,a0,0x20
 9c6:	9081                	srli	s1,s1,0x20
 9c8:	04bd                	addi	s1,s1,15
 9ca:	8091                	srli	s1,s1,0x4
 9cc:	0014899b          	addiw	s3,s1,1
 9d0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9d2:	00000517          	auipc	a0,0x0
 9d6:	1ee53503          	ld	a0,494(a0) # bc0 <freep>
 9da:	c515                	beqz	a0,a06 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9de:	4798                	lw	a4,8(a5)
 9e0:	02977f63          	bgeu	a4,s1,a1e <malloc+0x70>
 9e4:	8a4e                	mv	s4,s3
 9e6:	0009871b          	sext.w	a4,s3
 9ea:	6685                	lui	a3,0x1
 9ec:	00d77363          	bgeu	a4,a3,9f2 <malloc+0x44>
 9f0:	6a05                	lui	s4,0x1
 9f2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9f6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9fa:	00000917          	auipc	s2,0x0
 9fe:	1c690913          	addi	s2,s2,454 # bc0 <freep>
  if(p == (char*)-1)
 a02:	5afd                	li	s5,-1
 a04:	a895                	j	a78 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a06:	00000797          	auipc	a5,0x0
 a0a:	1c278793          	addi	a5,a5,450 # bc8 <base>
 a0e:	00000717          	auipc	a4,0x0
 a12:	1af73923          	sd	a5,434(a4) # bc0 <freep>
 a16:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a18:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a1c:	b7e1                	j	9e4 <malloc+0x36>
      if(p->s.size == nunits)
 a1e:	02e48c63          	beq	s1,a4,a56 <malloc+0xa8>
        p->s.size -= nunits;
 a22:	4137073b          	subw	a4,a4,s3
 a26:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a28:	02071693          	slli	a3,a4,0x20
 a2c:	01c6d713          	srli	a4,a3,0x1c
 a30:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a32:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a36:	00000717          	auipc	a4,0x0
 a3a:	18a73523          	sd	a0,394(a4) # bc0 <freep>
      return (void*)(p + 1);
 a3e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a42:	70e2                	ld	ra,56(sp)
 a44:	7442                	ld	s0,48(sp)
 a46:	74a2                	ld	s1,40(sp)
 a48:	7902                	ld	s2,32(sp)
 a4a:	69e2                	ld	s3,24(sp)
 a4c:	6a42                	ld	s4,16(sp)
 a4e:	6aa2                	ld	s5,8(sp)
 a50:	6b02                	ld	s6,0(sp)
 a52:	6121                	addi	sp,sp,64
 a54:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a56:	6398                	ld	a4,0(a5)
 a58:	e118                	sd	a4,0(a0)
 a5a:	bff1                	j	a36 <malloc+0x88>
  hp->s.size = nu;
 a5c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a60:	0541                	addi	a0,a0,16
 a62:	00000097          	auipc	ra,0x0
 a66:	ec4080e7          	jalr	-316(ra) # 926 <free>
  return freep;
 a6a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a6e:	d971                	beqz	a0,a42 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a70:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a72:	4798                	lw	a4,8(a5)
 a74:	fa9775e3          	bgeu	a4,s1,a1e <malloc+0x70>
    if(p == freep)
 a78:	00093703          	ld	a4,0(s2)
 a7c:	853e                	mv	a0,a5
 a7e:	fef719e3          	bne	a4,a5,a70 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a82:	8552                	mv	a0,s4
 a84:	00000097          	auipc	ra,0x0
 a88:	b7c080e7          	jalr	-1156(ra) # 600 <sbrk>
  if(p == (char*)-1)
 a8c:	fd5518e3          	bne	a0,s5,a5c <malloc+0xae>
        return 0;
 a90:	4501                	li	a0,0
 a92:	bf45                	j	a42 <malloc+0x94>
