
user/_test_sig:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <t_handler>:
void test1_handler(int signum){
    printf("created also in order to make test_handler`s address not 0\n");
}


void t_handler(int signum){
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
    test = 1;
   6:	4785                	li	a5,1
   8:	00001717          	auipc	a4,0x1
   c:	14f72423          	sw	a5,328(a4) # 1150 <test>
}
  10:	6422                	ld	s0,8(sp)
  12:	0141                	addi	sp,sp,16
  14:	8082                	ret

0000000000000016 <test_handler>:

void test_handler(int signum){
  16:	1141                	addi	sp,sp,-16
  18:	e422                	sd	s0,8(sp)
  1a:	0800                	addi	s0,sp,16
    test = 1;
  1c:	4785                	li	a5,1
  1e:	00001717          	auipc	a4,0x1
  22:	12f72923          	sw	a5,306(a4) # 1150 <test>
}
  26:	6422                	ld	s0,8(sp)
  28:	0141                	addi	sp,sp,16
  2a:	8082                	ret

000000000000002c <test2_handler>:
void test2_handler(int x){
  2c:	1141                	addi	sp,sp,-16
  2e:	e406                	sd	ra,8(sp)
  30:	e022                	sd	s0,0(sp)
  32:	0800                	addi	s0,sp,16
    printf("created in order to make test_handler`s address not 0\n");
  34:	00001517          	auipc	a0,0x1
  38:	cac50513          	addi	a0,a0,-852 # ce0 <malloc+0xec>
  3c:	00001097          	auipc	ra,0x1
  40:	afa080e7          	jalr	-1286(ra) # b36 <printf>
}
  44:	60a2                	ld	ra,8(sp)
  46:	6402                	ld	s0,0(sp)
  48:	0141                	addi	sp,sp,16
  4a:	8082                	ret

000000000000004c <test1_handler>:
void test1_handler(int signum){
  4c:	1141                	addi	sp,sp,-16
  4e:	e406                	sd	ra,8(sp)
  50:	e022                	sd	s0,0(sp)
  52:	0800                	addi	s0,sp,16
    printf("created also in order to make test_handler`s address not 0\n");
  54:	00001517          	auipc	a0,0x1
  58:	cc450513          	addi	a0,a0,-828 # d18 <malloc+0x124>
  5c:	00001097          	auipc	ra,0x1
  60:	ada080e7          	jalr	-1318(ra) # b36 <printf>
}
  64:	60a2                	ld	ra,8(sp)
  66:	6402                	ld	s0,0(sp)
  68:	0141                	addi	sp,sp,16
  6a:	8082                	ret

000000000000006c <test_kill_handler>:
void test_kill_handler(int x){
  6c:	1141                	addi	sp,sp,-16
  6e:	e406                	sd	ra,8(sp)
  70:	e022                	sd	s0,0(sp)
  72:	0800                	addi	s0,sp,16
    printf("kill handler invoked\n");
  74:	00001517          	auipc	a0,0x1
  78:	ce450513          	addi	a0,a0,-796 # d58 <malloc+0x164>
  7c:	00001097          	auipc	ra,0x1
  80:	aba080e7          	jalr	-1350(ra) # b36 <printf>
}
  84:	60a2                	ld	ra,8(sp)
  86:	6402                	ld	s0,0(sp)
  88:	0141                	addi	sp,sp,16
  8a:	8082                	ret

000000000000008c <main>:

int main(int argc, char **argv)
{
  8c:	7179                	addi	sp,sp,-48
  8e:	f406                	sd	ra,40(sp)
  90:	f022                	sd	s0,32(sp)
  92:	ec26                	sd	s1,24(sp)
  94:	1800                	addi	s0,sp,48
    printf("HELLO TEST SIG\n");
  96:	00001517          	auipc	a0,0x1
  9a:	cda50513          	addi	a0,a0,-806 # d70 <malloc+0x17c>
  9e:	00001097          	auipc	ra,0x1
  a2:	a98080e7          	jalr	-1384(ra) # b36 <printf>
    printf("test2 handler pointer: %p\n", test2_handler);
  a6:	00000597          	auipc	a1,0x0
  aa:	f8658593          	addi	a1,a1,-122 # 2c <test2_handler>
  ae:	00001517          	auipc	a0,0x1
  b2:	cd250513          	addi	a0,a0,-814 # d80 <malloc+0x18c>
  b6:	00001097          	auipc	ra,0x1
  ba:	a80080e7          	jalr	-1408(ra) # b36 <printf>
    printf("test handler pointer: %p\n", t_handler);
  be:	00000597          	auipc	a1,0x0
  c2:	f4258593          	addi	a1,a1,-190 # 0 <t_handler>
  c6:	00001517          	auipc	a0,0x1
  ca:	cda50513          	addi	a0,a0,-806 # da0 <malloc+0x1ac>
  ce:	00001097          	auipc	ra,0x1
  d2:	a68080e7          	jalr	-1432(ra) # b36 <printf>
    printf("t handler pointer: %p\n", t_handler);
  d6:	00000597          	auipc	a1,0x0
  da:	f2a58593          	addi	a1,a1,-214 # 0 <t_handler>
  de:	00001517          	auipc	a0,0x1
  e2:	ce250513          	addi	a0,a0,-798 # dc0 <malloc+0x1cc>
  e6:	00001097          	auipc	ra,0x1
  ea:	a50080e7          	jalr	-1456(ra) # b36 <printf>
    printf("test1 handler pointer: %p\n", test1_handler);
  ee:	00000597          	auipc	a1,0x0
  f2:	f5e58593          	addi	a1,a1,-162 # 4c <test1_handler>
  f6:	00001517          	auipc	a0,0x1
  fa:	ce250513          	addi	a0,a0,-798 # dd8 <malloc+0x1e4>
  fe:	00001097          	auipc	ra,0x1
 102:	a38080e7          	jalr	-1480(ra) # b36 <printf>
    printf("created in order to make test_handler`s address not 0\n");
 106:	00001517          	auipc	a0,0x1
 10a:	bda50513          	addi	a0,a0,-1062 # ce0 <malloc+0xec>
 10e:	00001097          	auipc	ra,0x1
 112:	a28080e7          	jalr	-1496(ra) # b36 <printf>

    test2_handler(1);

    test = 0;
 116:	00001797          	auipc	a5,0x1
 11a:	0207ad23          	sw	zero,58(a5) # 1150 <test>
    
    struct sigaction act;
    act.sa_handler = (void(*)(int)) test_handler;
 11e:	00000797          	auipc	a5,0x0
 122:	ef878793          	addi	a5,a5,-264 # 16 <test_handler>
 126:	fcf43823          	sd	a5,-48(s0)
    act.sigmask = 0;
 12a:	fc042c23          	sw	zero,-40(s0)

    if(sigaction(SIGSTOP, &act, 0) != -1){
 12e:	4601                	li	a2,0
 130:	fd040593          	addi	a1,s0,-48
 134:	4545                	li	a0,17
 136:	00000097          	auipc	ra,0x0
 13a:	6d6080e7          	jalr	1750(ra) # 80c <sigaction>
 13e:	57fd                	li	a5,-1
 140:	12f50563          	beq	a0,a5,26a <main+0x1de>
        printf("test1 failed - SIGSTOP cannot be modified\n");
 144:	00001517          	auipc	a0,0x1
 148:	cb450513          	addi	a0,a0,-844 # df8 <malloc+0x204>
 14c:	00001097          	auipc	ra,0x1
 150:	9ea080e7          	jalr	-1558(ra) # b36 <printf>
    }else{
        printf("test1 passed\n");
    }

    if(sigaction(SIGKILL, &act, 0) != -1){
 154:	4601                	li	a2,0
 156:	fd040593          	addi	a1,s0,-48
 15a:	4525                	li	a0,9
 15c:	00000097          	auipc	ra,0x0
 160:	6b0080e7          	jalr	1712(ra) # 80c <sigaction>
 164:	57fd                	li	a5,-1
 166:	10f50b63          	beq	a0,a5,27c <main+0x1f0>
        printf("test2 failed - SIGKILL cannot be modified\n");
 16a:	00001517          	auipc	a0,0x1
 16e:	cce50513          	addi	a0,a0,-818 # e38 <malloc+0x244>
 172:	00001097          	auipc	ra,0x1
 176:	9c4080e7          	jalr	-1596(ra) # b36 <printf>
    }else{
        printf("test2 passed\n");
    }

    act.sigmask = (1 << SIGKILL) | (1 << SIGSTOP);
 17a:	000207b7          	lui	a5,0x20
 17e:	20078793          	addi	a5,a5,512 # 20200 <__global_pointer$+0x1e8b7>
 182:	fcf42c23          	sw	a5,-40(s0)
    if(sigaction(SIGSTOP, &act, 0) != -1){
 186:	4601                	li	a2,0
 188:	fd040593          	addi	a1,s0,-48
 18c:	4545                	li	a0,17
 18e:	00000097          	auipc	ra,0x0
 192:	67e080e7          	jalr	1662(ra) # 80c <sigaction>
 196:	57fd                	li	a5,-1
 198:	0ef50b63          	beq	a0,a5,28e <main+0x202>
        printf("test3 failed - SIGSTOP and SIGKILL cannot be ignored\n");
 19c:	00001517          	auipc	a0,0x1
 1a0:	cdc50513          	addi	a0,a0,-804 # e78 <malloc+0x284>
 1a4:	00001097          	auipc	ra,0x1
 1a8:	992080e7          	jalr	-1646(ra) # b36 <printf>
    }else{
        printf("test3 passed\n");
    }

    uint mask = (1 << SIGKILL) | (1 << SIGSTOP);
    if (sigprocmask(mask) != -1){
 1ac:	00020537          	lui	a0,0x20
 1b0:	20050513          	addi	a0,a0,512 # 20200 <__global_pointer$+0x1e8b7>
 1b4:	00000097          	auipc	ra,0x0
 1b8:	650080e7          	jalr	1616(ra) # 804 <sigprocmask>
 1bc:	2501                	sext.w	a0,a0
 1be:	57fd                	li	a5,-1
 1c0:	0ef50063          	beq	a0,a5,2a0 <main+0x214>
        printf("test4 failed - SIGSTOP and SIGKILL cannot be blocked\n");
 1c4:	00001517          	auipc	a0,0x1
 1c8:	cfc50513          	addi	a0,a0,-772 # ec0 <malloc+0x2cc>
 1cc:	00001097          	auipc	ra,0x1
 1d0:	96a080e7          	jalr	-1686(ra) # b36 <printf>
    }else{
        printf("test4 passed\n");
    }

    mask = (1 << 7);
    if (sigprocmask(mask) != 0){
 1d4:	08000513          	li	a0,128
 1d8:	00000097          	auipc	ra,0x0
 1dc:	62c080e7          	jalr	1580(ra) # 804 <sigprocmask>
 1e0:	2501                	sext.w	a0,a0
 1e2:	c961                	beqz	a0,2b2 <main+0x226>
        printf("test5 failed - init mask should be 0\n");
 1e4:	00001517          	auipc	a0,0x1
 1e8:	d2450513          	addi	a0,a0,-732 # f08 <malloc+0x314>
 1ec:	00001097          	auipc	ra,0x1
 1f0:	94a080e7          	jalr	-1718(ra) # b36 <printf>
    }else{
        printf("test5 passed\n");
    }
    
    if (sigprocmask((1 << 14)) != mask){
 1f4:	6511                	lui	a0,0x4
 1f6:	00000097          	auipc	ra,0x0
 1fa:	60e080e7          	jalr	1550(ra) # 804 <sigprocmask>
 1fe:	2501                	sext.w	a0,a0
 200:	08000793          	li	a5,128
 204:	0cf50063          	beq	a0,a5,2c4 <main+0x238>
        printf("test6 failed - old mask should be 7\n");
 208:	00001517          	auipc	a0,0x1
 20c:	d3850513          	addi	a0,a0,-712 # f40 <malloc+0x34c>
 210:	00001097          	auipc	ra,0x1
 214:	926080e7          	jalr	-1754(ra) # b36 <printf>
    }else{
        printf("test6 passed\n");
    }
    
    act.sigmask = 0;
 218:	fc042c23          	sw	zero,-40(s0)
    if (sigaction(7, &act, 0) == 0){
 21c:	4601                	li	a2,0
 21e:	fd040593          	addi	a1,s0,-48
 222:	451d                	li	a0,7
 224:	00000097          	auipc	ra,0x0
 228:	5e8080e7          	jalr	1512(ra) # 80c <sigaction>
 22c:	ed55                	bnez	a0,2e8 <main+0x25c>
        kill(getpid(), 7);
 22e:	00000097          	auipc	ra,0x0
 232:	5b6080e7          	jalr	1462(ra) # 7e4 <getpid>
 236:	459d                	li	a1,7
 238:	00000097          	auipc	ra,0x0
 23c:	55c080e7          	jalr	1372(ra) # 794 <kill>
        sleep(2);
 240:	4509                	li	a0,2
 242:	00000097          	auipc	ra,0x0
 246:	5b2080e7          	jalr	1458(ra) # 7f4 <sleep>
        if(test != 1){
 24a:	00001717          	auipc	a4,0x1
 24e:	f0672703          	lw	a4,-250(a4) # 1150 <test>
 252:	4785                	li	a5,1
 254:	08f70163          	beq	a4,a5,2d6 <main+0x24a>
            printf("test7 failed - test_handler did not invoke\n");
 258:	00001517          	auipc	a0,0x1
 25c:	d2050513          	addi	a0,a0,-736 # f78 <malloc+0x384>
 260:	00001097          	auipc	ra,0x1
 264:	8d6080e7          	jalr	-1834(ra) # b36 <printf>
 268:	a841                	j	2f8 <main+0x26c>
        printf("test1 passed\n");
 26a:	00001517          	auipc	a0,0x1
 26e:	bbe50513          	addi	a0,a0,-1090 # e28 <malloc+0x234>
 272:	00001097          	auipc	ra,0x1
 276:	8c4080e7          	jalr	-1852(ra) # b36 <printf>
 27a:	bde9                	j	154 <main+0xc8>
        printf("test2 passed\n");
 27c:	00001517          	auipc	a0,0x1
 280:	bec50513          	addi	a0,a0,-1044 # e68 <malloc+0x274>
 284:	00001097          	auipc	ra,0x1
 288:	8b2080e7          	jalr	-1870(ra) # b36 <printf>
 28c:	b5fd                	j	17a <main+0xee>
        printf("test3 passed\n");
 28e:	00001517          	auipc	a0,0x1
 292:	c2250513          	addi	a0,a0,-990 # eb0 <malloc+0x2bc>
 296:	00001097          	auipc	ra,0x1
 29a:	8a0080e7          	jalr	-1888(ra) # b36 <printf>
 29e:	b739                	j	1ac <main+0x120>
        printf("test4 passed\n");
 2a0:	00001517          	auipc	a0,0x1
 2a4:	c5850513          	addi	a0,a0,-936 # ef8 <malloc+0x304>
 2a8:	00001097          	auipc	ra,0x1
 2ac:	88e080e7          	jalr	-1906(ra) # b36 <printf>
 2b0:	b715                	j	1d4 <main+0x148>
        printf("test5 passed\n");
 2b2:	00001517          	auipc	a0,0x1
 2b6:	c7e50513          	addi	a0,a0,-898 # f30 <malloc+0x33c>
 2ba:	00001097          	auipc	ra,0x1
 2be:	87c080e7          	jalr	-1924(ra) # b36 <printf>
 2c2:	bf0d                	j	1f4 <main+0x168>
        printf("test6 passed\n");
 2c4:	00001517          	auipc	a0,0x1
 2c8:	ca450513          	addi	a0,a0,-860 # f68 <malloc+0x374>
 2cc:	00001097          	auipc	ra,0x1
 2d0:	86a080e7          	jalr	-1942(ra) # b36 <printf>
 2d4:	b791                	j	218 <main+0x18c>
        }else{
            printf("test7 passed\n");
 2d6:	00001517          	auipc	a0,0x1
 2da:	cd250513          	addi	a0,a0,-814 # fa8 <malloc+0x3b4>
 2de:	00001097          	auipc	ra,0x1
 2e2:	858080e7          	jalr	-1960(ra) # b36 <printf>
 2e6:	a809                	j	2f8 <main+0x26c>
        }
    }else{
        printf("test7 failed - sigaction failed\n");
 2e8:	00001517          	auipc	a0,0x1
 2ec:	cd050513          	addi	a0,a0,-816 # fb8 <malloc+0x3c4>
 2f0:	00001097          	auipc	ra,0x1
 2f4:	846080e7          	jalr	-1978(ra) # b36 <printf>
    }

    test = 0;
 2f8:	00001797          	auipc	a5,0x1
 2fc:	e407ac23          	sw	zero,-424(a5) # 1150 <test>
    sigprocmask((1 << 14));
 300:	6511                	lui	a0,0x4
 302:	00000097          	auipc	ra,0x0
 306:	502080e7          	jalr	1282(ra) # 804 <sigprocmask>
    if (sigaction(14, &act, 0) == 0){
 30a:	4601                	li	a2,0
 30c:	fd040593          	addi	a1,s0,-48
 310:	4539                	li	a0,14
 312:	00000097          	auipc	ra,0x0
 316:	4fa080e7          	jalr	1274(ra) # 80c <sigaction>
 31a:	e921                	bnez	a0,36a <main+0x2de>
        kill(getpid(), 14);
 31c:	00000097          	auipc	ra,0x0
 320:	4c8080e7          	jalr	1224(ra) # 7e4 <getpid>
 324:	45b9                	li	a1,14
 326:	00000097          	auipc	ra,0x0
 32a:	46e080e7          	jalr	1134(ra) # 794 <kill>
        sleep(2);
 32e:	4509                	li	a0,2
 330:	00000097          	auipc	ra,0x0
 334:	4c4080e7          	jalr	1220(ra) # 7f4 <sleep>
        if(test == 1){
 338:	00001717          	auipc	a4,0x1
 33c:	e1872703          	lw	a4,-488(a4) # 1150 <test>
 340:	4785                	li	a5,1
 342:	00f70b63          	beq	a4,a5,358 <main+0x2cc>
            printf("test8 failed - test_handler did not blocked by the mask\n");
        } else{
            printf("test8 passed\n");
 346:	00001517          	auipc	a0,0x1
 34a:	cda50513          	addi	a0,a0,-806 # 1020 <malloc+0x42c>
 34e:	00000097          	auipc	ra,0x0
 352:	7e8080e7          	jalr	2024(ra) # b36 <printf>
 356:	a015                	j	37a <main+0x2ee>
            printf("test8 failed - test_handler did not blocked by the mask\n");
 358:	00001517          	auipc	a0,0x1
 35c:	c8850513          	addi	a0,a0,-888 # fe0 <malloc+0x3ec>
 360:	00000097          	auipc	ra,0x0
 364:	7d6080e7          	jalr	2006(ra) # b36 <printf>
 368:	a809                	j	37a <main+0x2ee>
        }   
    }else{
        printf("test8 failed - sigaction failed\n");
 36a:	00001517          	auipc	a0,0x1
 36e:	cc650513          	addi	a0,a0,-826 # 1030 <malloc+0x43c>
 372:	00000097          	auipc	ra,0x0
 376:	7c4080e7          	jalr	1988(ra) # b36 <printf>
    }

    printf("in order to pass tests 9-12 you should get a passed messages\n");
 37a:	00001517          	auipc	a0,0x1
 37e:	cde50513          	addi	a0,a0,-802 # 1058 <malloc+0x464>
 382:	00000097          	auipc	ra,0x0
 386:	7b4080e7          	jalr	1972(ra) # b36 <printf>

    // check sleep and wakeup child
    int pid = fork();
 38a:	00000097          	auipc	ra,0x0
 38e:	3d2080e7          	jalr	978(ra) # 75c <fork>
 392:	84aa                	mv	s1,a0
    if (pid == 0) {
 394:	e11d                	bnez	a0,3ba <main+0x32e>
        sleep(1);
 396:	4505                	li	a0,1
 398:	00000097          	auipc	ra,0x0
 39c:	45c080e7          	jalr	1116(ra) # 7f4 <sleep>
        printf("test9 - passed\n");
 3a0:	00001517          	auipc	a0,0x1
 3a4:	cf850513          	addi	a0,a0,-776 # 1098 <malloc+0x4a4>
 3a8:	00000097          	auipc	ra,0x0
 3ac:	78e080e7          	jalr	1934(ra) # b36 <printf>
        exit(0);
 3b0:	4501                	li	a0,0
 3b2:	00000097          	auipc	ra,0x0
 3b6:	3b2080e7          	jalr	946(ra) # 764 <exit>
    } else {
        kill(pid, SIGSTOP);
 3ba:	45c5                	li	a1,17
 3bc:	00000097          	auipc	ra,0x0
 3c0:	3d8080e7          	jalr	984(ra) # 794 <kill>
        sleep(2);
 3c4:	4509                	li	a0,2
 3c6:	00000097          	auipc	ra,0x0
 3ca:	42e080e7          	jalr	1070(ra) # 7f4 <sleep>
        kill(pid, SIGCONT);
 3ce:	45cd                	li	a1,19
 3d0:	8526                	mv	a0,s1
 3d2:	00000097          	auipc	ra,0x0
 3d6:	3c2080e7          	jalr	962(ra) # 794 <kill>
        wait(0);
 3da:	4501                	li	a0,0
 3dc:	00000097          	auipc	ra,0x0
 3e0:	390080e7          	jalr	912(ra) # 76c <wait>
    }

    // check kill child 
    pid = fork();
 3e4:	00000097          	auipc	ra,0x0
 3e8:	378080e7          	jalr	888(ra) # 75c <fork>
    if (pid == 0) {
 3ec:	e519                	bnez	a0,3fa <main+0x36e>
        while(1){
            sleep(1);
 3ee:	4505                	li	a0,1
 3f0:	00000097          	auipc	ra,0x0
 3f4:	404080e7          	jalr	1028(ra) # 7f4 <sleep>
        while(1){
 3f8:	bfdd                	j	3ee <main+0x362>
        }
    } else {
        kill(pid, SIGKILL);
 3fa:	45a5                	li	a1,9
 3fc:	00000097          	auipc	ra,0x0
 400:	398080e7          	jalr	920(ra) # 794 <kill>
        wait(0);
 404:	4501                	li	a0,0
 406:	00000097          	auipc	ra,0x0
 40a:	366080e7          	jalr	870(ra) # 76c <wait>
        printf("test 10 - passed\n");
 40e:	00001517          	auipc	a0,0x1
 412:	c9a50513          	addi	a0,a0,-870 # 10a8 <malloc+0x4b4>
 416:	00000097          	auipc	ra,0x0
 41a:	720080e7          	jalr	1824(ra) # b36 <printf>
    }

    //check kill child with SIG_DFL
    pid = fork();
 41e:	00000097          	auipc	ra,0x0
 422:	33e080e7          	jalr	830(ra) # 75c <fork>
    if (pid == 0) {
 426:	e519                	bnez	a0,434 <main+0x3a8>
        while(1){
            sleep(1);
 428:	4505                	li	a0,1
 42a:	00000097          	auipc	ra,0x0
 42e:	3ca080e7          	jalr	970(ra) # 7f4 <sleep>
        while(1){
 432:	bfdd                	j	428 <main+0x39c>
        }
    } else {
        kill(pid, 24);
 434:	45e1                	li	a1,24
 436:	00000097          	auipc	ra,0x0
 43a:	35e080e7          	jalr	862(ra) # 794 <kill>
        wait(0);
 43e:	4501                	li	a0,0
 440:	00000097          	auipc	ra,0x0
 444:	32c080e7          	jalr	812(ra) # 76c <wait>
        printf("test 11 - passed\n");
 448:	00001517          	auipc	a0,0x1
 44c:	c7850513          	addi	a0,a0,-904 # 10c0 <malloc+0x4cc>
 450:	00000097          	auipc	ra,0x0
 454:	6e6080e7          	jalr	1766(ra) # b36 <printf>
    }

    // check if child inherit parnet's mask and handlers
    act.sa_handler = (void(*)(int)) test_handler;
 458:	00000797          	auipc	a5,0x0
 45c:	bbe78793          	addi	a5,a5,-1090 # 16 <test_handler>
 460:	fcf43823          	sd	a5,-48(s0)
    act.sigmask = 0;
 464:	fc042c23          	sw	zero,-40(s0)
    sigaction(27, &act, 0);
 468:	4601                	li	a2,0
 46a:	fd040593          	addi	a1,s0,-48
 46e:	456d                	li	a0,27
 470:	00000097          	auipc	ra,0x0
 474:	39c080e7          	jalr	924(ra) # 80c <sigaction>
    sigprocmask((1<<26));
 478:	04000537          	lui	a0,0x4000
 47c:	00000097          	auipc	ra,0x0
 480:	388080e7          	jalr	904(ra) # 804 <sigprocmask>
    pid = fork();
 484:	00000097          	auipc	ra,0x0
 488:	2d8080e7          	jalr	728(ra) # 75c <fork>
    if(pid == 0){
 48c:	ed39                	bnez	a0,4ea <main+0x45e>
        if(sigprocmask(0) != (1<<26)){
 48e:	00000097          	auipc	ra,0x0
 492:	376080e7          	jalr	886(ra) # 804 <sigprocmask>
 496:	0005079b          	sext.w	a5,a0
 49a:	04000737          	lui	a4,0x4000
 49e:	02e78d63          	beq	a5,a4,4d8 <main+0x44c>
            printf("test12A faild - child didn't inherit parent's mask\n");
 4a2:	00001517          	auipc	a0,0x1
 4a6:	c3650513          	addi	a0,a0,-970 # 10d8 <malloc+0x4e4>
 4aa:	00000097          	auipc	ra,0x0
 4ae:	68c080e7          	jalr	1676(ra) # b36 <printf>
        }else{
            printf("test12A passed\n");
        }
        kill(pid, 27);
 4b2:	45ed                	li	a1,27
 4b4:	4501                	li	a0,0
 4b6:	00000097          	auipc	ra,0x0
 4ba:	2de080e7          	jalr	734(ra) # 794 <kill>
        printf("test12B passed\n");
 4be:	00001517          	auipc	a0,0x1
 4c2:	c6250513          	addi	a0,a0,-926 # 1120 <malloc+0x52c>
 4c6:	00000097          	auipc	ra,0x0
 4ca:	670080e7          	jalr	1648(ra) # b36 <printf>
    }else{
        wait(0);
    }
    
    exit(0);
 4ce:	4501                	li	a0,0
 4d0:	00000097          	auipc	ra,0x0
 4d4:	294080e7          	jalr	660(ra) # 764 <exit>
            printf("test12A passed\n");
 4d8:	00001517          	auipc	a0,0x1
 4dc:	c3850513          	addi	a0,a0,-968 # 1110 <malloc+0x51c>
 4e0:	00000097          	auipc	ra,0x0
 4e4:	656080e7          	jalr	1622(ra) # b36 <printf>
 4e8:	b7e9                	j	4b2 <main+0x426>
        wait(0);
 4ea:	4501                	li	a0,0
 4ec:	00000097          	auipc	ra,0x0
 4f0:	280080e7          	jalr	640(ra) # 76c <wait>
 4f4:	bfe9                	j	4ce <main+0x442>

00000000000004f6 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 4f6:	1141                	addi	sp,sp,-16
 4f8:	e422                	sd	s0,8(sp)
 4fa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4fc:	87aa                	mv	a5,a0
 4fe:	0585                	addi	a1,a1,1
 500:	0785                	addi	a5,a5,1
 502:	fff5c703          	lbu	a4,-1(a1)
 506:	fee78fa3          	sb	a4,-1(a5)
 50a:	fb75                	bnez	a4,4fe <strcpy+0x8>
    ;
  return os;
}
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret

0000000000000512 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 512:	1141                	addi	sp,sp,-16
 514:	e422                	sd	s0,8(sp)
 516:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 518:	00054783          	lbu	a5,0(a0)
 51c:	cb91                	beqz	a5,530 <strcmp+0x1e>
 51e:	0005c703          	lbu	a4,0(a1)
 522:	00f71763          	bne	a4,a5,530 <strcmp+0x1e>
    p++, q++;
 526:	0505                	addi	a0,a0,1
 528:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 52a:	00054783          	lbu	a5,0(a0)
 52e:	fbe5                	bnez	a5,51e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 530:	0005c503          	lbu	a0,0(a1)
}
 534:	40a7853b          	subw	a0,a5,a0
 538:	6422                	ld	s0,8(sp)
 53a:	0141                	addi	sp,sp,16
 53c:	8082                	ret

000000000000053e <strlen>:

uint
strlen(const char *s)
{
 53e:	1141                	addi	sp,sp,-16
 540:	e422                	sd	s0,8(sp)
 542:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 544:	00054783          	lbu	a5,0(a0)
 548:	cf91                	beqz	a5,564 <strlen+0x26>
 54a:	0505                	addi	a0,a0,1
 54c:	87aa                	mv	a5,a0
 54e:	4685                	li	a3,1
 550:	9e89                	subw	a3,a3,a0
 552:	00f6853b          	addw	a0,a3,a5
 556:	0785                	addi	a5,a5,1
 558:	fff7c703          	lbu	a4,-1(a5)
 55c:	fb7d                	bnez	a4,552 <strlen+0x14>
    ;
  return n;
}
 55e:	6422                	ld	s0,8(sp)
 560:	0141                	addi	sp,sp,16
 562:	8082                	ret
  for(n = 0; s[n]; n++)
 564:	4501                	li	a0,0
 566:	bfe5                	j	55e <strlen+0x20>

0000000000000568 <memset>:

void*
memset(void *dst, int c, uint n)
{
 568:	1141                	addi	sp,sp,-16
 56a:	e422                	sd	s0,8(sp)
 56c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 56e:	ca19                	beqz	a2,584 <memset+0x1c>
 570:	87aa                	mv	a5,a0
 572:	1602                	slli	a2,a2,0x20
 574:	9201                	srli	a2,a2,0x20
 576:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 57a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 57e:	0785                	addi	a5,a5,1
 580:	fee79de3          	bne	a5,a4,57a <memset+0x12>
  }
  return dst;
}
 584:	6422                	ld	s0,8(sp)
 586:	0141                	addi	sp,sp,16
 588:	8082                	ret

000000000000058a <strchr>:

char*
strchr(const char *s, char c)
{
 58a:	1141                	addi	sp,sp,-16
 58c:	e422                	sd	s0,8(sp)
 58e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 590:	00054783          	lbu	a5,0(a0)
 594:	cb99                	beqz	a5,5aa <strchr+0x20>
    if(*s == c)
 596:	00f58763          	beq	a1,a5,5a4 <strchr+0x1a>
  for(; *s; s++)
 59a:	0505                	addi	a0,a0,1
 59c:	00054783          	lbu	a5,0(a0)
 5a0:	fbfd                	bnez	a5,596 <strchr+0xc>
      return (char*)s;
  return 0;
 5a2:	4501                	li	a0,0
}
 5a4:	6422                	ld	s0,8(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret
  return 0;
 5aa:	4501                	li	a0,0
 5ac:	bfe5                	j	5a4 <strchr+0x1a>

00000000000005ae <gets>:

char*
gets(char *buf, int max)
{
 5ae:	711d                	addi	sp,sp,-96
 5b0:	ec86                	sd	ra,88(sp)
 5b2:	e8a2                	sd	s0,80(sp)
 5b4:	e4a6                	sd	s1,72(sp)
 5b6:	e0ca                	sd	s2,64(sp)
 5b8:	fc4e                	sd	s3,56(sp)
 5ba:	f852                	sd	s4,48(sp)
 5bc:	f456                	sd	s5,40(sp)
 5be:	f05a                	sd	s6,32(sp)
 5c0:	ec5e                	sd	s7,24(sp)
 5c2:	1080                	addi	s0,sp,96
 5c4:	8baa                	mv	s7,a0
 5c6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 5c8:	892a                	mv	s2,a0
 5ca:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5cc:	4aa9                	li	s5,10
 5ce:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5d0:	89a6                	mv	s3,s1
 5d2:	2485                	addiw	s1,s1,1
 5d4:	0344d863          	bge	s1,s4,604 <gets+0x56>
    cc = read(0, &c, 1);
 5d8:	4605                	li	a2,1
 5da:	faf40593          	addi	a1,s0,-81
 5de:	4501                	li	a0,0
 5e0:	00000097          	auipc	ra,0x0
 5e4:	19c080e7          	jalr	412(ra) # 77c <read>
    if(cc < 1)
 5e8:	00a05e63          	blez	a0,604 <gets+0x56>
    buf[i++] = c;
 5ec:	faf44783          	lbu	a5,-81(s0)
 5f0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 5f4:	01578763          	beq	a5,s5,602 <gets+0x54>
 5f8:	0905                	addi	s2,s2,1
 5fa:	fd679be3          	bne	a5,s6,5d0 <gets+0x22>
  for(i=0; i+1 < max; ){
 5fe:	89a6                	mv	s3,s1
 600:	a011                	j	604 <gets+0x56>
 602:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 604:	99de                	add	s3,s3,s7
 606:	00098023          	sb	zero,0(s3)
  return buf;
}
 60a:	855e                	mv	a0,s7
 60c:	60e6                	ld	ra,88(sp)
 60e:	6446                	ld	s0,80(sp)
 610:	64a6                	ld	s1,72(sp)
 612:	6906                	ld	s2,64(sp)
 614:	79e2                	ld	s3,56(sp)
 616:	7a42                	ld	s4,48(sp)
 618:	7aa2                	ld	s5,40(sp)
 61a:	7b02                	ld	s6,32(sp)
 61c:	6be2                	ld	s7,24(sp)
 61e:	6125                	addi	sp,sp,96
 620:	8082                	ret

0000000000000622 <stat>:

int
stat(const char *n, struct stat *st)
{
 622:	1101                	addi	sp,sp,-32
 624:	ec06                	sd	ra,24(sp)
 626:	e822                	sd	s0,16(sp)
 628:	e426                	sd	s1,8(sp)
 62a:	e04a                	sd	s2,0(sp)
 62c:	1000                	addi	s0,sp,32
 62e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 630:	4581                	li	a1,0
 632:	00000097          	auipc	ra,0x0
 636:	172080e7          	jalr	370(ra) # 7a4 <open>
  if(fd < 0)
 63a:	02054563          	bltz	a0,664 <stat+0x42>
 63e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 640:	85ca                	mv	a1,s2
 642:	00000097          	auipc	ra,0x0
 646:	17a080e7          	jalr	378(ra) # 7bc <fstat>
 64a:	892a                	mv	s2,a0
  close(fd);
 64c:	8526                	mv	a0,s1
 64e:	00000097          	auipc	ra,0x0
 652:	13e080e7          	jalr	318(ra) # 78c <close>
  return r;
}
 656:	854a                	mv	a0,s2
 658:	60e2                	ld	ra,24(sp)
 65a:	6442                	ld	s0,16(sp)
 65c:	64a2                	ld	s1,8(sp)
 65e:	6902                	ld	s2,0(sp)
 660:	6105                	addi	sp,sp,32
 662:	8082                	ret
    return -1;
 664:	597d                	li	s2,-1
 666:	bfc5                	j	656 <stat+0x34>

0000000000000668 <atoi>:

int
atoi(const char *s)
{
 668:	1141                	addi	sp,sp,-16
 66a:	e422                	sd	s0,8(sp)
 66c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 66e:	00054603          	lbu	a2,0(a0)
 672:	fd06079b          	addiw	a5,a2,-48
 676:	0ff7f793          	andi	a5,a5,255
 67a:	4725                	li	a4,9
 67c:	02f76963          	bltu	a4,a5,6ae <atoi+0x46>
 680:	86aa                	mv	a3,a0
  n = 0;
 682:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 684:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 686:	0685                	addi	a3,a3,1
 688:	0025179b          	slliw	a5,a0,0x2
 68c:	9fa9                	addw	a5,a5,a0
 68e:	0017979b          	slliw	a5,a5,0x1
 692:	9fb1                	addw	a5,a5,a2
 694:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 698:	0006c603          	lbu	a2,0(a3)
 69c:	fd06071b          	addiw	a4,a2,-48
 6a0:	0ff77713          	andi	a4,a4,255
 6a4:	fee5f1e3          	bgeu	a1,a4,686 <atoi+0x1e>
  return n;
}
 6a8:	6422                	ld	s0,8(sp)
 6aa:	0141                	addi	sp,sp,16
 6ac:	8082                	ret
  n = 0;
 6ae:	4501                	li	a0,0
 6b0:	bfe5                	j	6a8 <atoi+0x40>

00000000000006b2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6b2:	1141                	addi	sp,sp,-16
 6b4:	e422                	sd	s0,8(sp)
 6b6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6b8:	02b57463          	bgeu	a0,a1,6e0 <memmove+0x2e>
    while(n-- > 0)
 6bc:	00c05f63          	blez	a2,6da <memmove+0x28>
 6c0:	1602                	slli	a2,a2,0x20
 6c2:	9201                	srli	a2,a2,0x20
 6c4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 6c8:	872a                	mv	a4,a0
      *dst++ = *src++;
 6ca:	0585                	addi	a1,a1,1
 6cc:	0705                	addi	a4,a4,1
 6ce:	fff5c683          	lbu	a3,-1(a1)
 6d2:	fed70fa3          	sb	a3,-1(a4) # 3ffffff <__global_pointer$+0x3ffe6b6>
    while(n-- > 0)
 6d6:	fee79ae3          	bne	a5,a4,6ca <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 6da:	6422                	ld	s0,8(sp)
 6dc:	0141                	addi	sp,sp,16
 6de:	8082                	ret
    dst += n;
 6e0:	00c50733          	add	a4,a0,a2
    src += n;
 6e4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6e6:	fec05ae3          	blez	a2,6da <memmove+0x28>
 6ea:	fff6079b          	addiw	a5,a2,-1
 6ee:	1782                	slli	a5,a5,0x20
 6f0:	9381                	srli	a5,a5,0x20
 6f2:	fff7c793          	not	a5,a5
 6f6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6f8:	15fd                	addi	a1,a1,-1
 6fa:	177d                	addi	a4,a4,-1
 6fc:	0005c683          	lbu	a3,0(a1)
 700:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 704:	fee79ae3          	bne	a5,a4,6f8 <memmove+0x46>
 708:	bfc9                	j	6da <memmove+0x28>

000000000000070a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 70a:	1141                	addi	sp,sp,-16
 70c:	e422                	sd	s0,8(sp)
 70e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 710:	ca05                	beqz	a2,740 <memcmp+0x36>
 712:	fff6069b          	addiw	a3,a2,-1
 716:	1682                	slli	a3,a3,0x20
 718:	9281                	srli	a3,a3,0x20
 71a:	0685                	addi	a3,a3,1
 71c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 71e:	00054783          	lbu	a5,0(a0)
 722:	0005c703          	lbu	a4,0(a1)
 726:	00e79863          	bne	a5,a4,736 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 72a:	0505                	addi	a0,a0,1
    p2++;
 72c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 72e:	fed518e3          	bne	a0,a3,71e <memcmp+0x14>
  }
  return 0;
 732:	4501                	li	a0,0
 734:	a019                	j	73a <memcmp+0x30>
      return *p1 - *p2;
 736:	40e7853b          	subw	a0,a5,a4
}
 73a:	6422                	ld	s0,8(sp)
 73c:	0141                	addi	sp,sp,16
 73e:	8082                	ret
  return 0;
 740:	4501                	li	a0,0
 742:	bfe5                	j	73a <memcmp+0x30>

0000000000000744 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 744:	1141                	addi	sp,sp,-16
 746:	e406                	sd	ra,8(sp)
 748:	e022                	sd	s0,0(sp)
 74a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 74c:	00000097          	auipc	ra,0x0
 750:	f66080e7          	jalr	-154(ra) # 6b2 <memmove>
}
 754:	60a2                	ld	ra,8(sp)
 756:	6402                	ld	s0,0(sp)
 758:	0141                	addi	sp,sp,16
 75a:	8082                	ret

000000000000075c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 75c:	4885                	li	a7,1
 ecall
 75e:	00000073          	ecall
 ret
 762:	8082                	ret

0000000000000764 <exit>:
.global exit
exit:
 li a7, SYS_exit
 764:	4889                	li	a7,2
 ecall
 766:	00000073          	ecall
 ret
 76a:	8082                	ret

000000000000076c <wait>:
.global wait
wait:
 li a7, SYS_wait
 76c:	488d                	li	a7,3
 ecall
 76e:	00000073          	ecall
 ret
 772:	8082                	ret

0000000000000774 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 774:	4891                	li	a7,4
 ecall
 776:	00000073          	ecall
 ret
 77a:	8082                	ret

000000000000077c <read>:
.global read
read:
 li a7, SYS_read
 77c:	4895                	li	a7,5
 ecall
 77e:	00000073          	ecall
 ret
 782:	8082                	ret

0000000000000784 <write>:
.global write
write:
 li a7, SYS_write
 784:	48c1                	li	a7,16
 ecall
 786:	00000073          	ecall
 ret
 78a:	8082                	ret

000000000000078c <close>:
.global close
close:
 li a7, SYS_close
 78c:	48d5                	li	a7,21
 ecall
 78e:	00000073          	ecall
 ret
 792:	8082                	ret

0000000000000794 <kill>:
.global kill
kill:
 li a7, SYS_kill
 794:	4899                	li	a7,6
 ecall
 796:	00000073          	ecall
 ret
 79a:	8082                	ret

000000000000079c <exec>:
.global exec
exec:
 li a7, SYS_exec
 79c:	489d                	li	a7,7
 ecall
 79e:	00000073          	ecall
 ret
 7a2:	8082                	ret

00000000000007a4 <open>:
.global open
open:
 li a7, SYS_open
 7a4:	48bd                	li	a7,15
 ecall
 7a6:	00000073          	ecall
 ret
 7aa:	8082                	ret

00000000000007ac <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 7ac:	48c5                	li	a7,17
 ecall
 7ae:	00000073          	ecall
 ret
 7b2:	8082                	ret

00000000000007b4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7b4:	48c9                	li	a7,18
 ecall
 7b6:	00000073          	ecall
 ret
 7ba:	8082                	ret

00000000000007bc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 7bc:	48a1                	li	a7,8
 ecall
 7be:	00000073          	ecall
 ret
 7c2:	8082                	ret

00000000000007c4 <link>:
.global link
link:
 li a7, SYS_link
 7c4:	48cd                	li	a7,19
 ecall
 7c6:	00000073          	ecall
 ret
 7ca:	8082                	ret

00000000000007cc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 7cc:	48d1                	li	a7,20
 ecall
 7ce:	00000073          	ecall
 ret
 7d2:	8082                	ret

00000000000007d4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 7d4:	48a5                	li	a7,9
 ecall
 7d6:	00000073          	ecall
 ret
 7da:	8082                	ret

00000000000007dc <dup>:
.global dup
dup:
 li a7, SYS_dup
 7dc:	48a9                	li	a7,10
 ecall
 7de:	00000073          	ecall
 ret
 7e2:	8082                	ret

00000000000007e4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7e4:	48ad                	li	a7,11
 ecall
 7e6:	00000073          	ecall
 ret
 7ea:	8082                	ret

00000000000007ec <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 7ec:	48b1                	li	a7,12
 ecall
 7ee:	00000073          	ecall
 ret
 7f2:	8082                	ret

00000000000007f4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 7f4:	48b5                	li	a7,13
 ecall
 7f6:	00000073          	ecall
 ret
 7fa:	8082                	ret

00000000000007fc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7fc:	48b9                	li	a7,14
 ecall
 7fe:	00000073          	ecall
 ret
 802:	8082                	ret

0000000000000804 <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
 804:	48d9                	li	a7,22
 ecall
 806:	00000073          	ecall
 ret
 80a:	8082                	ret

000000000000080c <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
 80c:	48dd                	li	a7,23
 ecall
 80e:	00000073          	ecall
 ret
 812:	8082                	ret

0000000000000814 <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
 814:	48e1                	li	a7,24
 ecall
 816:	00000073          	ecall
 ret
 81a:	8082                	ret

000000000000081c <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
 81c:	48e5                	li	a7,25
 ecall
 81e:	00000073          	ecall
 ret
 822:	8082                	ret

0000000000000824 <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
 824:	48e9                	li	a7,26
 ecall
 826:	00000073          	ecall
 ret
 82a:	8082                	ret

000000000000082c <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
 82c:	48ed                	li	a7,27
 ecall
 82e:	00000073          	ecall
 ret
 832:	8082                	ret

0000000000000834 <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
 834:	48f1                	li	a7,28
 ecall
 836:	00000073          	ecall
 ret
 83a:	8082                	ret

000000000000083c <bsem_alloc>:
.global bsem_alloc
bsem_alloc:
 li a7, SYS_bsem_alloc
 83c:	48f5                	li	a7,29
 ecall
 83e:	00000073          	ecall
 ret
 842:	8082                	ret

0000000000000844 <bsem_free>:
.global bsem_free
bsem_free:
 li a7, SYS_bsem_free
 844:	48f9                	li	a7,30
 ecall
 846:	00000073          	ecall
 ret
 84a:	8082                	ret

000000000000084c <bsem_down>:
.global bsem_down
bsem_down:
 li a7, SYS_bsem_down
 84c:	48fd                	li	a7,31
 ecall
 84e:	00000073          	ecall
 ret
 852:	8082                	ret

0000000000000854 <bsem_up>:
.global bsem_up
bsem_up:
 li a7, SYS_bsem_up
 854:	02000893          	li	a7,32
 ecall
 858:	00000073          	ecall
 ret
 85c:	8082                	ret

000000000000085e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 85e:	1101                	addi	sp,sp,-32
 860:	ec06                	sd	ra,24(sp)
 862:	e822                	sd	s0,16(sp)
 864:	1000                	addi	s0,sp,32
 866:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 86a:	4605                	li	a2,1
 86c:	fef40593          	addi	a1,s0,-17
 870:	00000097          	auipc	ra,0x0
 874:	f14080e7          	jalr	-236(ra) # 784 <write>
}
 878:	60e2                	ld	ra,24(sp)
 87a:	6442                	ld	s0,16(sp)
 87c:	6105                	addi	sp,sp,32
 87e:	8082                	ret

0000000000000880 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 880:	7139                	addi	sp,sp,-64
 882:	fc06                	sd	ra,56(sp)
 884:	f822                	sd	s0,48(sp)
 886:	f426                	sd	s1,40(sp)
 888:	f04a                	sd	s2,32(sp)
 88a:	ec4e                	sd	s3,24(sp)
 88c:	0080                	addi	s0,sp,64
 88e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 890:	c299                	beqz	a3,896 <printint+0x16>
 892:	0805c863          	bltz	a1,922 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 896:	2581                	sext.w	a1,a1
  neg = 0;
 898:	4881                	li	a7,0
 89a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 89e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 8a0:	2601                	sext.w	a2,a2
 8a2:	00001517          	auipc	a0,0x1
 8a6:	89650513          	addi	a0,a0,-1898 # 1138 <digits>
 8aa:	883a                	mv	a6,a4
 8ac:	2705                	addiw	a4,a4,1
 8ae:	02c5f7bb          	remuw	a5,a1,a2
 8b2:	1782                	slli	a5,a5,0x20
 8b4:	9381                	srli	a5,a5,0x20
 8b6:	97aa                	add	a5,a5,a0
 8b8:	0007c783          	lbu	a5,0(a5)
 8bc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 8c0:	0005879b          	sext.w	a5,a1
 8c4:	02c5d5bb          	divuw	a1,a1,a2
 8c8:	0685                	addi	a3,a3,1
 8ca:	fec7f0e3          	bgeu	a5,a2,8aa <printint+0x2a>
  if(neg)
 8ce:	00088b63          	beqz	a7,8e4 <printint+0x64>
    buf[i++] = '-';
 8d2:	fd040793          	addi	a5,s0,-48
 8d6:	973e                	add	a4,a4,a5
 8d8:	02d00793          	li	a5,45
 8dc:	fef70823          	sb	a5,-16(a4)
 8e0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 8e4:	02e05863          	blez	a4,914 <printint+0x94>
 8e8:	fc040793          	addi	a5,s0,-64
 8ec:	00e78933          	add	s2,a5,a4
 8f0:	fff78993          	addi	s3,a5,-1
 8f4:	99ba                	add	s3,s3,a4
 8f6:	377d                	addiw	a4,a4,-1
 8f8:	1702                	slli	a4,a4,0x20
 8fa:	9301                	srli	a4,a4,0x20
 8fc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 900:	fff94583          	lbu	a1,-1(s2)
 904:	8526                	mv	a0,s1
 906:	00000097          	auipc	ra,0x0
 90a:	f58080e7          	jalr	-168(ra) # 85e <putc>
  while(--i >= 0)
 90e:	197d                	addi	s2,s2,-1
 910:	ff3918e3          	bne	s2,s3,900 <printint+0x80>
}
 914:	70e2                	ld	ra,56(sp)
 916:	7442                	ld	s0,48(sp)
 918:	74a2                	ld	s1,40(sp)
 91a:	7902                	ld	s2,32(sp)
 91c:	69e2                	ld	s3,24(sp)
 91e:	6121                	addi	sp,sp,64
 920:	8082                	ret
    x = -xx;
 922:	40b005bb          	negw	a1,a1
    neg = 1;
 926:	4885                	li	a7,1
    x = -xx;
 928:	bf8d                	j	89a <printint+0x1a>

000000000000092a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 92a:	7119                	addi	sp,sp,-128
 92c:	fc86                	sd	ra,120(sp)
 92e:	f8a2                	sd	s0,112(sp)
 930:	f4a6                	sd	s1,104(sp)
 932:	f0ca                	sd	s2,96(sp)
 934:	ecce                	sd	s3,88(sp)
 936:	e8d2                	sd	s4,80(sp)
 938:	e4d6                	sd	s5,72(sp)
 93a:	e0da                	sd	s6,64(sp)
 93c:	fc5e                	sd	s7,56(sp)
 93e:	f862                	sd	s8,48(sp)
 940:	f466                	sd	s9,40(sp)
 942:	f06a                	sd	s10,32(sp)
 944:	ec6e                	sd	s11,24(sp)
 946:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 948:	0005c903          	lbu	s2,0(a1)
 94c:	18090f63          	beqz	s2,aea <vprintf+0x1c0>
 950:	8aaa                	mv	s5,a0
 952:	8b32                	mv	s6,a2
 954:	00158493          	addi	s1,a1,1
  state = 0;
 958:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 95a:	02500a13          	li	s4,37
      if(c == 'd'){
 95e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 962:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 966:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 96a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 96e:	00000b97          	auipc	s7,0x0
 972:	7cab8b93          	addi	s7,s7,1994 # 1138 <digits>
 976:	a839                	j	994 <vprintf+0x6a>
        putc(fd, c);
 978:	85ca                	mv	a1,s2
 97a:	8556                	mv	a0,s5
 97c:	00000097          	auipc	ra,0x0
 980:	ee2080e7          	jalr	-286(ra) # 85e <putc>
 984:	a019                	j	98a <vprintf+0x60>
    } else if(state == '%'){
 986:	01498f63          	beq	s3,s4,9a4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 98a:	0485                	addi	s1,s1,1
 98c:	fff4c903          	lbu	s2,-1(s1)
 990:	14090d63          	beqz	s2,aea <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 994:	0009079b          	sext.w	a5,s2
    if(state == 0){
 998:	fe0997e3          	bnez	s3,986 <vprintf+0x5c>
      if(c == '%'){
 99c:	fd479ee3          	bne	a5,s4,978 <vprintf+0x4e>
        state = '%';
 9a0:	89be                	mv	s3,a5
 9a2:	b7e5                	j	98a <vprintf+0x60>
      if(c == 'd'){
 9a4:	05878063          	beq	a5,s8,9e4 <vprintf+0xba>
      } else if(c == 'l') {
 9a8:	05978c63          	beq	a5,s9,a00 <vprintf+0xd6>
      } else if(c == 'x') {
 9ac:	07a78863          	beq	a5,s10,a1c <vprintf+0xf2>
      } else if(c == 'p') {
 9b0:	09b78463          	beq	a5,s11,a38 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 9b4:	07300713          	li	a4,115
 9b8:	0ce78663          	beq	a5,a4,a84 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 9bc:	06300713          	li	a4,99
 9c0:	0ee78e63          	beq	a5,a4,abc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 9c4:	11478863          	beq	a5,s4,ad4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 9c8:	85d2                	mv	a1,s4
 9ca:	8556                	mv	a0,s5
 9cc:	00000097          	auipc	ra,0x0
 9d0:	e92080e7          	jalr	-366(ra) # 85e <putc>
        putc(fd, c);
 9d4:	85ca                	mv	a1,s2
 9d6:	8556                	mv	a0,s5
 9d8:	00000097          	auipc	ra,0x0
 9dc:	e86080e7          	jalr	-378(ra) # 85e <putc>
      }
      state = 0;
 9e0:	4981                	li	s3,0
 9e2:	b765                	j	98a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 9e4:	008b0913          	addi	s2,s6,8
 9e8:	4685                	li	a3,1
 9ea:	4629                	li	a2,10
 9ec:	000b2583          	lw	a1,0(s6)
 9f0:	8556                	mv	a0,s5
 9f2:	00000097          	auipc	ra,0x0
 9f6:	e8e080e7          	jalr	-370(ra) # 880 <printint>
 9fa:	8b4a                	mv	s6,s2
      state = 0;
 9fc:	4981                	li	s3,0
 9fe:	b771                	j	98a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a00:	008b0913          	addi	s2,s6,8
 a04:	4681                	li	a3,0
 a06:	4629                	li	a2,10
 a08:	000b2583          	lw	a1,0(s6)
 a0c:	8556                	mv	a0,s5
 a0e:	00000097          	auipc	ra,0x0
 a12:	e72080e7          	jalr	-398(ra) # 880 <printint>
 a16:	8b4a                	mv	s6,s2
      state = 0;
 a18:	4981                	li	s3,0
 a1a:	bf85                	j	98a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a1c:	008b0913          	addi	s2,s6,8
 a20:	4681                	li	a3,0
 a22:	4641                	li	a2,16
 a24:	000b2583          	lw	a1,0(s6)
 a28:	8556                	mv	a0,s5
 a2a:	00000097          	auipc	ra,0x0
 a2e:	e56080e7          	jalr	-426(ra) # 880 <printint>
 a32:	8b4a                	mv	s6,s2
      state = 0;
 a34:	4981                	li	s3,0
 a36:	bf91                	j	98a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a38:	008b0793          	addi	a5,s6,8
 a3c:	f8f43423          	sd	a5,-120(s0)
 a40:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a44:	03000593          	li	a1,48
 a48:	8556                	mv	a0,s5
 a4a:	00000097          	auipc	ra,0x0
 a4e:	e14080e7          	jalr	-492(ra) # 85e <putc>
  putc(fd, 'x');
 a52:	85ea                	mv	a1,s10
 a54:	8556                	mv	a0,s5
 a56:	00000097          	auipc	ra,0x0
 a5a:	e08080e7          	jalr	-504(ra) # 85e <putc>
 a5e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a60:	03c9d793          	srli	a5,s3,0x3c
 a64:	97de                	add	a5,a5,s7
 a66:	0007c583          	lbu	a1,0(a5)
 a6a:	8556                	mv	a0,s5
 a6c:	00000097          	auipc	ra,0x0
 a70:	df2080e7          	jalr	-526(ra) # 85e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a74:	0992                	slli	s3,s3,0x4
 a76:	397d                	addiw	s2,s2,-1
 a78:	fe0914e3          	bnez	s2,a60 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 a7c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a80:	4981                	li	s3,0
 a82:	b721                	j	98a <vprintf+0x60>
        s = va_arg(ap, char*);
 a84:	008b0993          	addi	s3,s6,8
 a88:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 a8c:	02090163          	beqz	s2,aae <vprintf+0x184>
        while(*s != 0){
 a90:	00094583          	lbu	a1,0(s2)
 a94:	c9a1                	beqz	a1,ae4 <vprintf+0x1ba>
          putc(fd, *s);
 a96:	8556                	mv	a0,s5
 a98:	00000097          	auipc	ra,0x0
 a9c:	dc6080e7          	jalr	-570(ra) # 85e <putc>
          s++;
 aa0:	0905                	addi	s2,s2,1
        while(*s != 0){
 aa2:	00094583          	lbu	a1,0(s2)
 aa6:	f9e5                	bnez	a1,a96 <vprintf+0x16c>
        s = va_arg(ap, char*);
 aa8:	8b4e                	mv	s6,s3
      state = 0;
 aaa:	4981                	li	s3,0
 aac:	bdf9                	j	98a <vprintf+0x60>
          s = "(null)";
 aae:	00000917          	auipc	s2,0x0
 ab2:	68290913          	addi	s2,s2,1666 # 1130 <malloc+0x53c>
        while(*s != 0){
 ab6:	02800593          	li	a1,40
 aba:	bff1                	j	a96 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 abc:	008b0913          	addi	s2,s6,8
 ac0:	000b4583          	lbu	a1,0(s6)
 ac4:	8556                	mv	a0,s5
 ac6:	00000097          	auipc	ra,0x0
 aca:	d98080e7          	jalr	-616(ra) # 85e <putc>
 ace:	8b4a                	mv	s6,s2
      state = 0;
 ad0:	4981                	li	s3,0
 ad2:	bd65                	j	98a <vprintf+0x60>
        putc(fd, c);
 ad4:	85d2                	mv	a1,s4
 ad6:	8556                	mv	a0,s5
 ad8:	00000097          	auipc	ra,0x0
 adc:	d86080e7          	jalr	-634(ra) # 85e <putc>
      state = 0;
 ae0:	4981                	li	s3,0
 ae2:	b565                	j	98a <vprintf+0x60>
        s = va_arg(ap, char*);
 ae4:	8b4e                	mv	s6,s3
      state = 0;
 ae6:	4981                	li	s3,0
 ae8:	b54d                	j	98a <vprintf+0x60>
    }
  }
}
 aea:	70e6                	ld	ra,120(sp)
 aec:	7446                	ld	s0,112(sp)
 aee:	74a6                	ld	s1,104(sp)
 af0:	7906                	ld	s2,96(sp)
 af2:	69e6                	ld	s3,88(sp)
 af4:	6a46                	ld	s4,80(sp)
 af6:	6aa6                	ld	s5,72(sp)
 af8:	6b06                	ld	s6,64(sp)
 afa:	7be2                	ld	s7,56(sp)
 afc:	7c42                	ld	s8,48(sp)
 afe:	7ca2                	ld	s9,40(sp)
 b00:	7d02                	ld	s10,32(sp)
 b02:	6de2                	ld	s11,24(sp)
 b04:	6109                	addi	sp,sp,128
 b06:	8082                	ret

0000000000000b08 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b08:	715d                	addi	sp,sp,-80
 b0a:	ec06                	sd	ra,24(sp)
 b0c:	e822                	sd	s0,16(sp)
 b0e:	1000                	addi	s0,sp,32
 b10:	e010                	sd	a2,0(s0)
 b12:	e414                	sd	a3,8(s0)
 b14:	e818                	sd	a4,16(s0)
 b16:	ec1c                	sd	a5,24(s0)
 b18:	03043023          	sd	a6,32(s0)
 b1c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b20:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b24:	8622                	mv	a2,s0
 b26:	00000097          	auipc	ra,0x0
 b2a:	e04080e7          	jalr	-508(ra) # 92a <vprintf>
}
 b2e:	60e2                	ld	ra,24(sp)
 b30:	6442                	ld	s0,16(sp)
 b32:	6161                	addi	sp,sp,80
 b34:	8082                	ret

0000000000000b36 <printf>:

void
printf(const char *fmt, ...)
{
 b36:	711d                	addi	sp,sp,-96
 b38:	ec06                	sd	ra,24(sp)
 b3a:	e822                	sd	s0,16(sp)
 b3c:	1000                	addi	s0,sp,32
 b3e:	e40c                	sd	a1,8(s0)
 b40:	e810                	sd	a2,16(s0)
 b42:	ec14                	sd	a3,24(s0)
 b44:	f018                	sd	a4,32(s0)
 b46:	f41c                	sd	a5,40(s0)
 b48:	03043823          	sd	a6,48(s0)
 b4c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b50:	00840613          	addi	a2,s0,8
 b54:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b58:	85aa                	mv	a1,a0
 b5a:	4505                	li	a0,1
 b5c:	00000097          	auipc	ra,0x0
 b60:	dce080e7          	jalr	-562(ra) # 92a <vprintf>
}
 b64:	60e2                	ld	ra,24(sp)
 b66:	6442                	ld	s0,16(sp)
 b68:	6125                	addi	sp,sp,96
 b6a:	8082                	ret

0000000000000b6c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b6c:	1141                	addi	sp,sp,-16
 b6e:	e422                	sd	s0,8(sp)
 b70:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b72:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b76:	00000797          	auipc	a5,0x0
 b7a:	5e27b783          	ld	a5,1506(a5) # 1158 <freep>
 b7e:	a805                	j	bae <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b80:	4618                	lw	a4,8(a2)
 b82:	9db9                	addw	a1,a1,a4
 b84:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b88:	6398                	ld	a4,0(a5)
 b8a:	6318                	ld	a4,0(a4)
 b8c:	fee53823          	sd	a4,-16(a0)
 b90:	a091                	j	bd4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b92:	ff852703          	lw	a4,-8(a0)
 b96:	9e39                	addw	a2,a2,a4
 b98:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b9a:	ff053703          	ld	a4,-16(a0)
 b9e:	e398                	sd	a4,0(a5)
 ba0:	a099                	j	be6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ba2:	6398                	ld	a4,0(a5)
 ba4:	00e7e463          	bltu	a5,a4,bac <free+0x40>
 ba8:	00e6ea63          	bltu	a3,a4,bbc <free+0x50>
{
 bac:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bae:	fed7fae3          	bgeu	a5,a3,ba2 <free+0x36>
 bb2:	6398                	ld	a4,0(a5)
 bb4:	00e6e463          	bltu	a3,a4,bbc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bb8:	fee7eae3          	bltu	a5,a4,bac <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 bbc:	ff852583          	lw	a1,-8(a0)
 bc0:	6390                	ld	a2,0(a5)
 bc2:	02059813          	slli	a6,a1,0x20
 bc6:	01c85713          	srli	a4,a6,0x1c
 bca:	9736                	add	a4,a4,a3
 bcc:	fae60ae3          	beq	a2,a4,b80 <free+0x14>
    bp->s.ptr = p->s.ptr;
 bd0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 bd4:	4790                	lw	a2,8(a5)
 bd6:	02061593          	slli	a1,a2,0x20
 bda:	01c5d713          	srli	a4,a1,0x1c
 bde:	973e                	add	a4,a4,a5
 be0:	fae689e3          	beq	a3,a4,b92 <free+0x26>
  } else
    p->s.ptr = bp;
 be4:	e394                	sd	a3,0(a5)
  freep = p;
 be6:	00000717          	auipc	a4,0x0
 bea:	56f73923          	sd	a5,1394(a4) # 1158 <freep>
}
 bee:	6422                	ld	s0,8(sp)
 bf0:	0141                	addi	sp,sp,16
 bf2:	8082                	ret

0000000000000bf4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bf4:	7139                	addi	sp,sp,-64
 bf6:	fc06                	sd	ra,56(sp)
 bf8:	f822                	sd	s0,48(sp)
 bfa:	f426                	sd	s1,40(sp)
 bfc:	f04a                	sd	s2,32(sp)
 bfe:	ec4e                	sd	s3,24(sp)
 c00:	e852                	sd	s4,16(sp)
 c02:	e456                	sd	s5,8(sp)
 c04:	e05a                	sd	s6,0(sp)
 c06:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c08:	02051493          	slli	s1,a0,0x20
 c0c:	9081                	srli	s1,s1,0x20
 c0e:	04bd                	addi	s1,s1,15
 c10:	8091                	srli	s1,s1,0x4
 c12:	0014899b          	addiw	s3,s1,1
 c16:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c18:	00000517          	auipc	a0,0x0
 c1c:	54053503          	ld	a0,1344(a0) # 1158 <freep>
 c20:	c515                	beqz	a0,c4c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c22:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c24:	4798                	lw	a4,8(a5)
 c26:	02977f63          	bgeu	a4,s1,c64 <malloc+0x70>
 c2a:	8a4e                	mv	s4,s3
 c2c:	0009871b          	sext.w	a4,s3
 c30:	6685                	lui	a3,0x1
 c32:	00d77363          	bgeu	a4,a3,c38 <malloc+0x44>
 c36:	6a05                	lui	s4,0x1
 c38:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c3c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c40:	00000917          	auipc	s2,0x0
 c44:	51890913          	addi	s2,s2,1304 # 1158 <freep>
  if(p == (char*)-1)
 c48:	5afd                	li	s5,-1
 c4a:	a895                	j	cbe <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 c4c:	00000797          	auipc	a5,0x0
 c50:	51478793          	addi	a5,a5,1300 # 1160 <base>
 c54:	00000717          	auipc	a4,0x0
 c58:	50f73223          	sd	a5,1284(a4) # 1158 <freep>
 c5c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c5e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c62:	b7e1                	j	c2a <malloc+0x36>
      if(p->s.size == nunits)
 c64:	02e48c63          	beq	s1,a4,c9c <malloc+0xa8>
        p->s.size -= nunits;
 c68:	4137073b          	subw	a4,a4,s3
 c6c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c6e:	02071693          	slli	a3,a4,0x20
 c72:	01c6d713          	srli	a4,a3,0x1c
 c76:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c78:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c7c:	00000717          	auipc	a4,0x0
 c80:	4ca73e23          	sd	a0,1244(a4) # 1158 <freep>
      return (void*)(p + 1);
 c84:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c88:	70e2                	ld	ra,56(sp)
 c8a:	7442                	ld	s0,48(sp)
 c8c:	74a2                	ld	s1,40(sp)
 c8e:	7902                	ld	s2,32(sp)
 c90:	69e2                	ld	s3,24(sp)
 c92:	6a42                	ld	s4,16(sp)
 c94:	6aa2                	ld	s5,8(sp)
 c96:	6b02                	ld	s6,0(sp)
 c98:	6121                	addi	sp,sp,64
 c9a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c9c:	6398                	ld	a4,0(a5)
 c9e:	e118                	sd	a4,0(a0)
 ca0:	bff1                	j	c7c <malloc+0x88>
  hp->s.size = nu;
 ca2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ca6:	0541                	addi	a0,a0,16
 ca8:	00000097          	auipc	ra,0x0
 cac:	ec4080e7          	jalr	-316(ra) # b6c <free>
  return freep;
 cb0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 cb4:	d971                	beqz	a0,c88 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cb6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cb8:	4798                	lw	a4,8(a5)
 cba:	fa9775e3          	bgeu	a4,s1,c64 <malloc+0x70>
    if(p == freep)
 cbe:	00093703          	ld	a4,0(s2)
 cc2:	853e                	mv	a0,a5
 cc4:	fef719e3          	bne	a4,a5,cb6 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 cc8:	8552                	mv	a0,s4
 cca:	00000097          	auipc	ra,0x0
 cce:	b22080e7          	jalr	-1246(ra) # 7ec <sbrk>
  if(p == (char*)-1)
 cd2:	fd5518e3          	bne	a0,s5,ca2 <malloc+0xae>
        return 0;
 cd6:	4501                	li	a0,0
 cd8:	bf45                	j	c88 <malloc+0x94>
