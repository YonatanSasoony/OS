
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
  1c:	9e6080e7          	jalr	-1562(ra) # 9fe <malloc>
  20:	8baa                	mv	s7,a0
    printf("Allocated %d pages\n", MAX_PG_NUM);
  22:	45ed                	li	a1,27
  24:	00001517          	auipc	a0,0x1
  28:	ac450513          	addi	a0,a0,-1340 # ae8 <malloc+0xea>
  2c:	00001097          	auipc	ra,0x1
  30:	914080e7          	jalr	-1772(ra) # 940 <printf>

    for (int i = 0; i < MAX_PG_NUM; i++){
  34:	895e                	mv	s2,s7
    printf("Allocated %d pages\n", MAX_PG_NUM);
  36:	89de                	mv	s3,s7
    for (int i = 0; i < MAX_PG_NUM; i++){
  38:	4481                	li	s1,0
        printf("write to page %d: %d\n", i, i);
  3a:	00001b17          	auipc	s6,0x1
  3e:	ac6b0b13          	addi	s6,s6,-1338 # b00 <malloc+0x102>
    for (int i = 0; i < MAX_PG_NUM; i++){
  42:	6a85                	lui	s5,0x1
  44:	4a6d                	li	s4,27
        printf("write to page %d: %d\n", i, i);
  46:	8626                	mv	a2,s1
  48:	85a6                	mv	a1,s1
  4a:	855a                	mv	a0,s6
  4c:	00001097          	auipc	ra,0x1
  50:	8f4080e7          	jalr	-1804(ra) # 940 <printf>
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
  66:	ab6a8a93          	addi	s5,s5,-1354 # b18 <malloc+0x11a>
    for (int i = 0; i < MAX_PG_NUM; i++){
  6a:	6a05                	lui	s4,0x1
  6c:	49ed                	li	s3,27
        printf("read from page %d: %d\n", i, pages[i * PG_SIZE]);
  6e:	00094603          	lbu	a2,0(s2)
  72:	85a6                	mv	a1,s1
  74:	8556                	mv	a0,s5
  76:	00001097          	auipc	ra,0x1
  7a:	8ca080e7          	jalr	-1846(ra) # 940 <printf>
    for (int i = 0; i < MAX_PG_NUM; i++){
  7e:	2485                	addiw	s1,s1,1
  80:	9952                	add	s2,s2,s4
  82:	ff3496e3          	bne	s1,s3,6e <sanity_test+0x6e>
    }
    free(pages);
  86:	855e                	mv	a0,s7
  88:	00001097          	auipc	ra,0x1
  8c:	8ee080e7          	jalr	-1810(ra) # 976 <free>
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
  b8:	94a080e7          	jalr	-1718(ra) # 9fe <malloc>
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
  da:	582080e7          	jalr	1410(ra) # 658 <sleep>
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
  f6:	566080e7          	jalr	1382(ra) # 658 <sleep>
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
 11e:	8e4080e7          	jalr	-1820(ra) # 9fe <malloc>
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
 13c:	00e78023          	sb	a4,0(a5) # 10000 <__global_pointer$+0xebdf>
    // RAM: 16 1 2 3 4 5 6 7 8 9 10 11 12 13 15
    pages[1 * PG_SIZE] = 1;
 140:	6785                	lui	a5,0x1
 142:	97aa                	add	a5,a5,a0
 144:	4705                	li	a4,1
 146:	00e78023          	sb	a4,0(a5) # 1000 <__BSS_END__+0x3c0>
    pages[17 * PG_SIZE] = 17; // should replace page #2 - check kernel print
 14a:	67c5                	lui	a5,0x11
 14c:	953e                	add	a0,a0,a5
 14e:	47c5                	li	a5,17
 150:	00f50023          	sb	a5,0(a0) # 12000 <__global_pointer$+0x10bdf>
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
 16a:	898080e7          	jalr	-1896(ra) # 9fe <malloc>
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
 186:	00054583          	lbu	a1,0(a0) # 11000 <__global_pointer$+0xfbdf>
 18a:	00001517          	auipc	a0,0x1
 18e:	9a650513          	addi	a0,a0,-1626 # b30 <malloc+0x132>
 192:	00000097          	auipc	ra,0x0
 196:	7ae080e7          	jalr	1966(ra) # 940 <printf>
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
 1bc:	846080e7          	jalr	-1978(ra) # 9fe <malloc>
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
 1de:	976b0b13          	addi	s6,s6,-1674 # b50 <malloc+0x152>
    for (int i = 0; i < 17; i++){
 1e2:	6a85                	lui	s5,0x1
 1e4:	4a45                	li	s4,17
        printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 1e6:	00094603          	lbu	a2,0(s2)
 1ea:	85a6                	mv	a1,s1
 1ec:	855a                	mv	a0,s6
 1ee:	00000097          	auipc	ra,0x0
 1f2:	752080e7          	jalr	1874(ra) # 940 <printf>
    for (int i = 0; i < 17; i++){
 1f6:	2485                	addiw	s1,s1,1
 1f8:	9956                	add	s2,s2,s5
 1fa:	ff4496e3          	bne	s1,s4,1e6 <fork_test+0x44>
    }
    printf("###FORKING###\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	97250513          	addi	a0,a0,-1678 # b70 <malloc+0x172>
 206:	00000097          	auipc	ra,0x0
 20a:	73a080e7          	jalr	1850(ra) # 940 <printf>
    int pid = fork();
 20e:	00000097          	auipc	ra,0x0
 212:	3b2080e7          	jalr	946(ra) # 5c0 <fork>
 216:	84aa                	mv	s1,a0
    if(pid == 0){
 218:	e541                	bnez	a0,2a0 <fork_test+0xfe>
        printf("###CHILD###\n");
 21a:	00001517          	auipc	a0,0x1
 21e:	96650513          	addi	a0,a0,-1690 # b80 <malloc+0x182>
 222:	00000097          	auipc	ra,0x0
 226:	71e080e7          	jalr	1822(ra) # 940 <printf>
 22a:	894e                	mv	s2,s3
        for (int i = 0; i < 17; i++){
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 22c:	00001b17          	auipc	s6,0x1
 230:	924b0b13          	addi	s6,s6,-1756 # b50 <malloc+0x152>
        for (int i = 0; i < 17; i++){
 234:	6a85                	lui	s5,0x1
 236:	4a45                	li	s4,17
            printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 238:	00094603          	lbu	a2,0(s2)
 23c:	85a6                	mv	a1,s1
 23e:	855a                	mv	a0,s6
 240:	00000097          	auipc	ra,0x0
 244:	700080e7          	jalr	1792(ra) # 940 <printf>
        for (int i = 0; i < 17; i++){
 248:	2485                	addiw	s1,s1,1
 24a:	9956                	add	s2,s2,s5
 24c:	ff4496e3          	bne	s1,s4,238 <fork_test+0x96>
        }
        int pid2 = fork();
 250:	00000097          	auipc	ra,0x0
 254:	370080e7          	jalr	880(ra) # 5c0 <fork>
 258:	84aa                	mv	s1,a0
        if(pid2 == 0){
 25a:	ed05                	bnez	a0,292 <fork_test+0xf0>
            printf("###CHILDS CHILD###\n");
 25c:	00001517          	auipc	a0,0x1
 260:	93450513          	addi	a0,a0,-1740 # b90 <malloc+0x192>
 264:	00000097          	auipc	ra,0x0
 268:	6dc080e7          	jalr	1756(ra) # 940 <printf>
            for (int i = 0; i < 17; i++){
                printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 26c:	00001a97          	auipc	s5,0x1
 270:	8e4a8a93          	addi	s5,s5,-1820 # b50 <malloc+0x152>
            for (int i = 0; i < 17; i++){
 274:	6a05                	lui	s4,0x1
 276:	4945                	li	s2,17
                printf("pages[%d * PG_SIZE] = %d\n", i, pages[i * PG_SIZE]);
 278:	0009c603          	lbu	a2,0(s3)
 27c:	85a6                	mv	a1,s1
 27e:	8556                	mv	a0,s5
 280:	00000097          	auipc	ra,0x0
 284:	6c0080e7          	jalr	1728(ra) # 940 <printf>
            for (int i = 0; i < 17; i++){
 288:	2485                	addiw	s1,s1,1
 28a:	99d2                	add	s3,s3,s4
 28c:	ff2496e3          	bne	s1,s2,278 <fork_test+0xd6>
 290:	a831                	j	2ac <fork_test+0x10a>
            }
        }
        else{
        int status2;
        wait(&status2);
 292:	fbc40513          	addi	a0,s0,-68
 296:	00000097          	auipc	ra,0x0
 29a:	33a080e7          	jalr	826(ra) # 5d0 <wait>
 29e:	a039                	j	2ac <fork_test+0x10a>
    }
    }
    else{
        int status;
        wait(&status);
 2a0:	fbc40513          	addi	a0,s0,-68
 2a4:	00000097          	auipc	ra,0x0
 2a8:	32c080e7          	jalr	812(ra) # 5d0 <wait>
    }
}
 2ac:	60a6                	ld	ra,72(sp)
 2ae:	6406                	ld	s0,64(sp)
 2b0:	74e2                	ld	s1,56(sp)
 2b2:	7942                	ld	s2,48(sp)
 2b4:	79a2                	ld	s3,40(sp)
 2b6:	7a02                	ld	s4,32(sp)
 2b8:	6ae2                	ld	s5,24(sp)
 2ba:	6b42                	ld	s6,16(sp)
 2bc:	6161                	addi	sp,sp,80
 2be:	8082                	ret

00000000000002c0 <exec_test>:

void exec_test(){
 2c0:	1101                	addi	sp,sp,-32
 2c2:	ec06                	sd	ra,24(sp)
 2c4:	e822                	sd	s0,16(sp)
 2c6:	e426                	sd	s1,8(sp)
 2c8:	1000                	addi	s0,sp,32
    char *pages = malloc(PG_SIZE * 17);
 2ca:	6545                	lui	a0,0x11
 2cc:	00000097          	auipc	ra,0x0
 2d0:	732080e7          	jalr	1842(ra) # 9fe <malloc>
 2d4:	84aa                	mv	s1,a0
    for (int i = 0; i < 17; i++){
 2d6:	872a                	mv	a4,a0
 2d8:	4781                	li	a5,0
 2da:	6605                	lui	a2,0x1
 2dc:	46c5                	li	a3,17
        pages[i * PG_SIZE] = i;
 2de:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < 17; i++){
 2e2:	2785                	addiw	a5,a5,1
 2e4:	9732                	add	a4,a4,a2
 2e6:	fed79ce3          	bne	a5,a3,2de <exec_test+0x1e>
    }
    printf("exec output: %d\n", exec("exec_fail", 0)); // hope exec will fail and return -1
 2ea:	4581                	li	a1,0
 2ec:	00001517          	auipc	a0,0x1
 2f0:	8bc50513          	addi	a0,a0,-1860 # ba8 <malloc+0x1aa>
 2f4:	00000097          	auipc	ra,0x0
 2f8:	30c080e7          	jalr	780(ra) # 600 <exec>
 2fc:	85aa                	mv	a1,a0
 2fe:	00001517          	auipc	a0,0x1
 302:	8ba50513          	addi	a0,a0,-1862 # bb8 <malloc+0x1ba>
 306:	00000097          	auipc	ra,0x0
 30a:	63a080e7          	jalr	1594(ra) # 940 <printf>
    printf("pages[10 * PG_SIZE] = %d\n", pages[10 * PG_SIZE]); // should print 10
 30e:	67a9                	lui	a5,0xa
 310:	94be                	add	s1,s1,a5
 312:	0004c583          	lbu	a1,0(s1)
 316:	00001517          	auipc	a0,0x1
 31a:	8ba50513          	addi	a0,a0,-1862 # bd0 <malloc+0x1d2>
 31e:	00000097          	auipc	ra,0x0
 322:	622080e7          	jalr	1570(ra) # 940 <printf>
}
 326:	60e2                	ld	ra,24(sp)
 328:	6442                	ld	s0,16(sp)
 32a:	64a2                	ld	s1,8(sp)
 32c:	6105                	addi	sp,sp,32
 32e:	8082                	ret

0000000000000330 <main>:

int main()
{
 330:	1141                	addi	sp,sp,-16
 332:	e406                	sd	ra,8(sp)
 334:	e022                	sd	s0,0(sp)
 336:	0800                	addi	s0,sp,16
    printf("hello test_task3\n");
 338:	00001517          	auipc	a0,0x1
 33c:	8b850513          	addi	a0,a0,-1864 # bf0 <malloc+0x1f2>
 340:	00000097          	auipc	ra,0x0
 344:	600080e7          	jalr	1536(ra) # 940 <printf>
    //sanity_test();
    //NFUA_LAPA_tests();
    // SCFIFO_test();
    // NONE_test();
    fork_test();
 348:	00000097          	auipc	ra,0x0
 34c:	e5a080e7          	jalr	-422(ra) # 1a2 <fork_test>
    //exec_test();
    exit(0);
 350:	4501                	li	a0,0
 352:	00000097          	auipc	ra,0x0
 356:	276080e7          	jalr	630(ra) # 5c8 <exit>

000000000000035a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 35a:	1141                	addi	sp,sp,-16
 35c:	e422                	sd	s0,8(sp)
 35e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 360:	87aa                	mv	a5,a0
 362:	0585                	addi	a1,a1,1
 364:	0785                	addi	a5,a5,1
 366:	fff5c703          	lbu	a4,-1(a1)
 36a:	fee78fa3          	sb	a4,-1(a5) # 9fff <__global_pointer$+0x8bde>
 36e:	fb75                	bnez	a4,362 <strcpy+0x8>
    ;
  return os;
}
 370:	6422                	ld	s0,8(sp)
 372:	0141                	addi	sp,sp,16
 374:	8082                	ret

0000000000000376 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 376:	1141                	addi	sp,sp,-16
 378:	e422                	sd	s0,8(sp)
 37a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 37c:	00054783          	lbu	a5,0(a0)
 380:	cb91                	beqz	a5,394 <strcmp+0x1e>
 382:	0005c703          	lbu	a4,0(a1)
 386:	00f71763          	bne	a4,a5,394 <strcmp+0x1e>
    p++, q++;
 38a:	0505                	addi	a0,a0,1
 38c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 38e:	00054783          	lbu	a5,0(a0)
 392:	fbe5                	bnez	a5,382 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 394:	0005c503          	lbu	a0,0(a1)
}
 398:	40a7853b          	subw	a0,a5,a0
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret

00000000000003a2 <strlen>:

uint
strlen(const char *s)
{
 3a2:	1141                	addi	sp,sp,-16
 3a4:	e422                	sd	s0,8(sp)
 3a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 3a8:	00054783          	lbu	a5,0(a0)
 3ac:	cf91                	beqz	a5,3c8 <strlen+0x26>
 3ae:	0505                	addi	a0,a0,1
 3b0:	87aa                	mv	a5,a0
 3b2:	4685                	li	a3,1
 3b4:	9e89                	subw	a3,a3,a0
 3b6:	00f6853b          	addw	a0,a3,a5
 3ba:	0785                	addi	a5,a5,1
 3bc:	fff7c703          	lbu	a4,-1(a5)
 3c0:	fb7d                	bnez	a4,3b6 <strlen+0x14>
    ;
  return n;
}
 3c2:	6422                	ld	s0,8(sp)
 3c4:	0141                	addi	sp,sp,16
 3c6:	8082                	ret
  for(n = 0; s[n]; n++)
 3c8:	4501                	li	a0,0
 3ca:	bfe5                	j	3c2 <strlen+0x20>

00000000000003cc <memset>:

void*
memset(void *dst, int c, uint n)
{
 3cc:	1141                	addi	sp,sp,-16
 3ce:	e422                	sd	s0,8(sp)
 3d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3d2:	ca19                	beqz	a2,3e8 <memset+0x1c>
 3d4:	87aa                	mv	a5,a0
 3d6:	1602                	slli	a2,a2,0x20
 3d8:	9201                	srli	a2,a2,0x20
 3da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3e2:	0785                	addi	a5,a5,1
 3e4:	fee79de3          	bne	a5,a4,3de <memset+0x12>
  }
  return dst;
}
 3e8:	6422                	ld	s0,8(sp)
 3ea:	0141                	addi	sp,sp,16
 3ec:	8082                	ret

00000000000003ee <strchr>:

char*
strchr(const char *s, char c)
{
 3ee:	1141                	addi	sp,sp,-16
 3f0:	e422                	sd	s0,8(sp)
 3f2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3f4:	00054783          	lbu	a5,0(a0)
 3f8:	cb99                	beqz	a5,40e <strchr+0x20>
    if(*s == c)
 3fa:	00f58763          	beq	a1,a5,408 <strchr+0x1a>
  for(; *s; s++)
 3fe:	0505                	addi	a0,a0,1
 400:	00054783          	lbu	a5,0(a0)
 404:	fbfd                	bnez	a5,3fa <strchr+0xc>
      return (char*)s;
  return 0;
 406:	4501                	li	a0,0
}
 408:	6422                	ld	s0,8(sp)
 40a:	0141                	addi	sp,sp,16
 40c:	8082                	ret
  return 0;
 40e:	4501                	li	a0,0
 410:	bfe5                	j	408 <strchr+0x1a>

0000000000000412 <gets>:

char*
gets(char *buf, int max)
{
 412:	711d                	addi	sp,sp,-96
 414:	ec86                	sd	ra,88(sp)
 416:	e8a2                	sd	s0,80(sp)
 418:	e4a6                	sd	s1,72(sp)
 41a:	e0ca                	sd	s2,64(sp)
 41c:	fc4e                	sd	s3,56(sp)
 41e:	f852                	sd	s4,48(sp)
 420:	f456                	sd	s5,40(sp)
 422:	f05a                	sd	s6,32(sp)
 424:	ec5e                	sd	s7,24(sp)
 426:	1080                	addi	s0,sp,96
 428:	8baa                	mv	s7,a0
 42a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 42c:	892a                	mv	s2,a0
 42e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 430:	4aa9                	li	s5,10
 432:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 434:	89a6                	mv	s3,s1
 436:	2485                	addiw	s1,s1,1
 438:	0344d863          	bge	s1,s4,468 <gets+0x56>
    cc = read(0, &c, 1);
 43c:	4605                	li	a2,1
 43e:	faf40593          	addi	a1,s0,-81
 442:	4501                	li	a0,0
 444:	00000097          	auipc	ra,0x0
 448:	19c080e7          	jalr	412(ra) # 5e0 <read>
    if(cc < 1)
 44c:	00a05e63          	blez	a0,468 <gets+0x56>
    buf[i++] = c;
 450:	faf44783          	lbu	a5,-81(s0)
 454:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 458:	01578763          	beq	a5,s5,466 <gets+0x54>
 45c:	0905                	addi	s2,s2,1
 45e:	fd679be3          	bne	a5,s6,434 <gets+0x22>
  for(i=0; i+1 < max; ){
 462:	89a6                	mv	s3,s1
 464:	a011                	j	468 <gets+0x56>
 466:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 468:	99de                	add	s3,s3,s7
 46a:	00098023          	sb	zero,0(s3)
  return buf;
}
 46e:	855e                	mv	a0,s7
 470:	60e6                	ld	ra,88(sp)
 472:	6446                	ld	s0,80(sp)
 474:	64a6                	ld	s1,72(sp)
 476:	6906                	ld	s2,64(sp)
 478:	79e2                	ld	s3,56(sp)
 47a:	7a42                	ld	s4,48(sp)
 47c:	7aa2                	ld	s5,40(sp)
 47e:	7b02                	ld	s6,32(sp)
 480:	6be2                	ld	s7,24(sp)
 482:	6125                	addi	sp,sp,96
 484:	8082                	ret

0000000000000486 <stat>:

int
stat(const char *n, struct stat *st)
{
 486:	1101                	addi	sp,sp,-32
 488:	ec06                	sd	ra,24(sp)
 48a:	e822                	sd	s0,16(sp)
 48c:	e426                	sd	s1,8(sp)
 48e:	e04a                	sd	s2,0(sp)
 490:	1000                	addi	s0,sp,32
 492:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 494:	4581                	li	a1,0
 496:	00000097          	auipc	ra,0x0
 49a:	172080e7          	jalr	370(ra) # 608 <open>
  if(fd < 0)
 49e:	02054563          	bltz	a0,4c8 <stat+0x42>
 4a2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 4a4:	85ca                	mv	a1,s2
 4a6:	00000097          	auipc	ra,0x0
 4aa:	17a080e7          	jalr	378(ra) # 620 <fstat>
 4ae:	892a                	mv	s2,a0
  close(fd);
 4b0:	8526                	mv	a0,s1
 4b2:	00000097          	auipc	ra,0x0
 4b6:	13e080e7          	jalr	318(ra) # 5f0 <close>
  return r;
}
 4ba:	854a                	mv	a0,s2
 4bc:	60e2                	ld	ra,24(sp)
 4be:	6442                	ld	s0,16(sp)
 4c0:	64a2                	ld	s1,8(sp)
 4c2:	6902                	ld	s2,0(sp)
 4c4:	6105                	addi	sp,sp,32
 4c6:	8082                	ret
    return -1;
 4c8:	597d                	li	s2,-1
 4ca:	bfc5                	j	4ba <stat+0x34>

00000000000004cc <atoi>:

int
atoi(const char *s)
{
 4cc:	1141                	addi	sp,sp,-16
 4ce:	e422                	sd	s0,8(sp)
 4d0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4d2:	00054603          	lbu	a2,0(a0)
 4d6:	fd06079b          	addiw	a5,a2,-48
 4da:	0ff7f793          	andi	a5,a5,255
 4de:	4725                	li	a4,9
 4e0:	02f76963          	bltu	a4,a5,512 <atoi+0x46>
 4e4:	86aa                	mv	a3,a0
  n = 0;
 4e6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4e8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4ea:	0685                	addi	a3,a3,1
 4ec:	0025179b          	slliw	a5,a0,0x2
 4f0:	9fa9                	addw	a5,a5,a0
 4f2:	0017979b          	slliw	a5,a5,0x1
 4f6:	9fb1                	addw	a5,a5,a2
 4f8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4fc:	0006c603          	lbu	a2,0(a3) # 1000 <__BSS_END__+0x3c0>
 500:	fd06071b          	addiw	a4,a2,-48
 504:	0ff77713          	andi	a4,a4,255
 508:	fee5f1e3          	bgeu	a1,a4,4ea <atoi+0x1e>
  return n;
}
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret
  n = 0;
 512:	4501                	li	a0,0
 514:	bfe5                	j	50c <atoi+0x40>

0000000000000516 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 516:	1141                	addi	sp,sp,-16
 518:	e422                	sd	s0,8(sp)
 51a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 51c:	02b57463          	bgeu	a0,a1,544 <memmove+0x2e>
    while(n-- > 0)
 520:	00c05f63          	blez	a2,53e <memmove+0x28>
 524:	1602                	slli	a2,a2,0x20
 526:	9201                	srli	a2,a2,0x20
 528:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 52c:	872a                	mv	a4,a0
      *dst++ = *src++;
 52e:	0585                	addi	a1,a1,1
 530:	0705                	addi	a4,a4,1
 532:	fff5c683          	lbu	a3,-1(a1)
 536:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 53a:	fee79ae3          	bne	a5,a4,52e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 53e:	6422                	ld	s0,8(sp)
 540:	0141                	addi	sp,sp,16
 542:	8082                	ret
    dst += n;
 544:	00c50733          	add	a4,a0,a2
    src += n;
 548:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 54a:	fec05ae3          	blez	a2,53e <memmove+0x28>
 54e:	fff6079b          	addiw	a5,a2,-1
 552:	1782                	slli	a5,a5,0x20
 554:	9381                	srli	a5,a5,0x20
 556:	fff7c793          	not	a5,a5
 55a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 55c:	15fd                	addi	a1,a1,-1
 55e:	177d                	addi	a4,a4,-1
 560:	0005c683          	lbu	a3,0(a1)
 564:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 568:	fee79ae3          	bne	a5,a4,55c <memmove+0x46>
 56c:	bfc9                	j	53e <memmove+0x28>

000000000000056e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 56e:	1141                	addi	sp,sp,-16
 570:	e422                	sd	s0,8(sp)
 572:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 574:	ca05                	beqz	a2,5a4 <memcmp+0x36>
 576:	fff6069b          	addiw	a3,a2,-1
 57a:	1682                	slli	a3,a3,0x20
 57c:	9281                	srli	a3,a3,0x20
 57e:	0685                	addi	a3,a3,1
 580:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 582:	00054783          	lbu	a5,0(a0)
 586:	0005c703          	lbu	a4,0(a1)
 58a:	00e79863          	bne	a5,a4,59a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 58e:	0505                	addi	a0,a0,1
    p2++;
 590:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 592:	fed518e3          	bne	a0,a3,582 <memcmp+0x14>
  }
  return 0;
 596:	4501                	li	a0,0
 598:	a019                	j	59e <memcmp+0x30>
      return *p1 - *p2;
 59a:	40e7853b          	subw	a0,a5,a4
}
 59e:	6422                	ld	s0,8(sp)
 5a0:	0141                	addi	sp,sp,16
 5a2:	8082                	ret
  return 0;
 5a4:	4501                	li	a0,0
 5a6:	bfe5                	j	59e <memcmp+0x30>

00000000000005a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5a8:	1141                	addi	sp,sp,-16
 5aa:	e406                	sd	ra,8(sp)
 5ac:	e022                	sd	s0,0(sp)
 5ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5b0:	00000097          	auipc	ra,0x0
 5b4:	f66080e7          	jalr	-154(ra) # 516 <memmove>
}
 5b8:	60a2                	ld	ra,8(sp)
 5ba:	6402                	ld	s0,0(sp)
 5bc:	0141                	addi	sp,sp,16
 5be:	8082                	ret

00000000000005c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5c0:	4885                	li	a7,1
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5c8:	4889                	li	a7,2
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 5d0:	488d                	li	a7,3
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5d8:	4891                	li	a7,4
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <read>:
.global read
read:
 li a7, SYS_read
 5e0:	4895                	li	a7,5
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <write>:
.global write
write:
 li a7, SYS_write
 5e8:	48c1                	li	a7,16
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <close>:
.global close
close:
 li a7, SYS_close
 5f0:	48d5                	li	a7,21
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5f8:	4899                	li	a7,6
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <exec>:
.global exec
exec:
 li a7, SYS_exec
 600:	489d                	li	a7,7
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <open>:
.global open
open:
 li a7, SYS_open
 608:	48bd                	li	a7,15
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 610:	48c5                	li	a7,17
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 618:	48c9                	li	a7,18
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 620:	48a1                	li	a7,8
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <link>:
.global link
link:
 li a7, SYS_link
 628:	48cd                	li	a7,19
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 630:	48d1                	li	a7,20
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 638:	48a5                	li	a7,9
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <dup>:
.global dup
dup:
 li a7, SYS_dup
 640:	48a9                	li	a7,10
 ecall
 642:	00000073          	ecall
 ret
 646:	8082                	ret

0000000000000648 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 648:	48ad                	li	a7,11
 ecall
 64a:	00000073          	ecall
 ret
 64e:	8082                	ret

0000000000000650 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 650:	48b1                	li	a7,12
 ecall
 652:	00000073          	ecall
 ret
 656:	8082                	ret

0000000000000658 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 658:	48b5                	li	a7,13
 ecall
 65a:	00000073          	ecall
 ret
 65e:	8082                	ret

0000000000000660 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 660:	48b9                	li	a7,14
 ecall
 662:	00000073          	ecall
 ret
 666:	8082                	ret

0000000000000668 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 668:	1101                	addi	sp,sp,-32
 66a:	ec06                	sd	ra,24(sp)
 66c:	e822                	sd	s0,16(sp)
 66e:	1000                	addi	s0,sp,32
 670:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 674:	4605                	li	a2,1
 676:	fef40593          	addi	a1,s0,-17
 67a:	00000097          	auipc	ra,0x0
 67e:	f6e080e7          	jalr	-146(ra) # 5e8 <write>
}
 682:	60e2                	ld	ra,24(sp)
 684:	6442                	ld	s0,16(sp)
 686:	6105                	addi	sp,sp,32
 688:	8082                	ret

000000000000068a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 68a:	7139                	addi	sp,sp,-64
 68c:	fc06                	sd	ra,56(sp)
 68e:	f822                	sd	s0,48(sp)
 690:	f426                	sd	s1,40(sp)
 692:	f04a                	sd	s2,32(sp)
 694:	ec4e                	sd	s3,24(sp)
 696:	0080                	addi	s0,sp,64
 698:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 69a:	c299                	beqz	a3,6a0 <printint+0x16>
 69c:	0805c863          	bltz	a1,72c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6a0:	2581                	sext.w	a1,a1
  neg = 0;
 6a2:	4881                	li	a7,0
 6a4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6a8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6aa:	2601                	sext.w	a2,a2
 6ac:	00000517          	auipc	a0,0x0
 6b0:	56450513          	addi	a0,a0,1380 # c10 <digits>
 6b4:	883a                	mv	a6,a4
 6b6:	2705                	addiw	a4,a4,1
 6b8:	02c5f7bb          	remuw	a5,a1,a2
 6bc:	1782                	slli	a5,a5,0x20
 6be:	9381                	srli	a5,a5,0x20
 6c0:	97aa                	add	a5,a5,a0
 6c2:	0007c783          	lbu	a5,0(a5)
 6c6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6ca:	0005879b          	sext.w	a5,a1
 6ce:	02c5d5bb          	divuw	a1,a1,a2
 6d2:	0685                	addi	a3,a3,1
 6d4:	fec7f0e3          	bgeu	a5,a2,6b4 <printint+0x2a>
  if(neg)
 6d8:	00088b63          	beqz	a7,6ee <printint+0x64>
    buf[i++] = '-';
 6dc:	fd040793          	addi	a5,s0,-48
 6e0:	973e                	add	a4,a4,a5
 6e2:	02d00793          	li	a5,45
 6e6:	fef70823          	sb	a5,-16(a4)
 6ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6ee:	02e05863          	blez	a4,71e <printint+0x94>
 6f2:	fc040793          	addi	a5,s0,-64
 6f6:	00e78933          	add	s2,a5,a4
 6fa:	fff78993          	addi	s3,a5,-1
 6fe:	99ba                	add	s3,s3,a4
 700:	377d                	addiw	a4,a4,-1
 702:	1702                	slli	a4,a4,0x20
 704:	9301                	srli	a4,a4,0x20
 706:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 70a:	fff94583          	lbu	a1,-1(s2)
 70e:	8526                	mv	a0,s1
 710:	00000097          	auipc	ra,0x0
 714:	f58080e7          	jalr	-168(ra) # 668 <putc>
  while(--i >= 0)
 718:	197d                	addi	s2,s2,-1
 71a:	ff3918e3          	bne	s2,s3,70a <printint+0x80>
}
 71e:	70e2                	ld	ra,56(sp)
 720:	7442                	ld	s0,48(sp)
 722:	74a2                	ld	s1,40(sp)
 724:	7902                	ld	s2,32(sp)
 726:	69e2                	ld	s3,24(sp)
 728:	6121                	addi	sp,sp,64
 72a:	8082                	ret
    x = -xx;
 72c:	40b005bb          	negw	a1,a1
    neg = 1;
 730:	4885                	li	a7,1
    x = -xx;
 732:	bf8d                	j	6a4 <printint+0x1a>

0000000000000734 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 734:	7119                	addi	sp,sp,-128
 736:	fc86                	sd	ra,120(sp)
 738:	f8a2                	sd	s0,112(sp)
 73a:	f4a6                	sd	s1,104(sp)
 73c:	f0ca                	sd	s2,96(sp)
 73e:	ecce                	sd	s3,88(sp)
 740:	e8d2                	sd	s4,80(sp)
 742:	e4d6                	sd	s5,72(sp)
 744:	e0da                	sd	s6,64(sp)
 746:	fc5e                	sd	s7,56(sp)
 748:	f862                	sd	s8,48(sp)
 74a:	f466                	sd	s9,40(sp)
 74c:	f06a                	sd	s10,32(sp)
 74e:	ec6e                	sd	s11,24(sp)
 750:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 752:	0005c903          	lbu	s2,0(a1)
 756:	18090f63          	beqz	s2,8f4 <vprintf+0x1c0>
 75a:	8aaa                	mv	s5,a0
 75c:	8b32                	mv	s6,a2
 75e:	00158493          	addi	s1,a1,1
  state = 0;
 762:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 764:	02500a13          	li	s4,37
      if(c == 'd'){
 768:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 76c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 770:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 774:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 778:	00000b97          	auipc	s7,0x0
 77c:	498b8b93          	addi	s7,s7,1176 # c10 <digits>
 780:	a839                	j	79e <vprintf+0x6a>
        putc(fd, c);
 782:	85ca                	mv	a1,s2
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	ee2080e7          	jalr	-286(ra) # 668 <putc>
 78e:	a019                	j	794 <vprintf+0x60>
    } else if(state == '%'){
 790:	01498f63          	beq	s3,s4,7ae <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 794:	0485                	addi	s1,s1,1
 796:	fff4c903          	lbu	s2,-1(s1)
 79a:	14090d63          	beqz	s2,8f4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 79e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7a2:	fe0997e3          	bnez	s3,790 <vprintf+0x5c>
      if(c == '%'){
 7a6:	fd479ee3          	bne	a5,s4,782 <vprintf+0x4e>
        state = '%';
 7aa:	89be                	mv	s3,a5
 7ac:	b7e5                	j	794 <vprintf+0x60>
      if(c == 'd'){
 7ae:	05878063          	beq	a5,s8,7ee <vprintf+0xba>
      } else if(c == 'l') {
 7b2:	05978c63          	beq	a5,s9,80a <vprintf+0xd6>
      } else if(c == 'x') {
 7b6:	07a78863          	beq	a5,s10,826 <vprintf+0xf2>
      } else if(c == 'p') {
 7ba:	09b78463          	beq	a5,s11,842 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 7be:	07300713          	li	a4,115
 7c2:	0ce78663          	beq	a5,a4,88e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7c6:	06300713          	li	a4,99
 7ca:	0ee78e63          	beq	a5,a4,8c6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7ce:	11478863          	beq	a5,s4,8de <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7d2:	85d2                	mv	a1,s4
 7d4:	8556                	mv	a0,s5
 7d6:	00000097          	auipc	ra,0x0
 7da:	e92080e7          	jalr	-366(ra) # 668 <putc>
        putc(fd, c);
 7de:	85ca                	mv	a1,s2
 7e0:	8556                	mv	a0,s5
 7e2:	00000097          	auipc	ra,0x0
 7e6:	e86080e7          	jalr	-378(ra) # 668 <putc>
      }
      state = 0;
 7ea:	4981                	li	s3,0
 7ec:	b765                	j	794 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7ee:	008b0913          	addi	s2,s6,8
 7f2:	4685                	li	a3,1
 7f4:	4629                	li	a2,10
 7f6:	000b2583          	lw	a1,0(s6)
 7fa:	8556                	mv	a0,s5
 7fc:	00000097          	auipc	ra,0x0
 800:	e8e080e7          	jalr	-370(ra) # 68a <printint>
 804:	8b4a                	mv	s6,s2
      state = 0;
 806:	4981                	li	s3,0
 808:	b771                	j	794 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 80a:	008b0913          	addi	s2,s6,8
 80e:	4681                	li	a3,0
 810:	4629                	li	a2,10
 812:	000b2583          	lw	a1,0(s6)
 816:	8556                	mv	a0,s5
 818:	00000097          	auipc	ra,0x0
 81c:	e72080e7          	jalr	-398(ra) # 68a <printint>
 820:	8b4a                	mv	s6,s2
      state = 0;
 822:	4981                	li	s3,0
 824:	bf85                	j	794 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 826:	008b0913          	addi	s2,s6,8
 82a:	4681                	li	a3,0
 82c:	4641                	li	a2,16
 82e:	000b2583          	lw	a1,0(s6)
 832:	8556                	mv	a0,s5
 834:	00000097          	auipc	ra,0x0
 838:	e56080e7          	jalr	-426(ra) # 68a <printint>
 83c:	8b4a                	mv	s6,s2
      state = 0;
 83e:	4981                	li	s3,0
 840:	bf91                	j	794 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 842:	008b0793          	addi	a5,s6,8
 846:	f8f43423          	sd	a5,-120(s0)
 84a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 84e:	03000593          	li	a1,48
 852:	8556                	mv	a0,s5
 854:	00000097          	auipc	ra,0x0
 858:	e14080e7          	jalr	-492(ra) # 668 <putc>
  putc(fd, 'x');
 85c:	85ea                	mv	a1,s10
 85e:	8556                	mv	a0,s5
 860:	00000097          	auipc	ra,0x0
 864:	e08080e7          	jalr	-504(ra) # 668 <putc>
 868:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 86a:	03c9d793          	srli	a5,s3,0x3c
 86e:	97de                	add	a5,a5,s7
 870:	0007c583          	lbu	a1,0(a5)
 874:	8556                	mv	a0,s5
 876:	00000097          	auipc	ra,0x0
 87a:	df2080e7          	jalr	-526(ra) # 668 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 87e:	0992                	slli	s3,s3,0x4
 880:	397d                	addiw	s2,s2,-1
 882:	fe0914e3          	bnez	s2,86a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 886:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 88a:	4981                	li	s3,0
 88c:	b721                	j	794 <vprintf+0x60>
        s = va_arg(ap, char*);
 88e:	008b0993          	addi	s3,s6,8
 892:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 896:	02090163          	beqz	s2,8b8 <vprintf+0x184>
        while(*s != 0){
 89a:	00094583          	lbu	a1,0(s2)
 89e:	c9a1                	beqz	a1,8ee <vprintf+0x1ba>
          putc(fd, *s);
 8a0:	8556                	mv	a0,s5
 8a2:	00000097          	auipc	ra,0x0
 8a6:	dc6080e7          	jalr	-570(ra) # 668 <putc>
          s++;
 8aa:	0905                	addi	s2,s2,1
        while(*s != 0){
 8ac:	00094583          	lbu	a1,0(s2)
 8b0:	f9e5                	bnez	a1,8a0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 8b2:	8b4e                	mv	s6,s3
      state = 0;
 8b4:	4981                	li	s3,0
 8b6:	bdf9                	j	794 <vprintf+0x60>
          s = "(null)";
 8b8:	00000917          	auipc	s2,0x0
 8bc:	35090913          	addi	s2,s2,848 # c08 <malloc+0x20a>
        while(*s != 0){
 8c0:	02800593          	li	a1,40
 8c4:	bff1                	j	8a0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8c6:	008b0913          	addi	s2,s6,8
 8ca:	000b4583          	lbu	a1,0(s6)
 8ce:	8556                	mv	a0,s5
 8d0:	00000097          	auipc	ra,0x0
 8d4:	d98080e7          	jalr	-616(ra) # 668 <putc>
 8d8:	8b4a                	mv	s6,s2
      state = 0;
 8da:	4981                	li	s3,0
 8dc:	bd65                	j	794 <vprintf+0x60>
        putc(fd, c);
 8de:	85d2                	mv	a1,s4
 8e0:	8556                	mv	a0,s5
 8e2:	00000097          	auipc	ra,0x0
 8e6:	d86080e7          	jalr	-634(ra) # 668 <putc>
      state = 0;
 8ea:	4981                	li	s3,0
 8ec:	b565                	j	794 <vprintf+0x60>
        s = va_arg(ap, char*);
 8ee:	8b4e                	mv	s6,s3
      state = 0;
 8f0:	4981                	li	s3,0
 8f2:	b54d                	j	794 <vprintf+0x60>
    }
  }
}
 8f4:	70e6                	ld	ra,120(sp)
 8f6:	7446                	ld	s0,112(sp)
 8f8:	74a6                	ld	s1,104(sp)
 8fa:	7906                	ld	s2,96(sp)
 8fc:	69e6                	ld	s3,88(sp)
 8fe:	6a46                	ld	s4,80(sp)
 900:	6aa6                	ld	s5,72(sp)
 902:	6b06                	ld	s6,64(sp)
 904:	7be2                	ld	s7,56(sp)
 906:	7c42                	ld	s8,48(sp)
 908:	7ca2                	ld	s9,40(sp)
 90a:	7d02                	ld	s10,32(sp)
 90c:	6de2                	ld	s11,24(sp)
 90e:	6109                	addi	sp,sp,128
 910:	8082                	ret

0000000000000912 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 912:	715d                	addi	sp,sp,-80
 914:	ec06                	sd	ra,24(sp)
 916:	e822                	sd	s0,16(sp)
 918:	1000                	addi	s0,sp,32
 91a:	e010                	sd	a2,0(s0)
 91c:	e414                	sd	a3,8(s0)
 91e:	e818                	sd	a4,16(s0)
 920:	ec1c                	sd	a5,24(s0)
 922:	03043023          	sd	a6,32(s0)
 926:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 92a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 92e:	8622                	mv	a2,s0
 930:	00000097          	auipc	ra,0x0
 934:	e04080e7          	jalr	-508(ra) # 734 <vprintf>
}
 938:	60e2                	ld	ra,24(sp)
 93a:	6442                	ld	s0,16(sp)
 93c:	6161                	addi	sp,sp,80
 93e:	8082                	ret

0000000000000940 <printf>:

void
printf(const char *fmt, ...)
{
 940:	711d                	addi	sp,sp,-96
 942:	ec06                	sd	ra,24(sp)
 944:	e822                	sd	s0,16(sp)
 946:	1000                	addi	s0,sp,32
 948:	e40c                	sd	a1,8(s0)
 94a:	e810                	sd	a2,16(s0)
 94c:	ec14                	sd	a3,24(s0)
 94e:	f018                	sd	a4,32(s0)
 950:	f41c                	sd	a5,40(s0)
 952:	03043823          	sd	a6,48(s0)
 956:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 95a:	00840613          	addi	a2,s0,8
 95e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 962:	85aa                	mv	a1,a0
 964:	4505                	li	a0,1
 966:	00000097          	auipc	ra,0x0
 96a:	dce080e7          	jalr	-562(ra) # 734 <vprintf>
}
 96e:	60e2                	ld	ra,24(sp)
 970:	6442                	ld	s0,16(sp)
 972:	6125                	addi	sp,sp,96
 974:	8082                	ret

0000000000000976 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 976:	1141                	addi	sp,sp,-16
 978:	e422                	sd	s0,8(sp)
 97a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 97c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 980:	00000797          	auipc	a5,0x0
 984:	2a87b783          	ld	a5,680(a5) # c28 <freep>
 988:	a805                	j	9b8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 98a:	4618                	lw	a4,8(a2)
 98c:	9db9                	addw	a1,a1,a4
 98e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 992:	6398                	ld	a4,0(a5)
 994:	6318                	ld	a4,0(a4)
 996:	fee53823          	sd	a4,-16(a0)
 99a:	a091                	j	9de <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 99c:	ff852703          	lw	a4,-8(a0)
 9a0:	9e39                	addw	a2,a2,a4
 9a2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9a4:	ff053703          	ld	a4,-16(a0)
 9a8:	e398                	sd	a4,0(a5)
 9aa:	a099                	j	9f0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9ac:	6398                	ld	a4,0(a5)
 9ae:	00e7e463          	bltu	a5,a4,9b6 <free+0x40>
 9b2:	00e6ea63          	bltu	a3,a4,9c6 <free+0x50>
{
 9b6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9b8:	fed7fae3          	bgeu	a5,a3,9ac <free+0x36>
 9bc:	6398                	ld	a4,0(a5)
 9be:	00e6e463          	bltu	a3,a4,9c6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9c2:	fee7eae3          	bltu	a5,a4,9b6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9c6:	ff852583          	lw	a1,-8(a0)
 9ca:	6390                	ld	a2,0(a5)
 9cc:	02059813          	slli	a6,a1,0x20
 9d0:	01c85713          	srli	a4,a6,0x1c
 9d4:	9736                	add	a4,a4,a3
 9d6:	fae60ae3          	beq	a2,a4,98a <free+0x14>
    bp->s.ptr = p->s.ptr;
 9da:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9de:	4790                	lw	a2,8(a5)
 9e0:	02061593          	slli	a1,a2,0x20
 9e4:	01c5d713          	srli	a4,a1,0x1c
 9e8:	973e                	add	a4,a4,a5
 9ea:	fae689e3          	beq	a3,a4,99c <free+0x26>
  } else
    p->s.ptr = bp;
 9ee:	e394                	sd	a3,0(a5)
  freep = p;
 9f0:	00000717          	auipc	a4,0x0
 9f4:	22f73c23          	sd	a5,568(a4) # c28 <freep>
}
 9f8:	6422                	ld	s0,8(sp)
 9fa:	0141                	addi	sp,sp,16
 9fc:	8082                	ret

00000000000009fe <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9fe:	7139                	addi	sp,sp,-64
 a00:	fc06                	sd	ra,56(sp)
 a02:	f822                	sd	s0,48(sp)
 a04:	f426                	sd	s1,40(sp)
 a06:	f04a                	sd	s2,32(sp)
 a08:	ec4e                	sd	s3,24(sp)
 a0a:	e852                	sd	s4,16(sp)
 a0c:	e456                	sd	s5,8(sp)
 a0e:	e05a                	sd	s6,0(sp)
 a10:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a12:	02051493          	slli	s1,a0,0x20
 a16:	9081                	srli	s1,s1,0x20
 a18:	04bd                	addi	s1,s1,15
 a1a:	8091                	srli	s1,s1,0x4
 a1c:	0014899b          	addiw	s3,s1,1
 a20:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a22:	00000517          	auipc	a0,0x0
 a26:	20653503          	ld	a0,518(a0) # c28 <freep>
 a2a:	c515                	beqz	a0,a56 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a2c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a2e:	4798                	lw	a4,8(a5)
 a30:	02977f63          	bgeu	a4,s1,a6e <malloc+0x70>
 a34:	8a4e                	mv	s4,s3
 a36:	0009871b          	sext.w	a4,s3
 a3a:	6685                	lui	a3,0x1
 a3c:	00d77363          	bgeu	a4,a3,a42 <malloc+0x44>
 a40:	6a05                	lui	s4,0x1
 a42:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a46:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a4a:	00000917          	auipc	s2,0x0
 a4e:	1de90913          	addi	s2,s2,478 # c28 <freep>
  if(p == (char*)-1)
 a52:	5afd                	li	s5,-1
 a54:	a895                	j	ac8 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a56:	00000797          	auipc	a5,0x0
 a5a:	1da78793          	addi	a5,a5,474 # c30 <base>
 a5e:	00000717          	auipc	a4,0x0
 a62:	1cf73523          	sd	a5,458(a4) # c28 <freep>
 a66:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a68:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a6c:	b7e1                	j	a34 <malloc+0x36>
      if(p->s.size == nunits)
 a6e:	02e48c63          	beq	s1,a4,aa6 <malloc+0xa8>
        p->s.size -= nunits;
 a72:	4137073b          	subw	a4,a4,s3
 a76:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a78:	02071693          	slli	a3,a4,0x20
 a7c:	01c6d713          	srli	a4,a3,0x1c
 a80:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a82:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a86:	00000717          	auipc	a4,0x0
 a8a:	1aa73123          	sd	a0,418(a4) # c28 <freep>
      return (void*)(p + 1);
 a8e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a92:	70e2                	ld	ra,56(sp)
 a94:	7442                	ld	s0,48(sp)
 a96:	74a2                	ld	s1,40(sp)
 a98:	7902                	ld	s2,32(sp)
 a9a:	69e2                	ld	s3,24(sp)
 a9c:	6a42                	ld	s4,16(sp)
 a9e:	6aa2                	ld	s5,8(sp)
 aa0:	6b02                	ld	s6,0(sp)
 aa2:	6121                	addi	sp,sp,64
 aa4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 aa6:	6398                	ld	a4,0(a5)
 aa8:	e118                	sd	a4,0(a0)
 aaa:	bff1                	j	a86 <malloc+0x88>
  hp->s.size = nu;
 aac:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ab0:	0541                	addi	a0,a0,16
 ab2:	00000097          	auipc	ra,0x0
 ab6:	ec4080e7          	jalr	-316(ra) # 976 <free>
  return freep;
 aba:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 abe:	d971                	beqz	a0,a92 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ac0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 ac2:	4798                	lw	a4,8(a5)
 ac4:	fa9775e3          	bgeu	a4,s1,a6e <malloc+0x70>
    if(p == freep)
 ac8:	00093703          	ld	a4,0(s2)
 acc:	853e                	mv	a0,a5
 ace:	fef719e3          	bne	a4,a5,ac0 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 ad2:	8552                	mv	a0,s4
 ad4:	00000097          	auipc	ra,0x0
 ad8:	b7c080e7          	jalr	-1156(ra) # 650 <sbrk>
  if(p == (char*)-1)
 adc:	fd5518e3          	bne	a0,s5,aac <malloc+0xae>
        return 0;
 ae0:	4501                	li	a0,0
 ae2:	bf45                	j	a92 <malloc+0x94>
