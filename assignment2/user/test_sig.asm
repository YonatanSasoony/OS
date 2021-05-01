
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
   c:	12f72023          	sw	a5,288(a4) # 1128 <test>
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
  22:	10f72523          	sw	a5,266(a4) # 1128 <test>
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
  38:	c8450513          	addi	a0,a0,-892 # cb8 <malloc+0xe6>
  3c:	00001097          	auipc	ra,0x1
  40:	ad8080e7          	jalr	-1320(ra) # b14 <printf>
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
  58:	c9c50513          	addi	a0,a0,-868 # cf0 <malloc+0x11e>
  5c:	00001097          	auipc	ra,0x1
  60:	ab8080e7          	jalr	-1352(ra) # b14 <printf>
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
  78:	cbc50513          	addi	a0,a0,-836 # d30 <malloc+0x15e>
  7c:	00001097          	auipc	ra,0x1
  80:	a98080e7          	jalr	-1384(ra) # b14 <printf>
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
  9a:	cb250513          	addi	a0,a0,-846 # d48 <malloc+0x176>
  9e:	00001097          	auipc	ra,0x1
  a2:	a76080e7          	jalr	-1418(ra) # b14 <printf>
    printf("test2 handler pointer: %p\n", test2_handler);
  a6:	00000597          	auipc	a1,0x0
  aa:	f8658593          	addi	a1,a1,-122 # 2c <test2_handler>
  ae:	00001517          	auipc	a0,0x1
  b2:	caa50513          	addi	a0,a0,-854 # d58 <malloc+0x186>
  b6:	00001097          	auipc	ra,0x1
  ba:	a5e080e7          	jalr	-1442(ra) # b14 <printf>
    printf("test handler pointer: %p\n", t_handler);
  be:	00000597          	auipc	a1,0x0
  c2:	f4258593          	addi	a1,a1,-190 # 0 <t_handler>
  c6:	00001517          	auipc	a0,0x1
  ca:	cb250513          	addi	a0,a0,-846 # d78 <malloc+0x1a6>
  ce:	00001097          	auipc	ra,0x1
  d2:	a46080e7          	jalr	-1466(ra) # b14 <printf>
    printf("t handler pointer: %p\n", t_handler);
  d6:	00000597          	auipc	a1,0x0
  da:	f2a58593          	addi	a1,a1,-214 # 0 <t_handler>
  de:	00001517          	auipc	a0,0x1
  e2:	cba50513          	addi	a0,a0,-838 # d98 <malloc+0x1c6>
  e6:	00001097          	auipc	ra,0x1
  ea:	a2e080e7          	jalr	-1490(ra) # b14 <printf>
    printf("test1 handler pointer: %p\n", test1_handler);
  ee:	00000597          	auipc	a1,0x0
  f2:	f5e58593          	addi	a1,a1,-162 # 4c <test1_handler>
  f6:	00001517          	auipc	a0,0x1
  fa:	cba50513          	addi	a0,a0,-838 # db0 <malloc+0x1de>
  fe:	00001097          	auipc	ra,0x1
 102:	a16080e7          	jalr	-1514(ra) # b14 <printf>
    printf("created in order to make test_handler`s address not 0\n");
 106:	00001517          	auipc	a0,0x1
 10a:	bb250513          	addi	a0,a0,-1102 # cb8 <malloc+0xe6>
 10e:	00001097          	auipc	ra,0x1
 112:	a06080e7          	jalr	-1530(ra) # b14 <printf>

    test2_handler(1);

    test = 0;
 116:	00001797          	auipc	a5,0x1
 11a:	0007a923          	sw	zero,18(a5) # 1128 <test>
    
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
 148:	c8c50513          	addi	a0,a0,-884 # dd0 <malloc+0x1fe>
 14c:	00001097          	auipc	ra,0x1
 150:	9c8080e7          	jalr	-1592(ra) # b14 <printf>
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
 16e:	ca650513          	addi	a0,a0,-858 # e10 <malloc+0x23e>
 172:	00001097          	auipc	ra,0x1
 176:	9a2080e7          	jalr	-1630(ra) # b14 <printf>
    }else{
        printf("test2 passed\n");
    }

    act.sigmask = (1 << SIGKILL) | (1 << SIGSTOP);
 17a:	000207b7          	lui	a5,0x20
 17e:	20078793          	addi	a5,a5,512 # 20200 <__global_pointer$+0x1e8df>
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
 1a0:	cb450513          	addi	a0,a0,-844 # e50 <malloc+0x27e>
 1a4:	00001097          	auipc	ra,0x1
 1a8:	970080e7          	jalr	-1680(ra) # b14 <printf>
    }else{
        printf("test3 passed\n");
    }

    uint mask = (1 << SIGKILL) | (1 << SIGSTOP);
    if (sigprocmask(mask) != -1){
 1ac:	00020537          	lui	a0,0x20
 1b0:	20050513          	addi	a0,a0,512 # 20200 <__global_pointer$+0x1e8df>
 1b4:	00000097          	auipc	ra,0x0
 1b8:	650080e7          	jalr	1616(ra) # 804 <sigprocmask>
 1bc:	2501                	sext.w	a0,a0
 1be:	57fd                	li	a5,-1
 1c0:	0ef50063          	beq	a0,a5,2a0 <main+0x214>
        printf("test4 failed - SIGSTOP and SIGKILL cannot be blocked\n");
 1c4:	00001517          	auipc	a0,0x1
 1c8:	cd450513          	addi	a0,a0,-812 # e98 <malloc+0x2c6>
 1cc:	00001097          	auipc	ra,0x1
 1d0:	948080e7          	jalr	-1720(ra) # b14 <printf>
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
 1e8:	cfc50513          	addi	a0,a0,-772 # ee0 <malloc+0x30e>
 1ec:	00001097          	auipc	ra,0x1
 1f0:	928080e7          	jalr	-1752(ra) # b14 <printf>
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
 20c:	d1050513          	addi	a0,a0,-752 # f18 <malloc+0x346>
 210:	00001097          	auipc	ra,0x1
 214:	904080e7          	jalr	-1788(ra) # b14 <printf>
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
 24e:	ede72703          	lw	a4,-290(a4) # 1128 <test>
 252:	4785                	li	a5,1
 254:	08f70163          	beq	a4,a5,2d6 <main+0x24a>
            printf("test7 failed - test_handler did not invoke\n");
 258:	00001517          	auipc	a0,0x1
 25c:	cf850513          	addi	a0,a0,-776 # f50 <malloc+0x37e>
 260:	00001097          	auipc	ra,0x1
 264:	8b4080e7          	jalr	-1868(ra) # b14 <printf>
 268:	a841                	j	2f8 <main+0x26c>
        printf("test1 passed\n");
 26a:	00001517          	auipc	a0,0x1
 26e:	b9650513          	addi	a0,a0,-1130 # e00 <malloc+0x22e>
 272:	00001097          	auipc	ra,0x1
 276:	8a2080e7          	jalr	-1886(ra) # b14 <printf>
 27a:	bde9                	j	154 <main+0xc8>
        printf("test2 passed\n");
 27c:	00001517          	auipc	a0,0x1
 280:	bc450513          	addi	a0,a0,-1084 # e40 <malloc+0x26e>
 284:	00001097          	auipc	ra,0x1
 288:	890080e7          	jalr	-1904(ra) # b14 <printf>
 28c:	b5fd                	j	17a <main+0xee>
        printf("test3 passed\n");
 28e:	00001517          	auipc	a0,0x1
 292:	bfa50513          	addi	a0,a0,-1030 # e88 <malloc+0x2b6>
 296:	00001097          	auipc	ra,0x1
 29a:	87e080e7          	jalr	-1922(ra) # b14 <printf>
 29e:	b739                	j	1ac <main+0x120>
        printf("test4 passed\n");
 2a0:	00001517          	auipc	a0,0x1
 2a4:	c3050513          	addi	a0,a0,-976 # ed0 <malloc+0x2fe>
 2a8:	00001097          	auipc	ra,0x1
 2ac:	86c080e7          	jalr	-1940(ra) # b14 <printf>
 2b0:	b715                	j	1d4 <main+0x148>
        printf("test5 passed\n");
 2b2:	00001517          	auipc	a0,0x1
 2b6:	c5650513          	addi	a0,a0,-938 # f08 <malloc+0x336>
 2ba:	00001097          	auipc	ra,0x1
 2be:	85a080e7          	jalr	-1958(ra) # b14 <printf>
 2c2:	bf0d                	j	1f4 <main+0x168>
        printf("test6 passed\n");
 2c4:	00001517          	auipc	a0,0x1
 2c8:	c7c50513          	addi	a0,a0,-900 # f40 <malloc+0x36e>
 2cc:	00001097          	auipc	ra,0x1
 2d0:	848080e7          	jalr	-1976(ra) # b14 <printf>
 2d4:	b791                	j	218 <main+0x18c>
        }else{
            printf("test7 passed\n");
 2d6:	00001517          	auipc	a0,0x1
 2da:	caa50513          	addi	a0,a0,-854 # f80 <malloc+0x3ae>
 2de:	00001097          	auipc	ra,0x1
 2e2:	836080e7          	jalr	-1994(ra) # b14 <printf>
 2e6:	a809                	j	2f8 <main+0x26c>
        }
    }else{
        printf("test7 failed - sigaction failed\n");
 2e8:	00001517          	auipc	a0,0x1
 2ec:	ca850513          	addi	a0,a0,-856 # f90 <malloc+0x3be>
 2f0:	00001097          	auipc	ra,0x1
 2f4:	824080e7          	jalr	-2012(ra) # b14 <printf>
    }

    test = 0;
 2f8:	00001797          	auipc	a5,0x1
 2fc:	e207a823          	sw	zero,-464(a5) # 1128 <test>
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
 33c:	df072703          	lw	a4,-528(a4) # 1128 <test>
 340:	4785                	li	a5,1
 342:	00f70b63          	beq	a4,a5,358 <main+0x2cc>
            printf("test8 failed - test_handler did not blocked by the mask\n");
        } else{
            printf("test8 passed\n");
 346:	00001517          	auipc	a0,0x1
 34a:	cb250513          	addi	a0,a0,-846 # ff8 <malloc+0x426>
 34e:	00000097          	auipc	ra,0x0
 352:	7c6080e7          	jalr	1990(ra) # b14 <printf>
 356:	a015                	j	37a <main+0x2ee>
            printf("test8 failed - test_handler did not blocked by the mask\n");
 358:	00001517          	auipc	a0,0x1
 35c:	c6050513          	addi	a0,a0,-928 # fb8 <malloc+0x3e6>
 360:	00000097          	auipc	ra,0x0
 364:	7b4080e7          	jalr	1972(ra) # b14 <printf>
 368:	a809                	j	37a <main+0x2ee>
        }   
    }else{
        printf("test8 failed - sigaction failed\n");
 36a:	00001517          	auipc	a0,0x1
 36e:	c9e50513          	addi	a0,a0,-866 # 1008 <malloc+0x436>
 372:	00000097          	auipc	ra,0x0
 376:	7a2080e7          	jalr	1954(ra) # b14 <printf>
    }

    printf("in order to pass tests 9-12 you should get a passed messages\n");
 37a:	00001517          	auipc	a0,0x1
 37e:	cb650513          	addi	a0,a0,-842 # 1030 <malloc+0x45e>
 382:	00000097          	auipc	ra,0x0
 386:	792080e7          	jalr	1938(ra) # b14 <printf>

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
 3a4:	cd050513          	addi	a0,a0,-816 # 1070 <malloc+0x49e>
 3a8:	00000097          	auipc	ra,0x0
 3ac:	76c080e7          	jalr	1900(ra) # b14 <printf>
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
 412:	c7250513          	addi	a0,a0,-910 # 1080 <malloc+0x4ae>
 416:	00000097          	auipc	ra,0x0
 41a:	6fe080e7          	jalr	1790(ra) # b14 <printf>
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
 44c:	c5050513          	addi	a0,a0,-944 # 1098 <malloc+0x4c6>
 450:	00000097          	auipc	ra,0x0
 454:	6c4080e7          	jalr	1732(ra) # b14 <printf>
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
 4a6:	c0e50513          	addi	a0,a0,-1010 # 10b0 <malloc+0x4de>
 4aa:	00000097          	auipc	ra,0x0
 4ae:	66a080e7          	jalr	1642(ra) # b14 <printf>
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
 4c2:	c3a50513          	addi	a0,a0,-966 # 10f8 <malloc+0x526>
 4c6:	00000097          	auipc	ra,0x0
 4ca:	64e080e7          	jalr	1614(ra) # b14 <printf>
    }else{
        wait(0);
    }
    
    exit(0);
 4ce:	4501                	li	a0,0
 4d0:	00000097          	auipc	ra,0x0
 4d4:	294080e7          	jalr	660(ra) # 764 <exit>
            printf("test12A passed\n");
 4d8:	00001517          	auipc	a0,0x1
 4dc:	c1050513          	addi	a0,a0,-1008 # 10e8 <malloc+0x516>
 4e0:	00000097          	auipc	ra,0x0
 4e4:	634080e7          	jalr	1588(ra) # b14 <printf>
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
 6d2:	fed70fa3          	sb	a3,-1(a4) # 3ffffff <__global_pointer$+0x3ffe6de>
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

000000000000083c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 83c:	1101                	addi	sp,sp,-32
 83e:	ec06                	sd	ra,24(sp)
 840:	e822                	sd	s0,16(sp)
 842:	1000                	addi	s0,sp,32
 844:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 848:	4605                	li	a2,1
 84a:	fef40593          	addi	a1,s0,-17
 84e:	00000097          	auipc	ra,0x0
 852:	f36080e7          	jalr	-202(ra) # 784 <write>
}
 856:	60e2                	ld	ra,24(sp)
 858:	6442                	ld	s0,16(sp)
 85a:	6105                	addi	sp,sp,32
 85c:	8082                	ret

000000000000085e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 85e:	7139                	addi	sp,sp,-64
 860:	fc06                	sd	ra,56(sp)
 862:	f822                	sd	s0,48(sp)
 864:	f426                	sd	s1,40(sp)
 866:	f04a                	sd	s2,32(sp)
 868:	ec4e                	sd	s3,24(sp)
 86a:	0080                	addi	s0,sp,64
 86c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 86e:	c299                	beqz	a3,874 <printint+0x16>
 870:	0805c863          	bltz	a1,900 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 874:	2581                	sext.w	a1,a1
  neg = 0;
 876:	4881                	li	a7,0
 878:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 87c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 87e:	2601                	sext.w	a2,a2
 880:	00001517          	auipc	a0,0x1
 884:	89050513          	addi	a0,a0,-1904 # 1110 <digits>
 888:	883a                	mv	a6,a4
 88a:	2705                	addiw	a4,a4,1
 88c:	02c5f7bb          	remuw	a5,a1,a2
 890:	1782                	slli	a5,a5,0x20
 892:	9381                	srli	a5,a5,0x20
 894:	97aa                	add	a5,a5,a0
 896:	0007c783          	lbu	a5,0(a5)
 89a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 89e:	0005879b          	sext.w	a5,a1
 8a2:	02c5d5bb          	divuw	a1,a1,a2
 8a6:	0685                	addi	a3,a3,1
 8a8:	fec7f0e3          	bgeu	a5,a2,888 <printint+0x2a>
  if(neg)
 8ac:	00088b63          	beqz	a7,8c2 <printint+0x64>
    buf[i++] = '-';
 8b0:	fd040793          	addi	a5,s0,-48
 8b4:	973e                	add	a4,a4,a5
 8b6:	02d00793          	li	a5,45
 8ba:	fef70823          	sb	a5,-16(a4)
 8be:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 8c2:	02e05863          	blez	a4,8f2 <printint+0x94>
 8c6:	fc040793          	addi	a5,s0,-64
 8ca:	00e78933          	add	s2,a5,a4
 8ce:	fff78993          	addi	s3,a5,-1
 8d2:	99ba                	add	s3,s3,a4
 8d4:	377d                	addiw	a4,a4,-1
 8d6:	1702                	slli	a4,a4,0x20
 8d8:	9301                	srli	a4,a4,0x20
 8da:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 8de:	fff94583          	lbu	a1,-1(s2)
 8e2:	8526                	mv	a0,s1
 8e4:	00000097          	auipc	ra,0x0
 8e8:	f58080e7          	jalr	-168(ra) # 83c <putc>
  while(--i >= 0)
 8ec:	197d                	addi	s2,s2,-1
 8ee:	ff3918e3          	bne	s2,s3,8de <printint+0x80>
}
 8f2:	70e2                	ld	ra,56(sp)
 8f4:	7442                	ld	s0,48(sp)
 8f6:	74a2                	ld	s1,40(sp)
 8f8:	7902                	ld	s2,32(sp)
 8fa:	69e2                	ld	s3,24(sp)
 8fc:	6121                	addi	sp,sp,64
 8fe:	8082                	ret
    x = -xx;
 900:	40b005bb          	negw	a1,a1
    neg = 1;
 904:	4885                	li	a7,1
    x = -xx;
 906:	bf8d                	j	878 <printint+0x1a>

0000000000000908 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 908:	7119                	addi	sp,sp,-128
 90a:	fc86                	sd	ra,120(sp)
 90c:	f8a2                	sd	s0,112(sp)
 90e:	f4a6                	sd	s1,104(sp)
 910:	f0ca                	sd	s2,96(sp)
 912:	ecce                	sd	s3,88(sp)
 914:	e8d2                	sd	s4,80(sp)
 916:	e4d6                	sd	s5,72(sp)
 918:	e0da                	sd	s6,64(sp)
 91a:	fc5e                	sd	s7,56(sp)
 91c:	f862                	sd	s8,48(sp)
 91e:	f466                	sd	s9,40(sp)
 920:	f06a                	sd	s10,32(sp)
 922:	ec6e                	sd	s11,24(sp)
 924:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 926:	0005c903          	lbu	s2,0(a1)
 92a:	18090f63          	beqz	s2,ac8 <vprintf+0x1c0>
 92e:	8aaa                	mv	s5,a0
 930:	8b32                	mv	s6,a2
 932:	00158493          	addi	s1,a1,1
  state = 0;
 936:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 938:	02500a13          	li	s4,37
      if(c == 'd'){
 93c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 940:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 944:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 948:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 94c:	00000b97          	auipc	s7,0x0
 950:	7c4b8b93          	addi	s7,s7,1988 # 1110 <digits>
 954:	a839                	j	972 <vprintf+0x6a>
        putc(fd, c);
 956:	85ca                	mv	a1,s2
 958:	8556                	mv	a0,s5
 95a:	00000097          	auipc	ra,0x0
 95e:	ee2080e7          	jalr	-286(ra) # 83c <putc>
 962:	a019                	j	968 <vprintf+0x60>
    } else if(state == '%'){
 964:	01498f63          	beq	s3,s4,982 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 968:	0485                	addi	s1,s1,1
 96a:	fff4c903          	lbu	s2,-1(s1)
 96e:	14090d63          	beqz	s2,ac8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 972:	0009079b          	sext.w	a5,s2
    if(state == 0){
 976:	fe0997e3          	bnez	s3,964 <vprintf+0x5c>
      if(c == '%'){
 97a:	fd479ee3          	bne	a5,s4,956 <vprintf+0x4e>
        state = '%';
 97e:	89be                	mv	s3,a5
 980:	b7e5                	j	968 <vprintf+0x60>
      if(c == 'd'){
 982:	05878063          	beq	a5,s8,9c2 <vprintf+0xba>
      } else if(c == 'l') {
 986:	05978c63          	beq	a5,s9,9de <vprintf+0xd6>
      } else if(c == 'x') {
 98a:	07a78863          	beq	a5,s10,9fa <vprintf+0xf2>
      } else if(c == 'p') {
 98e:	09b78463          	beq	a5,s11,a16 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 992:	07300713          	li	a4,115
 996:	0ce78663          	beq	a5,a4,a62 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 99a:	06300713          	li	a4,99
 99e:	0ee78e63          	beq	a5,a4,a9a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 9a2:	11478863          	beq	a5,s4,ab2 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 9a6:	85d2                	mv	a1,s4
 9a8:	8556                	mv	a0,s5
 9aa:	00000097          	auipc	ra,0x0
 9ae:	e92080e7          	jalr	-366(ra) # 83c <putc>
        putc(fd, c);
 9b2:	85ca                	mv	a1,s2
 9b4:	8556                	mv	a0,s5
 9b6:	00000097          	auipc	ra,0x0
 9ba:	e86080e7          	jalr	-378(ra) # 83c <putc>
      }
      state = 0;
 9be:	4981                	li	s3,0
 9c0:	b765                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 9c2:	008b0913          	addi	s2,s6,8
 9c6:	4685                	li	a3,1
 9c8:	4629                	li	a2,10
 9ca:	000b2583          	lw	a1,0(s6)
 9ce:	8556                	mv	a0,s5
 9d0:	00000097          	auipc	ra,0x0
 9d4:	e8e080e7          	jalr	-370(ra) # 85e <printint>
 9d8:	8b4a                	mv	s6,s2
      state = 0;
 9da:	4981                	li	s3,0
 9dc:	b771                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9de:	008b0913          	addi	s2,s6,8
 9e2:	4681                	li	a3,0
 9e4:	4629                	li	a2,10
 9e6:	000b2583          	lw	a1,0(s6)
 9ea:	8556                	mv	a0,s5
 9ec:	00000097          	auipc	ra,0x0
 9f0:	e72080e7          	jalr	-398(ra) # 85e <printint>
 9f4:	8b4a                	mv	s6,s2
      state = 0;
 9f6:	4981                	li	s3,0
 9f8:	bf85                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 9fa:	008b0913          	addi	s2,s6,8
 9fe:	4681                	li	a3,0
 a00:	4641                	li	a2,16
 a02:	000b2583          	lw	a1,0(s6)
 a06:	8556                	mv	a0,s5
 a08:	00000097          	auipc	ra,0x0
 a0c:	e56080e7          	jalr	-426(ra) # 85e <printint>
 a10:	8b4a                	mv	s6,s2
      state = 0;
 a12:	4981                	li	s3,0
 a14:	bf91                	j	968 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a16:	008b0793          	addi	a5,s6,8
 a1a:	f8f43423          	sd	a5,-120(s0)
 a1e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a22:	03000593          	li	a1,48
 a26:	8556                	mv	a0,s5
 a28:	00000097          	auipc	ra,0x0
 a2c:	e14080e7          	jalr	-492(ra) # 83c <putc>
  putc(fd, 'x');
 a30:	85ea                	mv	a1,s10
 a32:	8556                	mv	a0,s5
 a34:	00000097          	auipc	ra,0x0
 a38:	e08080e7          	jalr	-504(ra) # 83c <putc>
 a3c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a3e:	03c9d793          	srli	a5,s3,0x3c
 a42:	97de                	add	a5,a5,s7
 a44:	0007c583          	lbu	a1,0(a5)
 a48:	8556                	mv	a0,s5
 a4a:	00000097          	auipc	ra,0x0
 a4e:	df2080e7          	jalr	-526(ra) # 83c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a52:	0992                	slli	s3,s3,0x4
 a54:	397d                	addiw	s2,s2,-1
 a56:	fe0914e3          	bnez	s2,a3e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 a5a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a5e:	4981                	li	s3,0
 a60:	b721                	j	968 <vprintf+0x60>
        s = va_arg(ap, char*);
 a62:	008b0993          	addi	s3,s6,8
 a66:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 a6a:	02090163          	beqz	s2,a8c <vprintf+0x184>
        while(*s != 0){
 a6e:	00094583          	lbu	a1,0(s2)
 a72:	c9a1                	beqz	a1,ac2 <vprintf+0x1ba>
          putc(fd, *s);
 a74:	8556                	mv	a0,s5
 a76:	00000097          	auipc	ra,0x0
 a7a:	dc6080e7          	jalr	-570(ra) # 83c <putc>
          s++;
 a7e:	0905                	addi	s2,s2,1
        while(*s != 0){
 a80:	00094583          	lbu	a1,0(s2)
 a84:	f9e5                	bnez	a1,a74 <vprintf+0x16c>
        s = va_arg(ap, char*);
 a86:	8b4e                	mv	s6,s3
      state = 0;
 a88:	4981                	li	s3,0
 a8a:	bdf9                	j	968 <vprintf+0x60>
          s = "(null)";
 a8c:	00000917          	auipc	s2,0x0
 a90:	67c90913          	addi	s2,s2,1660 # 1108 <malloc+0x536>
        while(*s != 0){
 a94:	02800593          	li	a1,40
 a98:	bff1                	j	a74 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 a9a:	008b0913          	addi	s2,s6,8
 a9e:	000b4583          	lbu	a1,0(s6)
 aa2:	8556                	mv	a0,s5
 aa4:	00000097          	auipc	ra,0x0
 aa8:	d98080e7          	jalr	-616(ra) # 83c <putc>
 aac:	8b4a                	mv	s6,s2
      state = 0;
 aae:	4981                	li	s3,0
 ab0:	bd65                	j	968 <vprintf+0x60>
        putc(fd, c);
 ab2:	85d2                	mv	a1,s4
 ab4:	8556                	mv	a0,s5
 ab6:	00000097          	auipc	ra,0x0
 aba:	d86080e7          	jalr	-634(ra) # 83c <putc>
      state = 0;
 abe:	4981                	li	s3,0
 ac0:	b565                	j	968 <vprintf+0x60>
        s = va_arg(ap, char*);
 ac2:	8b4e                	mv	s6,s3
      state = 0;
 ac4:	4981                	li	s3,0
 ac6:	b54d                	j	968 <vprintf+0x60>
    }
  }
}
 ac8:	70e6                	ld	ra,120(sp)
 aca:	7446                	ld	s0,112(sp)
 acc:	74a6                	ld	s1,104(sp)
 ace:	7906                	ld	s2,96(sp)
 ad0:	69e6                	ld	s3,88(sp)
 ad2:	6a46                	ld	s4,80(sp)
 ad4:	6aa6                	ld	s5,72(sp)
 ad6:	6b06                	ld	s6,64(sp)
 ad8:	7be2                	ld	s7,56(sp)
 ada:	7c42                	ld	s8,48(sp)
 adc:	7ca2                	ld	s9,40(sp)
 ade:	7d02                	ld	s10,32(sp)
 ae0:	6de2                	ld	s11,24(sp)
 ae2:	6109                	addi	sp,sp,128
 ae4:	8082                	ret

0000000000000ae6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 ae6:	715d                	addi	sp,sp,-80
 ae8:	ec06                	sd	ra,24(sp)
 aea:	e822                	sd	s0,16(sp)
 aec:	1000                	addi	s0,sp,32
 aee:	e010                	sd	a2,0(s0)
 af0:	e414                	sd	a3,8(s0)
 af2:	e818                	sd	a4,16(s0)
 af4:	ec1c                	sd	a5,24(s0)
 af6:	03043023          	sd	a6,32(s0)
 afa:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 afe:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b02:	8622                	mv	a2,s0
 b04:	00000097          	auipc	ra,0x0
 b08:	e04080e7          	jalr	-508(ra) # 908 <vprintf>
}
 b0c:	60e2                	ld	ra,24(sp)
 b0e:	6442                	ld	s0,16(sp)
 b10:	6161                	addi	sp,sp,80
 b12:	8082                	ret

0000000000000b14 <printf>:

void
printf(const char *fmt, ...)
{
 b14:	711d                	addi	sp,sp,-96
 b16:	ec06                	sd	ra,24(sp)
 b18:	e822                	sd	s0,16(sp)
 b1a:	1000                	addi	s0,sp,32
 b1c:	e40c                	sd	a1,8(s0)
 b1e:	e810                	sd	a2,16(s0)
 b20:	ec14                	sd	a3,24(s0)
 b22:	f018                	sd	a4,32(s0)
 b24:	f41c                	sd	a5,40(s0)
 b26:	03043823          	sd	a6,48(s0)
 b2a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b2e:	00840613          	addi	a2,s0,8
 b32:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b36:	85aa                	mv	a1,a0
 b38:	4505                	li	a0,1
 b3a:	00000097          	auipc	ra,0x0
 b3e:	dce080e7          	jalr	-562(ra) # 908 <vprintf>
}
 b42:	60e2                	ld	ra,24(sp)
 b44:	6442                	ld	s0,16(sp)
 b46:	6125                	addi	sp,sp,96
 b48:	8082                	ret

0000000000000b4a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b4a:	1141                	addi	sp,sp,-16
 b4c:	e422                	sd	s0,8(sp)
 b4e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b50:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b54:	00000797          	auipc	a5,0x0
 b58:	5dc7b783          	ld	a5,1500(a5) # 1130 <freep>
 b5c:	a805                	j	b8c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b5e:	4618                	lw	a4,8(a2)
 b60:	9db9                	addw	a1,a1,a4
 b62:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b66:	6398                	ld	a4,0(a5)
 b68:	6318                	ld	a4,0(a4)
 b6a:	fee53823          	sd	a4,-16(a0)
 b6e:	a091                	j	bb2 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b70:	ff852703          	lw	a4,-8(a0)
 b74:	9e39                	addw	a2,a2,a4
 b76:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b78:	ff053703          	ld	a4,-16(a0)
 b7c:	e398                	sd	a4,0(a5)
 b7e:	a099                	j	bc4 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b80:	6398                	ld	a4,0(a5)
 b82:	00e7e463          	bltu	a5,a4,b8a <free+0x40>
 b86:	00e6ea63          	bltu	a3,a4,b9a <free+0x50>
{
 b8a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b8c:	fed7fae3          	bgeu	a5,a3,b80 <free+0x36>
 b90:	6398                	ld	a4,0(a5)
 b92:	00e6e463          	bltu	a3,a4,b9a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b96:	fee7eae3          	bltu	a5,a4,b8a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 b9a:	ff852583          	lw	a1,-8(a0)
 b9e:	6390                	ld	a2,0(a5)
 ba0:	02059813          	slli	a6,a1,0x20
 ba4:	01c85713          	srli	a4,a6,0x1c
 ba8:	9736                	add	a4,a4,a3
 baa:	fae60ae3          	beq	a2,a4,b5e <free+0x14>
    bp->s.ptr = p->s.ptr;
 bae:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 bb2:	4790                	lw	a2,8(a5)
 bb4:	02061593          	slli	a1,a2,0x20
 bb8:	01c5d713          	srli	a4,a1,0x1c
 bbc:	973e                	add	a4,a4,a5
 bbe:	fae689e3          	beq	a3,a4,b70 <free+0x26>
  } else
    p->s.ptr = bp;
 bc2:	e394                	sd	a3,0(a5)
  freep = p;
 bc4:	00000717          	auipc	a4,0x0
 bc8:	56f73623          	sd	a5,1388(a4) # 1130 <freep>
}
 bcc:	6422                	ld	s0,8(sp)
 bce:	0141                	addi	sp,sp,16
 bd0:	8082                	ret

0000000000000bd2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bd2:	7139                	addi	sp,sp,-64
 bd4:	fc06                	sd	ra,56(sp)
 bd6:	f822                	sd	s0,48(sp)
 bd8:	f426                	sd	s1,40(sp)
 bda:	f04a                	sd	s2,32(sp)
 bdc:	ec4e                	sd	s3,24(sp)
 bde:	e852                	sd	s4,16(sp)
 be0:	e456                	sd	s5,8(sp)
 be2:	e05a                	sd	s6,0(sp)
 be4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 be6:	02051493          	slli	s1,a0,0x20
 bea:	9081                	srli	s1,s1,0x20
 bec:	04bd                	addi	s1,s1,15
 bee:	8091                	srli	s1,s1,0x4
 bf0:	0014899b          	addiw	s3,s1,1
 bf4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 bf6:	00000517          	auipc	a0,0x0
 bfa:	53a53503          	ld	a0,1338(a0) # 1130 <freep>
 bfe:	c515                	beqz	a0,c2a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c00:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c02:	4798                	lw	a4,8(a5)
 c04:	02977f63          	bgeu	a4,s1,c42 <malloc+0x70>
 c08:	8a4e                	mv	s4,s3
 c0a:	0009871b          	sext.w	a4,s3
 c0e:	6685                	lui	a3,0x1
 c10:	00d77363          	bgeu	a4,a3,c16 <malloc+0x44>
 c14:	6a05                	lui	s4,0x1
 c16:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c1a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c1e:	00000917          	auipc	s2,0x0
 c22:	51290913          	addi	s2,s2,1298 # 1130 <freep>
  if(p == (char*)-1)
 c26:	5afd                	li	s5,-1
 c28:	a895                	j	c9c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 c2a:	00000797          	auipc	a5,0x0
 c2e:	50e78793          	addi	a5,a5,1294 # 1138 <base>
 c32:	00000717          	auipc	a4,0x0
 c36:	4ef73f23          	sd	a5,1278(a4) # 1130 <freep>
 c3a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c3c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c40:	b7e1                	j	c08 <malloc+0x36>
      if(p->s.size == nunits)
 c42:	02e48c63          	beq	s1,a4,c7a <malloc+0xa8>
        p->s.size -= nunits;
 c46:	4137073b          	subw	a4,a4,s3
 c4a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c4c:	02071693          	slli	a3,a4,0x20
 c50:	01c6d713          	srli	a4,a3,0x1c
 c54:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c56:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c5a:	00000717          	auipc	a4,0x0
 c5e:	4ca73b23          	sd	a0,1238(a4) # 1130 <freep>
      return (void*)(p + 1);
 c62:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c66:	70e2                	ld	ra,56(sp)
 c68:	7442                	ld	s0,48(sp)
 c6a:	74a2                	ld	s1,40(sp)
 c6c:	7902                	ld	s2,32(sp)
 c6e:	69e2                	ld	s3,24(sp)
 c70:	6a42                	ld	s4,16(sp)
 c72:	6aa2                	ld	s5,8(sp)
 c74:	6b02                	ld	s6,0(sp)
 c76:	6121                	addi	sp,sp,64
 c78:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c7a:	6398                	ld	a4,0(a5)
 c7c:	e118                	sd	a4,0(a0)
 c7e:	bff1                	j	c5a <malloc+0x88>
  hp->s.size = nu;
 c80:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c84:	0541                	addi	a0,a0,16
 c86:	00000097          	auipc	ra,0x0
 c8a:	ec4080e7          	jalr	-316(ra) # b4a <free>
  return freep;
 c8e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c92:	d971                	beqz	a0,c66 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c94:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c96:	4798                	lw	a4,8(a5)
 c98:	fa9775e3          	bgeu	a4,s1,c42 <malloc+0x70>
    if(p == freep)
 c9c:	00093703          	ld	a4,0(s2)
 ca0:	853e                	mv	a0,a5
 ca2:	fef719e3          	bne	a4,a5,c94 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 ca6:	8552                	mv	a0,s4
 ca8:	00000097          	auipc	ra,0x0
 cac:	b44080e7          	jalr	-1212(ra) # 7ec <sbrk>
  if(p == (char*)-1)
 cb0:	fd5518e3          	bne	a0,s5,c80 <malloc+0xae>
        return 0;
 cb4:	4501                	li	a0,0
 cb6:	bf45                	j	c66 <malloc+0x94>
