
user/_grind:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <do_rand>:
#include "kernel/riscv.h"

// from FreeBSD.
int
do_rand(unsigned long *ctx)
{
       0:	1141                	addi	sp,sp,-16
       2:	e422                	sd	s0,8(sp)
       4:	0800                	addi	s0,sp,16
 * October 1988, p. 1195.
 */
    long hi, lo, x;

    /* Transform to [1, 0x7ffffffe] range. */
    x = (*ctx % 0x7ffffffe) + 1;
       6:	611c                	ld	a5,0(a0)
       8:	80000737          	lui	a4,0x80000
       c:	ffe74713          	xori	a4,a4,-2
      10:	02e7f7b3          	remu	a5,a5,a4
      14:	0785                	addi	a5,a5,1
    hi = x / 127773;
    lo = x % 127773;
      16:	66fd                	lui	a3,0x1f
      18:	31d68693          	addi	a3,a3,797 # 1f31d <__global_pointer$+0x1d45c>
      1c:	02d7e733          	rem	a4,a5,a3
    x = 16807 * lo - 2836 * hi;
      20:	6611                	lui	a2,0x4
      22:	1a760613          	addi	a2,a2,423 # 41a7 <__global_pointer$+0x22e6>
      26:	02c70733          	mul	a4,a4,a2
    hi = x / 127773;
      2a:	02d7c7b3          	div	a5,a5,a3
    x = 16807 * lo - 2836 * hi;
      2e:	76fd                	lui	a3,0xfffff
      30:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <__global_pointer$+0xffffffffffffd62b>
      34:	02d787b3          	mul	a5,a5,a3
      38:	97ba                	add	a5,a5,a4
    if (x < 0)
      3a:	0007c963          	bltz	a5,4c <do_rand+0x4c>
        x += 0x7fffffff;
    /* Transform to [0, 0x7ffffffd] range. */
    x--;
      3e:	17fd                	addi	a5,a5,-1
    *ctx = x;
      40:	e11c                	sd	a5,0(a0)
    return (x);
}
      42:	0007851b          	sext.w	a0,a5
      46:	6422                	ld	s0,8(sp)
      48:	0141                	addi	sp,sp,16
      4a:	8082                	ret
        x += 0x7fffffff;
      4c:	80000737          	lui	a4,0x80000
      50:	fff74713          	not	a4,a4
      54:	97ba                	add	a5,a5,a4
      56:	b7e5                	j	3e <do_rand+0x3e>

0000000000000058 <rand>:

unsigned long rand_next = 1;

int
rand(void)
{
      58:	1141                	addi	sp,sp,-16
      5a:	e406                	sd	ra,8(sp)
      5c:	e022                	sd	s0,0(sp)
      5e:	0800                	addi	s0,sp,16
    return (do_rand(&rand_next));
      60:	00001517          	auipc	a0,0x1
      64:	66850513          	addi	a0,a0,1640 # 16c8 <rand_next>
      68:	00000097          	auipc	ra,0x0
      6c:	f98080e7          	jalr	-104(ra) # 0 <do_rand>
}
      70:	60a2                	ld	ra,8(sp)
      72:	6402                	ld	s0,0(sp)
      74:	0141                	addi	sp,sp,16
      76:	8082                	ret

0000000000000078 <go>:

void
go(int which_child)
{
      78:	7159                	addi	sp,sp,-112
      7a:	f486                	sd	ra,104(sp)
      7c:	f0a2                	sd	s0,96(sp)
      7e:	eca6                	sd	s1,88(sp)
      80:	e8ca                	sd	s2,80(sp)
      82:	e4ce                	sd	s3,72(sp)
      84:	e0d2                	sd	s4,64(sp)
      86:	fc56                	sd	s5,56(sp)
      88:	f85a                	sd	s6,48(sp)
      8a:	1880                	addi	s0,sp,112
      8c:	84aa                	mv	s1,a0
  int fd = -1;
  static char buf[999];
  char *break0 = sbrk(0);
      8e:	4501                	li	a0,0
      90:	00001097          	auipc	ra,0x1
      94:	e5e080e7          	jalr	-418(ra) # eee <sbrk>
      98:	8aaa                	mv	s5,a0
  uint64 iters = 0;

  mkdir("grindir");
      9a:	00001517          	auipc	a0,0x1
      9e:	32650513          	addi	a0,a0,806 # 13c0 <malloc+0xec>
      a2:	00001097          	auipc	ra,0x1
      a6:	e2c080e7          	jalr	-468(ra) # ece <mkdir>
  if(chdir("grindir") != 0){
      aa:	00001517          	auipc	a0,0x1
      ae:	31650513          	addi	a0,a0,790 # 13c0 <malloc+0xec>
      b2:	00001097          	auipc	ra,0x1
      b6:	e24080e7          	jalr	-476(ra) # ed6 <chdir>
      ba:	cd11                	beqz	a0,d6 <go+0x5e>
    printf("grind: chdir grindir failed\n");
      bc:	00001517          	auipc	a0,0x1
      c0:	30c50513          	addi	a0,a0,780 # 13c8 <malloc+0xf4>
      c4:	00001097          	auipc	ra,0x1
      c8:	152080e7          	jalr	338(ra) # 1216 <printf>
    exit(1);
      cc:	4505                	li	a0,1
      ce:	00001097          	auipc	ra,0x1
      d2:	d98080e7          	jalr	-616(ra) # e66 <exit>
  }
  chdir("/");
      d6:	00001517          	auipc	a0,0x1
      da:	31250513          	addi	a0,a0,786 # 13e8 <malloc+0x114>
      de:	00001097          	auipc	ra,0x1
      e2:	df8080e7          	jalr	-520(ra) # ed6 <chdir>
  
  while(1){
    iters++;
    if((iters % 500) == 0)
      e6:	00001997          	auipc	s3,0x1
      ea:	31298993          	addi	s3,s3,786 # 13f8 <malloc+0x124>
      ee:	c489                	beqz	s1,f8 <go+0x80>
      f0:	00001997          	auipc	s3,0x1
      f4:	30098993          	addi	s3,s3,768 # 13f0 <malloc+0x11c>
    iters++;
      f8:	4485                	li	s1,1
  int fd = -1;
      fa:	597d                	li	s2,-1
      close(fd);
      fd = open("/./grindir/./../b", O_CREATE|O_RDWR);
    } else if(what == 7){
      write(fd, buf, sizeof(buf));
    } else if(what == 8){
      read(fd, buf, sizeof(buf));
      fc:	00001a17          	auipc	s4,0x1
     100:	5dca0a13          	addi	s4,s4,1500 # 16d8 <buf.0>
     104:	a825                	j	13c <go+0xc4>
      close(open("grindir/../a", O_CREATE|O_RDWR));
     106:	20200593          	li	a1,514
     10a:	00001517          	auipc	a0,0x1
     10e:	2f650513          	addi	a0,a0,758 # 1400 <malloc+0x12c>
     112:	00001097          	auipc	ra,0x1
     116:	d94080e7          	jalr	-620(ra) # ea6 <open>
     11a:	00001097          	auipc	ra,0x1
     11e:	d74080e7          	jalr	-652(ra) # e8e <close>
    iters++;
     122:	0485                	addi	s1,s1,1
    if((iters % 500) == 0)
     124:	1f400793          	li	a5,500
     128:	02f4f7b3          	remu	a5,s1,a5
     12c:	eb81                	bnez	a5,13c <go+0xc4>
      write(1, which_child?"B":"A", 1);
     12e:	4605                	li	a2,1
     130:	85ce                	mv	a1,s3
     132:	4505                	li	a0,1
     134:	00001097          	auipc	ra,0x1
     138:	d52080e7          	jalr	-686(ra) # e86 <write>
    int what = rand() % 23;
     13c:	00000097          	auipc	ra,0x0
     140:	f1c080e7          	jalr	-228(ra) # 58 <rand>
     144:	47dd                	li	a5,23
     146:	02f5653b          	remw	a0,a0,a5
    if(what == 1){
     14a:	4785                	li	a5,1
     14c:	faf50de3          	beq	a0,a5,106 <go+0x8e>
    } else if(what == 2){
     150:	4789                	li	a5,2
     152:	18f50563          	beq	a0,a5,2dc <go+0x264>
    } else if(what == 3){
     156:	478d                	li	a5,3
     158:	1af50163          	beq	a0,a5,2fa <go+0x282>
    } else if(what == 4){
     15c:	4791                	li	a5,4
     15e:	1af50763          	beq	a0,a5,30c <go+0x294>
    } else if(what == 5){
     162:	4795                	li	a5,5
     164:	1ef50b63          	beq	a0,a5,35a <go+0x2e2>
    } else if(what == 6){
     168:	4799                	li	a5,6
     16a:	20f50963          	beq	a0,a5,37c <go+0x304>
    } else if(what == 7){
     16e:	479d                	li	a5,7
     170:	22f50763          	beq	a0,a5,39e <go+0x326>
    } else if(what == 8){
     174:	47a1                	li	a5,8
     176:	22f50d63          	beq	a0,a5,3b0 <go+0x338>
    } else if(what == 9){
     17a:	47a5                	li	a5,9
     17c:	24f50363          	beq	a0,a5,3c2 <go+0x34a>
      mkdir("grindir/../a");
      close(open("a/../a/./a", O_CREATE|O_RDWR));
      unlink("a/a");
    } else if(what == 10){
     180:	47a9                	li	a5,10
     182:	26f50f63          	beq	a0,a5,400 <go+0x388>
      mkdir("/../b");
      close(open("grindir/../b/b", O_CREATE|O_RDWR));
      unlink("b/b");
    } else if(what == 11){
     186:	47ad                	li	a5,11
     188:	2af50b63          	beq	a0,a5,43e <go+0x3c6>
      unlink("b");
      link("../grindir/./../a", "../b");
    } else if(what == 12){
     18c:	47b1                	li	a5,12
     18e:	2cf50d63          	beq	a0,a5,468 <go+0x3f0>
      unlink("../grindir/../a");
      link(".././b", "/grindir/../a");
    } else if(what == 13){
     192:	47b5                	li	a5,13
     194:	2ef50f63          	beq	a0,a5,492 <go+0x41a>
      } else if(pid < 0){
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 14){
     198:	47b9                	li	a5,14
     19a:	32f50a63          	beq	a0,a5,4ce <go+0x456>
      } else if(pid < 0){
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 15){
     19e:	47bd                	li	a5,15
     1a0:	36f50e63          	beq	a0,a5,51c <go+0x4a4>
      sbrk(6011);
    } else if(what == 16){
     1a4:	47c1                	li	a5,16
     1a6:	38f50363          	beq	a0,a5,52c <go+0x4b4>
      if(sbrk(0) > break0)
        sbrk(-(sbrk(0) - break0));
    } else if(what == 17){
     1aa:	47c5                	li	a5,17
     1ac:	3af50363          	beq	a0,a5,552 <go+0x4da>
        printf("grind: chdir failed\n");
        exit(1);
      }
      kill(pid, SIGKILL); // ADDED Q2.2.2
      wait(0);
    } else if(what == 18){
     1b0:	47c9                	li	a5,18
     1b2:	42f50a63          	beq	a0,a5,5e6 <go+0x56e>
      } else if(pid < 0){
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 19){
     1b6:	47cd                	li	a5,19
     1b8:	46f50f63          	beq	a0,a5,636 <go+0x5be>
        exit(1);
      }
      close(fds[0]);
      close(fds[1]);
      wait(0);
    } else if(what == 20){
     1bc:	47d1                	li	a5,20
     1be:	56f50063          	beq	a0,a5,71e <go+0x6a6>
      } else if(pid < 0){
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 21){
     1c2:	47d5                	li	a5,21
     1c4:	5ef50e63          	beq	a0,a5,7c0 <go+0x748>
        printf("grind: fstat reports crazy i-number %d\n", st.ino);
        exit(1);
      }
      close(fd1);
      unlink("c");
    } else if(what == 22){
     1c8:	47d9                	li	a5,22
     1ca:	f4f51ce3          	bne	a0,a5,122 <go+0xaa>
      // echo hi | cat
      int aa[2], bb[2];
      if(pipe(aa) < 0){
     1ce:	f9840513          	addi	a0,s0,-104
     1d2:	00001097          	auipc	ra,0x1
     1d6:	ca4080e7          	jalr	-860(ra) # e76 <pipe>
     1da:	6e054763          	bltz	a0,8c8 <go+0x850>
        fprintf(2, "grind: pipe failed\n");
        exit(1);
      }
      if(pipe(bb) < 0){
     1de:	fa040513          	addi	a0,s0,-96
     1e2:	00001097          	auipc	ra,0x1
     1e6:	c94080e7          	jalr	-876(ra) # e76 <pipe>
     1ea:	6e054d63          	bltz	a0,8e4 <go+0x86c>
        fprintf(2, "grind: pipe failed\n");
        exit(1);
      }
      int pid1 = fork();
     1ee:	00001097          	auipc	ra,0x1
     1f2:	c70080e7          	jalr	-912(ra) # e5e <fork>
      if(pid1 == 0){
     1f6:	70050563          	beqz	a0,900 <go+0x888>
        close(aa[1]);
        char *args[3] = { "echo", "hi", 0 };
        exec("grindir/../echo", args);
        fprintf(2, "grind: echo: not found\n");
        exit(2);
      } else if(pid1 < 0){
     1fa:	7a054d63          	bltz	a0,9b4 <go+0x93c>
        fprintf(2, "grind: fork failed\n");
        exit(3);
      }
      int pid2 = fork();
     1fe:	00001097          	auipc	ra,0x1
     202:	c60080e7          	jalr	-928(ra) # e5e <fork>
      if(pid2 == 0){
     206:	7c050563          	beqz	a0,9d0 <go+0x958>
        close(bb[1]);
        char *args[2] = { "cat", 0 };
        exec("/cat", args);
        fprintf(2, "grind: cat: not found\n");
        exit(6);
      } else if(pid2 < 0){
     20a:	0a0541e3          	bltz	a0,aac <go+0xa34>
        fprintf(2, "grind: fork failed\n");
        exit(7);
      }
      close(aa[0]);
     20e:	f9842503          	lw	a0,-104(s0)
     212:	00001097          	auipc	ra,0x1
     216:	c7c080e7          	jalr	-900(ra) # e8e <close>
      close(aa[1]);
     21a:	f9c42503          	lw	a0,-100(s0)
     21e:	00001097          	auipc	ra,0x1
     222:	c70080e7          	jalr	-912(ra) # e8e <close>
      close(bb[1]);
     226:	fa442503          	lw	a0,-92(s0)
     22a:	00001097          	auipc	ra,0x1
     22e:	c64080e7          	jalr	-924(ra) # e8e <close>
      char buf[4] = { 0, 0, 0, 0 };
     232:	f8042823          	sw	zero,-112(s0)
      read(bb[0], buf+0, 1);
     236:	4605                	li	a2,1
     238:	f9040593          	addi	a1,s0,-112
     23c:	fa042503          	lw	a0,-96(s0)
     240:	00001097          	auipc	ra,0x1
     244:	c3e080e7          	jalr	-962(ra) # e7e <read>
      read(bb[0], buf+1, 1);
     248:	4605                	li	a2,1
     24a:	f9140593          	addi	a1,s0,-111
     24e:	fa042503          	lw	a0,-96(s0)
     252:	00001097          	auipc	ra,0x1
     256:	c2c080e7          	jalr	-980(ra) # e7e <read>
      read(bb[0], buf+2, 1);
     25a:	4605                	li	a2,1
     25c:	f9240593          	addi	a1,s0,-110
     260:	fa042503          	lw	a0,-96(s0)
     264:	00001097          	auipc	ra,0x1
     268:	c1a080e7          	jalr	-998(ra) # e7e <read>
      close(bb[0]);
     26c:	fa042503          	lw	a0,-96(s0)
     270:	00001097          	auipc	ra,0x1
     274:	c1e080e7          	jalr	-994(ra) # e8e <close>
      int st1, st2;
      wait(&st1);
     278:	f9440513          	addi	a0,s0,-108
     27c:	00001097          	auipc	ra,0x1
     280:	bf2080e7          	jalr	-1038(ra) # e6e <wait>
      wait(&st2);
     284:	fa840513          	addi	a0,s0,-88
     288:	00001097          	auipc	ra,0x1
     28c:	be6080e7          	jalr	-1050(ra) # e6e <wait>
      if(st1 != 0 || st2 != 0 || strcmp(buf, "hi\n") != 0){
     290:	f9442783          	lw	a5,-108(s0)
     294:	fa842703          	lw	a4,-88(s0)
     298:	8fd9                	or	a5,a5,a4
     29a:	2781                	sext.w	a5,a5
     29c:	ef89                	bnez	a5,2b6 <go+0x23e>
     29e:	00001597          	auipc	a1,0x1
     2a2:	3da58593          	addi	a1,a1,986 # 1678 <malloc+0x3a4>
     2a6:	f9040513          	addi	a0,s0,-112
     2aa:	00001097          	auipc	ra,0x1
     2ae:	96a080e7          	jalr	-1686(ra) # c14 <strcmp>
     2b2:	e60508e3          	beqz	a0,122 <go+0xaa>
        printf("grind: exec pipeline failed %d %d \"%s\"\n", st1, st2, buf);
     2b6:	f9040693          	addi	a3,s0,-112
     2ba:	fa842603          	lw	a2,-88(s0)
     2be:	f9442583          	lw	a1,-108(s0)
     2c2:	00001517          	auipc	a0,0x1
     2c6:	3be50513          	addi	a0,a0,958 # 1680 <malloc+0x3ac>
     2ca:	00001097          	auipc	ra,0x1
     2ce:	f4c080e7          	jalr	-180(ra) # 1216 <printf>
        exit(1);
     2d2:	4505                	li	a0,1
     2d4:	00001097          	auipc	ra,0x1
     2d8:	b92080e7          	jalr	-1134(ra) # e66 <exit>
      close(open("grindir/../grindir/../b", O_CREATE|O_RDWR));
     2dc:	20200593          	li	a1,514
     2e0:	00001517          	auipc	a0,0x1
     2e4:	13050513          	addi	a0,a0,304 # 1410 <malloc+0x13c>
     2e8:	00001097          	auipc	ra,0x1
     2ec:	bbe080e7          	jalr	-1090(ra) # ea6 <open>
     2f0:	00001097          	auipc	ra,0x1
     2f4:	b9e080e7          	jalr	-1122(ra) # e8e <close>
     2f8:	b52d                	j	122 <go+0xaa>
      unlink("grindir/../a");
     2fa:	00001517          	auipc	a0,0x1
     2fe:	10650513          	addi	a0,a0,262 # 1400 <malloc+0x12c>
     302:	00001097          	auipc	ra,0x1
     306:	bb4080e7          	jalr	-1100(ra) # eb6 <unlink>
     30a:	bd21                	j	122 <go+0xaa>
      if(chdir("grindir") != 0){
     30c:	00001517          	auipc	a0,0x1
     310:	0b450513          	addi	a0,a0,180 # 13c0 <malloc+0xec>
     314:	00001097          	auipc	ra,0x1
     318:	bc2080e7          	jalr	-1086(ra) # ed6 <chdir>
     31c:	e115                	bnez	a0,340 <go+0x2c8>
      unlink("../b");
     31e:	00001517          	auipc	a0,0x1
     322:	10a50513          	addi	a0,a0,266 # 1428 <malloc+0x154>
     326:	00001097          	auipc	ra,0x1
     32a:	b90080e7          	jalr	-1136(ra) # eb6 <unlink>
      chdir("/");
     32e:	00001517          	auipc	a0,0x1
     332:	0ba50513          	addi	a0,a0,186 # 13e8 <malloc+0x114>
     336:	00001097          	auipc	ra,0x1
     33a:	ba0080e7          	jalr	-1120(ra) # ed6 <chdir>
     33e:	b3d5                	j	122 <go+0xaa>
        printf("grind: chdir grindir failed\n");
     340:	00001517          	auipc	a0,0x1
     344:	08850513          	addi	a0,a0,136 # 13c8 <malloc+0xf4>
     348:	00001097          	auipc	ra,0x1
     34c:	ece080e7          	jalr	-306(ra) # 1216 <printf>
        exit(1);
     350:	4505                	li	a0,1
     352:	00001097          	auipc	ra,0x1
     356:	b14080e7          	jalr	-1260(ra) # e66 <exit>
      close(fd);
     35a:	854a                	mv	a0,s2
     35c:	00001097          	auipc	ra,0x1
     360:	b32080e7          	jalr	-1230(ra) # e8e <close>
      fd = open("/grindir/../a", O_CREATE|O_RDWR);
     364:	20200593          	li	a1,514
     368:	00001517          	auipc	a0,0x1
     36c:	0c850513          	addi	a0,a0,200 # 1430 <malloc+0x15c>
     370:	00001097          	auipc	ra,0x1
     374:	b36080e7          	jalr	-1226(ra) # ea6 <open>
     378:	892a                	mv	s2,a0
     37a:	b365                	j	122 <go+0xaa>
      close(fd);
     37c:	854a                	mv	a0,s2
     37e:	00001097          	auipc	ra,0x1
     382:	b10080e7          	jalr	-1264(ra) # e8e <close>
      fd = open("/./grindir/./../b", O_CREATE|O_RDWR);
     386:	20200593          	li	a1,514
     38a:	00001517          	auipc	a0,0x1
     38e:	0b650513          	addi	a0,a0,182 # 1440 <malloc+0x16c>
     392:	00001097          	auipc	ra,0x1
     396:	b14080e7          	jalr	-1260(ra) # ea6 <open>
     39a:	892a                	mv	s2,a0
     39c:	b359                	j	122 <go+0xaa>
      write(fd, buf, sizeof(buf));
     39e:	3e700613          	li	a2,999
     3a2:	85d2                	mv	a1,s4
     3a4:	854a                	mv	a0,s2
     3a6:	00001097          	auipc	ra,0x1
     3aa:	ae0080e7          	jalr	-1312(ra) # e86 <write>
     3ae:	bb95                	j	122 <go+0xaa>
      read(fd, buf, sizeof(buf));
     3b0:	3e700613          	li	a2,999
     3b4:	85d2                	mv	a1,s4
     3b6:	854a                	mv	a0,s2
     3b8:	00001097          	auipc	ra,0x1
     3bc:	ac6080e7          	jalr	-1338(ra) # e7e <read>
     3c0:	b38d                	j	122 <go+0xaa>
      mkdir("grindir/../a");
     3c2:	00001517          	auipc	a0,0x1
     3c6:	03e50513          	addi	a0,a0,62 # 1400 <malloc+0x12c>
     3ca:	00001097          	auipc	ra,0x1
     3ce:	b04080e7          	jalr	-1276(ra) # ece <mkdir>
      close(open("a/../a/./a", O_CREATE|O_RDWR));
     3d2:	20200593          	li	a1,514
     3d6:	00001517          	auipc	a0,0x1
     3da:	08250513          	addi	a0,a0,130 # 1458 <malloc+0x184>
     3de:	00001097          	auipc	ra,0x1
     3e2:	ac8080e7          	jalr	-1336(ra) # ea6 <open>
     3e6:	00001097          	auipc	ra,0x1
     3ea:	aa8080e7          	jalr	-1368(ra) # e8e <close>
      unlink("a/a");
     3ee:	00001517          	auipc	a0,0x1
     3f2:	07a50513          	addi	a0,a0,122 # 1468 <malloc+0x194>
     3f6:	00001097          	auipc	ra,0x1
     3fa:	ac0080e7          	jalr	-1344(ra) # eb6 <unlink>
     3fe:	b315                	j	122 <go+0xaa>
      mkdir("/../b");
     400:	00001517          	auipc	a0,0x1
     404:	07050513          	addi	a0,a0,112 # 1470 <malloc+0x19c>
     408:	00001097          	auipc	ra,0x1
     40c:	ac6080e7          	jalr	-1338(ra) # ece <mkdir>
      close(open("grindir/../b/b", O_CREATE|O_RDWR));
     410:	20200593          	li	a1,514
     414:	00001517          	auipc	a0,0x1
     418:	06450513          	addi	a0,a0,100 # 1478 <malloc+0x1a4>
     41c:	00001097          	auipc	ra,0x1
     420:	a8a080e7          	jalr	-1398(ra) # ea6 <open>
     424:	00001097          	auipc	ra,0x1
     428:	a6a080e7          	jalr	-1430(ra) # e8e <close>
      unlink("b/b");
     42c:	00001517          	auipc	a0,0x1
     430:	05c50513          	addi	a0,a0,92 # 1488 <malloc+0x1b4>
     434:	00001097          	auipc	ra,0x1
     438:	a82080e7          	jalr	-1406(ra) # eb6 <unlink>
     43c:	b1dd                	j	122 <go+0xaa>
      unlink("b");
     43e:	00001517          	auipc	a0,0x1
     442:	01250513          	addi	a0,a0,18 # 1450 <malloc+0x17c>
     446:	00001097          	auipc	ra,0x1
     44a:	a70080e7          	jalr	-1424(ra) # eb6 <unlink>
      link("../grindir/./../a", "../b");
     44e:	00001597          	auipc	a1,0x1
     452:	fda58593          	addi	a1,a1,-38 # 1428 <malloc+0x154>
     456:	00001517          	auipc	a0,0x1
     45a:	03a50513          	addi	a0,a0,58 # 1490 <malloc+0x1bc>
     45e:	00001097          	auipc	ra,0x1
     462:	a68080e7          	jalr	-1432(ra) # ec6 <link>
     466:	b975                	j	122 <go+0xaa>
      unlink("../grindir/../a");
     468:	00001517          	auipc	a0,0x1
     46c:	04050513          	addi	a0,a0,64 # 14a8 <malloc+0x1d4>
     470:	00001097          	auipc	ra,0x1
     474:	a46080e7          	jalr	-1466(ra) # eb6 <unlink>
      link(".././b", "/grindir/../a");
     478:	00001597          	auipc	a1,0x1
     47c:	fb858593          	addi	a1,a1,-72 # 1430 <malloc+0x15c>
     480:	00001517          	auipc	a0,0x1
     484:	03850513          	addi	a0,a0,56 # 14b8 <malloc+0x1e4>
     488:	00001097          	auipc	ra,0x1
     48c:	a3e080e7          	jalr	-1474(ra) # ec6 <link>
     490:	b949                	j	122 <go+0xaa>
      int pid = fork();
     492:	00001097          	auipc	ra,0x1
     496:	9cc080e7          	jalr	-1588(ra) # e5e <fork>
      if(pid == 0){
     49a:	c909                	beqz	a0,4ac <go+0x434>
      } else if(pid < 0){
     49c:	00054c63          	bltz	a0,4b4 <go+0x43c>
      wait(0);
     4a0:	4501                	li	a0,0
     4a2:	00001097          	auipc	ra,0x1
     4a6:	9cc080e7          	jalr	-1588(ra) # e6e <wait>
     4aa:	b9a5                	j	122 <go+0xaa>
        exit(0);
     4ac:	00001097          	auipc	ra,0x1
     4b0:	9ba080e7          	jalr	-1606(ra) # e66 <exit>
        printf("grind: fork failed\n");
     4b4:	00001517          	auipc	a0,0x1
     4b8:	00c50513          	addi	a0,a0,12 # 14c0 <malloc+0x1ec>
     4bc:	00001097          	auipc	ra,0x1
     4c0:	d5a080e7          	jalr	-678(ra) # 1216 <printf>
        exit(1);
     4c4:	4505                	li	a0,1
     4c6:	00001097          	auipc	ra,0x1
     4ca:	9a0080e7          	jalr	-1632(ra) # e66 <exit>
      int pid = fork();
     4ce:	00001097          	auipc	ra,0x1
     4d2:	990080e7          	jalr	-1648(ra) # e5e <fork>
      if(pid == 0){
     4d6:	c909                	beqz	a0,4e8 <go+0x470>
      } else if(pid < 0){
     4d8:	02054563          	bltz	a0,502 <go+0x48a>
      wait(0);
     4dc:	4501                	li	a0,0
     4de:	00001097          	auipc	ra,0x1
     4e2:	990080e7          	jalr	-1648(ra) # e6e <wait>
     4e6:	b935                	j	122 <go+0xaa>
        fork();
     4e8:	00001097          	auipc	ra,0x1
     4ec:	976080e7          	jalr	-1674(ra) # e5e <fork>
        fork();
     4f0:	00001097          	auipc	ra,0x1
     4f4:	96e080e7          	jalr	-1682(ra) # e5e <fork>
        exit(0);
     4f8:	4501                	li	a0,0
     4fa:	00001097          	auipc	ra,0x1
     4fe:	96c080e7          	jalr	-1684(ra) # e66 <exit>
        printf("grind: fork failed\n");
     502:	00001517          	auipc	a0,0x1
     506:	fbe50513          	addi	a0,a0,-66 # 14c0 <malloc+0x1ec>
     50a:	00001097          	auipc	ra,0x1
     50e:	d0c080e7          	jalr	-756(ra) # 1216 <printf>
        exit(1);
     512:	4505                	li	a0,1
     514:	00001097          	auipc	ra,0x1
     518:	952080e7          	jalr	-1710(ra) # e66 <exit>
      sbrk(6011);
     51c:	6505                	lui	a0,0x1
     51e:	77b50513          	addi	a0,a0,1915 # 177b <buf.0+0xa3>
     522:	00001097          	auipc	ra,0x1
     526:	9cc080e7          	jalr	-1588(ra) # eee <sbrk>
     52a:	bee5                	j	122 <go+0xaa>
      if(sbrk(0) > break0)
     52c:	4501                	li	a0,0
     52e:	00001097          	auipc	ra,0x1
     532:	9c0080e7          	jalr	-1600(ra) # eee <sbrk>
     536:	beaaf6e3          	bgeu	s5,a0,122 <go+0xaa>
        sbrk(-(sbrk(0) - break0));
     53a:	4501                	li	a0,0
     53c:	00001097          	auipc	ra,0x1
     540:	9b2080e7          	jalr	-1614(ra) # eee <sbrk>
     544:	40aa853b          	subw	a0,s5,a0
     548:	00001097          	auipc	ra,0x1
     54c:	9a6080e7          	jalr	-1626(ra) # eee <sbrk>
     550:	bec9                	j	122 <go+0xaa>
      int pid = fork();
     552:	00001097          	auipc	ra,0x1
     556:	90c080e7          	jalr	-1780(ra) # e5e <fork>
     55a:	8b2a                	mv	s6,a0
      if(pid == 0){
     55c:	c905                	beqz	a0,58c <go+0x514>
      } else if(pid < 0){
     55e:	04054a63          	bltz	a0,5b2 <go+0x53a>
      if(chdir("../grindir/..") != 0){
     562:	00001517          	auipc	a0,0x1
     566:	f7650513          	addi	a0,a0,-138 # 14d8 <malloc+0x204>
     56a:	00001097          	auipc	ra,0x1
     56e:	96c080e7          	jalr	-1684(ra) # ed6 <chdir>
     572:	ed29                	bnez	a0,5cc <go+0x554>
      kill(pid, SIGKILL); // ADDED Q2.2.2
     574:	45a5                	li	a1,9
     576:	855a                	mv	a0,s6
     578:	00001097          	auipc	ra,0x1
     57c:	91e080e7          	jalr	-1762(ra) # e96 <kill>
      wait(0);
     580:	4501                	li	a0,0
     582:	00001097          	auipc	ra,0x1
     586:	8ec080e7          	jalr	-1812(ra) # e6e <wait>
     58a:	be61                	j	122 <go+0xaa>
        close(open("a", O_CREATE|O_RDWR));
     58c:	20200593          	li	a1,514
     590:	00001517          	auipc	a0,0x1
     594:	f1050513          	addi	a0,a0,-240 # 14a0 <malloc+0x1cc>
     598:	00001097          	auipc	ra,0x1
     59c:	90e080e7          	jalr	-1778(ra) # ea6 <open>
     5a0:	00001097          	auipc	ra,0x1
     5a4:	8ee080e7          	jalr	-1810(ra) # e8e <close>
        exit(0);
     5a8:	4501                	li	a0,0
     5aa:	00001097          	auipc	ra,0x1
     5ae:	8bc080e7          	jalr	-1860(ra) # e66 <exit>
        printf("grind: fork failed\n");
     5b2:	00001517          	auipc	a0,0x1
     5b6:	f0e50513          	addi	a0,a0,-242 # 14c0 <malloc+0x1ec>
     5ba:	00001097          	auipc	ra,0x1
     5be:	c5c080e7          	jalr	-932(ra) # 1216 <printf>
        exit(1);
     5c2:	4505                	li	a0,1
     5c4:	00001097          	auipc	ra,0x1
     5c8:	8a2080e7          	jalr	-1886(ra) # e66 <exit>
        printf("grind: chdir failed\n");
     5cc:	00001517          	auipc	a0,0x1
     5d0:	f1c50513          	addi	a0,a0,-228 # 14e8 <malloc+0x214>
     5d4:	00001097          	auipc	ra,0x1
     5d8:	c42080e7          	jalr	-958(ra) # 1216 <printf>
        exit(1);
     5dc:	4505                	li	a0,1
     5de:	00001097          	auipc	ra,0x1
     5e2:	888080e7          	jalr	-1912(ra) # e66 <exit>
      int pid = fork();
     5e6:	00001097          	auipc	ra,0x1
     5ea:	878080e7          	jalr	-1928(ra) # e5e <fork>
      if(pid == 0){
     5ee:	c909                	beqz	a0,600 <go+0x588>
      } else if(pid < 0){
     5f0:	02054663          	bltz	a0,61c <go+0x5a4>
      wait(0);
     5f4:	4501                	li	a0,0
     5f6:	00001097          	auipc	ra,0x1
     5fa:	878080e7          	jalr	-1928(ra) # e6e <wait>
     5fe:	b615                	j	122 <go+0xaa>
        kill(getpid(), SIGKILL); // ADDED Q2.2.2
     600:	00001097          	auipc	ra,0x1
     604:	8e6080e7          	jalr	-1818(ra) # ee6 <getpid>
     608:	45a5                	li	a1,9
     60a:	00001097          	auipc	ra,0x1
     60e:	88c080e7          	jalr	-1908(ra) # e96 <kill>
        exit(0);
     612:	4501                	li	a0,0
     614:	00001097          	auipc	ra,0x1
     618:	852080e7          	jalr	-1966(ra) # e66 <exit>
        printf("grind: fork failed\n");
     61c:	00001517          	auipc	a0,0x1
     620:	ea450513          	addi	a0,a0,-348 # 14c0 <malloc+0x1ec>
     624:	00001097          	auipc	ra,0x1
     628:	bf2080e7          	jalr	-1038(ra) # 1216 <printf>
        exit(1);
     62c:	4505                	li	a0,1
     62e:	00001097          	auipc	ra,0x1
     632:	838080e7          	jalr	-1992(ra) # e66 <exit>
      if(pipe(fds) < 0){
     636:	fa840513          	addi	a0,s0,-88
     63a:	00001097          	auipc	ra,0x1
     63e:	83c080e7          	jalr	-1988(ra) # e76 <pipe>
     642:	02054b63          	bltz	a0,678 <go+0x600>
      int pid = fork();
     646:	00001097          	auipc	ra,0x1
     64a:	818080e7          	jalr	-2024(ra) # e5e <fork>
      if(pid == 0){
     64e:	c131                	beqz	a0,692 <go+0x61a>
      } else if(pid < 0){
     650:	0a054a63          	bltz	a0,704 <go+0x68c>
      close(fds[0]);
     654:	fa842503          	lw	a0,-88(s0)
     658:	00001097          	auipc	ra,0x1
     65c:	836080e7          	jalr	-1994(ra) # e8e <close>
      close(fds[1]);
     660:	fac42503          	lw	a0,-84(s0)
     664:	00001097          	auipc	ra,0x1
     668:	82a080e7          	jalr	-2006(ra) # e8e <close>
      wait(0);
     66c:	4501                	li	a0,0
     66e:	00001097          	auipc	ra,0x1
     672:	800080e7          	jalr	-2048(ra) # e6e <wait>
     676:	b475                	j	122 <go+0xaa>
        printf("grind: pipe failed\n");
     678:	00001517          	auipc	a0,0x1
     67c:	e8850513          	addi	a0,a0,-376 # 1500 <malloc+0x22c>
     680:	00001097          	auipc	ra,0x1
     684:	b96080e7          	jalr	-1130(ra) # 1216 <printf>
        exit(1);
     688:	4505                	li	a0,1
     68a:	00000097          	auipc	ra,0x0
     68e:	7dc080e7          	jalr	2012(ra) # e66 <exit>
        fork();
     692:	00000097          	auipc	ra,0x0
     696:	7cc080e7          	jalr	1996(ra) # e5e <fork>
        fork();
     69a:	00000097          	auipc	ra,0x0
     69e:	7c4080e7          	jalr	1988(ra) # e5e <fork>
        if(write(fds[1], "x", 1) != 1)
     6a2:	4605                	li	a2,1
     6a4:	00001597          	auipc	a1,0x1
     6a8:	e7458593          	addi	a1,a1,-396 # 1518 <malloc+0x244>
     6ac:	fac42503          	lw	a0,-84(s0)
     6b0:	00000097          	auipc	ra,0x0
     6b4:	7d6080e7          	jalr	2006(ra) # e86 <write>
     6b8:	4785                	li	a5,1
     6ba:	02f51363          	bne	a0,a5,6e0 <go+0x668>
        if(read(fds[0], &c, 1) != 1)
     6be:	4605                	li	a2,1
     6c0:	fa040593          	addi	a1,s0,-96
     6c4:	fa842503          	lw	a0,-88(s0)
     6c8:	00000097          	auipc	ra,0x0
     6cc:	7b6080e7          	jalr	1974(ra) # e7e <read>
     6d0:	4785                	li	a5,1
     6d2:	02f51063          	bne	a0,a5,6f2 <go+0x67a>
        exit(0);
     6d6:	4501                	li	a0,0
     6d8:	00000097          	auipc	ra,0x0
     6dc:	78e080e7          	jalr	1934(ra) # e66 <exit>
          printf("grind: pipe write failed\n");
     6e0:	00001517          	auipc	a0,0x1
     6e4:	e4050513          	addi	a0,a0,-448 # 1520 <malloc+0x24c>
     6e8:	00001097          	auipc	ra,0x1
     6ec:	b2e080e7          	jalr	-1234(ra) # 1216 <printf>
     6f0:	b7f9                	j	6be <go+0x646>
          printf("grind: pipe read failed\n");
     6f2:	00001517          	auipc	a0,0x1
     6f6:	e4e50513          	addi	a0,a0,-434 # 1540 <malloc+0x26c>
     6fa:	00001097          	auipc	ra,0x1
     6fe:	b1c080e7          	jalr	-1252(ra) # 1216 <printf>
     702:	bfd1                	j	6d6 <go+0x65e>
        printf("grind: fork failed\n");
     704:	00001517          	auipc	a0,0x1
     708:	dbc50513          	addi	a0,a0,-580 # 14c0 <malloc+0x1ec>
     70c:	00001097          	auipc	ra,0x1
     710:	b0a080e7          	jalr	-1270(ra) # 1216 <printf>
        exit(1);
     714:	4505                	li	a0,1
     716:	00000097          	auipc	ra,0x0
     71a:	750080e7          	jalr	1872(ra) # e66 <exit>
      int pid = fork();
     71e:	00000097          	auipc	ra,0x0
     722:	740080e7          	jalr	1856(ra) # e5e <fork>
      if(pid == 0){
     726:	c909                	beqz	a0,738 <go+0x6c0>
      } else if(pid < 0){
     728:	06054f63          	bltz	a0,7a6 <go+0x72e>
      wait(0);
     72c:	4501                	li	a0,0
     72e:	00000097          	auipc	ra,0x0
     732:	740080e7          	jalr	1856(ra) # e6e <wait>
     736:	b2f5                	j	122 <go+0xaa>
        unlink("a");
     738:	00001517          	auipc	a0,0x1
     73c:	d6850513          	addi	a0,a0,-664 # 14a0 <malloc+0x1cc>
     740:	00000097          	auipc	ra,0x0
     744:	776080e7          	jalr	1910(ra) # eb6 <unlink>
        mkdir("a");
     748:	00001517          	auipc	a0,0x1
     74c:	d5850513          	addi	a0,a0,-680 # 14a0 <malloc+0x1cc>
     750:	00000097          	auipc	ra,0x0
     754:	77e080e7          	jalr	1918(ra) # ece <mkdir>
        chdir("a");
     758:	00001517          	auipc	a0,0x1
     75c:	d4850513          	addi	a0,a0,-696 # 14a0 <malloc+0x1cc>
     760:	00000097          	auipc	ra,0x0
     764:	776080e7          	jalr	1910(ra) # ed6 <chdir>
        unlink("../a");
     768:	00001517          	auipc	a0,0x1
     76c:	ca050513          	addi	a0,a0,-864 # 1408 <malloc+0x134>
     770:	00000097          	auipc	ra,0x0
     774:	746080e7          	jalr	1862(ra) # eb6 <unlink>
        fd = open("x", O_CREATE|O_RDWR);
     778:	20200593          	li	a1,514
     77c:	00001517          	auipc	a0,0x1
     780:	d9c50513          	addi	a0,a0,-612 # 1518 <malloc+0x244>
     784:	00000097          	auipc	ra,0x0
     788:	722080e7          	jalr	1826(ra) # ea6 <open>
        unlink("x");
     78c:	00001517          	auipc	a0,0x1
     790:	d8c50513          	addi	a0,a0,-628 # 1518 <malloc+0x244>
     794:	00000097          	auipc	ra,0x0
     798:	722080e7          	jalr	1826(ra) # eb6 <unlink>
        exit(0);
     79c:	4501                	li	a0,0
     79e:	00000097          	auipc	ra,0x0
     7a2:	6c8080e7          	jalr	1736(ra) # e66 <exit>
        printf("grind: fork failed\n");
     7a6:	00001517          	auipc	a0,0x1
     7aa:	d1a50513          	addi	a0,a0,-742 # 14c0 <malloc+0x1ec>
     7ae:	00001097          	auipc	ra,0x1
     7b2:	a68080e7          	jalr	-1432(ra) # 1216 <printf>
        exit(1);
     7b6:	4505                	li	a0,1
     7b8:	00000097          	auipc	ra,0x0
     7bc:	6ae080e7          	jalr	1710(ra) # e66 <exit>
      unlink("c");
     7c0:	00001517          	auipc	a0,0x1
     7c4:	da050513          	addi	a0,a0,-608 # 1560 <malloc+0x28c>
     7c8:	00000097          	auipc	ra,0x0
     7cc:	6ee080e7          	jalr	1774(ra) # eb6 <unlink>
      int fd1 = open("c", O_CREATE|O_RDWR);
     7d0:	20200593          	li	a1,514
     7d4:	00001517          	auipc	a0,0x1
     7d8:	d8c50513          	addi	a0,a0,-628 # 1560 <malloc+0x28c>
     7dc:	00000097          	auipc	ra,0x0
     7e0:	6ca080e7          	jalr	1738(ra) # ea6 <open>
     7e4:	8b2a                	mv	s6,a0
      if(fd1 < 0){
     7e6:	04054f63          	bltz	a0,844 <go+0x7cc>
      if(write(fd1, "x", 1) != 1){
     7ea:	4605                	li	a2,1
     7ec:	00001597          	auipc	a1,0x1
     7f0:	d2c58593          	addi	a1,a1,-724 # 1518 <malloc+0x244>
     7f4:	00000097          	auipc	ra,0x0
     7f8:	692080e7          	jalr	1682(ra) # e86 <write>
     7fc:	4785                	li	a5,1
     7fe:	06f51063          	bne	a0,a5,85e <go+0x7e6>
      if(fstat(fd1, &st) != 0){
     802:	fa840593          	addi	a1,s0,-88
     806:	855a                	mv	a0,s6
     808:	00000097          	auipc	ra,0x0
     80c:	6b6080e7          	jalr	1718(ra) # ebe <fstat>
     810:	e525                	bnez	a0,878 <go+0x800>
      if(st.size != 1){
     812:	fb843583          	ld	a1,-72(s0)
     816:	4785                	li	a5,1
     818:	06f59d63          	bne	a1,a5,892 <go+0x81a>
      if(st.ino > 200){
     81c:	fac42583          	lw	a1,-84(s0)
     820:	0c800793          	li	a5,200
     824:	08b7e563          	bltu	a5,a1,8ae <go+0x836>
      close(fd1);
     828:	855a                	mv	a0,s6
     82a:	00000097          	auipc	ra,0x0
     82e:	664080e7          	jalr	1636(ra) # e8e <close>
      unlink("c");
     832:	00001517          	auipc	a0,0x1
     836:	d2e50513          	addi	a0,a0,-722 # 1560 <malloc+0x28c>
     83a:	00000097          	auipc	ra,0x0
     83e:	67c080e7          	jalr	1660(ra) # eb6 <unlink>
     842:	b0c5                	j	122 <go+0xaa>
        printf("grind: create c failed\n");
     844:	00001517          	auipc	a0,0x1
     848:	d2450513          	addi	a0,a0,-732 # 1568 <malloc+0x294>
     84c:	00001097          	auipc	ra,0x1
     850:	9ca080e7          	jalr	-1590(ra) # 1216 <printf>
        exit(1);
     854:	4505                	li	a0,1
     856:	00000097          	auipc	ra,0x0
     85a:	610080e7          	jalr	1552(ra) # e66 <exit>
        printf("grind: write c failed\n");
     85e:	00001517          	auipc	a0,0x1
     862:	d2250513          	addi	a0,a0,-734 # 1580 <malloc+0x2ac>
     866:	00001097          	auipc	ra,0x1
     86a:	9b0080e7          	jalr	-1616(ra) # 1216 <printf>
        exit(1);
     86e:	4505                	li	a0,1
     870:	00000097          	auipc	ra,0x0
     874:	5f6080e7          	jalr	1526(ra) # e66 <exit>
        printf("grind: fstat failed\n");
     878:	00001517          	auipc	a0,0x1
     87c:	d2050513          	addi	a0,a0,-736 # 1598 <malloc+0x2c4>
     880:	00001097          	auipc	ra,0x1
     884:	996080e7          	jalr	-1642(ra) # 1216 <printf>
        exit(1);
     888:	4505                	li	a0,1
     88a:	00000097          	auipc	ra,0x0
     88e:	5dc080e7          	jalr	1500(ra) # e66 <exit>
        printf("grind: fstat reports wrong size %d\n", (int)st.size);
     892:	2581                	sext.w	a1,a1
     894:	00001517          	auipc	a0,0x1
     898:	d1c50513          	addi	a0,a0,-740 # 15b0 <malloc+0x2dc>
     89c:	00001097          	auipc	ra,0x1
     8a0:	97a080e7          	jalr	-1670(ra) # 1216 <printf>
        exit(1);
     8a4:	4505                	li	a0,1
     8a6:	00000097          	auipc	ra,0x0
     8aa:	5c0080e7          	jalr	1472(ra) # e66 <exit>
        printf("grind: fstat reports crazy i-number %d\n", st.ino);
     8ae:	00001517          	auipc	a0,0x1
     8b2:	d2a50513          	addi	a0,a0,-726 # 15d8 <malloc+0x304>
     8b6:	00001097          	auipc	ra,0x1
     8ba:	960080e7          	jalr	-1696(ra) # 1216 <printf>
        exit(1);
     8be:	4505                	li	a0,1
     8c0:	00000097          	auipc	ra,0x0
     8c4:	5a6080e7          	jalr	1446(ra) # e66 <exit>
        fprintf(2, "grind: pipe failed\n");
     8c8:	00001597          	auipc	a1,0x1
     8cc:	c3858593          	addi	a1,a1,-968 # 1500 <malloc+0x22c>
     8d0:	4509                	li	a0,2
     8d2:	00001097          	auipc	ra,0x1
     8d6:	916080e7          	jalr	-1770(ra) # 11e8 <fprintf>
        exit(1);
     8da:	4505                	li	a0,1
     8dc:	00000097          	auipc	ra,0x0
     8e0:	58a080e7          	jalr	1418(ra) # e66 <exit>
        fprintf(2, "grind: pipe failed\n");
     8e4:	00001597          	auipc	a1,0x1
     8e8:	c1c58593          	addi	a1,a1,-996 # 1500 <malloc+0x22c>
     8ec:	4509                	li	a0,2
     8ee:	00001097          	auipc	ra,0x1
     8f2:	8fa080e7          	jalr	-1798(ra) # 11e8 <fprintf>
        exit(1);
     8f6:	4505                	li	a0,1
     8f8:	00000097          	auipc	ra,0x0
     8fc:	56e080e7          	jalr	1390(ra) # e66 <exit>
        close(bb[0]);
     900:	fa042503          	lw	a0,-96(s0)
     904:	00000097          	auipc	ra,0x0
     908:	58a080e7          	jalr	1418(ra) # e8e <close>
        close(bb[1]);
     90c:	fa442503          	lw	a0,-92(s0)
     910:	00000097          	auipc	ra,0x0
     914:	57e080e7          	jalr	1406(ra) # e8e <close>
        close(aa[0]);
     918:	f9842503          	lw	a0,-104(s0)
     91c:	00000097          	auipc	ra,0x0
     920:	572080e7          	jalr	1394(ra) # e8e <close>
        close(1);
     924:	4505                	li	a0,1
     926:	00000097          	auipc	ra,0x0
     92a:	568080e7          	jalr	1384(ra) # e8e <close>
        if(dup(aa[1]) != 1){
     92e:	f9c42503          	lw	a0,-100(s0)
     932:	00000097          	auipc	ra,0x0
     936:	5ac080e7          	jalr	1452(ra) # ede <dup>
     93a:	4785                	li	a5,1
     93c:	02f50063          	beq	a0,a5,95c <go+0x8e4>
          fprintf(2, "grind: dup failed\n");
     940:	00001597          	auipc	a1,0x1
     944:	cc058593          	addi	a1,a1,-832 # 1600 <malloc+0x32c>
     948:	4509                	li	a0,2
     94a:	00001097          	auipc	ra,0x1
     94e:	89e080e7          	jalr	-1890(ra) # 11e8 <fprintf>
          exit(1);
     952:	4505                	li	a0,1
     954:	00000097          	auipc	ra,0x0
     958:	512080e7          	jalr	1298(ra) # e66 <exit>
        close(aa[1]);
     95c:	f9c42503          	lw	a0,-100(s0)
     960:	00000097          	auipc	ra,0x0
     964:	52e080e7          	jalr	1326(ra) # e8e <close>
        char *args[3] = { "echo", "hi", 0 };
     968:	00001797          	auipc	a5,0x1
     96c:	cb078793          	addi	a5,a5,-848 # 1618 <malloc+0x344>
     970:	faf43423          	sd	a5,-88(s0)
     974:	00001797          	auipc	a5,0x1
     978:	cac78793          	addi	a5,a5,-852 # 1620 <malloc+0x34c>
     97c:	faf43823          	sd	a5,-80(s0)
     980:	fa043c23          	sd	zero,-72(s0)
        exec("grindir/../echo", args);
     984:	fa840593          	addi	a1,s0,-88
     988:	00001517          	auipc	a0,0x1
     98c:	ca050513          	addi	a0,a0,-864 # 1628 <malloc+0x354>
     990:	00000097          	auipc	ra,0x0
     994:	50e080e7          	jalr	1294(ra) # e9e <exec>
        fprintf(2, "grind: echo: not found\n");
     998:	00001597          	auipc	a1,0x1
     99c:	ca058593          	addi	a1,a1,-864 # 1638 <malloc+0x364>
     9a0:	4509                	li	a0,2
     9a2:	00001097          	auipc	ra,0x1
     9a6:	846080e7          	jalr	-1978(ra) # 11e8 <fprintf>
        exit(2);
     9aa:	4509                	li	a0,2
     9ac:	00000097          	auipc	ra,0x0
     9b0:	4ba080e7          	jalr	1210(ra) # e66 <exit>
        fprintf(2, "grind: fork failed\n");
     9b4:	00001597          	auipc	a1,0x1
     9b8:	b0c58593          	addi	a1,a1,-1268 # 14c0 <malloc+0x1ec>
     9bc:	4509                	li	a0,2
     9be:	00001097          	auipc	ra,0x1
     9c2:	82a080e7          	jalr	-2006(ra) # 11e8 <fprintf>
        exit(3);
     9c6:	450d                	li	a0,3
     9c8:	00000097          	auipc	ra,0x0
     9cc:	49e080e7          	jalr	1182(ra) # e66 <exit>
        close(aa[1]);
     9d0:	f9c42503          	lw	a0,-100(s0)
     9d4:	00000097          	auipc	ra,0x0
     9d8:	4ba080e7          	jalr	1210(ra) # e8e <close>
        close(bb[0]);
     9dc:	fa042503          	lw	a0,-96(s0)
     9e0:	00000097          	auipc	ra,0x0
     9e4:	4ae080e7          	jalr	1198(ra) # e8e <close>
        close(0);
     9e8:	4501                	li	a0,0
     9ea:	00000097          	auipc	ra,0x0
     9ee:	4a4080e7          	jalr	1188(ra) # e8e <close>
        if(dup(aa[0]) != 0){
     9f2:	f9842503          	lw	a0,-104(s0)
     9f6:	00000097          	auipc	ra,0x0
     9fa:	4e8080e7          	jalr	1256(ra) # ede <dup>
     9fe:	cd19                	beqz	a0,a1c <go+0x9a4>
          fprintf(2, "grind: dup failed\n");
     a00:	00001597          	auipc	a1,0x1
     a04:	c0058593          	addi	a1,a1,-1024 # 1600 <malloc+0x32c>
     a08:	4509                	li	a0,2
     a0a:	00000097          	auipc	ra,0x0
     a0e:	7de080e7          	jalr	2014(ra) # 11e8 <fprintf>
          exit(4);
     a12:	4511                	li	a0,4
     a14:	00000097          	auipc	ra,0x0
     a18:	452080e7          	jalr	1106(ra) # e66 <exit>
        close(aa[0]);
     a1c:	f9842503          	lw	a0,-104(s0)
     a20:	00000097          	auipc	ra,0x0
     a24:	46e080e7          	jalr	1134(ra) # e8e <close>
        close(1);
     a28:	4505                	li	a0,1
     a2a:	00000097          	auipc	ra,0x0
     a2e:	464080e7          	jalr	1124(ra) # e8e <close>
        if(dup(bb[1]) != 1){
     a32:	fa442503          	lw	a0,-92(s0)
     a36:	00000097          	auipc	ra,0x0
     a3a:	4a8080e7          	jalr	1192(ra) # ede <dup>
     a3e:	4785                	li	a5,1
     a40:	02f50063          	beq	a0,a5,a60 <go+0x9e8>
          fprintf(2, "grind: dup failed\n");
     a44:	00001597          	auipc	a1,0x1
     a48:	bbc58593          	addi	a1,a1,-1092 # 1600 <malloc+0x32c>
     a4c:	4509                	li	a0,2
     a4e:	00000097          	auipc	ra,0x0
     a52:	79a080e7          	jalr	1946(ra) # 11e8 <fprintf>
          exit(5);
     a56:	4515                	li	a0,5
     a58:	00000097          	auipc	ra,0x0
     a5c:	40e080e7          	jalr	1038(ra) # e66 <exit>
        close(bb[1]);
     a60:	fa442503          	lw	a0,-92(s0)
     a64:	00000097          	auipc	ra,0x0
     a68:	42a080e7          	jalr	1066(ra) # e8e <close>
        char *args[2] = { "cat", 0 };
     a6c:	00001797          	auipc	a5,0x1
     a70:	be478793          	addi	a5,a5,-1052 # 1650 <malloc+0x37c>
     a74:	faf43423          	sd	a5,-88(s0)
     a78:	fa043823          	sd	zero,-80(s0)
        exec("/cat", args);
     a7c:	fa840593          	addi	a1,s0,-88
     a80:	00001517          	auipc	a0,0x1
     a84:	bd850513          	addi	a0,a0,-1064 # 1658 <malloc+0x384>
     a88:	00000097          	auipc	ra,0x0
     a8c:	416080e7          	jalr	1046(ra) # e9e <exec>
        fprintf(2, "grind: cat: not found\n");
     a90:	00001597          	auipc	a1,0x1
     a94:	bd058593          	addi	a1,a1,-1072 # 1660 <malloc+0x38c>
     a98:	4509                	li	a0,2
     a9a:	00000097          	auipc	ra,0x0
     a9e:	74e080e7          	jalr	1870(ra) # 11e8 <fprintf>
        exit(6);
     aa2:	4519                	li	a0,6
     aa4:	00000097          	auipc	ra,0x0
     aa8:	3c2080e7          	jalr	962(ra) # e66 <exit>
        fprintf(2, "grind: fork failed\n");
     aac:	00001597          	auipc	a1,0x1
     ab0:	a1458593          	addi	a1,a1,-1516 # 14c0 <malloc+0x1ec>
     ab4:	4509                	li	a0,2
     ab6:	00000097          	auipc	ra,0x0
     aba:	732080e7          	jalr	1842(ra) # 11e8 <fprintf>
        exit(7);
     abe:	451d                	li	a0,7
     ac0:	00000097          	auipc	ra,0x0
     ac4:	3a6080e7          	jalr	934(ra) # e66 <exit>

0000000000000ac8 <iter>:
  }
}

void
iter()
{
     ac8:	7179                	addi	sp,sp,-48
     aca:	f406                	sd	ra,40(sp)
     acc:	f022                	sd	s0,32(sp)
     ace:	ec26                	sd	s1,24(sp)
     ad0:	e84a                	sd	s2,16(sp)
     ad2:	1800                	addi	s0,sp,48
  unlink("a");
     ad4:	00001517          	auipc	a0,0x1
     ad8:	9cc50513          	addi	a0,a0,-1588 # 14a0 <malloc+0x1cc>
     adc:	00000097          	auipc	ra,0x0
     ae0:	3da080e7          	jalr	986(ra) # eb6 <unlink>
  unlink("b");
     ae4:	00001517          	auipc	a0,0x1
     ae8:	96c50513          	addi	a0,a0,-1684 # 1450 <malloc+0x17c>
     aec:	00000097          	auipc	ra,0x0
     af0:	3ca080e7          	jalr	970(ra) # eb6 <unlink>
  
  int pid1 = fork();
     af4:	00000097          	auipc	ra,0x0
     af8:	36a080e7          	jalr	874(ra) # e5e <fork>
  if(pid1 < 0){
     afc:	00054e63          	bltz	a0,b18 <iter+0x50>
     b00:	84aa                	mv	s1,a0
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid1 == 0){
     b02:	e905                	bnez	a0,b32 <iter+0x6a>
    rand_next = 31;
     b04:	47fd                	li	a5,31
     b06:	00001717          	auipc	a4,0x1
     b0a:	bcf73123          	sd	a5,-1086(a4) # 16c8 <rand_next>
    go(0);
     b0e:	4501                	li	a0,0
     b10:	fffff097          	auipc	ra,0xfffff
     b14:	568080e7          	jalr	1384(ra) # 78 <go>
    printf("grind: fork failed\n");
     b18:	00001517          	auipc	a0,0x1
     b1c:	9a850513          	addi	a0,a0,-1624 # 14c0 <malloc+0x1ec>
     b20:	00000097          	auipc	ra,0x0
     b24:	6f6080e7          	jalr	1782(ra) # 1216 <printf>
    exit(1);
     b28:	4505                	li	a0,1
     b2a:	00000097          	auipc	ra,0x0
     b2e:	33c080e7          	jalr	828(ra) # e66 <exit>
    exit(0);
  }

  int pid2 = fork();
     b32:	00000097          	auipc	ra,0x0
     b36:	32c080e7          	jalr	812(ra) # e5e <fork>
     b3a:	892a                	mv	s2,a0
  if(pid2 < 0){
     b3c:	00054f63          	bltz	a0,b5a <iter+0x92>
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid2 == 0){
     b40:	e915                	bnez	a0,b74 <iter+0xac>
    rand_next = 7177;
     b42:	6789                	lui	a5,0x2
     b44:	c0978793          	addi	a5,a5,-1015 # 1c09 <__BSS_END__+0x139>
     b48:	00001717          	auipc	a4,0x1
     b4c:	b8f73023          	sd	a5,-1152(a4) # 16c8 <rand_next>
    go(1);
     b50:	4505                	li	a0,1
     b52:	fffff097          	auipc	ra,0xfffff
     b56:	526080e7          	jalr	1318(ra) # 78 <go>
    printf("grind: fork failed\n");
     b5a:	00001517          	auipc	a0,0x1
     b5e:	96650513          	addi	a0,a0,-1690 # 14c0 <malloc+0x1ec>
     b62:	00000097          	auipc	ra,0x0
     b66:	6b4080e7          	jalr	1716(ra) # 1216 <printf>
    exit(1);
     b6a:	4505                	li	a0,1
     b6c:	00000097          	auipc	ra,0x0
     b70:	2fa080e7          	jalr	762(ra) # e66 <exit>
    exit(0);
  }

  int st1 = -1;
     b74:	57fd                	li	a5,-1
     b76:	fcf42e23          	sw	a5,-36(s0)
  wait(&st1);
     b7a:	fdc40513          	addi	a0,s0,-36
     b7e:	00000097          	auipc	ra,0x0
     b82:	2f0080e7          	jalr	752(ra) # e6e <wait>
  if(st1 != 0){
     b86:	fdc42783          	lw	a5,-36(s0)
     b8a:	ef99                	bnez	a5,ba8 <iter+0xe0>
    kill(pid1, SIGKILL); // ADDED Q2.2.2
    kill(pid2, SIGKILL);  // ADDED Q2.2.2
  }
  int st2 = -1;
     b8c:	57fd                	li	a5,-1
     b8e:	fcf42c23          	sw	a5,-40(s0)
  wait(&st2);
     b92:	fd840513          	addi	a0,s0,-40
     b96:	00000097          	auipc	ra,0x0
     b9a:	2d8080e7          	jalr	728(ra) # e6e <wait>

  exit(0);
     b9e:	4501                	li	a0,0
     ba0:	00000097          	auipc	ra,0x0
     ba4:	2c6080e7          	jalr	710(ra) # e66 <exit>
    kill(pid1, SIGKILL); // ADDED Q2.2.2
     ba8:	45a5                	li	a1,9
     baa:	8526                	mv	a0,s1
     bac:	00000097          	auipc	ra,0x0
     bb0:	2ea080e7          	jalr	746(ra) # e96 <kill>
    kill(pid2, SIGKILL);  // ADDED Q2.2.2
     bb4:	45a5                	li	a1,9
     bb6:	854a                	mv	a0,s2
     bb8:	00000097          	auipc	ra,0x0
     bbc:	2de080e7          	jalr	734(ra) # e96 <kill>
     bc0:	b7f1                	j	b8c <iter+0xc4>

0000000000000bc2 <main>:
}

int
main()
{
     bc2:	1141                	addi	sp,sp,-16
     bc4:	e406                	sd	ra,8(sp)
     bc6:	e022                	sd	s0,0(sp)
     bc8:	0800                	addi	s0,sp,16
     bca:	a811                	j	bde <main+0x1c>
  while(1){
    int pid = fork();
    if(pid == 0){
      iter();
     bcc:	00000097          	auipc	ra,0x0
     bd0:	efc080e7          	jalr	-260(ra) # ac8 <iter>
      exit(0);
    }
    if(pid > 0){
      wait(0);
    }
    sleep(20);
     bd4:	4551                	li	a0,20
     bd6:	00000097          	auipc	ra,0x0
     bda:	320080e7          	jalr	800(ra) # ef6 <sleep>
    int pid = fork();
     bde:	00000097          	auipc	ra,0x0
     be2:	280080e7          	jalr	640(ra) # e5e <fork>
    if(pid == 0){
     be6:	d17d                	beqz	a0,bcc <main+0xa>
    if(pid > 0){
     be8:	fea056e3          	blez	a0,bd4 <main+0x12>
      wait(0);
     bec:	4501                	li	a0,0
     bee:	00000097          	auipc	ra,0x0
     bf2:	280080e7          	jalr	640(ra) # e6e <wait>
     bf6:	bff9                	j	bd4 <main+0x12>

0000000000000bf8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     bf8:	1141                	addi	sp,sp,-16
     bfa:	e422                	sd	s0,8(sp)
     bfc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     bfe:	87aa                	mv	a5,a0
     c00:	0585                	addi	a1,a1,1
     c02:	0785                	addi	a5,a5,1
     c04:	fff5c703          	lbu	a4,-1(a1)
     c08:	fee78fa3          	sb	a4,-1(a5)
     c0c:	fb75                	bnez	a4,c00 <strcpy+0x8>
    ;
  return os;
}
     c0e:	6422                	ld	s0,8(sp)
     c10:	0141                	addi	sp,sp,16
     c12:	8082                	ret

0000000000000c14 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     c14:	1141                	addi	sp,sp,-16
     c16:	e422                	sd	s0,8(sp)
     c18:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     c1a:	00054783          	lbu	a5,0(a0)
     c1e:	cb91                	beqz	a5,c32 <strcmp+0x1e>
     c20:	0005c703          	lbu	a4,0(a1)
     c24:	00f71763          	bne	a4,a5,c32 <strcmp+0x1e>
    p++, q++;
     c28:	0505                	addi	a0,a0,1
     c2a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c2c:	00054783          	lbu	a5,0(a0)
     c30:	fbe5                	bnez	a5,c20 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c32:	0005c503          	lbu	a0,0(a1)
}
     c36:	40a7853b          	subw	a0,a5,a0
     c3a:	6422                	ld	s0,8(sp)
     c3c:	0141                	addi	sp,sp,16
     c3e:	8082                	ret

0000000000000c40 <strlen>:

uint
strlen(const char *s)
{
     c40:	1141                	addi	sp,sp,-16
     c42:	e422                	sd	s0,8(sp)
     c44:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c46:	00054783          	lbu	a5,0(a0)
     c4a:	cf91                	beqz	a5,c66 <strlen+0x26>
     c4c:	0505                	addi	a0,a0,1
     c4e:	87aa                	mv	a5,a0
     c50:	4685                	li	a3,1
     c52:	9e89                	subw	a3,a3,a0
     c54:	00f6853b          	addw	a0,a3,a5
     c58:	0785                	addi	a5,a5,1
     c5a:	fff7c703          	lbu	a4,-1(a5)
     c5e:	fb7d                	bnez	a4,c54 <strlen+0x14>
    ;
  return n;
}
     c60:	6422                	ld	s0,8(sp)
     c62:	0141                	addi	sp,sp,16
     c64:	8082                	ret
  for(n = 0; s[n]; n++)
     c66:	4501                	li	a0,0
     c68:	bfe5                	j	c60 <strlen+0x20>

0000000000000c6a <memset>:

void*
memset(void *dst, int c, uint n)
{
     c6a:	1141                	addi	sp,sp,-16
     c6c:	e422                	sd	s0,8(sp)
     c6e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c70:	ca19                	beqz	a2,c86 <memset+0x1c>
     c72:	87aa                	mv	a5,a0
     c74:	1602                	slli	a2,a2,0x20
     c76:	9201                	srli	a2,a2,0x20
     c78:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     c7c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     c80:	0785                	addi	a5,a5,1
     c82:	fee79de3          	bne	a5,a4,c7c <memset+0x12>
  }
  return dst;
}
     c86:	6422                	ld	s0,8(sp)
     c88:	0141                	addi	sp,sp,16
     c8a:	8082                	ret

0000000000000c8c <strchr>:

char*
strchr(const char *s, char c)
{
     c8c:	1141                	addi	sp,sp,-16
     c8e:	e422                	sd	s0,8(sp)
     c90:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c92:	00054783          	lbu	a5,0(a0)
     c96:	cb99                	beqz	a5,cac <strchr+0x20>
    if(*s == c)
     c98:	00f58763          	beq	a1,a5,ca6 <strchr+0x1a>
  for(; *s; s++)
     c9c:	0505                	addi	a0,a0,1
     c9e:	00054783          	lbu	a5,0(a0)
     ca2:	fbfd                	bnez	a5,c98 <strchr+0xc>
      return (char*)s;
  return 0;
     ca4:	4501                	li	a0,0
}
     ca6:	6422                	ld	s0,8(sp)
     ca8:	0141                	addi	sp,sp,16
     caa:	8082                	ret
  return 0;
     cac:	4501                	li	a0,0
     cae:	bfe5                	j	ca6 <strchr+0x1a>

0000000000000cb0 <gets>:

char*
gets(char *buf, int max)
{
     cb0:	711d                	addi	sp,sp,-96
     cb2:	ec86                	sd	ra,88(sp)
     cb4:	e8a2                	sd	s0,80(sp)
     cb6:	e4a6                	sd	s1,72(sp)
     cb8:	e0ca                	sd	s2,64(sp)
     cba:	fc4e                	sd	s3,56(sp)
     cbc:	f852                	sd	s4,48(sp)
     cbe:	f456                	sd	s5,40(sp)
     cc0:	f05a                	sd	s6,32(sp)
     cc2:	ec5e                	sd	s7,24(sp)
     cc4:	1080                	addi	s0,sp,96
     cc6:	8baa                	mv	s7,a0
     cc8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     cca:	892a                	mv	s2,a0
     ccc:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     cce:	4aa9                	li	s5,10
     cd0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     cd2:	89a6                	mv	s3,s1
     cd4:	2485                	addiw	s1,s1,1
     cd6:	0344d863          	bge	s1,s4,d06 <gets+0x56>
    cc = read(0, &c, 1);
     cda:	4605                	li	a2,1
     cdc:	faf40593          	addi	a1,s0,-81
     ce0:	4501                	li	a0,0
     ce2:	00000097          	auipc	ra,0x0
     ce6:	19c080e7          	jalr	412(ra) # e7e <read>
    if(cc < 1)
     cea:	00a05e63          	blez	a0,d06 <gets+0x56>
    buf[i++] = c;
     cee:	faf44783          	lbu	a5,-81(s0)
     cf2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     cf6:	01578763          	beq	a5,s5,d04 <gets+0x54>
     cfa:	0905                	addi	s2,s2,1
     cfc:	fd679be3          	bne	a5,s6,cd2 <gets+0x22>
  for(i=0; i+1 < max; ){
     d00:	89a6                	mv	s3,s1
     d02:	a011                	j	d06 <gets+0x56>
     d04:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     d06:	99de                	add	s3,s3,s7
     d08:	00098023          	sb	zero,0(s3)
  return buf;
}
     d0c:	855e                	mv	a0,s7
     d0e:	60e6                	ld	ra,88(sp)
     d10:	6446                	ld	s0,80(sp)
     d12:	64a6                	ld	s1,72(sp)
     d14:	6906                	ld	s2,64(sp)
     d16:	79e2                	ld	s3,56(sp)
     d18:	7a42                	ld	s4,48(sp)
     d1a:	7aa2                	ld	s5,40(sp)
     d1c:	7b02                	ld	s6,32(sp)
     d1e:	6be2                	ld	s7,24(sp)
     d20:	6125                	addi	sp,sp,96
     d22:	8082                	ret

0000000000000d24 <stat>:

int
stat(const char *n, struct stat *st)
{
     d24:	1101                	addi	sp,sp,-32
     d26:	ec06                	sd	ra,24(sp)
     d28:	e822                	sd	s0,16(sp)
     d2a:	e426                	sd	s1,8(sp)
     d2c:	e04a                	sd	s2,0(sp)
     d2e:	1000                	addi	s0,sp,32
     d30:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d32:	4581                	li	a1,0
     d34:	00000097          	auipc	ra,0x0
     d38:	172080e7          	jalr	370(ra) # ea6 <open>
  if(fd < 0)
     d3c:	02054563          	bltz	a0,d66 <stat+0x42>
     d40:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d42:	85ca                	mv	a1,s2
     d44:	00000097          	auipc	ra,0x0
     d48:	17a080e7          	jalr	378(ra) # ebe <fstat>
     d4c:	892a                	mv	s2,a0
  close(fd);
     d4e:	8526                	mv	a0,s1
     d50:	00000097          	auipc	ra,0x0
     d54:	13e080e7          	jalr	318(ra) # e8e <close>
  return r;
}
     d58:	854a                	mv	a0,s2
     d5a:	60e2                	ld	ra,24(sp)
     d5c:	6442                	ld	s0,16(sp)
     d5e:	64a2                	ld	s1,8(sp)
     d60:	6902                	ld	s2,0(sp)
     d62:	6105                	addi	sp,sp,32
     d64:	8082                	ret
    return -1;
     d66:	597d                	li	s2,-1
     d68:	bfc5                	j	d58 <stat+0x34>

0000000000000d6a <atoi>:

int
atoi(const char *s)
{
     d6a:	1141                	addi	sp,sp,-16
     d6c:	e422                	sd	s0,8(sp)
     d6e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d70:	00054603          	lbu	a2,0(a0)
     d74:	fd06079b          	addiw	a5,a2,-48
     d78:	0ff7f793          	andi	a5,a5,255
     d7c:	4725                	li	a4,9
     d7e:	02f76963          	bltu	a4,a5,db0 <atoi+0x46>
     d82:	86aa                	mv	a3,a0
  n = 0;
     d84:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     d86:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     d88:	0685                	addi	a3,a3,1
     d8a:	0025179b          	slliw	a5,a0,0x2
     d8e:	9fa9                	addw	a5,a5,a0
     d90:	0017979b          	slliw	a5,a5,0x1
     d94:	9fb1                	addw	a5,a5,a2
     d96:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d9a:	0006c603          	lbu	a2,0(a3)
     d9e:	fd06071b          	addiw	a4,a2,-48
     da2:	0ff77713          	andi	a4,a4,255
     da6:	fee5f1e3          	bgeu	a1,a4,d88 <atoi+0x1e>
  return n;
}
     daa:	6422                	ld	s0,8(sp)
     dac:	0141                	addi	sp,sp,16
     dae:	8082                	ret
  n = 0;
     db0:	4501                	li	a0,0
     db2:	bfe5                	j	daa <atoi+0x40>

0000000000000db4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     db4:	1141                	addi	sp,sp,-16
     db6:	e422                	sd	s0,8(sp)
     db8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     dba:	02b57463          	bgeu	a0,a1,de2 <memmove+0x2e>
    while(n-- > 0)
     dbe:	00c05f63          	blez	a2,ddc <memmove+0x28>
     dc2:	1602                	slli	a2,a2,0x20
     dc4:	9201                	srli	a2,a2,0x20
     dc6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     dca:	872a                	mv	a4,a0
      *dst++ = *src++;
     dcc:	0585                	addi	a1,a1,1
     dce:	0705                	addi	a4,a4,1
     dd0:	fff5c683          	lbu	a3,-1(a1)
     dd4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     dd8:	fee79ae3          	bne	a5,a4,dcc <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     ddc:	6422                	ld	s0,8(sp)
     dde:	0141                	addi	sp,sp,16
     de0:	8082                	ret
    dst += n;
     de2:	00c50733          	add	a4,a0,a2
    src += n;
     de6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     de8:	fec05ae3          	blez	a2,ddc <memmove+0x28>
     dec:	fff6079b          	addiw	a5,a2,-1
     df0:	1782                	slli	a5,a5,0x20
     df2:	9381                	srli	a5,a5,0x20
     df4:	fff7c793          	not	a5,a5
     df8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     dfa:	15fd                	addi	a1,a1,-1
     dfc:	177d                	addi	a4,a4,-1
     dfe:	0005c683          	lbu	a3,0(a1)
     e02:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     e06:	fee79ae3          	bne	a5,a4,dfa <memmove+0x46>
     e0a:	bfc9                	j	ddc <memmove+0x28>

0000000000000e0c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     e0c:	1141                	addi	sp,sp,-16
     e0e:	e422                	sd	s0,8(sp)
     e10:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     e12:	ca05                	beqz	a2,e42 <memcmp+0x36>
     e14:	fff6069b          	addiw	a3,a2,-1
     e18:	1682                	slli	a3,a3,0x20
     e1a:	9281                	srli	a3,a3,0x20
     e1c:	0685                	addi	a3,a3,1
     e1e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e20:	00054783          	lbu	a5,0(a0)
     e24:	0005c703          	lbu	a4,0(a1)
     e28:	00e79863          	bne	a5,a4,e38 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e2c:	0505                	addi	a0,a0,1
    p2++;
     e2e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e30:	fed518e3          	bne	a0,a3,e20 <memcmp+0x14>
  }
  return 0;
     e34:	4501                	li	a0,0
     e36:	a019                	j	e3c <memcmp+0x30>
      return *p1 - *p2;
     e38:	40e7853b          	subw	a0,a5,a4
}
     e3c:	6422                	ld	s0,8(sp)
     e3e:	0141                	addi	sp,sp,16
     e40:	8082                	ret
  return 0;
     e42:	4501                	li	a0,0
     e44:	bfe5                	j	e3c <memcmp+0x30>

0000000000000e46 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e46:	1141                	addi	sp,sp,-16
     e48:	e406                	sd	ra,8(sp)
     e4a:	e022                	sd	s0,0(sp)
     e4c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e4e:	00000097          	auipc	ra,0x0
     e52:	f66080e7          	jalr	-154(ra) # db4 <memmove>
}
     e56:	60a2                	ld	ra,8(sp)
     e58:	6402                	ld	s0,0(sp)
     e5a:	0141                	addi	sp,sp,16
     e5c:	8082                	ret

0000000000000e5e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e5e:	4885                	li	a7,1
 ecall
     e60:	00000073          	ecall
 ret
     e64:	8082                	ret

0000000000000e66 <exit>:
.global exit
exit:
 li a7, SYS_exit
     e66:	4889                	li	a7,2
 ecall
     e68:	00000073          	ecall
 ret
     e6c:	8082                	ret

0000000000000e6e <wait>:
.global wait
wait:
 li a7, SYS_wait
     e6e:	488d                	li	a7,3
 ecall
     e70:	00000073          	ecall
 ret
     e74:	8082                	ret

0000000000000e76 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     e76:	4891                	li	a7,4
 ecall
     e78:	00000073          	ecall
 ret
     e7c:	8082                	ret

0000000000000e7e <read>:
.global read
read:
 li a7, SYS_read
     e7e:	4895                	li	a7,5
 ecall
     e80:	00000073          	ecall
 ret
     e84:	8082                	ret

0000000000000e86 <write>:
.global write
write:
 li a7, SYS_write
     e86:	48c1                	li	a7,16
 ecall
     e88:	00000073          	ecall
 ret
     e8c:	8082                	ret

0000000000000e8e <close>:
.global close
close:
 li a7, SYS_close
     e8e:	48d5                	li	a7,21
 ecall
     e90:	00000073          	ecall
 ret
     e94:	8082                	ret

0000000000000e96 <kill>:
.global kill
kill:
 li a7, SYS_kill
     e96:	4899                	li	a7,6
 ecall
     e98:	00000073          	ecall
 ret
     e9c:	8082                	ret

0000000000000e9e <exec>:
.global exec
exec:
 li a7, SYS_exec
     e9e:	489d                	li	a7,7
 ecall
     ea0:	00000073          	ecall
 ret
     ea4:	8082                	ret

0000000000000ea6 <open>:
.global open
open:
 li a7, SYS_open
     ea6:	48bd                	li	a7,15
 ecall
     ea8:	00000073          	ecall
 ret
     eac:	8082                	ret

0000000000000eae <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     eae:	48c5                	li	a7,17
 ecall
     eb0:	00000073          	ecall
 ret
     eb4:	8082                	ret

0000000000000eb6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     eb6:	48c9                	li	a7,18
 ecall
     eb8:	00000073          	ecall
 ret
     ebc:	8082                	ret

0000000000000ebe <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     ebe:	48a1                	li	a7,8
 ecall
     ec0:	00000073          	ecall
 ret
     ec4:	8082                	ret

0000000000000ec6 <link>:
.global link
link:
 li a7, SYS_link
     ec6:	48cd                	li	a7,19
 ecall
     ec8:	00000073          	ecall
 ret
     ecc:	8082                	ret

0000000000000ece <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     ece:	48d1                	li	a7,20
 ecall
     ed0:	00000073          	ecall
 ret
     ed4:	8082                	ret

0000000000000ed6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     ed6:	48a5                	li	a7,9
 ecall
     ed8:	00000073          	ecall
 ret
     edc:	8082                	ret

0000000000000ede <dup>:
.global dup
dup:
 li a7, SYS_dup
     ede:	48a9                	li	a7,10
 ecall
     ee0:	00000073          	ecall
 ret
     ee4:	8082                	ret

0000000000000ee6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     ee6:	48ad                	li	a7,11
 ecall
     ee8:	00000073          	ecall
 ret
     eec:	8082                	ret

0000000000000eee <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     eee:	48b1                	li	a7,12
 ecall
     ef0:	00000073          	ecall
 ret
     ef4:	8082                	ret

0000000000000ef6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     ef6:	48b5                	li	a7,13
 ecall
     ef8:	00000073          	ecall
 ret
     efc:	8082                	ret

0000000000000efe <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     efe:	48b9                	li	a7,14
 ecall
     f00:	00000073          	ecall
 ret
     f04:	8082                	ret

0000000000000f06 <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
     f06:	48d9                	li	a7,22
 ecall
     f08:	00000073          	ecall
 ret
     f0c:	8082                	ret

0000000000000f0e <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
     f0e:	48dd                	li	a7,23
 ecall
     f10:	00000073          	ecall
 ret
     f14:	8082                	ret

0000000000000f16 <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
     f16:	48e1                	li	a7,24
 ecall
     f18:	00000073          	ecall
 ret
     f1c:	8082                	ret

0000000000000f1e <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
     f1e:	48e5                	li	a7,25
 ecall
     f20:	00000073          	ecall
 ret
     f24:	8082                	ret

0000000000000f26 <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
     f26:	48e9                	li	a7,26
 ecall
     f28:	00000073          	ecall
 ret
     f2c:	8082                	ret

0000000000000f2e <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
     f2e:	48ed                	li	a7,27
 ecall
     f30:	00000073          	ecall
 ret
     f34:	8082                	ret

0000000000000f36 <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
     f36:	48f1                	li	a7,28
 ecall
     f38:	00000073          	ecall
 ret
     f3c:	8082                	ret

0000000000000f3e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     f3e:	1101                	addi	sp,sp,-32
     f40:	ec06                	sd	ra,24(sp)
     f42:	e822                	sd	s0,16(sp)
     f44:	1000                	addi	s0,sp,32
     f46:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f4a:	4605                	li	a2,1
     f4c:	fef40593          	addi	a1,s0,-17
     f50:	00000097          	auipc	ra,0x0
     f54:	f36080e7          	jalr	-202(ra) # e86 <write>
}
     f58:	60e2                	ld	ra,24(sp)
     f5a:	6442                	ld	s0,16(sp)
     f5c:	6105                	addi	sp,sp,32
     f5e:	8082                	ret

0000000000000f60 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f60:	7139                	addi	sp,sp,-64
     f62:	fc06                	sd	ra,56(sp)
     f64:	f822                	sd	s0,48(sp)
     f66:	f426                	sd	s1,40(sp)
     f68:	f04a                	sd	s2,32(sp)
     f6a:	ec4e                	sd	s3,24(sp)
     f6c:	0080                	addi	s0,sp,64
     f6e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f70:	c299                	beqz	a3,f76 <printint+0x16>
     f72:	0805c863          	bltz	a1,1002 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f76:	2581                	sext.w	a1,a1
  neg = 0;
     f78:	4881                	li	a7,0
     f7a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f7e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f80:	2601                	sext.w	a2,a2
     f82:	00000517          	auipc	a0,0x0
     f86:	72e50513          	addi	a0,a0,1838 # 16b0 <digits>
     f8a:	883a                	mv	a6,a4
     f8c:	2705                	addiw	a4,a4,1
     f8e:	02c5f7bb          	remuw	a5,a1,a2
     f92:	1782                	slli	a5,a5,0x20
     f94:	9381                	srli	a5,a5,0x20
     f96:	97aa                	add	a5,a5,a0
     f98:	0007c783          	lbu	a5,0(a5)
     f9c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     fa0:	0005879b          	sext.w	a5,a1
     fa4:	02c5d5bb          	divuw	a1,a1,a2
     fa8:	0685                	addi	a3,a3,1
     faa:	fec7f0e3          	bgeu	a5,a2,f8a <printint+0x2a>
  if(neg)
     fae:	00088b63          	beqz	a7,fc4 <printint+0x64>
    buf[i++] = '-';
     fb2:	fd040793          	addi	a5,s0,-48
     fb6:	973e                	add	a4,a4,a5
     fb8:	02d00793          	li	a5,45
     fbc:	fef70823          	sb	a5,-16(a4)
     fc0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     fc4:	02e05863          	blez	a4,ff4 <printint+0x94>
     fc8:	fc040793          	addi	a5,s0,-64
     fcc:	00e78933          	add	s2,a5,a4
     fd0:	fff78993          	addi	s3,a5,-1
     fd4:	99ba                	add	s3,s3,a4
     fd6:	377d                	addiw	a4,a4,-1
     fd8:	1702                	slli	a4,a4,0x20
     fda:	9301                	srli	a4,a4,0x20
     fdc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     fe0:	fff94583          	lbu	a1,-1(s2)
     fe4:	8526                	mv	a0,s1
     fe6:	00000097          	auipc	ra,0x0
     fea:	f58080e7          	jalr	-168(ra) # f3e <putc>
  while(--i >= 0)
     fee:	197d                	addi	s2,s2,-1
     ff0:	ff3918e3          	bne	s2,s3,fe0 <printint+0x80>
}
     ff4:	70e2                	ld	ra,56(sp)
     ff6:	7442                	ld	s0,48(sp)
     ff8:	74a2                	ld	s1,40(sp)
     ffa:	7902                	ld	s2,32(sp)
     ffc:	69e2                	ld	s3,24(sp)
     ffe:	6121                	addi	sp,sp,64
    1000:	8082                	ret
    x = -xx;
    1002:	40b005bb          	negw	a1,a1
    neg = 1;
    1006:	4885                	li	a7,1
    x = -xx;
    1008:	bf8d                	j	f7a <printint+0x1a>

000000000000100a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    100a:	7119                	addi	sp,sp,-128
    100c:	fc86                	sd	ra,120(sp)
    100e:	f8a2                	sd	s0,112(sp)
    1010:	f4a6                	sd	s1,104(sp)
    1012:	f0ca                	sd	s2,96(sp)
    1014:	ecce                	sd	s3,88(sp)
    1016:	e8d2                	sd	s4,80(sp)
    1018:	e4d6                	sd	s5,72(sp)
    101a:	e0da                	sd	s6,64(sp)
    101c:	fc5e                	sd	s7,56(sp)
    101e:	f862                	sd	s8,48(sp)
    1020:	f466                	sd	s9,40(sp)
    1022:	f06a                	sd	s10,32(sp)
    1024:	ec6e                	sd	s11,24(sp)
    1026:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    1028:	0005c903          	lbu	s2,0(a1)
    102c:	18090f63          	beqz	s2,11ca <vprintf+0x1c0>
    1030:	8aaa                	mv	s5,a0
    1032:	8b32                	mv	s6,a2
    1034:	00158493          	addi	s1,a1,1
  state = 0;
    1038:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    103a:	02500a13          	li	s4,37
      if(c == 'd'){
    103e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    1042:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    1046:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    104a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    104e:	00000b97          	auipc	s7,0x0
    1052:	662b8b93          	addi	s7,s7,1634 # 16b0 <digits>
    1056:	a839                	j	1074 <vprintf+0x6a>
        putc(fd, c);
    1058:	85ca                	mv	a1,s2
    105a:	8556                	mv	a0,s5
    105c:	00000097          	auipc	ra,0x0
    1060:	ee2080e7          	jalr	-286(ra) # f3e <putc>
    1064:	a019                	j	106a <vprintf+0x60>
    } else if(state == '%'){
    1066:	01498f63          	beq	s3,s4,1084 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    106a:	0485                	addi	s1,s1,1
    106c:	fff4c903          	lbu	s2,-1(s1)
    1070:	14090d63          	beqz	s2,11ca <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1074:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1078:	fe0997e3          	bnez	s3,1066 <vprintf+0x5c>
      if(c == '%'){
    107c:	fd479ee3          	bne	a5,s4,1058 <vprintf+0x4e>
        state = '%';
    1080:	89be                	mv	s3,a5
    1082:	b7e5                	j	106a <vprintf+0x60>
      if(c == 'd'){
    1084:	05878063          	beq	a5,s8,10c4 <vprintf+0xba>
      } else if(c == 'l') {
    1088:	05978c63          	beq	a5,s9,10e0 <vprintf+0xd6>
      } else if(c == 'x') {
    108c:	07a78863          	beq	a5,s10,10fc <vprintf+0xf2>
      } else if(c == 'p') {
    1090:	09b78463          	beq	a5,s11,1118 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1094:	07300713          	li	a4,115
    1098:	0ce78663          	beq	a5,a4,1164 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    109c:	06300713          	li	a4,99
    10a0:	0ee78e63          	beq	a5,a4,119c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    10a4:	11478863          	beq	a5,s4,11b4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    10a8:	85d2                	mv	a1,s4
    10aa:	8556                	mv	a0,s5
    10ac:	00000097          	auipc	ra,0x0
    10b0:	e92080e7          	jalr	-366(ra) # f3e <putc>
        putc(fd, c);
    10b4:	85ca                	mv	a1,s2
    10b6:	8556                	mv	a0,s5
    10b8:	00000097          	auipc	ra,0x0
    10bc:	e86080e7          	jalr	-378(ra) # f3e <putc>
      }
      state = 0;
    10c0:	4981                	li	s3,0
    10c2:	b765                	j	106a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    10c4:	008b0913          	addi	s2,s6,8
    10c8:	4685                	li	a3,1
    10ca:	4629                	li	a2,10
    10cc:	000b2583          	lw	a1,0(s6)
    10d0:	8556                	mv	a0,s5
    10d2:	00000097          	auipc	ra,0x0
    10d6:	e8e080e7          	jalr	-370(ra) # f60 <printint>
    10da:	8b4a                	mv	s6,s2
      state = 0;
    10dc:	4981                	li	s3,0
    10de:	b771                	j	106a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    10e0:	008b0913          	addi	s2,s6,8
    10e4:	4681                	li	a3,0
    10e6:	4629                	li	a2,10
    10e8:	000b2583          	lw	a1,0(s6)
    10ec:	8556                	mv	a0,s5
    10ee:	00000097          	auipc	ra,0x0
    10f2:	e72080e7          	jalr	-398(ra) # f60 <printint>
    10f6:	8b4a                	mv	s6,s2
      state = 0;
    10f8:	4981                	li	s3,0
    10fa:	bf85                	j	106a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    10fc:	008b0913          	addi	s2,s6,8
    1100:	4681                	li	a3,0
    1102:	4641                	li	a2,16
    1104:	000b2583          	lw	a1,0(s6)
    1108:	8556                	mv	a0,s5
    110a:	00000097          	auipc	ra,0x0
    110e:	e56080e7          	jalr	-426(ra) # f60 <printint>
    1112:	8b4a                	mv	s6,s2
      state = 0;
    1114:	4981                	li	s3,0
    1116:	bf91                	j	106a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    1118:	008b0793          	addi	a5,s6,8
    111c:	f8f43423          	sd	a5,-120(s0)
    1120:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    1124:	03000593          	li	a1,48
    1128:	8556                	mv	a0,s5
    112a:	00000097          	auipc	ra,0x0
    112e:	e14080e7          	jalr	-492(ra) # f3e <putc>
  putc(fd, 'x');
    1132:	85ea                	mv	a1,s10
    1134:	8556                	mv	a0,s5
    1136:	00000097          	auipc	ra,0x0
    113a:	e08080e7          	jalr	-504(ra) # f3e <putc>
    113e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1140:	03c9d793          	srli	a5,s3,0x3c
    1144:	97de                	add	a5,a5,s7
    1146:	0007c583          	lbu	a1,0(a5)
    114a:	8556                	mv	a0,s5
    114c:	00000097          	auipc	ra,0x0
    1150:	df2080e7          	jalr	-526(ra) # f3e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1154:	0992                	slli	s3,s3,0x4
    1156:	397d                	addiw	s2,s2,-1
    1158:	fe0914e3          	bnez	s2,1140 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    115c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    1160:	4981                	li	s3,0
    1162:	b721                	j	106a <vprintf+0x60>
        s = va_arg(ap, char*);
    1164:	008b0993          	addi	s3,s6,8
    1168:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    116c:	02090163          	beqz	s2,118e <vprintf+0x184>
        while(*s != 0){
    1170:	00094583          	lbu	a1,0(s2)
    1174:	c9a1                	beqz	a1,11c4 <vprintf+0x1ba>
          putc(fd, *s);
    1176:	8556                	mv	a0,s5
    1178:	00000097          	auipc	ra,0x0
    117c:	dc6080e7          	jalr	-570(ra) # f3e <putc>
          s++;
    1180:	0905                	addi	s2,s2,1
        while(*s != 0){
    1182:	00094583          	lbu	a1,0(s2)
    1186:	f9e5                	bnez	a1,1176 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1188:	8b4e                	mv	s6,s3
      state = 0;
    118a:	4981                	li	s3,0
    118c:	bdf9                	j	106a <vprintf+0x60>
          s = "(null)";
    118e:	00000917          	auipc	s2,0x0
    1192:	51a90913          	addi	s2,s2,1306 # 16a8 <malloc+0x3d4>
        while(*s != 0){
    1196:	02800593          	li	a1,40
    119a:	bff1                	j	1176 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    119c:	008b0913          	addi	s2,s6,8
    11a0:	000b4583          	lbu	a1,0(s6)
    11a4:	8556                	mv	a0,s5
    11a6:	00000097          	auipc	ra,0x0
    11aa:	d98080e7          	jalr	-616(ra) # f3e <putc>
    11ae:	8b4a                	mv	s6,s2
      state = 0;
    11b0:	4981                	li	s3,0
    11b2:	bd65                	j	106a <vprintf+0x60>
        putc(fd, c);
    11b4:	85d2                	mv	a1,s4
    11b6:	8556                	mv	a0,s5
    11b8:	00000097          	auipc	ra,0x0
    11bc:	d86080e7          	jalr	-634(ra) # f3e <putc>
      state = 0;
    11c0:	4981                	li	s3,0
    11c2:	b565                	j	106a <vprintf+0x60>
        s = va_arg(ap, char*);
    11c4:	8b4e                	mv	s6,s3
      state = 0;
    11c6:	4981                	li	s3,0
    11c8:	b54d                	j	106a <vprintf+0x60>
    }
  }
}
    11ca:	70e6                	ld	ra,120(sp)
    11cc:	7446                	ld	s0,112(sp)
    11ce:	74a6                	ld	s1,104(sp)
    11d0:	7906                	ld	s2,96(sp)
    11d2:	69e6                	ld	s3,88(sp)
    11d4:	6a46                	ld	s4,80(sp)
    11d6:	6aa6                	ld	s5,72(sp)
    11d8:	6b06                	ld	s6,64(sp)
    11da:	7be2                	ld	s7,56(sp)
    11dc:	7c42                	ld	s8,48(sp)
    11de:	7ca2                	ld	s9,40(sp)
    11e0:	7d02                	ld	s10,32(sp)
    11e2:	6de2                	ld	s11,24(sp)
    11e4:	6109                	addi	sp,sp,128
    11e6:	8082                	ret

00000000000011e8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11e8:	715d                	addi	sp,sp,-80
    11ea:	ec06                	sd	ra,24(sp)
    11ec:	e822                	sd	s0,16(sp)
    11ee:	1000                	addi	s0,sp,32
    11f0:	e010                	sd	a2,0(s0)
    11f2:	e414                	sd	a3,8(s0)
    11f4:	e818                	sd	a4,16(s0)
    11f6:	ec1c                	sd	a5,24(s0)
    11f8:	03043023          	sd	a6,32(s0)
    11fc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    1200:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    1204:	8622                	mv	a2,s0
    1206:	00000097          	auipc	ra,0x0
    120a:	e04080e7          	jalr	-508(ra) # 100a <vprintf>
}
    120e:	60e2                	ld	ra,24(sp)
    1210:	6442                	ld	s0,16(sp)
    1212:	6161                	addi	sp,sp,80
    1214:	8082                	ret

0000000000001216 <printf>:

void
printf(const char *fmt, ...)
{
    1216:	711d                	addi	sp,sp,-96
    1218:	ec06                	sd	ra,24(sp)
    121a:	e822                	sd	s0,16(sp)
    121c:	1000                	addi	s0,sp,32
    121e:	e40c                	sd	a1,8(s0)
    1220:	e810                	sd	a2,16(s0)
    1222:	ec14                	sd	a3,24(s0)
    1224:	f018                	sd	a4,32(s0)
    1226:	f41c                	sd	a5,40(s0)
    1228:	03043823          	sd	a6,48(s0)
    122c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    1230:	00840613          	addi	a2,s0,8
    1234:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    1238:	85aa                	mv	a1,a0
    123a:	4505                	li	a0,1
    123c:	00000097          	auipc	ra,0x0
    1240:	dce080e7          	jalr	-562(ra) # 100a <vprintf>
}
    1244:	60e2                	ld	ra,24(sp)
    1246:	6442                	ld	s0,16(sp)
    1248:	6125                	addi	sp,sp,96
    124a:	8082                	ret

000000000000124c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    124c:	1141                	addi	sp,sp,-16
    124e:	e422                	sd	s0,8(sp)
    1250:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1252:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1256:	00000797          	auipc	a5,0x0
    125a:	47a7b783          	ld	a5,1146(a5) # 16d0 <freep>
    125e:	a805                	j	128e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    1260:	4618                	lw	a4,8(a2)
    1262:	9db9                	addw	a1,a1,a4
    1264:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1268:	6398                	ld	a4,0(a5)
    126a:	6318                	ld	a4,0(a4)
    126c:	fee53823          	sd	a4,-16(a0)
    1270:	a091                	j	12b4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1272:	ff852703          	lw	a4,-8(a0)
    1276:	9e39                	addw	a2,a2,a4
    1278:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    127a:	ff053703          	ld	a4,-16(a0)
    127e:	e398                	sd	a4,0(a5)
    1280:	a099                	j	12c6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1282:	6398                	ld	a4,0(a5)
    1284:	00e7e463          	bltu	a5,a4,128c <free+0x40>
    1288:	00e6ea63          	bltu	a3,a4,129c <free+0x50>
{
    128c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    128e:	fed7fae3          	bgeu	a5,a3,1282 <free+0x36>
    1292:	6398                	ld	a4,0(a5)
    1294:	00e6e463          	bltu	a3,a4,129c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1298:	fee7eae3          	bltu	a5,a4,128c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    129c:	ff852583          	lw	a1,-8(a0)
    12a0:	6390                	ld	a2,0(a5)
    12a2:	02059813          	slli	a6,a1,0x20
    12a6:	01c85713          	srli	a4,a6,0x1c
    12aa:	9736                	add	a4,a4,a3
    12ac:	fae60ae3          	beq	a2,a4,1260 <free+0x14>
    bp->s.ptr = p->s.ptr;
    12b0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    12b4:	4790                	lw	a2,8(a5)
    12b6:	02061593          	slli	a1,a2,0x20
    12ba:	01c5d713          	srli	a4,a1,0x1c
    12be:	973e                	add	a4,a4,a5
    12c0:	fae689e3          	beq	a3,a4,1272 <free+0x26>
  } else
    p->s.ptr = bp;
    12c4:	e394                	sd	a3,0(a5)
  freep = p;
    12c6:	00000717          	auipc	a4,0x0
    12ca:	40f73523          	sd	a5,1034(a4) # 16d0 <freep>
}
    12ce:	6422                	ld	s0,8(sp)
    12d0:	0141                	addi	sp,sp,16
    12d2:	8082                	ret

00000000000012d4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    12d4:	7139                	addi	sp,sp,-64
    12d6:	fc06                	sd	ra,56(sp)
    12d8:	f822                	sd	s0,48(sp)
    12da:	f426                	sd	s1,40(sp)
    12dc:	f04a                	sd	s2,32(sp)
    12de:	ec4e                	sd	s3,24(sp)
    12e0:	e852                	sd	s4,16(sp)
    12e2:	e456                	sd	s5,8(sp)
    12e4:	e05a                	sd	s6,0(sp)
    12e6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    12e8:	02051493          	slli	s1,a0,0x20
    12ec:	9081                	srli	s1,s1,0x20
    12ee:	04bd                	addi	s1,s1,15
    12f0:	8091                	srli	s1,s1,0x4
    12f2:	0014899b          	addiw	s3,s1,1
    12f6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12f8:	00000517          	auipc	a0,0x0
    12fc:	3d853503          	ld	a0,984(a0) # 16d0 <freep>
    1300:	c515                	beqz	a0,132c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1302:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1304:	4798                	lw	a4,8(a5)
    1306:	02977f63          	bgeu	a4,s1,1344 <malloc+0x70>
    130a:	8a4e                	mv	s4,s3
    130c:	0009871b          	sext.w	a4,s3
    1310:	6685                	lui	a3,0x1
    1312:	00d77363          	bgeu	a4,a3,1318 <malloc+0x44>
    1316:	6a05                	lui	s4,0x1
    1318:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    131c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    1320:	00000917          	auipc	s2,0x0
    1324:	3b090913          	addi	s2,s2,944 # 16d0 <freep>
  if(p == (char*)-1)
    1328:	5afd                	li	s5,-1
    132a:	a895                	j	139e <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    132c:	00000797          	auipc	a5,0x0
    1330:	79478793          	addi	a5,a5,1940 # 1ac0 <base>
    1334:	00000717          	auipc	a4,0x0
    1338:	38f73e23          	sd	a5,924(a4) # 16d0 <freep>
    133c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    133e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1342:	b7e1                	j	130a <malloc+0x36>
      if(p->s.size == nunits)
    1344:	02e48c63          	beq	s1,a4,137c <malloc+0xa8>
        p->s.size -= nunits;
    1348:	4137073b          	subw	a4,a4,s3
    134c:	c798                	sw	a4,8(a5)
        p += p->s.size;
    134e:	02071693          	slli	a3,a4,0x20
    1352:	01c6d713          	srli	a4,a3,0x1c
    1356:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    1358:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    135c:	00000717          	auipc	a4,0x0
    1360:	36a73a23          	sd	a0,884(a4) # 16d0 <freep>
      return (void*)(p + 1);
    1364:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1368:	70e2                	ld	ra,56(sp)
    136a:	7442                	ld	s0,48(sp)
    136c:	74a2                	ld	s1,40(sp)
    136e:	7902                	ld	s2,32(sp)
    1370:	69e2                	ld	s3,24(sp)
    1372:	6a42                	ld	s4,16(sp)
    1374:	6aa2                	ld	s5,8(sp)
    1376:	6b02                	ld	s6,0(sp)
    1378:	6121                	addi	sp,sp,64
    137a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    137c:	6398                	ld	a4,0(a5)
    137e:	e118                	sd	a4,0(a0)
    1380:	bff1                	j	135c <malloc+0x88>
  hp->s.size = nu;
    1382:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1386:	0541                	addi	a0,a0,16
    1388:	00000097          	auipc	ra,0x0
    138c:	ec4080e7          	jalr	-316(ra) # 124c <free>
  return freep;
    1390:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1394:	d971                	beqz	a0,1368 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1396:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1398:	4798                	lw	a4,8(a5)
    139a:	fa9775e3          	bgeu	a4,s1,1344 <malloc+0x70>
    if(p == freep)
    139e:	00093703          	ld	a4,0(s2)
    13a2:	853e                	mv	a0,a5
    13a4:	fef719e3          	bne	a4,a5,1396 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    13a8:	8552                	mv	a0,s4
    13aa:	00000097          	auipc	ra,0x0
    13ae:	b44080e7          	jalr	-1212(ra) # eee <sbrk>
  if(p == (char*)-1)
    13b2:	fd5518e3          	bne	a0,s5,1382 <malloc+0xae>
        return 0;
    13b6:	4501                	li	a0,0
    13b8:	bf45                	j	1368 <malloc+0x94>
