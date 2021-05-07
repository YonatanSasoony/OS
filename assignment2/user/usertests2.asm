
user/_usertests2:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_handler>:
char buf[BUFSZ];


int wait_sig = 0;

void test_handler(int signum){
       0:	1141                	addi	sp,sp,-16
       2:	e406                	sd	ra,8(sp)
       4:	e022                	sd	s0,0(sp)
       6:	0800                	addi	s0,sp,16
    wait_sig = 1;
       8:	4785                	li	a5,1
       a:	00008717          	auipc	a4,0x8
       e:	36f72f23          	sw	a5,894(a4) # 8388 <wait_sig>
    printf("Received sigtest\n");
      12:	00006517          	auipc	a0,0x6
      16:	fae50513          	addi	a0,a0,-82 # 5fc0 <malloc+0x310>
      1a:	00006097          	auipc	ra,0x6
      1e:	bd8080e7          	jalr	-1064(ra) # 5bf2 <printf>
}
      22:	60a2                	ld	ra,8(sp)
      24:	6402                	ld	s0,0(sp)
      26:	0141                	addi	sp,sp,16
      28:	8082                	ret

000000000000002a <test_thread>:

void test_thread(){
      2a:	1141                	addi	sp,sp,-16
      2c:	e406                	sd	ra,8(sp)
      2e:	e022                	sd	s0,0(sp)
      30:	0800                	addi	s0,sp,16
    printf("Thread is now running\n");
      32:	00006517          	auipc	a0,0x6
      36:	fa650513          	addi	a0,a0,-90 # 5fd8 <malloc+0x328>
      3a:	00006097          	auipc	ra,0x6
      3e:	bb8080e7          	jalr	-1096(ra) # 5bf2 <printf>
    kthread_exit(0);
      42:	4501                	li	a0,0
      44:	00006097          	auipc	ra,0x6
      48:	8a4080e7          	jalr	-1884(ra) # 58e8 <kthread_exit>
}
      4c:	60a2                	ld	ra,8(sp)
      4e:	6402                	ld	s0,0(sp)
      50:	0141                	addi	sp,sp,16
      52:	8082                	ret

0000000000000054 <bsstest>:
void
bsstest(char *s)
{
  int i;

  for(i = 0; i < sizeof(uninit); i++){
      54:	00009797          	auipc	a5,0x9
      58:	44c78793          	addi	a5,a5,1100 # 94a0 <uninit>
      5c:	0000c697          	auipc	a3,0xc
      60:	b5468693          	addi	a3,a3,-1196 # bbb0 <buf>
    if(uninit[i] != '\0'){
      64:	0007c703          	lbu	a4,0(a5)
      68:	e709                	bnez	a4,72 <bsstest+0x1e>
  for(i = 0; i < sizeof(uninit); i++){
      6a:	0785                	addi	a5,a5,1
      6c:	fed79ce3          	bne	a5,a3,64 <bsstest+0x10>
      70:	8082                	ret
{
      72:	1141                	addi	sp,sp,-16
      74:	e406                	sd	ra,8(sp)
      76:	e022                	sd	s0,0(sp)
      78:	0800                	addi	s0,sp,16
      printf("%s: bss test failed\n", s);
      7a:	85aa                	mv	a1,a0
      7c:	00006517          	auipc	a0,0x6
      80:	f7450513          	addi	a0,a0,-140 # 5ff0 <malloc+0x340>
      84:	00006097          	auipc	ra,0x6
      88:	b6e080e7          	jalr	-1170(ra) # 5bf2 <printf>
      exit(1);
      8c:	4505                	li	a0,1
      8e:	00005097          	auipc	ra,0x5
      92:	792080e7          	jalr	1938(ra) # 5820 <exit>

0000000000000096 <signal_test>:
void signal_test(char *s){
      96:	715d                	addi	sp,sp,-80
      98:	e486                	sd	ra,72(sp)
      9a:	e0a2                	sd	s0,64(sp)
      9c:	fc26                	sd	s1,56(sp)
      9e:	0880                	addi	s0,sp,80
    struct sigaction act = {test_handler, (uint)(1 << 29)};
      a0:	00000797          	auipc	a5,0x0
      a4:	f6078793          	addi	a5,a5,-160 # 0 <test_handler>
      a8:	fcf43423          	sd	a5,-56(s0)
      ac:	200007b7          	lui	a5,0x20000
      b0:	fcf42823          	sw	a5,-48(s0)
    sigprocmask(0);
      b4:	4501                	li	a0,0
      b6:	00006097          	auipc	ra,0x6
      ba:	80a080e7          	jalr	-2038(ra) # 58c0 <sigprocmask>
    sigaction(testsig, &act, &old);
      be:	fb840613          	addi	a2,s0,-72
      c2:	fc840593          	addi	a1,s0,-56
      c6:	453d                	li	a0,15
      c8:	00006097          	auipc	ra,0x6
      cc:	800080e7          	jalr	-2048(ra) # 58c8 <sigaction>
    if((pid = fork()) == 0){
      d0:	00005097          	auipc	ra,0x5
      d4:	748080e7          	jalr	1864(ra) # 5818 <fork>
      d8:	fca42e23          	sw	a0,-36(s0)
      dc:	c90d                	beqz	a0,10e <signal_test+0x78>
    kill(pid, testsig);
      de:	45bd                	li	a1,15
      e0:	00005097          	auipc	ra,0x5
      e4:	770080e7          	jalr	1904(ra) # 5850 <kill>
    wait(&pid);
      e8:	fdc40513          	addi	a0,s0,-36
      ec:	00005097          	auipc	ra,0x5
      f0:	73c080e7          	jalr	1852(ra) # 5828 <wait>
    printf("Finished testing signals\n");
      f4:	00006517          	auipc	a0,0x6
      f8:	f1450513          	addi	a0,a0,-236 # 6008 <malloc+0x358>
      fc:	00006097          	auipc	ra,0x6
     100:	af6080e7          	jalr	-1290(ra) # 5bf2 <printf>
}
     104:	60a6                	ld	ra,72(sp)
     106:	6406                	ld	s0,64(sp)
     108:	74e2                	ld	s1,56(sp)
     10a:	6161                	addi	sp,sp,80
     10c:	8082                	ret
        while(!wait_sig)
     10e:	00008797          	auipc	a5,0x8
     112:	27a7a783          	lw	a5,634(a5) # 8388 <wait_sig>
     116:	ef81                	bnez	a5,12e <signal_test+0x98>
     118:	00008497          	auipc	s1,0x8
     11c:	27048493          	addi	s1,s1,624 # 8388 <wait_sig>
            sleep(1);
     120:	4505                	li	a0,1
     122:	00005097          	auipc	ra,0x5
     126:	78e080e7          	jalr	1934(ra) # 58b0 <sleep>
        while(!wait_sig)
     12a:	409c                	lw	a5,0(s1)
     12c:	dbf5                	beqz	a5,120 <signal_test+0x8a>
        exit(0);
     12e:	4501                	li	a0,0
     130:	00005097          	auipc	ra,0x5
     134:	6f0080e7          	jalr	1776(ra) # 5820 <exit>

0000000000000138 <exitwait>:
{
     138:	7139                	addi	sp,sp,-64
     13a:	fc06                	sd	ra,56(sp)
     13c:	f822                	sd	s0,48(sp)
     13e:	f426                	sd	s1,40(sp)
     140:	f04a                	sd	s2,32(sp)
     142:	ec4e                	sd	s3,24(sp)
     144:	e852                	sd	s4,16(sp)
     146:	0080                	addi	s0,sp,64
     148:	8a2a                	mv	s4,a0
  for(i = 0; i < 100; i++){
     14a:	4901                	li	s2,0
     14c:	06400993          	li	s3,100
    pid = fork();
     150:	00005097          	auipc	ra,0x5
     154:	6c8080e7          	jalr	1736(ra) # 5818 <fork>
     158:	84aa                	mv	s1,a0
    if(pid < 0){
     15a:	02054a63          	bltz	a0,18e <exitwait+0x56>
    if(pid){
     15e:	c151                	beqz	a0,1e2 <exitwait+0xaa>
      if(wait(&xstate) != pid){
     160:	fcc40513          	addi	a0,s0,-52
     164:	00005097          	auipc	ra,0x5
     168:	6c4080e7          	jalr	1732(ra) # 5828 <wait>
     16c:	02951f63          	bne	a0,s1,1aa <exitwait+0x72>
      if(i != xstate) {
     170:	fcc42783          	lw	a5,-52(s0)
     174:	05279963          	bne	a5,s2,1c6 <exitwait+0x8e>
  for(i = 0; i < 100; i++){
     178:	2905                	addiw	s2,s2,1
     17a:	fd391be3          	bne	s2,s3,150 <exitwait+0x18>
}
     17e:	70e2                	ld	ra,56(sp)
     180:	7442                	ld	s0,48(sp)
     182:	74a2                	ld	s1,40(sp)
     184:	7902                	ld	s2,32(sp)
     186:	69e2                	ld	s3,24(sp)
     188:	6a42                	ld	s4,16(sp)
     18a:	6121                	addi	sp,sp,64
     18c:	8082                	ret
      printf("%s: fork failed\n", s);
     18e:	85d2                	mv	a1,s4
     190:	00006517          	auipc	a0,0x6
     194:	e9850513          	addi	a0,a0,-360 # 6028 <malloc+0x378>
     198:	00006097          	auipc	ra,0x6
     19c:	a5a080e7          	jalr	-1446(ra) # 5bf2 <printf>
      exit(1);
     1a0:	4505                	li	a0,1
     1a2:	00005097          	auipc	ra,0x5
     1a6:	67e080e7          	jalr	1662(ra) # 5820 <exit>
        printf("%s: wait wrong pid\n", s);
     1aa:	85d2                	mv	a1,s4
     1ac:	00006517          	auipc	a0,0x6
     1b0:	e9450513          	addi	a0,a0,-364 # 6040 <malloc+0x390>
     1b4:	00006097          	auipc	ra,0x6
     1b8:	a3e080e7          	jalr	-1474(ra) # 5bf2 <printf>
        exit(1);
     1bc:	4505                	li	a0,1
     1be:	00005097          	auipc	ra,0x5
     1c2:	662080e7          	jalr	1634(ra) # 5820 <exit>
        printf("%s: wait wrong exit status\n", s);
     1c6:	85d2                	mv	a1,s4
     1c8:	00006517          	auipc	a0,0x6
     1cc:	e9050513          	addi	a0,a0,-368 # 6058 <malloc+0x3a8>
     1d0:	00006097          	auipc	ra,0x6
     1d4:	a22080e7          	jalr	-1502(ra) # 5bf2 <printf>
        exit(1);
     1d8:	4505                	li	a0,1
     1da:	00005097          	auipc	ra,0x5
     1de:	646080e7          	jalr	1606(ra) # 5820 <exit>
      exit(i);
     1e2:	854a                	mv	a0,s2
     1e4:	00005097          	auipc	ra,0x5
     1e8:	63c080e7          	jalr	1596(ra) # 5820 <exit>

00000000000001ec <twochildren>:
{
     1ec:	1101                	addi	sp,sp,-32
     1ee:	ec06                	sd	ra,24(sp)
     1f0:	e822                	sd	s0,16(sp)
     1f2:	e426                	sd	s1,8(sp)
     1f4:	e04a                	sd	s2,0(sp)
     1f6:	1000                	addi	s0,sp,32
     1f8:	892a                	mv	s2,a0
     1fa:	3e800493          	li	s1,1000
    int pid1 = fork();
     1fe:	00005097          	auipc	ra,0x5
     202:	61a080e7          	jalr	1562(ra) # 5818 <fork>
    if(pid1 < 0){
     206:	02054c63          	bltz	a0,23e <twochildren+0x52>
    if(pid1 == 0){
     20a:	c921                	beqz	a0,25a <twochildren+0x6e>
      int pid2 = fork();
     20c:	00005097          	auipc	ra,0x5
     210:	60c080e7          	jalr	1548(ra) # 5818 <fork>
      if(pid2 < 0){
     214:	04054763          	bltz	a0,262 <twochildren+0x76>
      if(pid2 == 0){
     218:	c13d                	beqz	a0,27e <twochildren+0x92>
        wait(0);
     21a:	4501                	li	a0,0
     21c:	00005097          	auipc	ra,0x5
     220:	60c080e7          	jalr	1548(ra) # 5828 <wait>
        wait(0);
     224:	4501                	li	a0,0
     226:	00005097          	auipc	ra,0x5
     22a:	602080e7          	jalr	1538(ra) # 5828 <wait>
  for(int i = 0; i < 1000; i++){
     22e:	34fd                	addiw	s1,s1,-1
     230:	f4f9                	bnez	s1,1fe <twochildren+0x12>
}
     232:	60e2                	ld	ra,24(sp)
     234:	6442                	ld	s0,16(sp)
     236:	64a2                	ld	s1,8(sp)
     238:	6902                	ld	s2,0(sp)
     23a:	6105                	addi	sp,sp,32
     23c:	8082                	ret
      printf("%s: fork failed\n", s);
     23e:	85ca                	mv	a1,s2
     240:	00006517          	auipc	a0,0x6
     244:	de850513          	addi	a0,a0,-536 # 6028 <malloc+0x378>
     248:	00006097          	auipc	ra,0x6
     24c:	9aa080e7          	jalr	-1622(ra) # 5bf2 <printf>
      exit(1);
     250:	4505                	li	a0,1
     252:	00005097          	auipc	ra,0x5
     256:	5ce080e7          	jalr	1486(ra) # 5820 <exit>
      exit(0);
     25a:	00005097          	auipc	ra,0x5
     25e:	5c6080e7          	jalr	1478(ra) # 5820 <exit>
        printf("%s: fork failed\n", s);
     262:	85ca                	mv	a1,s2
     264:	00006517          	auipc	a0,0x6
     268:	dc450513          	addi	a0,a0,-572 # 6028 <malloc+0x378>
     26c:	00006097          	auipc	ra,0x6
     270:	986080e7          	jalr	-1658(ra) # 5bf2 <printf>
        exit(1);
     274:	4505                	li	a0,1
     276:	00005097          	auipc	ra,0x5
     27a:	5aa080e7          	jalr	1450(ra) # 5820 <exit>
        exit(0);
     27e:	00005097          	auipc	ra,0x5
     282:	5a2080e7          	jalr	1442(ra) # 5820 <exit>

0000000000000286 <forkfork>:
{
     286:	7179                	addi	sp,sp,-48
     288:	f406                	sd	ra,40(sp)
     28a:	f022                	sd	s0,32(sp)
     28c:	ec26                	sd	s1,24(sp)
     28e:	1800                	addi	s0,sp,48
     290:	84aa                	mv	s1,a0
    int pid = fork();
     292:	00005097          	auipc	ra,0x5
     296:	586080e7          	jalr	1414(ra) # 5818 <fork>
    if(pid < 0){
     29a:	04054163          	bltz	a0,2dc <forkfork+0x56>
    if(pid == 0){
     29e:	cd29                	beqz	a0,2f8 <forkfork+0x72>
    int pid = fork();
     2a0:	00005097          	auipc	ra,0x5
     2a4:	578080e7          	jalr	1400(ra) # 5818 <fork>
    if(pid < 0){
     2a8:	02054a63          	bltz	a0,2dc <forkfork+0x56>
    if(pid == 0){
     2ac:	c531                	beqz	a0,2f8 <forkfork+0x72>
    wait(&xstatus);
     2ae:	fdc40513          	addi	a0,s0,-36
     2b2:	00005097          	auipc	ra,0x5
     2b6:	576080e7          	jalr	1398(ra) # 5828 <wait>
    if(xstatus != 0) {
     2ba:	fdc42783          	lw	a5,-36(s0)
     2be:	ebbd                	bnez	a5,334 <forkfork+0xae>
    wait(&xstatus);
     2c0:	fdc40513          	addi	a0,s0,-36
     2c4:	00005097          	auipc	ra,0x5
     2c8:	564080e7          	jalr	1380(ra) # 5828 <wait>
    if(xstatus != 0) {
     2cc:	fdc42783          	lw	a5,-36(s0)
     2d0:	e3b5                	bnez	a5,334 <forkfork+0xae>
}
     2d2:	70a2                	ld	ra,40(sp)
     2d4:	7402                	ld	s0,32(sp)
     2d6:	64e2                	ld	s1,24(sp)
     2d8:	6145                	addi	sp,sp,48
     2da:	8082                	ret
      printf("%s: fork failed", s);
     2dc:	85a6                	mv	a1,s1
     2de:	00006517          	auipc	a0,0x6
     2e2:	d9a50513          	addi	a0,a0,-614 # 6078 <malloc+0x3c8>
     2e6:	00006097          	auipc	ra,0x6
     2ea:	90c080e7          	jalr	-1780(ra) # 5bf2 <printf>
      exit(1);
     2ee:	4505                	li	a0,1
     2f0:	00005097          	auipc	ra,0x5
     2f4:	530080e7          	jalr	1328(ra) # 5820 <exit>
{
     2f8:	0c800493          	li	s1,200
        int pid1 = fork();
     2fc:	00005097          	auipc	ra,0x5
     300:	51c080e7          	jalr	1308(ra) # 5818 <fork>
        if(pid1 < 0){
     304:	00054f63          	bltz	a0,322 <forkfork+0x9c>
        if(pid1 == 0){
     308:	c115                	beqz	a0,32c <forkfork+0xa6>
        wait(0);
     30a:	4501                	li	a0,0
     30c:	00005097          	auipc	ra,0x5
     310:	51c080e7          	jalr	1308(ra) # 5828 <wait>
      for(int j = 0; j < 200; j++){
     314:	34fd                	addiw	s1,s1,-1
     316:	f0fd                	bnez	s1,2fc <forkfork+0x76>
      exit(0);
     318:	4501                	li	a0,0
     31a:	00005097          	auipc	ra,0x5
     31e:	506080e7          	jalr	1286(ra) # 5820 <exit>
          exit(1);
     322:	4505                	li	a0,1
     324:	00005097          	auipc	ra,0x5
     328:	4fc080e7          	jalr	1276(ra) # 5820 <exit>
          exit(0);
     32c:	00005097          	auipc	ra,0x5
     330:	4f4080e7          	jalr	1268(ra) # 5820 <exit>
      printf("%s: fork in child failed", s);
     334:	85a6                	mv	a1,s1
     336:	00006517          	auipc	a0,0x6
     33a:	d5250513          	addi	a0,a0,-686 # 6088 <malloc+0x3d8>
     33e:	00006097          	auipc	ra,0x6
     342:	8b4080e7          	jalr	-1868(ra) # 5bf2 <printf>
      exit(1);
     346:	4505                	li	a0,1
     348:	00005097          	auipc	ra,0x5
     34c:	4d8080e7          	jalr	1240(ra) # 5820 <exit>

0000000000000350 <forktest>:
{
     350:	7179                	addi	sp,sp,-48
     352:	f406                	sd	ra,40(sp)
     354:	f022                	sd	s0,32(sp)
     356:	ec26                	sd	s1,24(sp)
     358:	e84a                	sd	s2,16(sp)
     35a:	e44e                	sd	s3,8(sp)
     35c:	1800                	addi	s0,sp,48
     35e:	89aa                	mv	s3,a0
  for(n=0; n<N; n++){
     360:	4481                	li	s1,0
     362:	3e800913          	li	s2,1000
    pid = fork();
     366:	00005097          	auipc	ra,0x5
     36a:	4b2080e7          	jalr	1202(ra) # 5818 <fork>
    if(pid < 0)
     36e:	02054863          	bltz	a0,39e <forktest+0x4e>
    if(pid == 0)
     372:	c115                	beqz	a0,396 <forktest+0x46>
  for(n=0; n<N; n++){
     374:	2485                	addiw	s1,s1,1
     376:	ff2498e3          	bne	s1,s2,366 <forktest+0x16>
    printf("%s: fork claimed to work 1000 times!\n", s);
     37a:	85ce                	mv	a1,s3
     37c:	00006517          	auipc	a0,0x6
     380:	d4450513          	addi	a0,a0,-700 # 60c0 <malloc+0x410>
     384:	00006097          	auipc	ra,0x6
     388:	86e080e7          	jalr	-1938(ra) # 5bf2 <printf>
    exit(1);
     38c:	4505                	li	a0,1
     38e:	00005097          	auipc	ra,0x5
     392:	492080e7          	jalr	1170(ra) # 5820 <exit>
      exit(0);
     396:	00005097          	auipc	ra,0x5
     39a:	48a080e7          	jalr	1162(ra) # 5820 <exit>
  if (n == 0) {
     39e:	cc9d                	beqz	s1,3dc <forktest+0x8c>
  if(n == N){
     3a0:	3e800793          	li	a5,1000
     3a4:	fcf48be3          	beq	s1,a5,37a <forktest+0x2a>
  for(; n > 0; n--){
     3a8:	00905b63          	blez	s1,3be <forktest+0x6e>
    if(wait(0) < 0){
     3ac:	4501                	li	a0,0
     3ae:	00005097          	auipc	ra,0x5
     3b2:	47a080e7          	jalr	1146(ra) # 5828 <wait>
     3b6:	04054163          	bltz	a0,3f8 <forktest+0xa8>
  for(; n > 0; n--){
     3ba:	34fd                	addiw	s1,s1,-1
     3bc:	f8e5                	bnez	s1,3ac <forktest+0x5c>
  if(wait(0) != -1){
     3be:	4501                	li	a0,0
     3c0:	00005097          	auipc	ra,0x5
     3c4:	468080e7          	jalr	1128(ra) # 5828 <wait>
     3c8:	57fd                	li	a5,-1
     3ca:	04f51563          	bne	a0,a5,414 <forktest+0xc4>
}
     3ce:	70a2                	ld	ra,40(sp)
     3d0:	7402                	ld	s0,32(sp)
     3d2:	64e2                	ld	s1,24(sp)
     3d4:	6942                	ld	s2,16(sp)
     3d6:	69a2                	ld	s3,8(sp)
     3d8:	6145                	addi	sp,sp,48
     3da:	8082                	ret
    printf("%s: no fork at all!\n", s);
     3dc:	85ce                	mv	a1,s3
     3de:	00006517          	auipc	a0,0x6
     3e2:	cca50513          	addi	a0,a0,-822 # 60a8 <malloc+0x3f8>
     3e6:	00006097          	auipc	ra,0x6
     3ea:	80c080e7          	jalr	-2036(ra) # 5bf2 <printf>
    exit(1);
     3ee:	4505                	li	a0,1
     3f0:	00005097          	auipc	ra,0x5
     3f4:	430080e7          	jalr	1072(ra) # 5820 <exit>
      printf("%s: wait stopped early\n", s);
     3f8:	85ce                	mv	a1,s3
     3fa:	00006517          	auipc	a0,0x6
     3fe:	cee50513          	addi	a0,a0,-786 # 60e8 <malloc+0x438>
     402:	00005097          	auipc	ra,0x5
     406:	7f0080e7          	jalr	2032(ra) # 5bf2 <printf>
      exit(1);
     40a:	4505                	li	a0,1
     40c:	00005097          	auipc	ra,0x5
     410:	414080e7          	jalr	1044(ra) # 5820 <exit>
    printf("%s: wait got too many\n", s);
     414:	85ce                	mv	a1,s3
     416:	00006517          	auipc	a0,0x6
     41a:	cea50513          	addi	a0,a0,-790 # 6100 <malloc+0x450>
     41e:	00005097          	auipc	ra,0x5
     422:	7d4080e7          	jalr	2004(ra) # 5bf2 <printf>
    exit(1);
     426:	4505                	li	a0,1
     428:	00005097          	auipc	ra,0x5
     42c:	3f8080e7          	jalr	1016(ra) # 5820 <exit>

0000000000000430 <thread_test>:
void thread_test(char *s){
     430:	7179                	addi	sp,sp,-48
     432:	f406                	sd	ra,40(sp)
     434:	f022                	sd	s0,32(sp)
     436:	ec26                	sd	s1,24(sp)
     438:	e84a                	sd	s2,16(sp)
     43a:	1800                	addi	s0,sp,48
    void* stack = malloc(MAX_STACK_SIZE); //TODO- CHANGE TO STACK_SIZE
     43c:	6505                	lui	a0,0x1
     43e:	fa050513          	addi	a0,a0,-96 # fa0 <preempt+0x10c>
     442:	00006097          	auipc	ra,0x6
     446:	86e080e7          	jalr	-1938(ra) # 5cb0 <malloc>
     44a:	84aa                	mv	s1,a0
    tid = kthread_create(test_thread, stack);
     44c:	85aa                	mv	a1,a0
     44e:	00000517          	auipc	a0,0x0
     452:	bdc50513          	addi	a0,a0,-1060 # 2a <test_thread>
     456:	00005097          	auipc	ra,0x5
     45a:	482080e7          	jalr	1154(ra) # 58d8 <kthread_create>
    kthread_join(tid,&status);
     45e:	fdc40593          	addi	a1,s0,-36
     462:	00005097          	auipc	ra,0x5
     466:	48e080e7          	jalr	1166(ra) # 58f0 <kthread_join>
    tid = kthread_id();
     46a:	00005097          	auipc	ra,0x5
     46e:	476080e7          	jalr	1142(ra) # 58e0 <kthread_id>
     472:	892a                	mv	s2,a0
    free(stack);
     474:	8526                	mv	a0,s1
     476:	00005097          	auipc	ra,0x5
     47a:	7b2080e7          	jalr	1970(ra) # 5c28 <free>
    printf("Finished testing threads, main thread id: %d, %d\n", tid,status);
     47e:	fdc42603          	lw	a2,-36(s0)
     482:	85ca                	mv	a1,s2
     484:	00006517          	auipc	a0,0x6
     488:	c9450513          	addi	a0,a0,-876 # 6118 <malloc+0x468>
     48c:	00005097          	auipc	ra,0x5
     490:	766080e7          	jalr	1894(ra) # 5bf2 <printf>
}
     494:	70a2                	ld	ra,40(sp)
     496:	7402                	ld	s0,32(sp)
     498:	64e2                	ld	s1,24(sp)
     49a:	6942                	ld	s2,16(sp)
     49c:	6145                	addi	sp,sp,48
     49e:	8082                	ret

00000000000004a0 <copyinstr1>:
{
     4a0:	1141                	addi	sp,sp,-16
     4a2:	e406                	sd	ra,8(sp)
     4a4:	e022                	sd	s0,0(sp)
     4a6:	0800                	addi	s0,sp,16
    int fd = open((char *)addr, O_CREATE|O_WRONLY);
     4a8:	20100593          	li	a1,513
     4ac:	4505                	li	a0,1
     4ae:	057e                	slli	a0,a0,0x1f
     4b0:	00005097          	auipc	ra,0x5
     4b4:	3b0080e7          	jalr	944(ra) # 5860 <open>
    if(fd >= 0){
     4b8:	02055063          	bgez	a0,4d8 <copyinstr1+0x38>
    int fd = open((char *)addr, O_CREATE|O_WRONLY);
     4bc:	20100593          	li	a1,513
     4c0:	557d                	li	a0,-1
     4c2:	00005097          	auipc	ra,0x5
     4c6:	39e080e7          	jalr	926(ra) # 5860 <open>
    uint64 addr = addrs[ai];
     4ca:	55fd                	li	a1,-1
    if(fd >= 0){
     4cc:	00055863          	bgez	a0,4dc <copyinstr1+0x3c>
}
     4d0:	60a2                	ld	ra,8(sp)
     4d2:	6402                	ld	s0,0(sp)
     4d4:	0141                	addi	sp,sp,16
     4d6:	8082                	ret
    uint64 addr = addrs[ai];
     4d8:	4585                	li	a1,1
     4da:	05fe                	slli	a1,a1,0x1f
      printf("open(%p) returned %d, not -1\n", addr, fd);
     4dc:	862a                	mv	a2,a0
     4de:	00006517          	auipc	a0,0x6
     4e2:	c7250513          	addi	a0,a0,-910 # 6150 <malloc+0x4a0>
     4e6:	00005097          	auipc	ra,0x5
     4ea:	70c080e7          	jalr	1804(ra) # 5bf2 <printf>
      exit(1);
     4ee:	4505                	li	a0,1
     4f0:	00005097          	auipc	ra,0x5
     4f4:	330080e7          	jalr	816(ra) # 5820 <exit>

00000000000004f8 <opentest>:
{
     4f8:	1101                	addi	sp,sp,-32
     4fa:	ec06                	sd	ra,24(sp)
     4fc:	e822                	sd	s0,16(sp)
     4fe:	e426                	sd	s1,8(sp)
     500:	1000                	addi	s0,sp,32
     502:	84aa                	mv	s1,a0
  fd = open("echo", 0);
     504:	4581                	li	a1,0
     506:	00006517          	auipc	a0,0x6
     50a:	c6a50513          	addi	a0,a0,-918 # 6170 <malloc+0x4c0>
     50e:	00005097          	auipc	ra,0x5
     512:	352080e7          	jalr	850(ra) # 5860 <open>
  if(fd < 0){
     516:	02054663          	bltz	a0,542 <opentest+0x4a>
  close(fd);
     51a:	00005097          	auipc	ra,0x5
     51e:	32e080e7          	jalr	814(ra) # 5848 <close>
  fd = open("doesnotexist", 0);
     522:	4581                	li	a1,0
     524:	00006517          	auipc	a0,0x6
     528:	c6c50513          	addi	a0,a0,-916 # 6190 <malloc+0x4e0>
     52c:	00005097          	auipc	ra,0x5
     530:	334080e7          	jalr	820(ra) # 5860 <open>
  if(fd >= 0){
     534:	02055563          	bgez	a0,55e <opentest+0x66>
}
     538:	60e2                	ld	ra,24(sp)
     53a:	6442                	ld	s0,16(sp)
     53c:	64a2                	ld	s1,8(sp)
     53e:	6105                	addi	sp,sp,32
     540:	8082                	ret
    printf("%s: open echo failed!\n", s);
     542:	85a6                	mv	a1,s1
     544:	00006517          	auipc	a0,0x6
     548:	c3450513          	addi	a0,a0,-972 # 6178 <malloc+0x4c8>
     54c:	00005097          	auipc	ra,0x5
     550:	6a6080e7          	jalr	1702(ra) # 5bf2 <printf>
    exit(1);
     554:	4505                	li	a0,1
     556:	00005097          	auipc	ra,0x5
     55a:	2ca080e7          	jalr	714(ra) # 5820 <exit>
    printf("%s: open doesnotexist succeeded!\n", s);
     55e:	85a6                	mv	a1,s1
     560:	00006517          	auipc	a0,0x6
     564:	c4050513          	addi	a0,a0,-960 # 61a0 <malloc+0x4f0>
     568:	00005097          	auipc	ra,0x5
     56c:	68a080e7          	jalr	1674(ra) # 5bf2 <printf>
    exit(1);
     570:	4505                	li	a0,1
     572:	00005097          	auipc	ra,0x5
     576:	2ae080e7          	jalr	686(ra) # 5820 <exit>

000000000000057a <truncate2>:
{
     57a:	7179                	addi	sp,sp,-48
     57c:	f406                	sd	ra,40(sp)
     57e:	f022                	sd	s0,32(sp)
     580:	ec26                	sd	s1,24(sp)
     582:	e84a                	sd	s2,16(sp)
     584:	e44e                	sd	s3,8(sp)
     586:	1800                	addi	s0,sp,48
     588:	89aa                	mv	s3,a0
  unlink("truncfile");
     58a:	00006517          	auipc	a0,0x6
     58e:	c3e50513          	addi	a0,a0,-962 # 61c8 <malloc+0x518>
     592:	00005097          	auipc	ra,0x5
     596:	2de080e7          	jalr	734(ra) # 5870 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_TRUNC|O_WRONLY);
     59a:	60100593          	li	a1,1537
     59e:	00006517          	auipc	a0,0x6
     5a2:	c2a50513          	addi	a0,a0,-982 # 61c8 <malloc+0x518>
     5a6:	00005097          	auipc	ra,0x5
     5aa:	2ba080e7          	jalr	698(ra) # 5860 <open>
     5ae:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     5b0:	4611                	li	a2,4
     5b2:	00006597          	auipc	a1,0x6
     5b6:	c2658593          	addi	a1,a1,-986 # 61d8 <malloc+0x528>
     5ba:	00005097          	auipc	ra,0x5
     5be:	286080e7          	jalr	646(ra) # 5840 <write>
  int fd2 = open("truncfile", O_TRUNC|O_WRONLY);
     5c2:	40100593          	li	a1,1025
     5c6:	00006517          	auipc	a0,0x6
     5ca:	c0250513          	addi	a0,a0,-1022 # 61c8 <malloc+0x518>
     5ce:	00005097          	auipc	ra,0x5
     5d2:	292080e7          	jalr	658(ra) # 5860 <open>
     5d6:	892a                	mv	s2,a0
  int n = write(fd1, "x", 1);
     5d8:	4605                	li	a2,1
     5da:	00006597          	auipc	a1,0x6
     5de:	c0658593          	addi	a1,a1,-1018 # 61e0 <malloc+0x530>
     5e2:	8526                	mv	a0,s1
     5e4:	00005097          	auipc	ra,0x5
     5e8:	25c080e7          	jalr	604(ra) # 5840 <write>
  if(n != -1){
     5ec:	57fd                	li	a5,-1
     5ee:	02f51b63          	bne	a0,a5,624 <truncate2+0xaa>
  unlink("truncfile");
     5f2:	00006517          	auipc	a0,0x6
     5f6:	bd650513          	addi	a0,a0,-1066 # 61c8 <malloc+0x518>
     5fa:	00005097          	auipc	ra,0x5
     5fe:	276080e7          	jalr	630(ra) # 5870 <unlink>
  close(fd1);
     602:	8526                	mv	a0,s1
     604:	00005097          	auipc	ra,0x5
     608:	244080e7          	jalr	580(ra) # 5848 <close>
  close(fd2);
     60c:	854a                	mv	a0,s2
     60e:	00005097          	auipc	ra,0x5
     612:	23a080e7          	jalr	570(ra) # 5848 <close>
}
     616:	70a2                	ld	ra,40(sp)
     618:	7402                	ld	s0,32(sp)
     61a:	64e2                	ld	s1,24(sp)
     61c:	6942                	ld	s2,16(sp)
     61e:	69a2                	ld	s3,8(sp)
     620:	6145                	addi	sp,sp,48
     622:	8082                	ret
    printf("%s: write returned %d, expected -1\n", s, n);
     624:	862a                	mv	a2,a0
     626:	85ce                	mv	a1,s3
     628:	00006517          	auipc	a0,0x6
     62c:	bc050513          	addi	a0,a0,-1088 # 61e8 <malloc+0x538>
     630:	00005097          	auipc	ra,0x5
     634:	5c2080e7          	jalr	1474(ra) # 5bf2 <printf>
    exit(1);
     638:	4505                	li	a0,1
     63a:	00005097          	auipc	ra,0x5
     63e:	1e6080e7          	jalr	486(ra) # 5820 <exit>

0000000000000642 <forkforkfork>:
{
     642:	1101                	addi	sp,sp,-32
     644:	ec06                	sd	ra,24(sp)
     646:	e822                	sd	s0,16(sp)
     648:	e426                	sd	s1,8(sp)
     64a:	1000                	addi	s0,sp,32
     64c:	84aa                	mv	s1,a0
  unlink("stopforking");
     64e:	00006517          	auipc	a0,0x6
     652:	bc250513          	addi	a0,a0,-1086 # 6210 <malloc+0x560>
     656:	00005097          	auipc	ra,0x5
     65a:	21a080e7          	jalr	538(ra) # 5870 <unlink>
  int pid = fork();
     65e:	00005097          	auipc	ra,0x5
     662:	1ba080e7          	jalr	442(ra) # 5818 <fork>
  if(pid < 0){
     666:	04054563          	bltz	a0,6b0 <forkforkfork+0x6e>
  if(pid == 0){
     66a:	c12d                	beqz	a0,6cc <forkforkfork+0x8a>
  sleep(20); // two seconds
     66c:	4551                	li	a0,20
     66e:	00005097          	auipc	ra,0x5
     672:	242080e7          	jalr	578(ra) # 58b0 <sleep>
  close(open("stopforking", O_CREATE|O_RDWR));
     676:	20200593          	li	a1,514
     67a:	00006517          	auipc	a0,0x6
     67e:	b9650513          	addi	a0,a0,-1130 # 6210 <malloc+0x560>
     682:	00005097          	auipc	ra,0x5
     686:	1de080e7          	jalr	478(ra) # 5860 <open>
     68a:	00005097          	auipc	ra,0x5
     68e:	1be080e7          	jalr	446(ra) # 5848 <close>
  wait(0);
     692:	4501                	li	a0,0
     694:	00005097          	auipc	ra,0x5
     698:	194080e7          	jalr	404(ra) # 5828 <wait>
  sleep(10); // one second
     69c:	4529                	li	a0,10
     69e:	00005097          	auipc	ra,0x5
     6a2:	212080e7          	jalr	530(ra) # 58b0 <sleep>
}
     6a6:	60e2                	ld	ra,24(sp)
     6a8:	6442                	ld	s0,16(sp)
     6aa:	64a2                	ld	s1,8(sp)
     6ac:	6105                	addi	sp,sp,32
     6ae:	8082                	ret
    printf("%s: fork failed", s);
     6b0:	85a6                	mv	a1,s1
     6b2:	00006517          	auipc	a0,0x6
     6b6:	9c650513          	addi	a0,a0,-1594 # 6078 <malloc+0x3c8>
     6ba:	00005097          	auipc	ra,0x5
     6be:	538080e7          	jalr	1336(ra) # 5bf2 <printf>
    exit(1);
     6c2:	4505                	li	a0,1
     6c4:	00005097          	auipc	ra,0x5
     6c8:	15c080e7          	jalr	348(ra) # 5820 <exit>
      int fd = open("stopforking", 0);
     6cc:	00006497          	auipc	s1,0x6
     6d0:	b4448493          	addi	s1,s1,-1212 # 6210 <malloc+0x560>
     6d4:	4581                	li	a1,0
     6d6:	8526                	mv	a0,s1
     6d8:	00005097          	auipc	ra,0x5
     6dc:	188080e7          	jalr	392(ra) # 5860 <open>
      if(fd >= 0){
     6e0:	02055463          	bgez	a0,708 <forkforkfork+0xc6>
      if(fork() < 0){
     6e4:	00005097          	auipc	ra,0x5
     6e8:	134080e7          	jalr	308(ra) # 5818 <fork>
     6ec:	fe0554e3          	bgez	a0,6d4 <forkforkfork+0x92>
        close(open("stopforking", O_CREATE|O_RDWR));
     6f0:	20200593          	li	a1,514
     6f4:	8526                	mv	a0,s1
     6f6:	00005097          	auipc	ra,0x5
     6fa:	16a080e7          	jalr	362(ra) # 5860 <open>
     6fe:	00005097          	auipc	ra,0x5
     702:	14a080e7          	jalr	330(ra) # 5848 <close>
     706:	b7f9                	j	6d4 <forkforkfork+0x92>
        exit(0);
     708:	4501                	li	a0,0
     70a:	00005097          	auipc	ra,0x5
     70e:	116080e7          	jalr	278(ra) # 5820 <exit>

0000000000000712 <bigwrite>:
{
     712:	715d                	addi	sp,sp,-80
     714:	e486                	sd	ra,72(sp)
     716:	e0a2                	sd	s0,64(sp)
     718:	fc26                	sd	s1,56(sp)
     71a:	f84a                	sd	s2,48(sp)
     71c:	f44e                	sd	s3,40(sp)
     71e:	f052                	sd	s4,32(sp)
     720:	ec56                	sd	s5,24(sp)
     722:	e85a                	sd	s6,16(sp)
     724:	e45e                	sd	s7,8(sp)
     726:	0880                	addi	s0,sp,80
     728:	8baa                	mv	s7,a0
  unlink("bigwrite");
     72a:	00005517          	auipc	a0,0x5
     72e:	7d650513          	addi	a0,a0,2006 # 5f00 <malloc+0x250>
     732:	00005097          	auipc	ra,0x5
     736:	13e080e7          	jalr	318(ra) # 5870 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     73a:	1f300493          	li	s1,499
    fd = open("bigwrite", O_CREATE | O_RDWR);
     73e:	00005a97          	auipc	s5,0x5
     742:	7c2a8a93          	addi	s5,s5,1986 # 5f00 <malloc+0x250>
      int cc = write(fd, buf, sz);
     746:	0000ba17          	auipc	s4,0xb
     74a:	46aa0a13          	addi	s4,s4,1130 # bbb0 <buf>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     74e:	6b0d                	lui	s6,0x3
     750:	1c9b0b13          	addi	s6,s6,457 # 31c9 <bigfile+0x37>
    fd = open("bigwrite", O_CREATE | O_RDWR);
     754:	20200593          	li	a1,514
     758:	8556                	mv	a0,s5
     75a:	00005097          	auipc	ra,0x5
     75e:	106080e7          	jalr	262(ra) # 5860 <open>
     762:	892a                	mv	s2,a0
    if(fd < 0){
     764:	04054d63          	bltz	a0,7be <bigwrite+0xac>
      int cc = write(fd, buf, sz);
     768:	8626                	mv	a2,s1
     76a:	85d2                	mv	a1,s4
     76c:	00005097          	auipc	ra,0x5
     770:	0d4080e7          	jalr	212(ra) # 5840 <write>
     774:	89aa                	mv	s3,a0
      if(cc != sz){
     776:	06a49463          	bne	s1,a0,7de <bigwrite+0xcc>
      int cc = write(fd, buf, sz);
     77a:	8626                	mv	a2,s1
     77c:	85d2                	mv	a1,s4
     77e:	854a                	mv	a0,s2
     780:	00005097          	auipc	ra,0x5
     784:	0c0080e7          	jalr	192(ra) # 5840 <write>
      if(cc != sz){
     788:	04951963          	bne	a0,s1,7da <bigwrite+0xc8>
    close(fd);
     78c:	854a                	mv	a0,s2
     78e:	00005097          	auipc	ra,0x5
     792:	0ba080e7          	jalr	186(ra) # 5848 <close>
    unlink("bigwrite");
     796:	8556                	mv	a0,s5
     798:	00005097          	auipc	ra,0x5
     79c:	0d8080e7          	jalr	216(ra) # 5870 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     7a0:	1d74849b          	addiw	s1,s1,471
     7a4:	fb6498e3          	bne	s1,s6,754 <bigwrite+0x42>
}
     7a8:	60a6                	ld	ra,72(sp)
     7aa:	6406                	ld	s0,64(sp)
     7ac:	74e2                	ld	s1,56(sp)
     7ae:	7942                	ld	s2,48(sp)
     7b0:	79a2                	ld	s3,40(sp)
     7b2:	7a02                	ld	s4,32(sp)
     7b4:	6ae2                	ld	s5,24(sp)
     7b6:	6b42                	ld	s6,16(sp)
     7b8:	6ba2                	ld	s7,8(sp)
     7ba:	6161                	addi	sp,sp,80
     7bc:	8082                	ret
      printf("%s: cannot create bigwrite\n", s);
     7be:	85de                	mv	a1,s7
     7c0:	00006517          	auipc	a0,0x6
     7c4:	a6050513          	addi	a0,a0,-1440 # 6220 <malloc+0x570>
     7c8:	00005097          	auipc	ra,0x5
     7cc:	42a080e7          	jalr	1066(ra) # 5bf2 <printf>
      exit(1);
     7d0:	4505                	li	a0,1
     7d2:	00005097          	auipc	ra,0x5
     7d6:	04e080e7          	jalr	78(ra) # 5820 <exit>
     7da:	84ce                	mv	s1,s3
      int cc = write(fd, buf, sz);
     7dc:	89aa                	mv	s3,a0
        printf("%s: write(%d) ret %d\n", s, sz, cc);
     7de:	86ce                	mv	a3,s3
     7e0:	8626                	mv	a2,s1
     7e2:	85de                	mv	a1,s7
     7e4:	00006517          	auipc	a0,0x6
     7e8:	a5c50513          	addi	a0,a0,-1444 # 6240 <malloc+0x590>
     7ec:	00005097          	auipc	ra,0x5
     7f0:	406080e7          	jalr	1030(ra) # 5bf2 <printf>
        exit(1);
     7f4:	4505                	li	a0,1
     7f6:	00005097          	auipc	ra,0x5
     7fa:	02a080e7          	jalr	42(ra) # 5820 <exit>

00000000000007fe <copyin>:
{
     7fe:	715d                	addi	sp,sp,-80
     800:	e486                	sd	ra,72(sp)
     802:	e0a2                	sd	s0,64(sp)
     804:	fc26                	sd	s1,56(sp)
     806:	f84a                	sd	s2,48(sp)
     808:	f44e                	sd	s3,40(sp)
     80a:	f052                	sd	s4,32(sp)
     80c:	0880                	addi	s0,sp,80
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     80e:	4785                	li	a5,1
     810:	07fe                	slli	a5,a5,0x1f
     812:	fcf43023          	sd	a5,-64(s0)
     816:	57fd                	li	a5,-1
     818:	fcf43423          	sd	a5,-56(s0)
  for(int ai = 0; ai < 2; ai++){
     81c:	fc040913          	addi	s2,s0,-64
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     820:	00006a17          	auipc	s4,0x6
     824:	a38a0a13          	addi	s4,s4,-1480 # 6258 <malloc+0x5a8>
    uint64 addr = addrs[ai];
     828:	00093983          	ld	s3,0(s2)
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     82c:	20100593          	li	a1,513
     830:	8552                	mv	a0,s4
     832:	00005097          	auipc	ra,0x5
     836:	02e080e7          	jalr	46(ra) # 5860 <open>
     83a:	84aa                	mv	s1,a0
    if(fd < 0){
     83c:	08054863          	bltz	a0,8cc <copyin+0xce>
    int n = write(fd, (void*)addr, 8192);
     840:	6609                	lui	a2,0x2
     842:	85ce                	mv	a1,s3
     844:	00005097          	auipc	ra,0x5
     848:	ffc080e7          	jalr	-4(ra) # 5840 <write>
    if(n >= 0){
     84c:	08055d63          	bgez	a0,8e6 <copyin+0xe8>
    close(fd);
     850:	8526                	mv	a0,s1
     852:	00005097          	auipc	ra,0x5
     856:	ff6080e7          	jalr	-10(ra) # 5848 <close>
    unlink("copyin1");
     85a:	8552                	mv	a0,s4
     85c:	00005097          	auipc	ra,0x5
     860:	014080e7          	jalr	20(ra) # 5870 <unlink>
    n = write(1, (char*)addr, 8192);
     864:	6609                	lui	a2,0x2
     866:	85ce                	mv	a1,s3
     868:	4505                	li	a0,1
     86a:	00005097          	auipc	ra,0x5
     86e:	fd6080e7          	jalr	-42(ra) # 5840 <write>
    if(n > 0){
     872:	08a04963          	bgtz	a0,904 <copyin+0x106>
    if(pipe(fds) < 0){
     876:	fb840513          	addi	a0,s0,-72
     87a:	00005097          	auipc	ra,0x5
     87e:	fb6080e7          	jalr	-74(ra) # 5830 <pipe>
     882:	0a054063          	bltz	a0,922 <copyin+0x124>
    n = write(fds[1], (char*)addr, 8192);
     886:	6609                	lui	a2,0x2
     888:	85ce                	mv	a1,s3
     88a:	fbc42503          	lw	a0,-68(s0)
     88e:	00005097          	auipc	ra,0x5
     892:	fb2080e7          	jalr	-78(ra) # 5840 <write>
    if(n > 0){
     896:	0aa04363          	bgtz	a0,93c <copyin+0x13e>
    close(fds[0]);
     89a:	fb842503          	lw	a0,-72(s0)
     89e:	00005097          	auipc	ra,0x5
     8a2:	faa080e7          	jalr	-86(ra) # 5848 <close>
    close(fds[1]);
     8a6:	fbc42503          	lw	a0,-68(s0)
     8aa:	00005097          	auipc	ra,0x5
     8ae:	f9e080e7          	jalr	-98(ra) # 5848 <close>
  for(int ai = 0; ai < 2; ai++){
     8b2:	0921                	addi	s2,s2,8
     8b4:	fd040793          	addi	a5,s0,-48
     8b8:	f6f918e3          	bne	s2,a5,828 <copyin+0x2a>
}
     8bc:	60a6                	ld	ra,72(sp)
     8be:	6406                	ld	s0,64(sp)
     8c0:	74e2                	ld	s1,56(sp)
     8c2:	7942                	ld	s2,48(sp)
     8c4:	79a2                	ld	s3,40(sp)
     8c6:	7a02                	ld	s4,32(sp)
     8c8:	6161                	addi	sp,sp,80
     8ca:	8082                	ret
      printf("open(copyin1) failed\n");
     8cc:	00006517          	auipc	a0,0x6
     8d0:	99450513          	addi	a0,a0,-1644 # 6260 <malloc+0x5b0>
     8d4:	00005097          	auipc	ra,0x5
     8d8:	31e080e7          	jalr	798(ra) # 5bf2 <printf>
      exit(1);
     8dc:	4505                	li	a0,1
     8de:	00005097          	auipc	ra,0x5
     8e2:	f42080e7          	jalr	-190(ra) # 5820 <exit>
      printf("write(fd, %p, 8192) returned %d, not -1\n", addr, n);
     8e6:	862a                	mv	a2,a0
     8e8:	85ce                	mv	a1,s3
     8ea:	00006517          	auipc	a0,0x6
     8ee:	98e50513          	addi	a0,a0,-1650 # 6278 <malloc+0x5c8>
     8f2:	00005097          	auipc	ra,0x5
     8f6:	300080e7          	jalr	768(ra) # 5bf2 <printf>
      exit(1);
     8fa:	4505                	li	a0,1
     8fc:	00005097          	auipc	ra,0x5
     900:	f24080e7          	jalr	-220(ra) # 5820 <exit>
      printf("write(1, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     904:	862a                	mv	a2,a0
     906:	85ce                	mv	a1,s3
     908:	00006517          	auipc	a0,0x6
     90c:	9a050513          	addi	a0,a0,-1632 # 62a8 <malloc+0x5f8>
     910:	00005097          	auipc	ra,0x5
     914:	2e2080e7          	jalr	738(ra) # 5bf2 <printf>
      exit(1);
     918:	4505                	li	a0,1
     91a:	00005097          	auipc	ra,0x5
     91e:	f06080e7          	jalr	-250(ra) # 5820 <exit>
      printf("pipe() failed\n");
     922:	00006517          	auipc	a0,0x6
     926:	9b650513          	addi	a0,a0,-1610 # 62d8 <malloc+0x628>
     92a:	00005097          	auipc	ra,0x5
     92e:	2c8080e7          	jalr	712(ra) # 5bf2 <printf>
      exit(1);
     932:	4505                	li	a0,1
     934:	00005097          	auipc	ra,0x5
     938:	eec080e7          	jalr	-276(ra) # 5820 <exit>
      printf("write(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     93c:	862a                	mv	a2,a0
     93e:	85ce                	mv	a1,s3
     940:	00006517          	auipc	a0,0x6
     944:	9a850513          	addi	a0,a0,-1624 # 62e8 <malloc+0x638>
     948:	00005097          	auipc	ra,0x5
     94c:	2aa080e7          	jalr	682(ra) # 5bf2 <printf>
      exit(1);
     950:	4505                	li	a0,1
     952:	00005097          	auipc	ra,0x5
     956:	ece080e7          	jalr	-306(ra) # 5820 <exit>

000000000000095a <copyout>:
{
     95a:	711d                	addi	sp,sp,-96
     95c:	ec86                	sd	ra,88(sp)
     95e:	e8a2                	sd	s0,80(sp)
     960:	e4a6                	sd	s1,72(sp)
     962:	e0ca                	sd	s2,64(sp)
     964:	fc4e                	sd	s3,56(sp)
     966:	f852                	sd	s4,48(sp)
     968:	f456                	sd	s5,40(sp)
     96a:	1080                	addi	s0,sp,96
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     96c:	4785                	li	a5,1
     96e:	07fe                	slli	a5,a5,0x1f
     970:	faf43823          	sd	a5,-80(s0)
     974:	57fd                	li	a5,-1
     976:	faf43c23          	sd	a5,-72(s0)
  for(int ai = 0; ai < 2; ai++){
     97a:	fb040913          	addi	s2,s0,-80
    int fd = open("README", 0);
     97e:	00006a17          	auipc	s4,0x6
     982:	99aa0a13          	addi	s4,s4,-1638 # 6318 <malloc+0x668>
    n = write(fds[1], "x", 1);
     986:	00006a97          	auipc	s5,0x6
     98a:	85aa8a93          	addi	s5,s5,-1958 # 61e0 <malloc+0x530>
    uint64 addr = addrs[ai];
     98e:	00093983          	ld	s3,0(s2)
    int fd = open("README", 0);
     992:	4581                	li	a1,0
     994:	8552                	mv	a0,s4
     996:	00005097          	auipc	ra,0x5
     99a:	eca080e7          	jalr	-310(ra) # 5860 <open>
     99e:	84aa                	mv	s1,a0
    if(fd < 0){
     9a0:	08054663          	bltz	a0,a2c <copyout+0xd2>
    int n = read(fd, (void*)addr, 8192);
     9a4:	6609                	lui	a2,0x2
     9a6:	85ce                	mv	a1,s3
     9a8:	00005097          	auipc	ra,0x5
     9ac:	e90080e7          	jalr	-368(ra) # 5838 <read>
    if(n > 0){
     9b0:	08a04b63          	bgtz	a0,a46 <copyout+0xec>
    close(fd);
     9b4:	8526                	mv	a0,s1
     9b6:	00005097          	auipc	ra,0x5
     9ba:	e92080e7          	jalr	-366(ra) # 5848 <close>
    if(pipe(fds) < 0){
     9be:	fa840513          	addi	a0,s0,-88
     9c2:	00005097          	auipc	ra,0x5
     9c6:	e6e080e7          	jalr	-402(ra) # 5830 <pipe>
     9ca:	08054d63          	bltz	a0,a64 <copyout+0x10a>
    n = write(fds[1], "x", 1);
     9ce:	4605                	li	a2,1
     9d0:	85d6                	mv	a1,s5
     9d2:	fac42503          	lw	a0,-84(s0)
     9d6:	00005097          	auipc	ra,0x5
     9da:	e6a080e7          	jalr	-406(ra) # 5840 <write>
    if(n != 1){
     9de:	4785                	li	a5,1
     9e0:	08f51f63          	bne	a0,a5,a7e <copyout+0x124>
    n = read(fds[0], (void*)addr, 8192);
     9e4:	6609                	lui	a2,0x2
     9e6:	85ce                	mv	a1,s3
     9e8:	fa842503          	lw	a0,-88(s0)
     9ec:	00005097          	auipc	ra,0x5
     9f0:	e4c080e7          	jalr	-436(ra) # 5838 <read>
    if(n > 0){
     9f4:	0aa04263          	bgtz	a0,a98 <copyout+0x13e>
    close(fds[0]);
     9f8:	fa842503          	lw	a0,-88(s0)
     9fc:	00005097          	auipc	ra,0x5
     a00:	e4c080e7          	jalr	-436(ra) # 5848 <close>
    close(fds[1]);
     a04:	fac42503          	lw	a0,-84(s0)
     a08:	00005097          	auipc	ra,0x5
     a0c:	e40080e7          	jalr	-448(ra) # 5848 <close>
  for(int ai = 0; ai < 2; ai++){
     a10:	0921                	addi	s2,s2,8
     a12:	fc040793          	addi	a5,s0,-64
     a16:	f6f91ce3          	bne	s2,a5,98e <copyout+0x34>
}
     a1a:	60e6                	ld	ra,88(sp)
     a1c:	6446                	ld	s0,80(sp)
     a1e:	64a6                	ld	s1,72(sp)
     a20:	6906                	ld	s2,64(sp)
     a22:	79e2                	ld	s3,56(sp)
     a24:	7a42                	ld	s4,48(sp)
     a26:	7aa2                	ld	s5,40(sp)
     a28:	6125                	addi	sp,sp,96
     a2a:	8082                	ret
      printf("open(README) failed\n");
     a2c:	00006517          	auipc	a0,0x6
     a30:	8f450513          	addi	a0,a0,-1804 # 6320 <malloc+0x670>
     a34:	00005097          	auipc	ra,0x5
     a38:	1be080e7          	jalr	446(ra) # 5bf2 <printf>
      exit(1);
     a3c:	4505                	li	a0,1
     a3e:	00005097          	auipc	ra,0x5
     a42:	de2080e7          	jalr	-542(ra) # 5820 <exit>
      printf("read(fd, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     a46:	862a                	mv	a2,a0
     a48:	85ce                	mv	a1,s3
     a4a:	00006517          	auipc	a0,0x6
     a4e:	8ee50513          	addi	a0,a0,-1810 # 6338 <malloc+0x688>
     a52:	00005097          	auipc	ra,0x5
     a56:	1a0080e7          	jalr	416(ra) # 5bf2 <printf>
      exit(1);
     a5a:	4505                	li	a0,1
     a5c:	00005097          	auipc	ra,0x5
     a60:	dc4080e7          	jalr	-572(ra) # 5820 <exit>
      printf("pipe() failed\n");
     a64:	00006517          	auipc	a0,0x6
     a68:	87450513          	addi	a0,a0,-1932 # 62d8 <malloc+0x628>
     a6c:	00005097          	auipc	ra,0x5
     a70:	186080e7          	jalr	390(ra) # 5bf2 <printf>
      exit(1);
     a74:	4505                	li	a0,1
     a76:	00005097          	auipc	ra,0x5
     a7a:	daa080e7          	jalr	-598(ra) # 5820 <exit>
      printf("pipe write failed\n");
     a7e:	00006517          	auipc	a0,0x6
     a82:	8ea50513          	addi	a0,a0,-1814 # 6368 <malloc+0x6b8>
     a86:	00005097          	auipc	ra,0x5
     a8a:	16c080e7          	jalr	364(ra) # 5bf2 <printf>
      exit(1);
     a8e:	4505                	li	a0,1
     a90:	00005097          	auipc	ra,0x5
     a94:	d90080e7          	jalr	-624(ra) # 5820 <exit>
      printf("read(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     a98:	862a                	mv	a2,a0
     a9a:	85ce                	mv	a1,s3
     a9c:	00006517          	auipc	a0,0x6
     aa0:	8e450513          	addi	a0,a0,-1820 # 6380 <malloc+0x6d0>
     aa4:	00005097          	auipc	ra,0x5
     aa8:	14e080e7          	jalr	334(ra) # 5bf2 <printf>
      exit(1);
     aac:	4505                	li	a0,1
     aae:	00005097          	auipc	ra,0x5
     ab2:	d72080e7          	jalr	-654(ra) # 5820 <exit>

0000000000000ab6 <truncate1>:
{
     ab6:	711d                	addi	sp,sp,-96
     ab8:	ec86                	sd	ra,88(sp)
     aba:	e8a2                	sd	s0,80(sp)
     abc:	e4a6                	sd	s1,72(sp)
     abe:	e0ca                	sd	s2,64(sp)
     ac0:	fc4e                	sd	s3,56(sp)
     ac2:	f852                	sd	s4,48(sp)
     ac4:	f456                	sd	s5,40(sp)
     ac6:	1080                	addi	s0,sp,96
     ac8:	8aaa                	mv	s5,a0
  unlink("truncfile");
     aca:	00005517          	auipc	a0,0x5
     ace:	6fe50513          	addi	a0,a0,1790 # 61c8 <malloc+0x518>
     ad2:	00005097          	auipc	ra,0x5
     ad6:	d9e080e7          	jalr	-610(ra) # 5870 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
     ada:	60100593          	li	a1,1537
     ade:	00005517          	auipc	a0,0x5
     ae2:	6ea50513          	addi	a0,a0,1770 # 61c8 <malloc+0x518>
     ae6:	00005097          	auipc	ra,0x5
     aea:	d7a080e7          	jalr	-646(ra) # 5860 <open>
     aee:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     af0:	4611                	li	a2,4
     af2:	00005597          	auipc	a1,0x5
     af6:	6e658593          	addi	a1,a1,1766 # 61d8 <malloc+0x528>
     afa:	00005097          	auipc	ra,0x5
     afe:	d46080e7          	jalr	-698(ra) # 5840 <write>
  close(fd1);
     b02:	8526                	mv	a0,s1
     b04:	00005097          	auipc	ra,0x5
     b08:	d44080e7          	jalr	-700(ra) # 5848 <close>
  int fd2 = open("truncfile", O_RDONLY);
     b0c:	4581                	li	a1,0
     b0e:	00005517          	auipc	a0,0x5
     b12:	6ba50513          	addi	a0,a0,1722 # 61c8 <malloc+0x518>
     b16:	00005097          	auipc	ra,0x5
     b1a:	d4a080e7          	jalr	-694(ra) # 5860 <open>
     b1e:	84aa                	mv	s1,a0
  int n = read(fd2, buf, sizeof(buf));
     b20:	02000613          	li	a2,32
     b24:	fa040593          	addi	a1,s0,-96
     b28:	00005097          	auipc	ra,0x5
     b2c:	d10080e7          	jalr	-752(ra) # 5838 <read>
  if(n != 4){
     b30:	4791                	li	a5,4
     b32:	0cf51e63          	bne	a0,a5,c0e <truncate1+0x158>
  fd1 = open("truncfile", O_WRONLY|O_TRUNC);
     b36:	40100593          	li	a1,1025
     b3a:	00005517          	auipc	a0,0x5
     b3e:	68e50513          	addi	a0,a0,1678 # 61c8 <malloc+0x518>
     b42:	00005097          	auipc	ra,0x5
     b46:	d1e080e7          	jalr	-738(ra) # 5860 <open>
     b4a:	89aa                	mv	s3,a0
  int fd3 = open("truncfile", O_RDONLY);
     b4c:	4581                	li	a1,0
     b4e:	00005517          	auipc	a0,0x5
     b52:	67a50513          	addi	a0,a0,1658 # 61c8 <malloc+0x518>
     b56:	00005097          	auipc	ra,0x5
     b5a:	d0a080e7          	jalr	-758(ra) # 5860 <open>
     b5e:	892a                	mv	s2,a0
  n = read(fd3, buf, sizeof(buf));
     b60:	02000613          	li	a2,32
     b64:	fa040593          	addi	a1,s0,-96
     b68:	00005097          	auipc	ra,0x5
     b6c:	cd0080e7          	jalr	-816(ra) # 5838 <read>
     b70:	8a2a                	mv	s4,a0
  if(n != 0){
     b72:	ed4d                	bnez	a0,c2c <truncate1+0x176>
  n = read(fd2, buf, sizeof(buf));
     b74:	02000613          	li	a2,32
     b78:	fa040593          	addi	a1,s0,-96
     b7c:	8526                	mv	a0,s1
     b7e:	00005097          	auipc	ra,0x5
     b82:	cba080e7          	jalr	-838(ra) # 5838 <read>
     b86:	8a2a                	mv	s4,a0
  if(n != 0){
     b88:	e971                	bnez	a0,c5c <truncate1+0x1a6>
  write(fd1, "abcdef", 6);
     b8a:	4619                	li	a2,6
     b8c:	00006597          	auipc	a1,0x6
     b90:	88458593          	addi	a1,a1,-1916 # 6410 <malloc+0x760>
     b94:	854e                	mv	a0,s3
     b96:	00005097          	auipc	ra,0x5
     b9a:	caa080e7          	jalr	-854(ra) # 5840 <write>
  n = read(fd3, buf, sizeof(buf));
     b9e:	02000613          	li	a2,32
     ba2:	fa040593          	addi	a1,s0,-96
     ba6:	854a                	mv	a0,s2
     ba8:	00005097          	auipc	ra,0x5
     bac:	c90080e7          	jalr	-880(ra) # 5838 <read>
  if(n != 6){
     bb0:	4799                	li	a5,6
     bb2:	0cf51d63          	bne	a0,a5,c8c <truncate1+0x1d6>
  n = read(fd2, buf, sizeof(buf));
     bb6:	02000613          	li	a2,32
     bba:	fa040593          	addi	a1,s0,-96
     bbe:	8526                	mv	a0,s1
     bc0:	00005097          	auipc	ra,0x5
     bc4:	c78080e7          	jalr	-904(ra) # 5838 <read>
  if(n != 2){
     bc8:	4789                	li	a5,2
     bca:	0ef51063          	bne	a0,a5,caa <truncate1+0x1f4>
  unlink("truncfile");
     bce:	00005517          	auipc	a0,0x5
     bd2:	5fa50513          	addi	a0,a0,1530 # 61c8 <malloc+0x518>
     bd6:	00005097          	auipc	ra,0x5
     bda:	c9a080e7          	jalr	-870(ra) # 5870 <unlink>
  close(fd1);
     bde:	854e                	mv	a0,s3
     be0:	00005097          	auipc	ra,0x5
     be4:	c68080e7          	jalr	-920(ra) # 5848 <close>
  close(fd2);
     be8:	8526                	mv	a0,s1
     bea:	00005097          	auipc	ra,0x5
     bee:	c5e080e7          	jalr	-930(ra) # 5848 <close>
  close(fd3);
     bf2:	854a                	mv	a0,s2
     bf4:	00005097          	auipc	ra,0x5
     bf8:	c54080e7          	jalr	-940(ra) # 5848 <close>
}
     bfc:	60e6                	ld	ra,88(sp)
     bfe:	6446                	ld	s0,80(sp)
     c00:	64a6                	ld	s1,72(sp)
     c02:	6906                	ld	s2,64(sp)
     c04:	79e2                	ld	s3,56(sp)
     c06:	7a42                	ld	s4,48(sp)
     c08:	7aa2                	ld	s5,40(sp)
     c0a:	6125                	addi	sp,sp,96
     c0c:	8082                	ret
    printf("%s: read %d bytes, wanted 4\n", s, n);
     c0e:	862a                	mv	a2,a0
     c10:	85d6                	mv	a1,s5
     c12:	00005517          	auipc	a0,0x5
     c16:	79e50513          	addi	a0,a0,1950 # 63b0 <malloc+0x700>
     c1a:	00005097          	auipc	ra,0x5
     c1e:	fd8080e7          	jalr	-40(ra) # 5bf2 <printf>
    exit(1);
     c22:	4505                	li	a0,1
     c24:	00005097          	auipc	ra,0x5
     c28:	bfc080e7          	jalr	-1028(ra) # 5820 <exit>
    printf("aaa fd3=%d\n", fd3);
     c2c:	85ca                	mv	a1,s2
     c2e:	00005517          	auipc	a0,0x5
     c32:	7a250513          	addi	a0,a0,1954 # 63d0 <malloc+0x720>
     c36:	00005097          	auipc	ra,0x5
     c3a:	fbc080e7          	jalr	-68(ra) # 5bf2 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     c3e:	8652                	mv	a2,s4
     c40:	85d6                	mv	a1,s5
     c42:	00005517          	auipc	a0,0x5
     c46:	79e50513          	addi	a0,a0,1950 # 63e0 <malloc+0x730>
     c4a:	00005097          	auipc	ra,0x5
     c4e:	fa8080e7          	jalr	-88(ra) # 5bf2 <printf>
    exit(1);
     c52:	4505                	li	a0,1
     c54:	00005097          	auipc	ra,0x5
     c58:	bcc080e7          	jalr	-1076(ra) # 5820 <exit>
    printf("bbb fd2=%d\n", fd2);
     c5c:	85a6                	mv	a1,s1
     c5e:	00005517          	auipc	a0,0x5
     c62:	7a250513          	addi	a0,a0,1954 # 6400 <malloc+0x750>
     c66:	00005097          	auipc	ra,0x5
     c6a:	f8c080e7          	jalr	-116(ra) # 5bf2 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     c6e:	8652                	mv	a2,s4
     c70:	85d6                	mv	a1,s5
     c72:	00005517          	auipc	a0,0x5
     c76:	76e50513          	addi	a0,a0,1902 # 63e0 <malloc+0x730>
     c7a:	00005097          	auipc	ra,0x5
     c7e:	f78080e7          	jalr	-136(ra) # 5bf2 <printf>
    exit(1);
     c82:	4505                	li	a0,1
     c84:	00005097          	auipc	ra,0x5
     c88:	b9c080e7          	jalr	-1124(ra) # 5820 <exit>
    printf("%s: read %d bytes, wanted 6\n", s, n);
     c8c:	862a                	mv	a2,a0
     c8e:	85d6                	mv	a1,s5
     c90:	00005517          	auipc	a0,0x5
     c94:	78850513          	addi	a0,a0,1928 # 6418 <malloc+0x768>
     c98:	00005097          	auipc	ra,0x5
     c9c:	f5a080e7          	jalr	-166(ra) # 5bf2 <printf>
    exit(1);
     ca0:	4505                	li	a0,1
     ca2:	00005097          	auipc	ra,0x5
     ca6:	b7e080e7          	jalr	-1154(ra) # 5820 <exit>
    printf("%s: read %d bytes, wanted 2\n", s, n);
     caa:	862a                	mv	a2,a0
     cac:	85d6                	mv	a1,s5
     cae:	00005517          	auipc	a0,0x5
     cb2:	78a50513          	addi	a0,a0,1930 # 6438 <malloc+0x788>
     cb6:	00005097          	auipc	ra,0x5
     cba:	f3c080e7          	jalr	-196(ra) # 5bf2 <printf>
    exit(1);
     cbe:	4505                	li	a0,1
     cc0:	00005097          	auipc	ra,0x5
     cc4:	b60080e7          	jalr	-1184(ra) # 5820 <exit>

0000000000000cc8 <pipe1>:
{
     cc8:	711d                	addi	sp,sp,-96
     cca:	ec86                	sd	ra,88(sp)
     ccc:	e8a2                	sd	s0,80(sp)
     cce:	e4a6                	sd	s1,72(sp)
     cd0:	e0ca                	sd	s2,64(sp)
     cd2:	fc4e                	sd	s3,56(sp)
     cd4:	f852                	sd	s4,48(sp)
     cd6:	f456                	sd	s5,40(sp)
     cd8:	f05a                	sd	s6,32(sp)
     cda:	ec5e                	sd	s7,24(sp)
     cdc:	1080                	addi	s0,sp,96
     cde:	892a                	mv	s2,a0
  if(pipe(fds) != 0){
     ce0:	fa840513          	addi	a0,s0,-88
     ce4:	00005097          	auipc	ra,0x5
     ce8:	b4c080e7          	jalr	-1204(ra) # 5830 <pipe>
     cec:	ed25                	bnez	a0,d64 <pipe1+0x9c>
     cee:	84aa                	mv	s1,a0
  pid = fork();
     cf0:	00005097          	auipc	ra,0x5
     cf4:	b28080e7          	jalr	-1240(ra) # 5818 <fork>
     cf8:	8a2a                	mv	s4,a0
  if(pid == 0){
     cfa:	c159                	beqz	a0,d80 <pipe1+0xb8>
  } else if(pid > 0){
     cfc:	16a05e63          	blez	a0,e78 <pipe1+0x1b0>
    close(fds[1]);
     d00:	fac42503          	lw	a0,-84(s0)
     d04:	00005097          	auipc	ra,0x5
     d08:	b44080e7          	jalr	-1212(ra) # 5848 <close>
    total = 0;
     d0c:	8a26                	mv	s4,s1
    cc = 1;
     d0e:	4985                	li	s3,1
    while((n = read(fds[0], buf, cc)) > 0){
     d10:	0000ba97          	auipc	s5,0xb
     d14:	ea0a8a93          	addi	s5,s5,-352 # bbb0 <buf>
      if(cc > sizeof(buf))
     d18:	6b0d                	lui	s6,0x3
    while((n = read(fds[0], buf, cc)) > 0){
     d1a:	864e                	mv	a2,s3
     d1c:	85d6                	mv	a1,s5
     d1e:	fa842503          	lw	a0,-88(s0)
     d22:	00005097          	auipc	ra,0x5
     d26:	b16080e7          	jalr	-1258(ra) # 5838 <read>
     d2a:	10a05263          	blez	a0,e2e <pipe1+0x166>
      for(i = 0; i < n; i++){
     d2e:	0000b717          	auipc	a4,0xb
     d32:	e8270713          	addi	a4,a4,-382 # bbb0 <buf>
     d36:	00a4863b          	addw	a2,s1,a0
        if((buf[i] & 0xff) != (seq++ & 0xff)){
     d3a:	00074683          	lbu	a3,0(a4)
     d3e:	0ff4f793          	andi	a5,s1,255
     d42:	2485                	addiw	s1,s1,1
     d44:	0cf69163          	bne	a3,a5,e06 <pipe1+0x13e>
      for(i = 0; i < n; i++){
     d48:	0705                	addi	a4,a4,1
     d4a:	fec498e3          	bne	s1,a2,d3a <pipe1+0x72>
      total += n;
     d4e:	00aa0a3b          	addw	s4,s4,a0
      cc = cc * 2;
     d52:	0019979b          	slliw	a5,s3,0x1
     d56:	0007899b          	sext.w	s3,a5
      if(cc > sizeof(buf))
     d5a:	013b7363          	bgeu	s6,s3,d60 <pipe1+0x98>
        cc = sizeof(buf);
     d5e:	89da                	mv	s3,s6
        if((buf[i] & 0xff) != (seq++ & 0xff)){
     d60:	84b2                	mv	s1,a2
     d62:	bf65                	j	d1a <pipe1+0x52>
    printf("%s: pipe() failed\n", s);
     d64:	85ca                	mv	a1,s2
     d66:	00005517          	auipc	a0,0x5
     d6a:	6f250513          	addi	a0,a0,1778 # 6458 <malloc+0x7a8>
     d6e:	00005097          	auipc	ra,0x5
     d72:	e84080e7          	jalr	-380(ra) # 5bf2 <printf>
    exit(1);
     d76:	4505                	li	a0,1
     d78:	00005097          	auipc	ra,0x5
     d7c:	aa8080e7          	jalr	-1368(ra) # 5820 <exit>
    close(fds[0]);
     d80:	fa842503          	lw	a0,-88(s0)
     d84:	00005097          	auipc	ra,0x5
     d88:	ac4080e7          	jalr	-1340(ra) # 5848 <close>
    for(n = 0; n < N; n++){
     d8c:	0000bb17          	auipc	s6,0xb
     d90:	e24b0b13          	addi	s6,s6,-476 # bbb0 <buf>
     d94:	416004bb          	negw	s1,s6
     d98:	0ff4f493          	andi	s1,s1,255
     d9c:	409b0993          	addi	s3,s6,1033
      if(write(fds[1], buf, SZ) != SZ){
     da0:	8bda                	mv	s7,s6
    for(n = 0; n < N; n++){
     da2:	6a85                	lui	s5,0x1
     da4:	42da8a93          	addi	s5,s5,1069 # 142d <linktest+0x239>
{
     da8:	87da                	mv	a5,s6
        buf[i] = seq++;
     daa:	0097873b          	addw	a4,a5,s1
     dae:	00e78023          	sb	a4,0(a5)
      for(i = 0; i < SZ; i++)
     db2:	0785                	addi	a5,a5,1
     db4:	fef99be3          	bne	s3,a5,daa <pipe1+0xe2>
        buf[i] = seq++;
     db8:	409a0a1b          	addiw	s4,s4,1033
      if(write(fds[1], buf, SZ) != SZ){
     dbc:	40900613          	li	a2,1033
     dc0:	85de                	mv	a1,s7
     dc2:	fac42503          	lw	a0,-84(s0)
     dc6:	00005097          	auipc	ra,0x5
     dca:	a7a080e7          	jalr	-1414(ra) # 5840 <write>
     dce:	40900793          	li	a5,1033
     dd2:	00f51c63          	bne	a0,a5,dea <pipe1+0x122>
    for(n = 0; n < N; n++){
     dd6:	24a5                	addiw	s1,s1,9
     dd8:	0ff4f493          	andi	s1,s1,255
     ddc:	fd5a16e3          	bne	s4,s5,da8 <pipe1+0xe0>
    exit(0);
     de0:	4501                	li	a0,0
     de2:	00005097          	auipc	ra,0x5
     de6:	a3e080e7          	jalr	-1474(ra) # 5820 <exit>
        printf("%s: pipe1 oops 1\n", s);
     dea:	85ca                	mv	a1,s2
     dec:	00005517          	auipc	a0,0x5
     df0:	68450513          	addi	a0,a0,1668 # 6470 <malloc+0x7c0>
     df4:	00005097          	auipc	ra,0x5
     df8:	dfe080e7          	jalr	-514(ra) # 5bf2 <printf>
        exit(1);
     dfc:	4505                	li	a0,1
     dfe:	00005097          	auipc	ra,0x5
     e02:	a22080e7          	jalr	-1502(ra) # 5820 <exit>
          printf("%s: pipe1 oops 2\n", s);
     e06:	85ca                	mv	a1,s2
     e08:	00005517          	auipc	a0,0x5
     e0c:	68050513          	addi	a0,a0,1664 # 6488 <malloc+0x7d8>
     e10:	00005097          	auipc	ra,0x5
     e14:	de2080e7          	jalr	-542(ra) # 5bf2 <printf>
}
     e18:	60e6                	ld	ra,88(sp)
     e1a:	6446                	ld	s0,80(sp)
     e1c:	64a6                	ld	s1,72(sp)
     e1e:	6906                	ld	s2,64(sp)
     e20:	79e2                	ld	s3,56(sp)
     e22:	7a42                	ld	s4,48(sp)
     e24:	7aa2                	ld	s5,40(sp)
     e26:	7b02                	ld	s6,32(sp)
     e28:	6be2                	ld	s7,24(sp)
     e2a:	6125                	addi	sp,sp,96
     e2c:	8082                	ret
    if(total != N * SZ){
     e2e:	6785                	lui	a5,0x1
     e30:	42d78793          	addi	a5,a5,1069 # 142d <linktest+0x239>
     e34:	02fa0063          	beq	s4,a5,e54 <pipe1+0x18c>
      printf("%s: pipe1 oops 3 total %d\n", total);
     e38:	85d2                	mv	a1,s4
     e3a:	00005517          	auipc	a0,0x5
     e3e:	66650513          	addi	a0,a0,1638 # 64a0 <malloc+0x7f0>
     e42:	00005097          	auipc	ra,0x5
     e46:	db0080e7          	jalr	-592(ra) # 5bf2 <printf>
      exit(1);
     e4a:	4505                	li	a0,1
     e4c:	00005097          	auipc	ra,0x5
     e50:	9d4080e7          	jalr	-1580(ra) # 5820 <exit>
    close(fds[0]);
     e54:	fa842503          	lw	a0,-88(s0)
     e58:	00005097          	auipc	ra,0x5
     e5c:	9f0080e7          	jalr	-1552(ra) # 5848 <close>
    wait(&xstatus);
     e60:	fa440513          	addi	a0,s0,-92
     e64:	00005097          	auipc	ra,0x5
     e68:	9c4080e7          	jalr	-1596(ra) # 5828 <wait>
    exit(xstatus);
     e6c:	fa442503          	lw	a0,-92(s0)
     e70:	00005097          	auipc	ra,0x5
     e74:	9b0080e7          	jalr	-1616(ra) # 5820 <exit>
    printf("%s: fork() failed\n", s);
     e78:	85ca                	mv	a1,s2
     e7a:	00005517          	auipc	a0,0x5
     e7e:	64650513          	addi	a0,a0,1606 # 64c0 <malloc+0x810>
     e82:	00005097          	auipc	ra,0x5
     e86:	d70080e7          	jalr	-656(ra) # 5bf2 <printf>
    exit(1);
     e8a:	4505                	li	a0,1
     e8c:	00005097          	auipc	ra,0x5
     e90:	994080e7          	jalr	-1644(ra) # 5820 <exit>

0000000000000e94 <preempt>:
{
     e94:	7139                	addi	sp,sp,-64
     e96:	fc06                	sd	ra,56(sp)
     e98:	f822                	sd	s0,48(sp)
     e9a:	f426                	sd	s1,40(sp)
     e9c:	f04a                	sd	s2,32(sp)
     e9e:	ec4e                	sd	s3,24(sp)
     ea0:	e852                	sd	s4,16(sp)
     ea2:	0080                	addi	s0,sp,64
     ea4:	892a                	mv	s2,a0
  pid1 = fork();
     ea6:	00005097          	auipc	ra,0x5
     eaa:	972080e7          	jalr	-1678(ra) # 5818 <fork>
  if(pid1 < 0) {
     eae:	00054563          	bltz	a0,eb8 <preempt+0x24>
     eb2:	84aa                	mv	s1,a0
  if(pid1 == 0)
     eb4:	e105                	bnez	a0,ed4 <preempt+0x40>
    for(;;)
     eb6:	a001                	j	eb6 <preempt+0x22>
    printf("%s: fork failed", s);
     eb8:	85ca                	mv	a1,s2
     eba:	00005517          	auipc	a0,0x5
     ebe:	1be50513          	addi	a0,a0,446 # 6078 <malloc+0x3c8>
     ec2:	00005097          	auipc	ra,0x5
     ec6:	d30080e7          	jalr	-720(ra) # 5bf2 <printf>
    exit(1);
     eca:	4505                	li	a0,1
     ecc:	00005097          	auipc	ra,0x5
     ed0:	954080e7          	jalr	-1708(ra) # 5820 <exit>
  pid2 = fork();
     ed4:	00005097          	auipc	ra,0x5
     ed8:	944080e7          	jalr	-1724(ra) # 5818 <fork>
     edc:	89aa                	mv	s3,a0
  if(pid2 < 0) {
     ede:	00054463          	bltz	a0,ee6 <preempt+0x52>
  if(pid2 == 0)
     ee2:	e105                	bnez	a0,f02 <preempt+0x6e>
    for(;;)
     ee4:	a001                	j	ee4 <preempt+0x50>
    printf("%s: fork failed\n", s);
     ee6:	85ca                	mv	a1,s2
     ee8:	00005517          	auipc	a0,0x5
     eec:	14050513          	addi	a0,a0,320 # 6028 <malloc+0x378>
     ef0:	00005097          	auipc	ra,0x5
     ef4:	d02080e7          	jalr	-766(ra) # 5bf2 <printf>
    exit(1);
     ef8:	4505                	li	a0,1
     efa:	00005097          	auipc	ra,0x5
     efe:	926080e7          	jalr	-1754(ra) # 5820 <exit>
  pipe(pfds);
     f02:	fc840513          	addi	a0,s0,-56
     f06:	00005097          	auipc	ra,0x5
     f0a:	92a080e7          	jalr	-1750(ra) # 5830 <pipe>
  pid3 = fork();
     f0e:	00005097          	auipc	ra,0x5
     f12:	90a080e7          	jalr	-1782(ra) # 5818 <fork>
     f16:	8a2a                	mv	s4,a0
  if(pid3 < 0) {
     f18:	02054e63          	bltz	a0,f54 <preempt+0xc0>
  if(pid3 == 0){
     f1c:	e525                	bnez	a0,f84 <preempt+0xf0>
    close(pfds[0]);
     f1e:	fc842503          	lw	a0,-56(s0)
     f22:	00005097          	auipc	ra,0x5
     f26:	926080e7          	jalr	-1754(ra) # 5848 <close>
    if(write(pfds[1], "x", 1) != 1)
     f2a:	4605                	li	a2,1
     f2c:	00005597          	auipc	a1,0x5
     f30:	2b458593          	addi	a1,a1,692 # 61e0 <malloc+0x530>
     f34:	fcc42503          	lw	a0,-52(s0)
     f38:	00005097          	auipc	ra,0x5
     f3c:	908080e7          	jalr	-1784(ra) # 5840 <write>
     f40:	4785                	li	a5,1
     f42:	02f51763          	bne	a0,a5,f70 <preempt+0xdc>
    close(pfds[1]);
     f46:	fcc42503          	lw	a0,-52(s0)
     f4a:	00005097          	auipc	ra,0x5
     f4e:	8fe080e7          	jalr	-1794(ra) # 5848 <close>
    for(;;)
     f52:	a001                	j	f52 <preempt+0xbe>
     printf("%s: fork failed\n", s);
     f54:	85ca                	mv	a1,s2
     f56:	00005517          	auipc	a0,0x5
     f5a:	0d250513          	addi	a0,a0,210 # 6028 <malloc+0x378>
     f5e:	00005097          	auipc	ra,0x5
     f62:	c94080e7          	jalr	-876(ra) # 5bf2 <printf>
     exit(1);
     f66:	4505                	li	a0,1
     f68:	00005097          	auipc	ra,0x5
     f6c:	8b8080e7          	jalr	-1864(ra) # 5820 <exit>
      printf("%s: preempt write error", s);
     f70:	85ca                	mv	a1,s2
     f72:	00005517          	auipc	a0,0x5
     f76:	56650513          	addi	a0,a0,1382 # 64d8 <malloc+0x828>
     f7a:	00005097          	auipc	ra,0x5
     f7e:	c78080e7          	jalr	-904(ra) # 5bf2 <printf>
     f82:	b7d1                	j	f46 <preempt+0xb2>
  close(pfds[1]);
     f84:	fcc42503          	lw	a0,-52(s0)
     f88:	00005097          	auipc	ra,0x5
     f8c:	8c0080e7          	jalr	-1856(ra) # 5848 <close>
  if(read(pfds[0], buf, sizeof(buf)) != 1){
     f90:	660d                	lui	a2,0x3
     f92:	0000b597          	auipc	a1,0xb
     f96:	c1e58593          	addi	a1,a1,-994 # bbb0 <buf>
     f9a:	fc842503          	lw	a0,-56(s0)
     f9e:	00005097          	auipc	ra,0x5
     fa2:	89a080e7          	jalr	-1894(ra) # 5838 <read>
     fa6:	4785                	li	a5,1
     fa8:	02f50363          	beq	a0,a5,fce <preempt+0x13a>
    printf("%s: preempt read error", s);
     fac:	85ca                	mv	a1,s2
     fae:	00005517          	auipc	a0,0x5
     fb2:	54250513          	addi	a0,a0,1346 # 64f0 <malloc+0x840>
     fb6:	00005097          	auipc	ra,0x5
     fba:	c3c080e7          	jalr	-964(ra) # 5bf2 <printf>
}
     fbe:	70e2                	ld	ra,56(sp)
     fc0:	7442                	ld	s0,48(sp)
     fc2:	74a2                	ld	s1,40(sp)
     fc4:	7902                	ld	s2,32(sp)
     fc6:	69e2                	ld	s3,24(sp)
     fc8:	6a42                	ld	s4,16(sp)
     fca:	6121                	addi	sp,sp,64
     fcc:	8082                	ret
  close(pfds[0]);
     fce:	fc842503          	lw	a0,-56(s0)
     fd2:	00005097          	auipc	ra,0x5
     fd6:	876080e7          	jalr	-1930(ra) # 5848 <close>
  printf("kill... ");
     fda:	00005517          	auipc	a0,0x5
     fde:	52e50513          	addi	a0,a0,1326 # 6508 <malloc+0x858>
     fe2:	00005097          	auipc	ra,0x5
     fe6:	c10080e7          	jalr	-1008(ra) # 5bf2 <printf>
  kill(pid1, SIGKILL);
     fea:	45a5                	li	a1,9
     fec:	8526                	mv	a0,s1
     fee:	00005097          	auipc	ra,0x5
     ff2:	862080e7          	jalr	-1950(ra) # 5850 <kill>
  kill(pid2, SIGKILL);
     ff6:	45a5                	li	a1,9
     ff8:	854e                	mv	a0,s3
     ffa:	00005097          	auipc	ra,0x5
     ffe:	856080e7          	jalr	-1962(ra) # 5850 <kill>
  kill(pid3, SIGKILL);
    1002:	45a5                	li	a1,9
    1004:	8552                	mv	a0,s4
    1006:	00005097          	auipc	ra,0x5
    100a:	84a080e7          	jalr	-1974(ra) # 5850 <kill>
  printf("wait... ");
    100e:	00005517          	auipc	a0,0x5
    1012:	50a50513          	addi	a0,a0,1290 # 6518 <malloc+0x868>
    1016:	00005097          	auipc	ra,0x5
    101a:	bdc080e7          	jalr	-1060(ra) # 5bf2 <printf>
  wait(0);
    101e:	4501                	li	a0,0
    1020:	00005097          	auipc	ra,0x5
    1024:	808080e7          	jalr	-2040(ra) # 5828 <wait>
  wait(0);
    1028:	4501                	li	a0,0
    102a:	00004097          	auipc	ra,0x4
    102e:	7fe080e7          	jalr	2046(ra) # 5828 <wait>
  wait(0);
    1032:	4501                	li	a0,0
    1034:	00004097          	auipc	ra,0x4
    1038:	7f4080e7          	jalr	2036(ra) # 5828 <wait>
    103c:	b749                	j	fbe <preempt+0x12a>

000000000000103e <unlinkread>:
{
    103e:	7179                	addi	sp,sp,-48
    1040:	f406                	sd	ra,40(sp)
    1042:	f022                	sd	s0,32(sp)
    1044:	ec26                	sd	s1,24(sp)
    1046:	e84a                	sd	s2,16(sp)
    1048:	e44e                	sd	s3,8(sp)
    104a:	1800                	addi	s0,sp,48
    104c:	89aa                	mv	s3,a0
  fd = open("unlinkread", O_CREATE | O_RDWR);
    104e:	20200593          	li	a1,514
    1052:	00005517          	auipc	a0,0x5
    1056:	e5e50513          	addi	a0,a0,-418 # 5eb0 <malloc+0x200>
    105a:	00005097          	auipc	ra,0x5
    105e:	806080e7          	jalr	-2042(ra) # 5860 <open>
  if(fd < 0){
    1062:	0e054563          	bltz	a0,114c <unlinkread+0x10e>
    1066:	84aa                	mv	s1,a0
  write(fd, "hello", SZ);
    1068:	4615                	li	a2,5
    106a:	00005597          	auipc	a1,0x5
    106e:	4de58593          	addi	a1,a1,1246 # 6548 <malloc+0x898>
    1072:	00004097          	auipc	ra,0x4
    1076:	7ce080e7          	jalr	1998(ra) # 5840 <write>
  close(fd);
    107a:	8526                	mv	a0,s1
    107c:	00004097          	auipc	ra,0x4
    1080:	7cc080e7          	jalr	1996(ra) # 5848 <close>
  fd = open("unlinkread", O_RDWR);
    1084:	4589                	li	a1,2
    1086:	00005517          	auipc	a0,0x5
    108a:	e2a50513          	addi	a0,a0,-470 # 5eb0 <malloc+0x200>
    108e:	00004097          	auipc	ra,0x4
    1092:	7d2080e7          	jalr	2002(ra) # 5860 <open>
    1096:	84aa                	mv	s1,a0
  if(fd < 0){
    1098:	0c054863          	bltz	a0,1168 <unlinkread+0x12a>
  if(unlink("unlinkread") != 0){
    109c:	00005517          	auipc	a0,0x5
    10a0:	e1450513          	addi	a0,a0,-492 # 5eb0 <malloc+0x200>
    10a4:	00004097          	auipc	ra,0x4
    10a8:	7cc080e7          	jalr	1996(ra) # 5870 <unlink>
    10ac:	ed61                	bnez	a0,1184 <unlinkread+0x146>
  fd1 = open("unlinkread", O_CREATE | O_RDWR);
    10ae:	20200593          	li	a1,514
    10b2:	00005517          	auipc	a0,0x5
    10b6:	dfe50513          	addi	a0,a0,-514 # 5eb0 <malloc+0x200>
    10ba:	00004097          	auipc	ra,0x4
    10be:	7a6080e7          	jalr	1958(ra) # 5860 <open>
    10c2:	892a                	mv	s2,a0
  write(fd1, "yyy", 3);
    10c4:	460d                	li	a2,3
    10c6:	00005597          	auipc	a1,0x5
    10ca:	4ca58593          	addi	a1,a1,1226 # 6590 <malloc+0x8e0>
    10ce:	00004097          	auipc	ra,0x4
    10d2:	772080e7          	jalr	1906(ra) # 5840 <write>
  close(fd1);
    10d6:	854a                	mv	a0,s2
    10d8:	00004097          	auipc	ra,0x4
    10dc:	770080e7          	jalr	1904(ra) # 5848 <close>
  if(read(fd, buf, sizeof(buf)) != SZ){
    10e0:	660d                	lui	a2,0x3
    10e2:	0000b597          	auipc	a1,0xb
    10e6:	ace58593          	addi	a1,a1,-1330 # bbb0 <buf>
    10ea:	8526                	mv	a0,s1
    10ec:	00004097          	auipc	ra,0x4
    10f0:	74c080e7          	jalr	1868(ra) # 5838 <read>
    10f4:	4795                	li	a5,5
    10f6:	0af51563          	bne	a0,a5,11a0 <unlinkread+0x162>
  if(buf[0] != 'h'){
    10fa:	0000b717          	auipc	a4,0xb
    10fe:	ab674703          	lbu	a4,-1354(a4) # bbb0 <buf>
    1102:	06800793          	li	a5,104
    1106:	0af71b63          	bne	a4,a5,11bc <unlinkread+0x17e>
  if(write(fd, buf, 10) != 10){
    110a:	4629                	li	a2,10
    110c:	0000b597          	auipc	a1,0xb
    1110:	aa458593          	addi	a1,a1,-1372 # bbb0 <buf>
    1114:	8526                	mv	a0,s1
    1116:	00004097          	auipc	ra,0x4
    111a:	72a080e7          	jalr	1834(ra) # 5840 <write>
    111e:	47a9                	li	a5,10
    1120:	0af51c63          	bne	a0,a5,11d8 <unlinkread+0x19a>
  close(fd);
    1124:	8526                	mv	a0,s1
    1126:	00004097          	auipc	ra,0x4
    112a:	722080e7          	jalr	1826(ra) # 5848 <close>
  unlink("unlinkread");
    112e:	00005517          	auipc	a0,0x5
    1132:	d8250513          	addi	a0,a0,-638 # 5eb0 <malloc+0x200>
    1136:	00004097          	auipc	ra,0x4
    113a:	73a080e7          	jalr	1850(ra) # 5870 <unlink>
}
    113e:	70a2                	ld	ra,40(sp)
    1140:	7402                	ld	s0,32(sp)
    1142:	64e2                	ld	s1,24(sp)
    1144:	6942                	ld	s2,16(sp)
    1146:	69a2                	ld	s3,8(sp)
    1148:	6145                	addi	sp,sp,48
    114a:	8082                	ret
    printf("%s: create unlinkread failed\n", s);
    114c:	85ce                	mv	a1,s3
    114e:	00005517          	auipc	a0,0x5
    1152:	3da50513          	addi	a0,a0,986 # 6528 <malloc+0x878>
    1156:	00005097          	auipc	ra,0x5
    115a:	a9c080e7          	jalr	-1380(ra) # 5bf2 <printf>
    exit(1);
    115e:	4505                	li	a0,1
    1160:	00004097          	auipc	ra,0x4
    1164:	6c0080e7          	jalr	1728(ra) # 5820 <exit>
    printf("%s: open unlinkread failed\n", s);
    1168:	85ce                	mv	a1,s3
    116a:	00005517          	auipc	a0,0x5
    116e:	3e650513          	addi	a0,a0,998 # 6550 <malloc+0x8a0>
    1172:	00005097          	auipc	ra,0x5
    1176:	a80080e7          	jalr	-1408(ra) # 5bf2 <printf>
    exit(1);
    117a:	4505                	li	a0,1
    117c:	00004097          	auipc	ra,0x4
    1180:	6a4080e7          	jalr	1700(ra) # 5820 <exit>
    printf("%s: unlink unlinkread failed\n", s);
    1184:	85ce                	mv	a1,s3
    1186:	00005517          	auipc	a0,0x5
    118a:	3ea50513          	addi	a0,a0,1002 # 6570 <malloc+0x8c0>
    118e:	00005097          	auipc	ra,0x5
    1192:	a64080e7          	jalr	-1436(ra) # 5bf2 <printf>
    exit(1);
    1196:	4505                	li	a0,1
    1198:	00004097          	auipc	ra,0x4
    119c:	688080e7          	jalr	1672(ra) # 5820 <exit>
    printf("%s: unlinkread read failed", s);
    11a0:	85ce                	mv	a1,s3
    11a2:	00005517          	auipc	a0,0x5
    11a6:	3f650513          	addi	a0,a0,1014 # 6598 <malloc+0x8e8>
    11aa:	00005097          	auipc	ra,0x5
    11ae:	a48080e7          	jalr	-1464(ra) # 5bf2 <printf>
    exit(1);
    11b2:	4505                	li	a0,1
    11b4:	00004097          	auipc	ra,0x4
    11b8:	66c080e7          	jalr	1644(ra) # 5820 <exit>
    printf("%s: unlinkread wrong data\n", s);
    11bc:	85ce                	mv	a1,s3
    11be:	00005517          	auipc	a0,0x5
    11c2:	3fa50513          	addi	a0,a0,1018 # 65b8 <malloc+0x908>
    11c6:	00005097          	auipc	ra,0x5
    11ca:	a2c080e7          	jalr	-1492(ra) # 5bf2 <printf>
    exit(1);
    11ce:	4505                	li	a0,1
    11d0:	00004097          	auipc	ra,0x4
    11d4:	650080e7          	jalr	1616(ra) # 5820 <exit>
    printf("%s: unlinkread write failed\n", s);
    11d8:	85ce                	mv	a1,s3
    11da:	00005517          	auipc	a0,0x5
    11de:	3fe50513          	addi	a0,a0,1022 # 65d8 <malloc+0x928>
    11e2:	00005097          	auipc	ra,0x5
    11e6:	a10080e7          	jalr	-1520(ra) # 5bf2 <printf>
    exit(1);
    11ea:	4505                	li	a0,1
    11ec:	00004097          	auipc	ra,0x4
    11f0:	634080e7          	jalr	1588(ra) # 5820 <exit>

00000000000011f4 <linktest>:
{
    11f4:	1101                	addi	sp,sp,-32
    11f6:	ec06                	sd	ra,24(sp)
    11f8:	e822                	sd	s0,16(sp)
    11fa:	e426                	sd	s1,8(sp)
    11fc:	e04a                	sd	s2,0(sp)
    11fe:	1000                	addi	s0,sp,32
    1200:	892a                	mv	s2,a0
  unlink("lf1");
    1202:	00005517          	auipc	a0,0x5
    1206:	3f650513          	addi	a0,a0,1014 # 65f8 <malloc+0x948>
    120a:	00004097          	auipc	ra,0x4
    120e:	666080e7          	jalr	1638(ra) # 5870 <unlink>
  unlink("lf2");
    1212:	00005517          	auipc	a0,0x5
    1216:	3ee50513          	addi	a0,a0,1006 # 6600 <malloc+0x950>
    121a:	00004097          	auipc	ra,0x4
    121e:	656080e7          	jalr	1622(ra) # 5870 <unlink>
  fd = open("lf1", O_CREATE|O_RDWR);
    1222:	20200593          	li	a1,514
    1226:	00005517          	auipc	a0,0x5
    122a:	3d250513          	addi	a0,a0,978 # 65f8 <malloc+0x948>
    122e:	00004097          	auipc	ra,0x4
    1232:	632080e7          	jalr	1586(ra) # 5860 <open>
  if(fd < 0){
    1236:	10054763          	bltz	a0,1344 <linktest+0x150>
    123a:	84aa                	mv	s1,a0
  if(write(fd, "hello", SZ) != SZ){
    123c:	4615                	li	a2,5
    123e:	00005597          	auipc	a1,0x5
    1242:	30a58593          	addi	a1,a1,778 # 6548 <malloc+0x898>
    1246:	00004097          	auipc	ra,0x4
    124a:	5fa080e7          	jalr	1530(ra) # 5840 <write>
    124e:	4795                	li	a5,5
    1250:	10f51863          	bne	a0,a5,1360 <linktest+0x16c>
  close(fd);
    1254:	8526                	mv	a0,s1
    1256:	00004097          	auipc	ra,0x4
    125a:	5f2080e7          	jalr	1522(ra) # 5848 <close>
  if(link("lf1", "lf2") < 0){
    125e:	00005597          	auipc	a1,0x5
    1262:	3a258593          	addi	a1,a1,930 # 6600 <malloc+0x950>
    1266:	00005517          	auipc	a0,0x5
    126a:	39250513          	addi	a0,a0,914 # 65f8 <malloc+0x948>
    126e:	00004097          	auipc	ra,0x4
    1272:	612080e7          	jalr	1554(ra) # 5880 <link>
    1276:	10054363          	bltz	a0,137c <linktest+0x188>
  unlink("lf1");
    127a:	00005517          	auipc	a0,0x5
    127e:	37e50513          	addi	a0,a0,894 # 65f8 <malloc+0x948>
    1282:	00004097          	auipc	ra,0x4
    1286:	5ee080e7          	jalr	1518(ra) # 5870 <unlink>
  if(open("lf1", 0) >= 0){
    128a:	4581                	li	a1,0
    128c:	00005517          	auipc	a0,0x5
    1290:	36c50513          	addi	a0,a0,876 # 65f8 <malloc+0x948>
    1294:	00004097          	auipc	ra,0x4
    1298:	5cc080e7          	jalr	1484(ra) # 5860 <open>
    129c:	0e055e63          	bgez	a0,1398 <linktest+0x1a4>
  fd = open("lf2", 0);
    12a0:	4581                	li	a1,0
    12a2:	00005517          	auipc	a0,0x5
    12a6:	35e50513          	addi	a0,a0,862 # 6600 <malloc+0x950>
    12aa:	00004097          	auipc	ra,0x4
    12ae:	5b6080e7          	jalr	1462(ra) # 5860 <open>
    12b2:	84aa                	mv	s1,a0
  if(fd < 0){
    12b4:	10054063          	bltz	a0,13b4 <linktest+0x1c0>
  if(read(fd, buf, sizeof(buf)) != SZ){
    12b8:	660d                	lui	a2,0x3
    12ba:	0000b597          	auipc	a1,0xb
    12be:	8f658593          	addi	a1,a1,-1802 # bbb0 <buf>
    12c2:	00004097          	auipc	ra,0x4
    12c6:	576080e7          	jalr	1398(ra) # 5838 <read>
    12ca:	4795                	li	a5,5
    12cc:	10f51263          	bne	a0,a5,13d0 <linktest+0x1dc>
  close(fd);
    12d0:	8526                	mv	a0,s1
    12d2:	00004097          	auipc	ra,0x4
    12d6:	576080e7          	jalr	1398(ra) # 5848 <close>
  if(link("lf2", "lf2") >= 0){
    12da:	00005597          	auipc	a1,0x5
    12de:	32658593          	addi	a1,a1,806 # 6600 <malloc+0x950>
    12e2:	852e                	mv	a0,a1
    12e4:	00004097          	auipc	ra,0x4
    12e8:	59c080e7          	jalr	1436(ra) # 5880 <link>
    12ec:	10055063          	bgez	a0,13ec <linktest+0x1f8>
  unlink("lf2");
    12f0:	00005517          	auipc	a0,0x5
    12f4:	31050513          	addi	a0,a0,784 # 6600 <malloc+0x950>
    12f8:	00004097          	auipc	ra,0x4
    12fc:	578080e7          	jalr	1400(ra) # 5870 <unlink>
  if(link("lf2", "lf1") >= 0){
    1300:	00005597          	auipc	a1,0x5
    1304:	2f858593          	addi	a1,a1,760 # 65f8 <malloc+0x948>
    1308:	00005517          	auipc	a0,0x5
    130c:	2f850513          	addi	a0,a0,760 # 6600 <malloc+0x950>
    1310:	00004097          	auipc	ra,0x4
    1314:	570080e7          	jalr	1392(ra) # 5880 <link>
    1318:	0e055863          	bgez	a0,1408 <linktest+0x214>
  if(link(".", "lf1") >= 0){
    131c:	00005597          	auipc	a1,0x5
    1320:	2dc58593          	addi	a1,a1,732 # 65f8 <malloc+0x948>
    1324:	00005517          	auipc	a0,0x5
    1328:	3e450513          	addi	a0,a0,996 # 6708 <malloc+0xa58>
    132c:	00004097          	auipc	ra,0x4
    1330:	554080e7          	jalr	1364(ra) # 5880 <link>
    1334:	0e055863          	bgez	a0,1424 <linktest+0x230>
}
    1338:	60e2                	ld	ra,24(sp)
    133a:	6442                	ld	s0,16(sp)
    133c:	64a2                	ld	s1,8(sp)
    133e:	6902                	ld	s2,0(sp)
    1340:	6105                	addi	sp,sp,32
    1342:	8082                	ret
    printf("%s: create lf1 failed\n", s);
    1344:	85ca                	mv	a1,s2
    1346:	00005517          	auipc	a0,0x5
    134a:	2c250513          	addi	a0,a0,706 # 6608 <malloc+0x958>
    134e:	00005097          	auipc	ra,0x5
    1352:	8a4080e7          	jalr	-1884(ra) # 5bf2 <printf>
    exit(1);
    1356:	4505                	li	a0,1
    1358:	00004097          	auipc	ra,0x4
    135c:	4c8080e7          	jalr	1224(ra) # 5820 <exit>
    printf("%s: write lf1 failed\n", s);
    1360:	85ca                	mv	a1,s2
    1362:	00005517          	auipc	a0,0x5
    1366:	2be50513          	addi	a0,a0,702 # 6620 <malloc+0x970>
    136a:	00005097          	auipc	ra,0x5
    136e:	888080e7          	jalr	-1912(ra) # 5bf2 <printf>
    exit(1);
    1372:	4505                	li	a0,1
    1374:	00004097          	auipc	ra,0x4
    1378:	4ac080e7          	jalr	1196(ra) # 5820 <exit>
    printf("%s: link lf1 lf2 failed\n", s);
    137c:	85ca                	mv	a1,s2
    137e:	00005517          	auipc	a0,0x5
    1382:	2ba50513          	addi	a0,a0,698 # 6638 <malloc+0x988>
    1386:	00005097          	auipc	ra,0x5
    138a:	86c080e7          	jalr	-1940(ra) # 5bf2 <printf>
    exit(1);
    138e:	4505                	li	a0,1
    1390:	00004097          	auipc	ra,0x4
    1394:	490080e7          	jalr	1168(ra) # 5820 <exit>
    printf("%s: unlinked lf1 but it is still there!\n", s);
    1398:	85ca                	mv	a1,s2
    139a:	00005517          	auipc	a0,0x5
    139e:	2be50513          	addi	a0,a0,702 # 6658 <malloc+0x9a8>
    13a2:	00005097          	auipc	ra,0x5
    13a6:	850080e7          	jalr	-1968(ra) # 5bf2 <printf>
    exit(1);
    13aa:	4505                	li	a0,1
    13ac:	00004097          	auipc	ra,0x4
    13b0:	474080e7          	jalr	1140(ra) # 5820 <exit>
    printf("%s: open lf2 failed\n", s);
    13b4:	85ca                	mv	a1,s2
    13b6:	00005517          	auipc	a0,0x5
    13ba:	2d250513          	addi	a0,a0,722 # 6688 <malloc+0x9d8>
    13be:	00005097          	auipc	ra,0x5
    13c2:	834080e7          	jalr	-1996(ra) # 5bf2 <printf>
    exit(1);
    13c6:	4505                	li	a0,1
    13c8:	00004097          	auipc	ra,0x4
    13cc:	458080e7          	jalr	1112(ra) # 5820 <exit>
    printf("%s: read lf2 failed\n", s);
    13d0:	85ca                	mv	a1,s2
    13d2:	00005517          	auipc	a0,0x5
    13d6:	2ce50513          	addi	a0,a0,718 # 66a0 <malloc+0x9f0>
    13da:	00005097          	auipc	ra,0x5
    13de:	818080e7          	jalr	-2024(ra) # 5bf2 <printf>
    exit(1);
    13e2:	4505                	li	a0,1
    13e4:	00004097          	auipc	ra,0x4
    13e8:	43c080e7          	jalr	1084(ra) # 5820 <exit>
    printf("%s: link lf2 lf2 succeeded! oops\n", s);
    13ec:	85ca                	mv	a1,s2
    13ee:	00005517          	auipc	a0,0x5
    13f2:	2ca50513          	addi	a0,a0,714 # 66b8 <malloc+0xa08>
    13f6:	00004097          	auipc	ra,0x4
    13fa:	7fc080e7          	jalr	2044(ra) # 5bf2 <printf>
    exit(1);
    13fe:	4505                	li	a0,1
    1400:	00004097          	auipc	ra,0x4
    1404:	420080e7          	jalr	1056(ra) # 5820 <exit>
    printf("%s: link non-existant succeeded! oops\n", s);
    1408:	85ca                	mv	a1,s2
    140a:	00005517          	auipc	a0,0x5
    140e:	2d650513          	addi	a0,a0,726 # 66e0 <malloc+0xa30>
    1412:	00004097          	auipc	ra,0x4
    1416:	7e0080e7          	jalr	2016(ra) # 5bf2 <printf>
    exit(1);
    141a:	4505                	li	a0,1
    141c:	00004097          	auipc	ra,0x4
    1420:	404080e7          	jalr	1028(ra) # 5820 <exit>
    printf("%s: link . lf1 succeeded! oops\n", s);
    1424:	85ca                	mv	a1,s2
    1426:	00005517          	auipc	a0,0x5
    142a:	2ea50513          	addi	a0,a0,746 # 6710 <malloc+0xa60>
    142e:	00004097          	auipc	ra,0x4
    1432:	7c4080e7          	jalr	1988(ra) # 5bf2 <printf>
    exit(1);
    1436:	4505                	li	a0,1
    1438:	00004097          	auipc	ra,0x4
    143c:	3e8080e7          	jalr	1000(ra) # 5820 <exit>

0000000000001440 <validatetest>:
{
    1440:	7139                	addi	sp,sp,-64
    1442:	fc06                	sd	ra,56(sp)
    1444:	f822                	sd	s0,48(sp)
    1446:	f426                	sd	s1,40(sp)
    1448:	f04a                	sd	s2,32(sp)
    144a:	ec4e                	sd	s3,24(sp)
    144c:	e852                	sd	s4,16(sp)
    144e:	e456                	sd	s5,8(sp)
    1450:	e05a                	sd	s6,0(sp)
    1452:	0080                	addi	s0,sp,64
    1454:	8b2a                	mv	s6,a0
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    1456:	4481                	li	s1,0
    if(link("nosuchfile", (char*)p) != -1){
    1458:	00005997          	auipc	s3,0x5
    145c:	2d898993          	addi	s3,s3,728 # 6730 <malloc+0xa80>
    1460:	597d                	li	s2,-1
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    1462:	6a85                	lui	s5,0x1
    1464:	00114a37          	lui	s4,0x114
    if(link("nosuchfile", (char*)p) != -1){
    1468:	85a6                	mv	a1,s1
    146a:	854e                	mv	a0,s3
    146c:	00004097          	auipc	ra,0x4
    1470:	414080e7          	jalr	1044(ra) # 5880 <link>
    1474:	01251f63          	bne	a0,s2,1492 <validatetest+0x52>
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    1478:	94d6                	add	s1,s1,s5
    147a:	ff4497e3          	bne	s1,s4,1468 <validatetest+0x28>
}
    147e:	70e2                	ld	ra,56(sp)
    1480:	7442                	ld	s0,48(sp)
    1482:	74a2                	ld	s1,40(sp)
    1484:	7902                	ld	s2,32(sp)
    1486:	69e2                	ld	s3,24(sp)
    1488:	6a42                	ld	s4,16(sp)
    148a:	6aa2                	ld	s5,8(sp)
    148c:	6b02                	ld	s6,0(sp)
    148e:	6121                	addi	sp,sp,64
    1490:	8082                	ret
      printf("%s: link should not succeed\n", s);
    1492:	85da                	mv	a1,s6
    1494:	00005517          	auipc	a0,0x5
    1498:	2ac50513          	addi	a0,a0,684 # 6740 <malloc+0xa90>
    149c:	00004097          	auipc	ra,0x4
    14a0:	756080e7          	jalr	1878(ra) # 5bf2 <printf>
      exit(1);
    14a4:	4505                	li	a0,1
    14a6:	00004097          	auipc	ra,0x4
    14aa:	37a080e7          	jalr	890(ra) # 5820 <exit>

00000000000014ae <copyinstr2>:
{
    14ae:	7155                	addi	sp,sp,-208
    14b0:	e586                	sd	ra,200(sp)
    14b2:	e1a2                	sd	s0,192(sp)
    14b4:	0980                	addi	s0,sp,208
  for(int i = 0; i < MAXPATH; i++)
    14b6:	f6840793          	addi	a5,s0,-152
    14ba:	fe840693          	addi	a3,s0,-24
    b[i] = 'x';
    14be:	07800713          	li	a4,120
    14c2:	00e78023          	sb	a4,0(a5)
  for(int i = 0; i < MAXPATH; i++)
    14c6:	0785                	addi	a5,a5,1
    14c8:	fed79de3          	bne	a5,a3,14c2 <copyinstr2+0x14>
  b[MAXPATH] = '\0';
    14cc:	fe040423          	sb	zero,-24(s0)
  int ret = unlink(b);
    14d0:	f6840513          	addi	a0,s0,-152
    14d4:	00004097          	auipc	ra,0x4
    14d8:	39c080e7          	jalr	924(ra) # 5870 <unlink>
  if(ret != -1){
    14dc:	57fd                	li	a5,-1
    14de:	0ef51063          	bne	a0,a5,15be <copyinstr2+0x110>
  int fd = open(b, O_CREATE | O_WRONLY);
    14e2:	20100593          	li	a1,513
    14e6:	f6840513          	addi	a0,s0,-152
    14ea:	00004097          	auipc	ra,0x4
    14ee:	376080e7          	jalr	886(ra) # 5860 <open>
  if(fd != -1){
    14f2:	57fd                	li	a5,-1
    14f4:	0ef51563          	bne	a0,a5,15de <copyinstr2+0x130>
  ret = link(b, b);
    14f8:	f6840593          	addi	a1,s0,-152
    14fc:	852e                	mv	a0,a1
    14fe:	00004097          	auipc	ra,0x4
    1502:	382080e7          	jalr	898(ra) # 5880 <link>
  if(ret != -1){
    1506:	57fd                	li	a5,-1
    1508:	0ef51b63          	bne	a0,a5,15fe <copyinstr2+0x150>
  char *args[] = { "xx", 0 };
    150c:	00006797          	auipc	a5,0x6
    1510:	00c78793          	addi	a5,a5,12 # 7518 <malloc+0x1868>
    1514:	f4f43c23          	sd	a5,-168(s0)
    1518:	f6043023          	sd	zero,-160(s0)
  ret = exec(b, args);
    151c:	f5840593          	addi	a1,s0,-168
    1520:	f6840513          	addi	a0,s0,-152
    1524:	00004097          	auipc	ra,0x4
    1528:	334080e7          	jalr	820(ra) # 5858 <exec>
  if(ret != -1){
    152c:	57fd                	li	a5,-1
    152e:	0ef51963          	bne	a0,a5,1620 <copyinstr2+0x172>
  int pid = fork();
    1532:	00004097          	auipc	ra,0x4
    1536:	2e6080e7          	jalr	742(ra) # 5818 <fork>
  if(pid < 0){
    153a:	10054363          	bltz	a0,1640 <copyinstr2+0x192>
  if(pid == 0){
    153e:	12051463          	bnez	a0,1666 <copyinstr2+0x1b8>
    1542:	00007797          	auipc	a5,0x7
    1546:	f5678793          	addi	a5,a5,-170 # 8498 <big.0>
    154a:	00008697          	auipc	a3,0x8
    154e:	f4e68693          	addi	a3,a3,-178 # 9498 <__global_pointer$+0x920>
      big[i] = 'x';
    1552:	07800713          	li	a4,120
    1556:	00e78023          	sb	a4,0(a5)
    for(int i = 0; i < PGSIZE; i++)
    155a:	0785                	addi	a5,a5,1
    155c:	fed79de3          	bne	a5,a3,1556 <copyinstr2+0xa8>
    big[PGSIZE] = '\0';
    1560:	00008797          	auipc	a5,0x8
    1564:	f2078c23          	sb	zero,-200(a5) # 9498 <__global_pointer$+0x920>
    char *args2[] = { big, big, big, 0 };
    1568:	00007797          	auipc	a5,0x7
    156c:	b4078793          	addi	a5,a5,-1216 # 80a8 <malloc+0x23f8>
    1570:	6390                	ld	a2,0(a5)
    1572:	6794                	ld	a3,8(a5)
    1574:	6b98                	ld	a4,16(a5)
    1576:	6f9c                	ld	a5,24(a5)
    1578:	f2c43823          	sd	a2,-208(s0)
    157c:	f2d43c23          	sd	a3,-200(s0)
    1580:	f4e43023          	sd	a4,-192(s0)
    1584:	f4f43423          	sd	a5,-184(s0)
    ret = exec("echo", args2);
    1588:	f3040593          	addi	a1,s0,-208
    158c:	00005517          	auipc	a0,0x5
    1590:	be450513          	addi	a0,a0,-1052 # 6170 <malloc+0x4c0>
    1594:	00004097          	auipc	ra,0x4
    1598:	2c4080e7          	jalr	708(ra) # 5858 <exec>
    if(ret != -1){
    159c:	57fd                	li	a5,-1
    159e:	0af50e63          	beq	a0,a5,165a <copyinstr2+0x1ac>
      printf("exec(echo, BIG) returned %d, not -1\n", fd);
    15a2:	55fd                	li	a1,-1
    15a4:	00005517          	auipc	a0,0x5
    15a8:	24450513          	addi	a0,a0,580 # 67e8 <malloc+0xb38>
    15ac:	00004097          	auipc	ra,0x4
    15b0:	646080e7          	jalr	1606(ra) # 5bf2 <printf>
      exit(1);
    15b4:	4505                	li	a0,1
    15b6:	00004097          	auipc	ra,0x4
    15ba:	26a080e7          	jalr	618(ra) # 5820 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    15be:	862a                	mv	a2,a0
    15c0:	f6840593          	addi	a1,s0,-152
    15c4:	00005517          	auipc	a0,0x5
    15c8:	19c50513          	addi	a0,a0,412 # 6760 <malloc+0xab0>
    15cc:	00004097          	auipc	ra,0x4
    15d0:	626080e7          	jalr	1574(ra) # 5bf2 <printf>
    exit(1);
    15d4:	4505                	li	a0,1
    15d6:	00004097          	auipc	ra,0x4
    15da:	24a080e7          	jalr	586(ra) # 5820 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    15de:	862a                	mv	a2,a0
    15e0:	f6840593          	addi	a1,s0,-152
    15e4:	00005517          	auipc	a0,0x5
    15e8:	19c50513          	addi	a0,a0,412 # 6780 <malloc+0xad0>
    15ec:	00004097          	auipc	ra,0x4
    15f0:	606080e7          	jalr	1542(ra) # 5bf2 <printf>
    exit(1);
    15f4:	4505                	li	a0,1
    15f6:	00004097          	auipc	ra,0x4
    15fa:	22a080e7          	jalr	554(ra) # 5820 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    15fe:	86aa                	mv	a3,a0
    1600:	f6840613          	addi	a2,s0,-152
    1604:	85b2                	mv	a1,a2
    1606:	00005517          	auipc	a0,0x5
    160a:	19a50513          	addi	a0,a0,410 # 67a0 <malloc+0xaf0>
    160e:	00004097          	auipc	ra,0x4
    1612:	5e4080e7          	jalr	1508(ra) # 5bf2 <printf>
    exit(1);
    1616:	4505                	li	a0,1
    1618:	00004097          	auipc	ra,0x4
    161c:	208080e7          	jalr	520(ra) # 5820 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    1620:	567d                	li	a2,-1
    1622:	f6840593          	addi	a1,s0,-152
    1626:	00005517          	auipc	a0,0x5
    162a:	1a250513          	addi	a0,a0,418 # 67c8 <malloc+0xb18>
    162e:	00004097          	auipc	ra,0x4
    1632:	5c4080e7          	jalr	1476(ra) # 5bf2 <printf>
    exit(1);
    1636:	4505                	li	a0,1
    1638:	00004097          	auipc	ra,0x4
    163c:	1e8080e7          	jalr	488(ra) # 5820 <exit>
    printf("fork failed\n");
    1640:	00005517          	auipc	a0,0x5
    1644:	3b050513          	addi	a0,a0,944 # 69f0 <malloc+0xd40>
    1648:	00004097          	auipc	ra,0x4
    164c:	5aa080e7          	jalr	1450(ra) # 5bf2 <printf>
    exit(1);
    1650:	4505                	li	a0,1
    1652:	00004097          	auipc	ra,0x4
    1656:	1ce080e7          	jalr	462(ra) # 5820 <exit>
    exit(747); // OK
    165a:	2eb00513          	li	a0,747
    165e:	00004097          	auipc	ra,0x4
    1662:	1c2080e7          	jalr	450(ra) # 5820 <exit>
  int st = 0;
    1666:	f4042a23          	sw	zero,-172(s0)
  wait(&st);
    166a:	f5440513          	addi	a0,s0,-172
    166e:	00004097          	auipc	ra,0x4
    1672:	1ba080e7          	jalr	442(ra) # 5828 <wait>
  if(st != 747){
    1676:	f5442703          	lw	a4,-172(s0)
    167a:	2eb00793          	li	a5,747
    167e:	00f71663          	bne	a4,a5,168a <copyinstr2+0x1dc>
}
    1682:	60ae                	ld	ra,200(sp)
    1684:	640e                	ld	s0,192(sp)
    1686:	6169                	addi	sp,sp,208
    1688:	8082                	ret
    printf("exec(echo, BIG) succeeded, should have failed\n");
    168a:	00005517          	auipc	a0,0x5
    168e:	18650513          	addi	a0,a0,390 # 6810 <malloc+0xb60>
    1692:	00004097          	auipc	ra,0x4
    1696:	560080e7          	jalr	1376(ra) # 5bf2 <printf>
    exit(1);
    169a:	4505                	li	a0,1
    169c:	00004097          	auipc	ra,0x4
    16a0:	184080e7          	jalr	388(ra) # 5820 <exit>

00000000000016a4 <exectest>:
{
    16a4:	715d                	addi	sp,sp,-80
    16a6:	e486                	sd	ra,72(sp)
    16a8:	e0a2                	sd	s0,64(sp)
    16aa:	fc26                	sd	s1,56(sp)
    16ac:	f84a                	sd	s2,48(sp)
    16ae:	0880                	addi	s0,sp,80
    16b0:	892a                	mv	s2,a0
  char *echoargv[] = { "echo", "OK", 0 };
    16b2:	00005797          	auipc	a5,0x5
    16b6:	abe78793          	addi	a5,a5,-1346 # 6170 <malloc+0x4c0>
    16ba:	fcf43023          	sd	a5,-64(s0)
    16be:	00005797          	auipc	a5,0x5
    16c2:	18278793          	addi	a5,a5,386 # 6840 <malloc+0xb90>
    16c6:	fcf43423          	sd	a5,-56(s0)
    16ca:	fc043823          	sd	zero,-48(s0)
  unlink("echo-ok");
    16ce:	00005517          	auipc	a0,0x5
    16d2:	17a50513          	addi	a0,a0,378 # 6848 <malloc+0xb98>
    16d6:	00004097          	auipc	ra,0x4
    16da:	19a080e7          	jalr	410(ra) # 5870 <unlink>
  pid = fork();
    16de:	00004097          	auipc	ra,0x4
    16e2:	13a080e7          	jalr	314(ra) # 5818 <fork>
  if(pid < 0) {
    16e6:	04054663          	bltz	a0,1732 <exectest+0x8e>
    16ea:	84aa                	mv	s1,a0
  if(pid == 0) {
    16ec:	e959                	bnez	a0,1782 <exectest+0xde>
    close(1);
    16ee:	4505                	li	a0,1
    16f0:	00004097          	auipc	ra,0x4
    16f4:	158080e7          	jalr	344(ra) # 5848 <close>
    fd = open("echo-ok", O_CREATE|O_WRONLY);
    16f8:	20100593          	li	a1,513
    16fc:	00005517          	auipc	a0,0x5
    1700:	14c50513          	addi	a0,a0,332 # 6848 <malloc+0xb98>
    1704:	00004097          	auipc	ra,0x4
    1708:	15c080e7          	jalr	348(ra) # 5860 <open>
    if(fd < 0) {
    170c:	04054163          	bltz	a0,174e <exectest+0xaa>
    if(fd != 1) {
    1710:	4785                	li	a5,1
    1712:	04f50c63          	beq	a0,a5,176a <exectest+0xc6>
      printf("%s: wrong fd\n", s);
    1716:	85ca                	mv	a1,s2
    1718:	00005517          	auipc	a0,0x5
    171c:	15050513          	addi	a0,a0,336 # 6868 <malloc+0xbb8>
    1720:	00004097          	auipc	ra,0x4
    1724:	4d2080e7          	jalr	1234(ra) # 5bf2 <printf>
      exit(1);
    1728:	4505                	li	a0,1
    172a:	00004097          	auipc	ra,0x4
    172e:	0f6080e7          	jalr	246(ra) # 5820 <exit>
     printf("%s: fork failed\n", s);
    1732:	85ca                	mv	a1,s2
    1734:	00005517          	auipc	a0,0x5
    1738:	8f450513          	addi	a0,a0,-1804 # 6028 <malloc+0x378>
    173c:	00004097          	auipc	ra,0x4
    1740:	4b6080e7          	jalr	1206(ra) # 5bf2 <printf>
     exit(1);
    1744:	4505                	li	a0,1
    1746:	00004097          	auipc	ra,0x4
    174a:	0da080e7          	jalr	218(ra) # 5820 <exit>
      printf("%s: create failed\n", s);
    174e:	85ca                	mv	a1,s2
    1750:	00005517          	auipc	a0,0x5
    1754:	10050513          	addi	a0,a0,256 # 6850 <malloc+0xba0>
    1758:	00004097          	auipc	ra,0x4
    175c:	49a080e7          	jalr	1178(ra) # 5bf2 <printf>
      exit(1);
    1760:	4505                	li	a0,1
    1762:	00004097          	auipc	ra,0x4
    1766:	0be080e7          	jalr	190(ra) # 5820 <exit>
    if(exec("echo", echoargv) < 0){
    176a:	fc040593          	addi	a1,s0,-64
    176e:	00005517          	auipc	a0,0x5
    1772:	a0250513          	addi	a0,a0,-1534 # 6170 <malloc+0x4c0>
    1776:	00004097          	auipc	ra,0x4
    177a:	0e2080e7          	jalr	226(ra) # 5858 <exec>
    177e:	02054163          	bltz	a0,17a0 <exectest+0xfc>
  if (wait(&xstatus) != pid) {
    1782:	fdc40513          	addi	a0,s0,-36
    1786:	00004097          	auipc	ra,0x4
    178a:	0a2080e7          	jalr	162(ra) # 5828 <wait>
    178e:	02951763          	bne	a0,s1,17bc <exectest+0x118>
  if(xstatus != 0)
    1792:	fdc42503          	lw	a0,-36(s0)
    1796:	cd0d                	beqz	a0,17d0 <exectest+0x12c>
    exit(xstatus);
    1798:	00004097          	auipc	ra,0x4
    179c:	088080e7          	jalr	136(ra) # 5820 <exit>
      printf("%s: exec echo failed\n", s);
    17a0:	85ca                	mv	a1,s2
    17a2:	00005517          	auipc	a0,0x5
    17a6:	0d650513          	addi	a0,a0,214 # 6878 <malloc+0xbc8>
    17aa:	00004097          	auipc	ra,0x4
    17ae:	448080e7          	jalr	1096(ra) # 5bf2 <printf>
      exit(1);
    17b2:	4505                	li	a0,1
    17b4:	00004097          	auipc	ra,0x4
    17b8:	06c080e7          	jalr	108(ra) # 5820 <exit>
    printf("%s: wait failed!\n", s);
    17bc:	85ca                	mv	a1,s2
    17be:	00005517          	auipc	a0,0x5
    17c2:	0d250513          	addi	a0,a0,210 # 6890 <malloc+0xbe0>
    17c6:	00004097          	auipc	ra,0x4
    17ca:	42c080e7          	jalr	1068(ra) # 5bf2 <printf>
    17ce:	b7d1                	j	1792 <exectest+0xee>
  fd = open("echo-ok", O_RDONLY);
    17d0:	4581                	li	a1,0
    17d2:	00005517          	auipc	a0,0x5
    17d6:	07650513          	addi	a0,a0,118 # 6848 <malloc+0xb98>
    17da:	00004097          	auipc	ra,0x4
    17de:	086080e7          	jalr	134(ra) # 5860 <open>
  if(fd < 0) {
    17e2:	02054a63          	bltz	a0,1816 <exectest+0x172>
  if (read(fd, buf, 2) != 2) {
    17e6:	4609                	li	a2,2
    17e8:	fb840593          	addi	a1,s0,-72
    17ec:	00004097          	auipc	ra,0x4
    17f0:	04c080e7          	jalr	76(ra) # 5838 <read>
    17f4:	4789                	li	a5,2
    17f6:	02f50e63          	beq	a0,a5,1832 <exectest+0x18e>
    printf("%s: read failed\n", s);
    17fa:	85ca                	mv	a1,s2
    17fc:	00005517          	auipc	a0,0x5
    1800:	0c450513          	addi	a0,a0,196 # 68c0 <malloc+0xc10>
    1804:	00004097          	auipc	ra,0x4
    1808:	3ee080e7          	jalr	1006(ra) # 5bf2 <printf>
    exit(1);
    180c:	4505                	li	a0,1
    180e:	00004097          	auipc	ra,0x4
    1812:	012080e7          	jalr	18(ra) # 5820 <exit>
    printf("%s: open failed\n", s);
    1816:	85ca                	mv	a1,s2
    1818:	00005517          	auipc	a0,0x5
    181c:	09050513          	addi	a0,a0,144 # 68a8 <malloc+0xbf8>
    1820:	00004097          	auipc	ra,0x4
    1824:	3d2080e7          	jalr	978(ra) # 5bf2 <printf>
    exit(1);
    1828:	4505                	li	a0,1
    182a:	00004097          	auipc	ra,0x4
    182e:	ff6080e7          	jalr	-10(ra) # 5820 <exit>
  unlink("echo-ok");
    1832:	00005517          	auipc	a0,0x5
    1836:	01650513          	addi	a0,a0,22 # 6848 <malloc+0xb98>
    183a:	00004097          	auipc	ra,0x4
    183e:	036080e7          	jalr	54(ra) # 5870 <unlink>
  if(buf[0] == 'O' && buf[1] == 'K')
    1842:	fb844703          	lbu	a4,-72(s0)
    1846:	04f00793          	li	a5,79
    184a:	00f71863          	bne	a4,a5,185a <exectest+0x1b6>
    184e:	fb944703          	lbu	a4,-71(s0)
    1852:	04b00793          	li	a5,75
    1856:	02f70063          	beq	a4,a5,1876 <exectest+0x1d2>
    printf("%s: wrong output\n", s);
    185a:	85ca                	mv	a1,s2
    185c:	00005517          	auipc	a0,0x5
    1860:	07c50513          	addi	a0,a0,124 # 68d8 <malloc+0xc28>
    1864:	00004097          	auipc	ra,0x4
    1868:	38e080e7          	jalr	910(ra) # 5bf2 <printf>
    exit(1);
    186c:	4505                	li	a0,1
    186e:	00004097          	auipc	ra,0x4
    1872:	fb2080e7          	jalr	-78(ra) # 5820 <exit>
    exit(0);
    1876:	4501                	li	a0,0
    1878:	00004097          	auipc	ra,0x4
    187c:	fa8080e7          	jalr	-88(ra) # 5820 <exit>

0000000000001880 <bigargtest>:
// does exec return an error if the arguments
// are larger than a page? or does it write
// below the stack and wreck the instructions/data?
void
bigargtest(char *s)
{
    1880:	7179                	addi	sp,sp,-48
    1882:	f406                	sd	ra,40(sp)
    1884:	f022                	sd	s0,32(sp)
    1886:	ec26                	sd	s1,24(sp)
    1888:	1800                	addi	s0,sp,48
    188a:	84aa                	mv	s1,a0
  int pid, fd, xstatus;

  unlink("bigarg-ok");
    188c:	00005517          	auipc	a0,0x5
    1890:	06450513          	addi	a0,a0,100 # 68f0 <malloc+0xc40>
    1894:	00004097          	auipc	ra,0x4
    1898:	fdc080e7          	jalr	-36(ra) # 5870 <unlink>
  pid = fork();
    189c:	00004097          	auipc	ra,0x4
    18a0:	f7c080e7          	jalr	-132(ra) # 5818 <fork>
  if(pid == 0){
    18a4:	c121                	beqz	a0,18e4 <bigargtest+0x64>
    args[MAXARG-1] = 0;
    exec("echo", args);
    fd = open("bigarg-ok", O_CREATE);
    close(fd);
    exit(0);
  } else if(pid < 0){
    18a6:	0a054063          	bltz	a0,1946 <bigargtest+0xc6>
    printf("%s: bigargtest: fork failed\n", s);
    exit(1);
  }
  
  wait(&xstatus);
    18aa:	fdc40513          	addi	a0,s0,-36
    18ae:	00004097          	auipc	ra,0x4
    18b2:	f7a080e7          	jalr	-134(ra) # 5828 <wait>
  if(xstatus != 0)
    18b6:	fdc42503          	lw	a0,-36(s0)
    18ba:	e545                	bnez	a0,1962 <bigargtest+0xe2>
    exit(xstatus);
  fd = open("bigarg-ok", 0);
    18bc:	4581                	li	a1,0
    18be:	00005517          	auipc	a0,0x5
    18c2:	03250513          	addi	a0,a0,50 # 68f0 <malloc+0xc40>
    18c6:	00004097          	auipc	ra,0x4
    18ca:	f9a080e7          	jalr	-102(ra) # 5860 <open>
  if(fd < 0){
    18ce:	08054e63          	bltz	a0,196a <bigargtest+0xea>
    printf("%s: bigarg test failed!\n", s);
    exit(1);
  }
  close(fd);
    18d2:	00004097          	auipc	ra,0x4
    18d6:	f76080e7          	jalr	-138(ra) # 5848 <close>
}
    18da:	70a2                	ld	ra,40(sp)
    18dc:	7402                	ld	s0,32(sp)
    18de:	64e2                	ld	s1,24(sp)
    18e0:	6145                	addi	sp,sp,48
    18e2:	8082                	ret
    18e4:	00007797          	auipc	a5,0x7
    18e8:	ab478793          	addi	a5,a5,-1356 # 8398 <args.1>
    18ec:	00007697          	auipc	a3,0x7
    18f0:	ba468693          	addi	a3,a3,-1116 # 8490 <args.1+0xf8>
      args[i] = "bigargs test: failed\n                                                                                                                                                                                                       ";
    18f4:	00005717          	auipc	a4,0x5
    18f8:	00c70713          	addi	a4,a4,12 # 6900 <malloc+0xc50>
    18fc:	e398                	sd	a4,0(a5)
    for(i = 0; i < MAXARG-1; i++)
    18fe:	07a1                	addi	a5,a5,8
    1900:	fed79ee3          	bne	a5,a3,18fc <bigargtest+0x7c>
    args[MAXARG-1] = 0;
    1904:	00007597          	auipc	a1,0x7
    1908:	a9458593          	addi	a1,a1,-1388 # 8398 <args.1>
    190c:	0e05bc23          	sd	zero,248(a1)
    exec("echo", args);
    1910:	00005517          	auipc	a0,0x5
    1914:	86050513          	addi	a0,a0,-1952 # 6170 <malloc+0x4c0>
    1918:	00004097          	auipc	ra,0x4
    191c:	f40080e7          	jalr	-192(ra) # 5858 <exec>
    fd = open("bigarg-ok", O_CREATE);
    1920:	20000593          	li	a1,512
    1924:	00005517          	auipc	a0,0x5
    1928:	fcc50513          	addi	a0,a0,-52 # 68f0 <malloc+0xc40>
    192c:	00004097          	auipc	ra,0x4
    1930:	f34080e7          	jalr	-204(ra) # 5860 <open>
    close(fd);
    1934:	00004097          	auipc	ra,0x4
    1938:	f14080e7          	jalr	-236(ra) # 5848 <close>
    exit(0);
    193c:	4501                	li	a0,0
    193e:	00004097          	auipc	ra,0x4
    1942:	ee2080e7          	jalr	-286(ra) # 5820 <exit>
    printf("%s: bigargtest: fork failed\n", s);
    1946:	85a6                	mv	a1,s1
    1948:	00005517          	auipc	a0,0x5
    194c:	09850513          	addi	a0,a0,152 # 69e0 <malloc+0xd30>
    1950:	00004097          	auipc	ra,0x4
    1954:	2a2080e7          	jalr	674(ra) # 5bf2 <printf>
    exit(1);
    1958:	4505                	li	a0,1
    195a:	00004097          	auipc	ra,0x4
    195e:	ec6080e7          	jalr	-314(ra) # 5820 <exit>
    exit(xstatus);
    1962:	00004097          	auipc	ra,0x4
    1966:	ebe080e7          	jalr	-322(ra) # 5820 <exit>
    printf("%s: bigarg test failed!\n", s);
    196a:	85a6                	mv	a1,s1
    196c:	00005517          	auipc	a0,0x5
    1970:	09450513          	addi	a0,a0,148 # 6a00 <malloc+0xd50>
    1974:	00004097          	auipc	ra,0x4
    1978:	27e080e7          	jalr	638(ra) # 5bf2 <printf>
    exit(1);
    197c:	4505                	li	a0,1
    197e:	00004097          	auipc	ra,0x4
    1982:	ea2080e7          	jalr	-350(ra) # 5820 <exit>

0000000000001986 <pgbug>:
// regression test. copyin(), copyout(), and copyinstr() used to cast
// the virtual page address to uint, which (with certain wild system
// call arguments) resulted in a kernel page faults.
void
pgbug(char *s)
{
    1986:	7179                	addi	sp,sp,-48
    1988:	f406                	sd	ra,40(sp)
    198a:	f022                	sd	s0,32(sp)
    198c:	ec26                	sd	s1,24(sp)
    198e:	1800                	addi	s0,sp,48
  char *argv[1];
  argv[0] = 0;
    1990:	fc043c23          	sd	zero,-40(s0)
  exec((char*)0xeaeb0b5b00002f5e, argv);
    1994:	00007497          	auipc	s1,0x7
    1998:	9e44b483          	ld	s1,-1564(s1) # 8378 <__SDATA_BEGIN__>
    199c:	fd840593          	addi	a1,s0,-40
    19a0:	8526                	mv	a0,s1
    19a2:	00004097          	auipc	ra,0x4
    19a6:	eb6080e7          	jalr	-330(ra) # 5858 <exec>

  pipe((int*)0xeaeb0b5b00002f5e);
    19aa:	8526                	mv	a0,s1
    19ac:	00004097          	auipc	ra,0x4
    19b0:	e84080e7          	jalr	-380(ra) # 5830 <pipe>

  exit(0);
    19b4:	4501                	li	a0,0
    19b6:	00004097          	auipc	ra,0x4
    19ba:	e6a080e7          	jalr	-406(ra) # 5820 <exit>

00000000000019be <badarg>:

// regression test. test whether exec() leaks memory if one of the
// arguments is invalid. the test passes if the kernel doesn't panic.
void
badarg(char *s)
{
    19be:	7139                	addi	sp,sp,-64
    19c0:	fc06                	sd	ra,56(sp)
    19c2:	f822                	sd	s0,48(sp)
    19c4:	f426                	sd	s1,40(sp)
    19c6:	f04a                	sd	s2,32(sp)
    19c8:	ec4e                	sd	s3,24(sp)
    19ca:	0080                	addi	s0,sp,64
    19cc:	64b1                	lui	s1,0xc
    19ce:	35048493          	addi	s1,s1,848 # c350 <buf+0x7a0>
  for(int i = 0; i < 50000; i++){
    char *argv[2];
    argv[0] = (char*)0xffffffff;
    19d2:	597d                	li	s2,-1
    19d4:	02095913          	srli	s2,s2,0x20
    argv[1] = 0;
    exec("echo", argv);
    19d8:	00004997          	auipc	s3,0x4
    19dc:	79898993          	addi	s3,s3,1944 # 6170 <malloc+0x4c0>
    argv[0] = (char*)0xffffffff;
    19e0:	fd243023          	sd	s2,-64(s0)
    argv[1] = 0;
    19e4:	fc043423          	sd	zero,-56(s0)
    exec("echo", argv);
    19e8:	fc040593          	addi	a1,s0,-64
    19ec:	854e                	mv	a0,s3
    19ee:	00004097          	auipc	ra,0x4
    19f2:	e6a080e7          	jalr	-406(ra) # 5858 <exec>
  for(int i = 0; i < 50000; i++){
    19f6:	34fd                	addiw	s1,s1,-1
    19f8:	f4e5                	bnez	s1,19e0 <badarg+0x22>
  }
  
  exit(0);
    19fa:	4501                	li	a0,0
    19fc:	00004097          	auipc	ra,0x4
    1a00:	e24080e7          	jalr	-476(ra) # 5820 <exit>

0000000000001a04 <copyinstr3>:
{
    1a04:	7179                	addi	sp,sp,-48
    1a06:	f406                	sd	ra,40(sp)
    1a08:	f022                	sd	s0,32(sp)
    1a0a:	ec26                	sd	s1,24(sp)
    1a0c:	1800                	addi	s0,sp,48
  sbrk(8192);
    1a0e:	6509                	lui	a0,0x2
    1a10:	00004097          	auipc	ra,0x4
    1a14:	e98080e7          	jalr	-360(ra) # 58a8 <sbrk>
  uint64 top = (uint64) sbrk(0);
    1a18:	4501                	li	a0,0
    1a1a:	00004097          	auipc	ra,0x4
    1a1e:	e8e080e7          	jalr	-370(ra) # 58a8 <sbrk>
  if((top % PGSIZE) != 0){
    1a22:	03451793          	slli	a5,a0,0x34
    1a26:	e3c9                	bnez	a5,1aa8 <copyinstr3+0xa4>
  top = (uint64) sbrk(0);
    1a28:	4501                	li	a0,0
    1a2a:	00004097          	auipc	ra,0x4
    1a2e:	e7e080e7          	jalr	-386(ra) # 58a8 <sbrk>
  if(top % PGSIZE){
    1a32:	03451793          	slli	a5,a0,0x34
    1a36:	e3d9                	bnez	a5,1abc <copyinstr3+0xb8>
  char *b = (char *) (top - 1);
    1a38:	fff50493          	addi	s1,a0,-1 # 1fff <fourteen+0x119>
  *b = 'x';
    1a3c:	07800793          	li	a5,120
    1a40:	fef50fa3          	sb	a5,-1(a0)
  int ret = unlink(b);
    1a44:	8526                	mv	a0,s1
    1a46:	00004097          	auipc	ra,0x4
    1a4a:	e2a080e7          	jalr	-470(ra) # 5870 <unlink>
  if(ret != -1){
    1a4e:	57fd                	li	a5,-1
    1a50:	08f51363          	bne	a0,a5,1ad6 <copyinstr3+0xd2>
  int fd = open(b, O_CREATE | O_WRONLY);
    1a54:	20100593          	li	a1,513
    1a58:	8526                	mv	a0,s1
    1a5a:	00004097          	auipc	ra,0x4
    1a5e:	e06080e7          	jalr	-506(ra) # 5860 <open>
  if(fd != -1){
    1a62:	57fd                	li	a5,-1
    1a64:	08f51863          	bne	a0,a5,1af4 <copyinstr3+0xf0>
  ret = link(b, b);
    1a68:	85a6                	mv	a1,s1
    1a6a:	8526                	mv	a0,s1
    1a6c:	00004097          	auipc	ra,0x4
    1a70:	e14080e7          	jalr	-492(ra) # 5880 <link>
  if(ret != -1){
    1a74:	57fd                	li	a5,-1
    1a76:	08f51e63          	bne	a0,a5,1b12 <copyinstr3+0x10e>
  char *args[] = { "xx", 0 };
    1a7a:	00006797          	auipc	a5,0x6
    1a7e:	a9e78793          	addi	a5,a5,-1378 # 7518 <malloc+0x1868>
    1a82:	fcf43823          	sd	a5,-48(s0)
    1a86:	fc043c23          	sd	zero,-40(s0)
  ret = exec(b, args);
    1a8a:	fd040593          	addi	a1,s0,-48
    1a8e:	8526                	mv	a0,s1
    1a90:	00004097          	auipc	ra,0x4
    1a94:	dc8080e7          	jalr	-568(ra) # 5858 <exec>
  if(ret != -1){
    1a98:	57fd                	li	a5,-1
    1a9a:	08f51c63          	bne	a0,a5,1b32 <copyinstr3+0x12e>
}
    1a9e:	70a2                	ld	ra,40(sp)
    1aa0:	7402                	ld	s0,32(sp)
    1aa2:	64e2                	ld	s1,24(sp)
    1aa4:	6145                	addi	sp,sp,48
    1aa6:	8082                	ret
    sbrk(PGSIZE - (top % PGSIZE));
    1aa8:	0347d513          	srli	a0,a5,0x34
    1aac:	6785                	lui	a5,0x1
    1aae:	40a7853b          	subw	a0,a5,a0
    1ab2:	00004097          	auipc	ra,0x4
    1ab6:	df6080e7          	jalr	-522(ra) # 58a8 <sbrk>
    1aba:	b7bd                	j	1a28 <copyinstr3+0x24>
    printf("oops\n");
    1abc:	00005517          	auipc	a0,0x5
    1ac0:	f6450513          	addi	a0,a0,-156 # 6a20 <malloc+0xd70>
    1ac4:	00004097          	auipc	ra,0x4
    1ac8:	12e080e7          	jalr	302(ra) # 5bf2 <printf>
    exit(1);
    1acc:	4505                	li	a0,1
    1ace:	00004097          	auipc	ra,0x4
    1ad2:	d52080e7          	jalr	-686(ra) # 5820 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    1ad6:	862a                	mv	a2,a0
    1ad8:	85a6                	mv	a1,s1
    1ada:	00005517          	auipc	a0,0x5
    1ade:	c8650513          	addi	a0,a0,-890 # 6760 <malloc+0xab0>
    1ae2:	00004097          	auipc	ra,0x4
    1ae6:	110080e7          	jalr	272(ra) # 5bf2 <printf>
    exit(1);
    1aea:	4505                	li	a0,1
    1aec:	00004097          	auipc	ra,0x4
    1af0:	d34080e7          	jalr	-716(ra) # 5820 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    1af4:	862a                	mv	a2,a0
    1af6:	85a6                	mv	a1,s1
    1af8:	00005517          	auipc	a0,0x5
    1afc:	c8850513          	addi	a0,a0,-888 # 6780 <malloc+0xad0>
    1b00:	00004097          	auipc	ra,0x4
    1b04:	0f2080e7          	jalr	242(ra) # 5bf2 <printf>
    exit(1);
    1b08:	4505                	li	a0,1
    1b0a:	00004097          	auipc	ra,0x4
    1b0e:	d16080e7          	jalr	-746(ra) # 5820 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    1b12:	86aa                	mv	a3,a0
    1b14:	8626                	mv	a2,s1
    1b16:	85a6                	mv	a1,s1
    1b18:	00005517          	auipc	a0,0x5
    1b1c:	c8850513          	addi	a0,a0,-888 # 67a0 <malloc+0xaf0>
    1b20:	00004097          	auipc	ra,0x4
    1b24:	0d2080e7          	jalr	210(ra) # 5bf2 <printf>
    exit(1);
    1b28:	4505                	li	a0,1
    1b2a:	00004097          	auipc	ra,0x4
    1b2e:	cf6080e7          	jalr	-778(ra) # 5820 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    1b32:	567d                	li	a2,-1
    1b34:	85a6                	mv	a1,s1
    1b36:	00005517          	auipc	a0,0x5
    1b3a:	c9250513          	addi	a0,a0,-878 # 67c8 <malloc+0xb18>
    1b3e:	00004097          	auipc	ra,0x4
    1b42:	0b4080e7          	jalr	180(ra) # 5bf2 <printf>
    exit(1);
    1b46:	4505                	li	a0,1
    1b48:	00004097          	auipc	ra,0x4
    1b4c:	cd8080e7          	jalr	-808(ra) # 5820 <exit>

0000000000001b50 <rwsbrk>:
{
    1b50:	1101                	addi	sp,sp,-32
    1b52:	ec06                	sd	ra,24(sp)
    1b54:	e822                	sd	s0,16(sp)
    1b56:	e426                	sd	s1,8(sp)
    1b58:	e04a                	sd	s2,0(sp)
    1b5a:	1000                	addi	s0,sp,32
  uint64 a = (uint64) sbrk(8192);
    1b5c:	6509                	lui	a0,0x2
    1b5e:	00004097          	auipc	ra,0x4
    1b62:	d4a080e7          	jalr	-694(ra) # 58a8 <sbrk>
  if(a == 0xffffffffffffffffLL) {
    1b66:	57fd                	li	a5,-1
    1b68:	06f50363          	beq	a0,a5,1bce <rwsbrk+0x7e>
    1b6c:	84aa                	mv	s1,a0
  if ((uint64) sbrk(-8192) ==  0xffffffffffffffffLL) {
    1b6e:	7579                	lui	a0,0xffffe
    1b70:	00004097          	auipc	ra,0x4
    1b74:	d38080e7          	jalr	-712(ra) # 58a8 <sbrk>
    1b78:	57fd                	li	a5,-1
    1b7a:	06f50763          	beq	a0,a5,1be8 <rwsbrk+0x98>
  fd = open("rwsbrk", O_CREATE|O_WRONLY);
    1b7e:	20100593          	li	a1,513
    1b82:	00004517          	auipc	a0,0x4
    1b86:	29650513          	addi	a0,a0,662 # 5e18 <malloc+0x168>
    1b8a:	00004097          	auipc	ra,0x4
    1b8e:	cd6080e7          	jalr	-810(ra) # 5860 <open>
    1b92:	892a                	mv	s2,a0
  if(fd < 0){
    1b94:	06054763          	bltz	a0,1c02 <rwsbrk+0xb2>
  n = write(fd, (void*)(a+4096), 1024);
    1b98:	6505                	lui	a0,0x1
    1b9a:	94aa                	add	s1,s1,a0
    1b9c:	40000613          	li	a2,1024
    1ba0:	85a6                	mv	a1,s1
    1ba2:	854a                	mv	a0,s2
    1ba4:	00004097          	auipc	ra,0x4
    1ba8:	c9c080e7          	jalr	-868(ra) # 5840 <write>
    1bac:	862a                	mv	a2,a0
  if(n >= 0){
    1bae:	06054763          	bltz	a0,1c1c <rwsbrk+0xcc>
    printf("write(fd, %p, 1024) returned %d, not -1\n", a+4096, n);
    1bb2:	85a6                	mv	a1,s1
    1bb4:	00005517          	auipc	a0,0x5
    1bb8:	ec450513          	addi	a0,a0,-316 # 6a78 <malloc+0xdc8>
    1bbc:	00004097          	auipc	ra,0x4
    1bc0:	036080e7          	jalr	54(ra) # 5bf2 <printf>
    exit(1);
    1bc4:	4505                	li	a0,1
    1bc6:	00004097          	auipc	ra,0x4
    1bca:	c5a080e7          	jalr	-934(ra) # 5820 <exit>
    printf("sbrk(rwsbrk) failed\n");
    1bce:	00005517          	auipc	a0,0x5
    1bd2:	e5a50513          	addi	a0,a0,-422 # 6a28 <malloc+0xd78>
    1bd6:	00004097          	auipc	ra,0x4
    1bda:	01c080e7          	jalr	28(ra) # 5bf2 <printf>
    exit(1);
    1bde:	4505                	li	a0,1
    1be0:	00004097          	auipc	ra,0x4
    1be4:	c40080e7          	jalr	-960(ra) # 5820 <exit>
    printf("sbrk(rwsbrk) shrink failed\n");
    1be8:	00005517          	auipc	a0,0x5
    1bec:	e5850513          	addi	a0,a0,-424 # 6a40 <malloc+0xd90>
    1bf0:	00004097          	auipc	ra,0x4
    1bf4:	002080e7          	jalr	2(ra) # 5bf2 <printf>
    exit(1);
    1bf8:	4505                	li	a0,1
    1bfa:	00004097          	auipc	ra,0x4
    1bfe:	c26080e7          	jalr	-986(ra) # 5820 <exit>
    printf("open(rwsbrk) failed\n");
    1c02:	00005517          	auipc	a0,0x5
    1c06:	e5e50513          	addi	a0,a0,-418 # 6a60 <malloc+0xdb0>
    1c0a:	00004097          	auipc	ra,0x4
    1c0e:	fe8080e7          	jalr	-24(ra) # 5bf2 <printf>
    exit(1);
    1c12:	4505                	li	a0,1
    1c14:	00004097          	auipc	ra,0x4
    1c18:	c0c080e7          	jalr	-1012(ra) # 5820 <exit>
  close(fd);
    1c1c:	854a                	mv	a0,s2
    1c1e:	00004097          	auipc	ra,0x4
    1c22:	c2a080e7          	jalr	-982(ra) # 5848 <close>
  unlink("rwsbrk");
    1c26:	00004517          	auipc	a0,0x4
    1c2a:	1f250513          	addi	a0,a0,498 # 5e18 <malloc+0x168>
    1c2e:	00004097          	auipc	ra,0x4
    1c32:	c42080e7          	jalr	-958(ra) # 5870 <unlink>
  fd = open("README", O_RDONLY);
    1c36:	4581                	li	a1,0
    1c38:	00004517          	auipc	a0,0x4
    1c3c:	6e050513          	addi	a0,a0,1760 # 6318 <malloc+0x668>
    1c40:	00004097          	auipc	ra,0x4
    1c44:	c20080e7          	jalr	-992(ra) # 5860 <open>
    1c48:	892a                	mv	s2,a0
  if(fd < 0){
    1c4a:	02054963          	bltz	a0,1c7c <rwsbrk+0x12c>
  n = read(fd, (void*)(a+4096), 10);
    1c4e:	4629                	li	a2,10
    1c50:	85a6                	mv	a1,s1
    1c52:	00004097          	auipc	ra,0x4
    1c56:	be6080e7          	jalr	-1050(ra) # 5838 <read>
    1c5a:	862a                	mv	a2,a0
  if(n >= 0){
    1c5c:	02054d63          	bltz	a0,1c96 <rwsbrk+0x146>
    printf("read(fd, %p, 10) returned %d, not -1\n", a+4096, n);
    1c60:	85a6                	mv	a1,s1
    1c62:	00005517          	auipc	a0,0x5
    1c66:	e4650513          	addi	a0,a0,-442 # 6aa8 <malloc+0xdf8>
    1c6a:	00004097          	auipc	ra,0x4
    1c6e:	f88080e7          	jalr	-120(ra) # 5bf2 <printf>
    exit(1);
    1c72:	4505                	li	a0,1
    1c74:	00004097          	auipc	ra,0x4
    1c78:	bac080e7          	jalr	-1108(ra) # 5820 <exit>
    printf("open(rwsbrk) failed\n");
    1c7c:	00005517          	auipc	a0,0x5
    1c80:	de450513          	addi	a0,a0,-540 # 6a60 <malloc+0xdb0>
    1c84:	00004097          	auipc	ra,0x4
    1c88:	f6e080e7          	jalr	-146(ra) # 5bf2 <printf>
    exit(1);
    1c8c:	4505                	li	a0,1
    1c8e:	00004097          	auipc	ra,0x4
    1c92:	b92080e7          	jalr	-1134(ra) # 5820 <exit>
  close(fd);
    1c96:	854a                	mv	a0,s2
    1c98:	00004097          	auipc	ra,0x4
    1c9c:	bb0080e7          	jalr	-1104(ra) # 5848 <close>
  exit(0);
    1ca0:	4501                	li	a0,0
    1ca2:	00004097          	auipc	ra,0x4
    1ca6:	b7e080e7          	jalr	-1154(ra) # 5820 <exit>

0000000000001caa <sbrkarg>:
{
    1caa:	7179                	addi	sp,sp,-48
    1cac:	f406                	sd	ra,40(sp)
    1cae:	f022                	sd	s0,32(sp)
    1cb0:	ec26                	sd	s1,24(sp)
    1cb2:	e84a                	sd	s2,16(sp)
    1cb4:	e44e                	sd	s3,8(sp)
    1cb6:	1800                	addi	s0,sp,48
    1cb8:	89aa                	mv	s3,a0
  a = sbrk(PGSIZE);
    1cba:	6505                	lui	a0,0x1
    1cbc:	00004097          	auipc	ra,0x4
    1cc0:	bec080e7          	jalr	-1044(ra) # 58a8 <sbrk>
    1cc4:	892a                	mv	s2,a0
  fd = open("sbrk", O_CREATE|O_WRONLY);
    1cc6:	20100593          	li	a1,513
    1cca:	00005517          	auipc	a0,0x5
    1cce:	e0650513          	addi	a0,a0,-506 # 6ad0 <malloc+0xe20>
    1cd2:	00004097          	auipc	ra,0x4
    1cd6:	b8e080e7          	jalr	-1138(ra) # 5860 <open>
    1cda:	84aa                	mv	s1,a0
  unlink("sbrk");
    1cdc:	00005517          	auipc	a0,0x5
    1ce0:	df450513          	addi	a0,a0,-524 # 6ad0 <malloc+0xe20>
    1ce4:	00004097          	auipc	ra,0x4
    1ce8:	b8c080e7          	jalr	-1140(ra) # 5870 <unlink>
  if(fd < 0)  {
    1cec:	0404c163          	bltz	s1,1d2e <sbrkarg+0x84>
  if ((n = write(fd, a, PGSIZE)) < 0) {
    1cf0:	6605                	lui	a2,0x1
    1cf2:	85ca                	mv	a1,s2
    1cf4:	8526                	mv	a0,s1
    1cf6:	00004097          	auipc	ra,0x4
    1cfa:	b4a080e7          	jalr	-1206(ra) # 5840 <write>
    1cfe:	04054663          	bltz	a0,1d4a <sbrkarg+0xa0>
  close(fd);
    1d02:	8526                	mv	a0,s1
    1d04:	00004097          	auipc	ra,0x4
    1d08:	b44080e7          	jalr	-1212(ra) # 5848 <close>
  a = sbrk(PGSIZE);
    1d0c:	6505                	lui	a0,0x1
    1d0e:	00004097          	auipc	ra,0x4
    1d12:	b9a080e7          	jalr	-1126(ra) # 58a8 <sbrk>
  if(pipe((int *) a) != 0){
    1d16:	00004097          	auipc	ra,0x4
    1d1a:	b1a080e7          	jalr	-1254(ra) # 5830 <pipe>
    1d1e:	e521                	bnez	a0,1d66 <sbrkarg+0xbc>
}
    1d20:	70a2                	ld	ra,40(sp)
    1d22:	7402                	ld	s0,32(sp)
    1d24:	64e2                	ld	s1,24(sp)
    1d26:	6942                	ld	s2,16(sp)
    1d28:	69a2                	ld	s3,8(sp)
    1d2a:	6145                	addi	sp,sp,48
    1d2c:	8082                	ret
    printf("%s: open sbrk failed\n", s);
    1d2e:	85ce                	mv	a1,s3
    1d30:	00005517          	auipc	a0,0x5
    1d34:	da850513          	addi	a0,a0,-600 # 6ad8 <malloc+0xe28>
    1d38:	00004097          	auipc	ra,0x4
    1d3c:	eba080e7          	jalr	-326(ra) # 5bf2 <printf>
    exit(1);
    1d40:	4505                	li	a0,1
    1d42:	00004097          	auipc	ra,0x4
    1d46:	ade080e7          	jalr	-1314(ra) # 5820 <exit>
    printf("%s: write sbrk failed\n", s);
    1d4a:	85ce                	mv	a1,s3
    1d4c:	00005517          	auipc	a0,0x5
    1d50:	da450513          	addi	a0,a0,-604 # 6af0 <malloc+0xe40>
    1d54:	00004097          	auipc	ra,0x4
    1d58:	e9e080e7          	jalr	-354(ra) # 5bf2 <printf>
    exit(1);
    1d5c:	4505                	li	a0,1
    1d5e:	00004097          	auipc	ra,0x4
    1d62:	ac2080e7          	jalr	-1342(ra) # 5820 <exit>
    printf("%s: pipe() failed\n", s);
    1d66:	85ce                	mv	a1,s3
    1d68:	00004517          	auipc	a0,0x4
    1d6c:	6f050513          	addi	a0,a0,1776 # 6458 <malloc+0x7a8>
    1d70:	00004097          	auipc	ra,0x4
    1d74:	e82080e7          	jalr	-382(ra) # 5bf2 <printf>
    exit(1);
    1d78:	4505                	li	a0,1
    1d7a:	00004097          	auipc	ra,0x4
    1d7e:	aa6080e7          	jalr	-1370(ra) # 5820 <exit>

0000000000001d82 <argptest>:
{
    1d82:	1101                	addi	sp,sp,-32
    1d84:	ec06                	sd	ra,24(sp)
    1d86:	e822                	sd	s0,16(sp)
    1d88:	e426                	sd	s1,8(sp)
    1d8a:	e04a                	sd	s2,0(sp)
    1d8c:	1000                	addi	s0,sp,32
    1d8e:	892a                	mv	s2,a0
  fd = open("init", O_RDONLY);
    1d90:	4581                	li	a1,0
    1d92:	00005517          	auipc	a0,0x5
    1d96:	d7650513          	addi	a0,a0,-650 # 6b08 <malloc+0xe58>
    1d9a:	00004097          	auipc	ra,0x4
    1d9e:	ac6080e7          	jalr	-1338(ra) # 5860 <open>
  if (fd < 0) {
    1da2:	02054b63          	bltz	a0,1dd8 <argptest+0x56>
    1da6:	84aa                	mv	s1,a0
  read(fd, sbrk(0) - 1, -1);
    1da8:	4501                	li	a0,0
    1daa:	00004097          	auipc	ra,0x4
    1dae:	afe080e7          	jalr	-1282(ra) # 58a8 <sbrk>
    1db2:	567d                	li	a2,-1
    1db4:	fff50593          	addi	a1,a0,-1
    1db8:	8526                	mv	a0,s1
    1dba:	00004097          	auipc	ra,0x4
    1dbe:	a7e080e7          	jalr	-1410(ra) # 5838 <read>
  close(fd);
    1dc2:	8526                	mv	a0,s1
    1dc4:	00004097          	auipc	ra,0x4
    1dc8:	a84080e7          	jalr	-1404(ra) # 5848 <close>
}
    1dcc:	60e2                	ld	ra,24(sp)
    1dce:	6442                	ld	s0,16(sp)
    1dd0:	64a2                	ld	s1,8(sp)
    1dd2:	6902                	ld	s2,0(sp)
    1dd4:	6105                	addi	sp,sp,32
    1dd6:	8082                	ret
    printf("%s: open failed\n", s);
    1dd8:	85ca                	mv	a1,s2
    1dda:	00005517          	auipc	a0,0x5
    1dde:	ace50513          	addi	a0,a0,-1330 # 68a8 <malloc+0xbf8>
    1de2:	00004097          	auipc	ra,0x4
    1de6:	e10080e7          	jalr	-496(ra) # 5bf2 <printf>
    exit(1);
    1dea:	4505                	li	a0,1
    1dec:	00004097          	auipc	ra,0x4
    1df0:	a34080e7          	jalr	-1484(ra) # 5820 <exit>

0000000000001df4 <openiputtest>:
{
    1df4:	7179                	addi	sp,sp,-48
    1df6:	f406                	sd	ra,40(sp)
    1df8:	f022                	sd	s0,32(sp)
    1dfa:	ec26                	sd	s1,24(sp)
    1dfc:	1800                	addi	s0,sp,48
    1dfe:	84aa                	mv	s1,a0
  if(mkdir("oidir") < 0){
    1e00:	00005517          	auipc	a0,0x5
    1e04:	d1050513          	addi	a0,a0,-752 # 6b10 <malloc+0xe60>
    1e08:	00004097          	auipc	ra,0x4
    1e0c:	a80080e7          	jalr	-1408(ra) # 5888 <mkdir>
    1e10:	04054263          	bltz	a0,1e54 <openiputtest+0x60>
  pid = fork();
    1e14:	00004097          	auipc	ra,0x4
    1e18:	a04080e7          	jalr	-1532(ra) # 5818 <fork>
  if(pid < 0){
    1e1c:	04054a63          	bltz	a0,1e70 <openiputtest+0x7c>
  if(pid == 0){
    1e20:	e93d                	bnez	a0,1e96 <openiputtest+0xa2>
    int fd = open("oidir", O_RDWR);
    1e22:	4589                	li	a1,2
    1e24:	00005517          	auipc	a0,0x5
    1e28:	cec50513          	addi	a0,a0,-788 # 6b10 <malloc+0xe60>
    1e2c:	00004097          	auipc	ra,0x4
    1e30:	a34080e7          	jalr	-1484(ra) # 5860 <open>
    if(fd >= 0){
    1e34:	04054c63          	bltz	a0,1e8c <openiputtest+0x98>
      printf("%s: open directory for write succeeded\n", s);
    1e38:	85a6                	mv	a1,s1
    1e3a:	00005517          	auipc	a0,0x5
    1e3e:	cf650513          	addi	a0,a0,-778 # 6b30 <malloc+0xe80>
    1e42:	00004097          	auipc	ra,0x4
    1e46:	db0080e7          	jalr	-592(ra) # 5bf2 <printf>
      exit(1);
    1e4a:	4505                	li	a0,1
    1e4c:	00004097          	auipc	ra,0x4
    1e50:	9d4080e7          	jalr	-1580(ra) # 5820 <exit>
    printf("%s: mkdir oidir failed\n", s);
    1e54:	85a6                	mv	a1,s1
    1e56:	00005517          	auipc	a0,0x5
    1e5a:	cc250513          	addi	a0,a0,-830 # 6b18 <malloc+0xe68>
    1e5e:	00004097          	auipc	ra,0x4
    1e62:	d94080e7          	jalr	-620(ra) # 5bf2 <printf>
    exit(1);
    1e66:	4505                	li	a0,1
    1e68:	00004097          	auipc	ra,0x4
    1e6c:	9b8080e7          	jalr	-1608(ra) # 5820 <exit>
    printf("%s: fork failed\n", s);
    1e70:	85a6                	mv	a1,s1
    1e72:	00004517          	auipc	a0,0x4
    1e76:	1b650513          	addi	a0,a0,438 # 6028 <malloc+0x378>
    1e7a:	00004097          	auipc	ra,0x4
    1e7e:	d78080e7          	jalr	-648(ra) # 5bf2 <printf>
    exit(1);
    1e82:	4505                	li	a0,1
    1e84:	00004097          	auipc	ra,0x4
    1e88:	99c080e7          	jalr	-1636(ra) # 5820 <exit>
    exit(0);
    1e8c:	4501                	li	a0,0
    1e8e:	00004097          	auipc	ra,0x4
    1e92:	992080e7          	jalr	-1646(ra) # 5820 <exit>
  sleep(1);
    1e96:	4505                	li	a0,1
    1e98:	00004097          	auipc	ra,0x4
    1e9c:	a18080e7          	jalr	-1512(ra) # 58b0 <sleep>
  if(unlink("oidir") != 0){
    1ea0:	00005517          	auipc	a0,0x5
    1ea4:	c7050513          	addi	a0,a0,-912 # 6b10 <malloc+0xe60>
    1ea8:	00004097          	auipc	ra,0x4
    1eac:	9c8080e7          	jalr	-1592(ra) # 5870 <unlink>
    1eb0:	cd19                	beqz	a0,1ece <openiputtest+0xda>
    printf("%s: unlink failed\n", s);
    1eb2:	85a6                	mv	a1,s1
    1eb4:	00005517          	auipc	a0,0x5
    1eb8:	ca450513          	addi	a0,a0,-860 # 6b58 <malloc+0xea8>
    1ebc:	00004097          	auipc	ra,0x4
    1ec0:	d36080e7          	jalr	-714(ra) # 5bf2 <printf>
    exit(1);
    1ec4:	4505                	li	a0,1
    1ec6:	00004097          	auipc	ra,0x4
    1eca:	95a080e7          	jalr	-1702(ra) # 5820 <exit>
  wait(&xstatus);
    1ece:	fdc40513          	addi	a0,s0,-36
    1ed2:	00004097          	auipc	ra,0x4
    1ed6:	956080e7          	jalr	-1706(ra) # 5828 <wait>
  exit(xstatus);
    1eda:	fdc42503          	lw	a0,-36(s0)
    1ede:	00004097          	auipc	ra,0x4
    1ee2:	942080e7          	jalr	-1726(ra) # 5820 <exit>

0000000000001ee6 <fourteen>:
{
    1ee6:	1101                	addi	sp,sp,-32
    1ee8:	ec06                	sd	ra,24(sp)
    1eea:	e822                	sd	s0,16(sp)
    1eec:	e426                	sd	s1,8(sp)
    1eee:	1000                	addi	s0,sp,32
    1ef0:	84aa                	mv	s1,a0
  if(mkdir("12345678901234") != 0){
    1ef2:	00005517          	auipc	a0,0x5
    1ef6:	e4e50513          	addi	a0,a0,-434 # 6d40 <malloc+0x1090>
    1efa:	00004097          	auipc	ra,0x4
    1efe:	98e080e7          	jalr	-1650(ra) # 5888 <mkdir>
    1f02:	e165                	bnez	a0,1fe2 <fourteen+0xfc>
  if(mkdir("12345678901234/123456789012345") != 0){
    1f04:	00005517          	auipc	a0,0x5
    1f08:	c9450513          	addi	a0,a0,-876 # 6b98 <malloc+0xee8>
    1f0c:	00004097          	auipc	ra,0x4
    1f10:	97c080e7          	jalr	-1668(ra) # 5888 <mkdir>
    1f14:	e56d                	bnez	a0,1ffe <fourteen+0x118>
  fd = open("123456789012345/123456789012345/123456789012345", O_CREATE);
    1f16:	20000593          	li	a1,512
    1f1a:	00005517          	auipc	a0,0x5
    1f1e:	cd650513          	addi	a0,a0,-810 # 6bf0 <malloc+0xf40>
    1f22:	00004097          	auipc	ra,0x4
    1f26:	93e080e7          	jalr	-1730(ra) # 5860 <open>
  if(fd < 0){
    1f2a:	0e054863          	bltz	a0,201a <fourteen+0x134>
  close(fd);
    1f2e:	00004097          	auipc	ra,0x4
    1f32:	91a080e7          	jalr	-1766(ra) # 5848 <close>
  fd = open("12345678901234/12345678901234/12345678901234", 0);
    1f36:	4581                	li	a1,0
    1f38:	00005517          	auipc	a0,0x5
    1f3c:	d3050513          	addi	a0,a0,-720 # 6c68 <malloc+0xfb8>
    1f40:	00004097          	auipc	ra,0x4
    1f44:	920080e7          	jalr	-1760(ra) # 5860 <open>
  if(fd < 0){
    1f48:	0e054763          	bltz	a0,2036 <fourteen+0x150>
  close(fd);
    1f4c:	00004097          	auipc	ra,0x4
    1f50:	8fc080e7          	jalr	-1796(ra) # 5848 <close>
  if(mkdir("12345678901234/12345678901234") == 0){
    1f54:	00005517          	auipc	a0,0x5
    1f58:	d8450513          	addi	a0,a0,-636 # 6cd8 <malloc+0x1028>
    1f5c:	00004097          	auipc	ra,0x4
    1f60:	92c080e7          	jalr	-1748(ra) # 5888 <mkdir>
    1f64:	c57d                	beqz	a0,2052 <fourteen+0x16c>
  if(mkdir("123456789012345/12345678901234") == 0){
    1f66:	00005517          	auipc	a0,0x5
    1f6a:	dca50513          	addi	a0,a0,-566 # 6d30 <malloc+0x1080>
    1f6e:	00004097          	auipc	ra,0x4
    1f72:	91a080e7          	jalr	-1766(ra) # 5888 <mkdir>
    1f76:	cd65                	beqz	a0,206e <fourteen+0x188>
  unlink("123456789012345/12345678901234");
    1f78:	00005517          	auipc	a0,0x5
    1f7c:	db850513          	addi	a0,a0,-584 # 6d30 <malloc+0x1080>
    1f80:	00004097          	auipc	ra,0x4
    1f84:	8f0080e7          	jalr	-1808(ra) # 5870 <unlink>
  unlink("12345678901234/12345678901234");
    1f88:	00005517          	auipc	a0,0x5
    1f8c:	d5050513          	addi	a0,a0,-688 # 6cd8 <malloc+0x1028>
    1f90:	00004097          	auipc	ra,0x4
    1f94:	8e0080e7          	jalr	-1824(ra) # 5870 <unlink>
  unlink("12345678901234/12345678901234/12345678901234");
    1f98:	00005517          	auipc	a0,0x5
    1f9c:	cd050513          	addi	a0,a0,-816 # 6c68 <malloc+0xfb8>
    1fa0:	00004097          	auipc	ra,0x4
    1fa4:	8d0080e7          	jalr	-1840(ra) # 5870 <unlink>
  unlink("123456789012345/123456789012345/123456789012345");
    1fa8:	00005517          	auipc	a0,0x5
    1fac:	c4850513          	addi	a0,a0,-952 # 6bf0 <malloc+0xf40>
    1fb0:	00004097          	auipc	ra,0x4
    1fb4:	8c0080e7          	jalr	-1856(ra) # 5870 <unlink>
  unlink("12345678901234/123456789012345");
    1fb8:	00005517          	auipc	a0,0x5
    1fbc:	be050513          	addi	a0,a0,-1056 # 6b98 <malloc+0xee8>
    1fc0:	00004097          	auipc	ra,0x4
    1fc4:	8b0080e7          	jalr	-1872(ra) # 5870 <unlink>
  unlink("12345678901234");
    1fc8:	00005517          	auipc	a0,0x5
    1fcc:	d7850513          	addi	a0,a0,-648 # 6d40 <malloc+0x1090>
    1fd0:	00004097          	auipc	ra,0x4
    1fd4:	8a0080e7          	jalr	-1888(ra) # 5870 <unlink>
}
    1fd8:	60e2                	ld	ra,24(sp)
    1fda:	6442                	ld	s0,16(sp)
    1fdc:	64a2                	ld	s1,8(sp)
    1fde:	6105                	addi	sp,sp,32
    1fe0:	8082                	ret
    printf("%s: mkdir 12345678901234 failed\n", s);
    1fe2:	85a6                	mv	a1,s1
    1fe4:	00005517          	auipc	a0,0x5
    1fe8:	b8c50513          	addi	a0,a0,-1140 # 6b70 <malloc+0xec0>
    1fec:	00004097          	auipc	ra,0x4
    1ff0:	c06080e7          	jalr	-1018(ra) # 5bf2 <printf>
    exit(1);
    1ff4:	4505                	li	a0,1
    1ff6:	00004097          	auipc	ra,0x4
    1ffa:	82a080e7          	jalr	-2006(ra) # 5820 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 failed\n", s);
    1ffe:	85a6                	mv	a1,s1
    2000:	00005517          	auipc	a0,0x5
    2004:	bb850513          	addi	a0,a0,-1096 # 6bb8 <malloc+0xf08>
    2008:	00004097          	auipc	ra,0x4
    200c:	bea080e7          	jalr	-1046(ra) # 5bf2 <printf>
    exit(1);
    2010:	4505                	li	a0,1
    2012:	00004097          	auipc	ra,0x4
    2016:	80e080e7          	jalr	-2034(ra) # 5820 <exit>
    printf("%s: create 123456789012345/123456789012345/123456789012345 failed\n", s);
    201a:	85a6                	mv	a1,s1
    201c:	00005517          	auipc	a0,0x5
    2020:	c0450513          	addi	a0,a0,-1020 # 6c20 <malloc+0xf70>
    2024:	00004097          	auipc	ra,0x4
    2028:	bce080e7          	jalr	-1074(ra) # 5bf2 <printf>
    exit(1);
    202c:	4505                	li	a0,1
    202e:	00003097          	auipc	ra,0x3
    2032:	7f2080e7          	jalr	2034(ra) # 5820 <exit>
    printf("%s: open 12345678901234/12345678901234/12345678901234 failed\n", s);
    2036:	85a6                	mv	a1,s1
    2038:	00005517          	auipc	a0,0x5
    203c:	c6050513          	addi	a0,a0,-928 # 6c98 <malloc+0xfe8>
    2040:	00004097          	auipc	ra,0x4
    2044:	bb2080e7          	jalr	-1102(ra) # 5bf2 <printf>
    exit(1);
    2048:	4505                	li	a0,1
    204a:	00003097          	auipc	ra,0x3
    204e:	7d6080e7          	jalr	2006(ra) # 5820 <exit>
    printf("%s: mkdir 12345678901234/12345678901234 succeeded!\n", s);
    2052:	85a6                	mv	a1,s1
    2054:	00005517          	auipc	a0,0x5
    2058:	ca450513          	addi	a0,a0,-860 # 6cf8 <malloc+0x1048>
    205c:	00004097          	auipc	ra,0x4
    2060:	b96080e7          	jalr	-1130(ra) # 5bf2 <printf>
    exit(1);
    2064:	4505                	li	a0,1
    2066:	00003097          	auipc	ra,0x3
    206a:	7ba080e7          	jalr	1978(ra) # 5820 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 succeeded!\n", s);
    206e:	85a6                	mv	a1,s1
    2070:	00005517          	auipc	a0,0x5
    2074:	ce050513          	addi	a0,a0,-800 # 6d50 <malloc+0x10a0>
    2078:	00004097          	auipc	ra,0x4
    207c:	b7a080e7          	jalr	-1158(ra) # 5bf2 <printf>
    exit(1);
    2080:	4505                	li	a0,1
    2082:	00003097          	auipc	ra,0x3
    2086:	79e080e7          	jalr	1950(ra) # 5820 <exit>

000000000000208a <iputtest>:
{
    208a:	1101                	addi	sp,sp,-32
    208c:	ec06                	sd	ra,24(sp)
    208e:	e822                	sd	s0,16(sp)
    2090:	e426                	sd	s1,8(sp)
    2092:	1000                	addi	s0,sp,32
    2094:	84aa                	mv	s1,a0
  if(mkdir("iputdir") < 0){
    2096:	00005517          	auipc	a0,0x5
    209a:	cf250513          	addi	a0,a0,-782 # 6d88 <malloc+0x10d8>
    209e:	00003097          	auipc	ra,0x3
    20a2:	7ea080e7          	jalr	2026(ra) # 5888 <mkdir>
    20a6:	04054563          	bltz	a0,20f0 <iputtest+0x66>
  if(chdir("iputdir") < 0){
    20aa:	00005517          	auipc	a0,0x5
    20ae:	cde50513          	addi	a0,a0,-802 # 6d88 <malloc+0x10d8>
    20b2:	00003097          	auipc	ra,0x3
    20b6:	7de080e7          	jalr	2014(ra) # 5890 <chdir>
    20ba:	04054963          	bltz	a0,210c <iputtest+0x82>
  if(unlink("../iputdir") < 0){
    20be:	00005517          	auipc	a0,0x5
    20c2:	d0a50513          	addi	a0,a0,-758 # 6dc8 <malloc+0x1118>
    20c6:	00003097          	auipc	ra,0x3
    20ca:	7aa080e7          	jalr	1962(ra) # 5870 <unlink>
    20ce:	04054d63          	bltz	a0,2128 <iputtest+0x9e>
  if(chdir("/") < 0){
    20d2:	00005517          	auipc	a0,0x5
    20d6:	d2650513          	addi	a0,a0,-730 # 6df8 <malloc+0x1148>
    20da:	00003097          	auipc	ra,0x3
    20de:	7b6080e7          	jalr	1974(ra) # 5890 <chdir>
    20e2:	06054163          	bltz	a0,2144 <iputtest+0xba>
}
    20e6:	60e2                	ld	ra,24(sp)
    20e8:	6442                	ld	s0,16(sp)
    20ea:	64a2                	ld	s1,8(sp)
    20ec:	6105                	addi	sp,sp,32
    20ee:	8082                	ret
    printf("%s: mkdir failed\n", s);
    20f0:	85a6                	mv	a1,s1
    20f2:	00005517          	auipc	a0,0x5
    20f6:	c9e50513          	addi	a0,a0,-866 # 6d90 <malloc+0x10e0>
    20fa:	00004097          	auipc	ra,0x4
    20fe:	af8080e7          	jalr	-1288(ra) # 5bf2 <printf>
    exit(1);
    2102:	4505                	li	a0,1
    2104:	00003097          	auipc	ra,0x3
    2108:	71c080e7          	jalr	1820(ra) # 5820 <exit>
    printf("%s: chdir iputdir failed\n", s);
    210c:	85a6                	mv	a1,s1
    210e:	00005517          	auipc	a0,0x5
    2112:	c9a50513          	addi	a0,a0,-870 # 6da8 <malloc+0x10f8>
    2116:	00004097          	auipc	ra,0x4
    211a:	adc080e7          	jalr	-1316(ra) # 5bf2 <printf>
    exit(1);
    211e:	4505                	li	a0,1
    2120:	00003097          	auipc	ra,0x3
    2124:	700080e7          	jalr	1792(ra) # 5820 <exit>
    printf("%s: unlink ../iputdir failed\n", s);
    2128:	85a6                	mv	a1,s1
    212a:	00005517          	auipc	a0,0x5
    212e:	cae50513          	addi	a0,a0,-850 # 6dd8 <malloc+0x1128>
    2132:	00004097          	auipc	ra,0x4
    2136:	ac0080e7          	jalr	-1344(ra) # 5bf2 <printf>
    exit(1);
    213a:	4505                	li	a0,1
    213c:	00003097          	auipc	ra,0x3
    2140:	6e4080e7          	jalr	1764(ra) # 5820 <exit>
    printf("%s: chdir / failed\n", s);
    2144:	85a6                	mv	a1,s1
    2146:	00005517          	auipc	a0,0x5
    214a:	cba50513          	addi	a0,a0,-838 # 6e00 <malloc+0x1150>
    214e:	00004097          	auipc	ra,0x4
    2152:	aa4080e7          	jalr	-1372(ra) # 5bf2 <printf>
    exit(1);
    2156:	4505                	li	a0,1
    2158:	00003097          	auipc	ra,0x3
    215c:	6c8080e7          	jalr	1736(ra) # 5820 <exit>

0000000000002160 <exitiputtest>:
{
    2160:	7179                	addi	sp,sp,-48
    2162:	f406                	sd	ra,40(sp)
    2164:	f022                	sd	s0,32(sp)
    2166:	ec26                	sd	s1,24(sp)
    2168:	1800                	addi	s0,sp,48
    216a:	84aa                	mv	s1,a0
  pid = fork();
    216c:	00003097          	auipc	ra,0x3
    2170:	6ac080e7          	jalr	1708(ra) # 5818 <fork>
  if(pid < 0){
    2174:	04054663          	bltz	a0,21c0 <exitiputtest+0x60>
  if(pid == 0){
    2178:	ed45                	bnez	a0,2230 <exitiputtest+0xd0>
    if(mkdir("iputdir") < 0){
    217a:	00005517          	auipc	a0,0x5
    217e:	c0e50513          	addi	a0,a0,-1010 # 6d88 <malloc+0x10d8>
    2182:	00003097          	auipc	ra,0x3
    2186:	706080e7          	jalr	1798(ra) # 5888 <mkdir>
    218a:	04054963          	bltz	a0,21dc <exitiputtest+0x7c>
    if(chdir("iputdir") < 0){
    218e:	00005517          	auipc	a0,0x5
    2192:	bfa50513          	addi	a0,a0,-1030 # 6d88 <malloc+0x10d8>
    2196:	00003097          	auipc	ra,0x3
    219a:	6fa080e7          	jalr	1786(ra) # 5890 <chdir>
    219e:	04054d63          	bltz	a0,21f8 <exitiputtest+0x98>
    if(unlink("../iputdir") < 0){
    21a2:	00005517          	auipc	a0,0x5
    21a6:	c2650513          	addi	a0,a0,-986 # 6dc8 <malloc+0x1118>
    21aa:	00003097          	auipc	ra,0x3
    21ae:	6c6080e7          	jalr	1734(ra) # 5870 <unlink>
    21b2:	06054163          	bltz	a0,2214 <exitiputtest+0xb4>
    exit(0);
    21b6:	4501                	li	a0,0
    21b8:	00003097          	auipc	ra,0x3
    21bc:	668080e7          	jalr	1640(ra) # 5820 <exit>
    printf("%s: fork failed\n", s);
    21c0:	85a6                	mv	a1,s1
    21c2:	00004517          	auipc	a0,0x4
    21c6:	e6650513          	addi	a0,a0,-410 # 6028 <malloc+0x378>
    21ca:	00004097          	auipc	ra,0x4
    21ce:	a28080e7          	jalr	-1496(ra) # 5bf2 <printf>
    exit(1);
    21d2:	4505                	li	a0,1
    21d4:	00003097          	auipc	ra,0x3
    21d8:	64c080e7          	jalr	1612(ra) # 5820 <exit>
      printf("%s: mkdir failed\n", s);
    21dc:	85a6                	mv	a1,s1
    21de:	00005517          	auipc	a0,0x5
    21e2:	bb250513          	addi	a0,a0,-1102 # 6d90 <malloc+0x10e0>
    21e6:	00004097          	auipc	ra,0x4
    21ea:	a0c080e7          	jalr	-1524(ra) # 5bf2 <printf>
      exit(1);
    21ee:	4505                	li	a0,1
    21f0:	00003097          	auipc	ra,0x3
    21f4:	630080e7          	jalr	1584(ra) # 5820 <exit>
      printf("%s: child chdir failed\n", s);
    21f8:	85a6                	mv	a1,s1
    21fa:	00005517          	auipc	a0,0x5
    21fe:	c1e50513          	addi	a0,a0,-994 # 6e18 <malloc+0x1168>
    2202:	00004097          	auipc	ra,0x4
    2206:	9f0080e7          	jalr	-1552(ra) # 5bf2 <printf>
      exit(1);
    220a:	4505                	li	a0,1
    220c:	00003097          	auipc	ra,0x3
    2210:	614080e7          	jalr	1556(ra) # 5820 <exit>
      printf("%s: unlink ../iputdir failed\n", s);
    2214:	85a6                	mv	a1,s1
    2216:	00005517          	auipc	a0,0x5
    221a:	bc250513          	addi	a0,a0,-1086 # 6dd8 <malloc+0x1128>
    221e:	00004097          	auipc	ra,0x4
    2222:	9d4080e7          	jalr	-1580(ra) # 5bf2 <printf>
      exit(1);
    2226:	4505                	li	a0,1
    2228:	00003097          	auipc	ra,0x3
    222c:	5f8080e7          	jalr	1528(ra) # 5820 <exit>
  wait(&xstatus);
    2230:	fdc40513          	addi	a0,s0,-36
    2234:	00003097          	auipc	ra,0x3
    2238:	5f4080e7          	jalr	1524(ra) # 5828 <wait>
  exit(xstatus);
    223c:	fdc42503          	lw	a0,-36(s0)
    2240:	00003097          	auipc	ra,0x3
    2244:	5e0080e7          	jalr	1504(ra) # 5820 <exit>

0000000000002248 <dirtest>:
{
    2248:	1101                	addi	sp,sp,-32
    224a:	ec06                	sd	ra,24(sp)
    224c:	e822                	sd	s0,16(sp)
    224e:	e426                	sd	s1,8(sp)
    2250:	1000                	addi	s0,sp,32
    2252:	84aa                	mv	s1,a0
  if(mkdir("dir0") < 0){
    2254:	00005517          	auipc	a0,0x5
    2258:	bdc50513          	addi	a0,a0,-1060 # 6e30 <malloc+0x1180>
    225c:	00003097          	auipc	ra,0x3
    2260:	62c080e7          	jalr	1580(ra) # 5888 <mkdir>
    2264:	04054563          	bltz	a0,22ae <dirtest+0x66>
  if(chdir("dir0") < 0){
    2268:	00005517          	auipc	a0,0x5
    226c:	bc850513          	addi	a0,a0,-1080 # 6e30 <malloc+0x1180>
    2270:	00003097          	auipc	ra,0x3
    2274:	620080e7          	jalr	1568(ra) # 5890 <chdir>
    2278:	04054963          	bltz	a0,22ca <dirtest+0x82>
  if(chdir("..") < 0){
    227c:	00005517          	auipc	a0,0x5
    2280:	bd450513          	addi	a0,a0,-1068 # 6e50 <malloc+0x11a0>
    2284:	00003097          	auipc	ra,0x3
    2288:	60c080e7          	jalr	1548(ra) # 5890 <chdir>
    228c:	04054d63          	bltz	a0,22e6 <dirtest+0x9e>
  if(unlink("dir0") < 0){
    2290:	00005517          	auipc	a0,0x5
    2294:	ba050513          	addi	a0,a0,-1120 # 6e30 <malloc+0x1180>
    2298:	00003097          	auipc	ra,0x3
    229c:	5d8080e7          	jalr	1496(ra) # 5870 <unlink>
    22a0:	06054163          	bltz	a0,2302 <dirtest+0xba>
}
    22a4:	60e2                	ld	ra,24(sp)
    22a6:	6442                	ld	s0,16(sp)
    22a8:	64a2                	ld	s1,8(sp)
    22aa:	6105                	addi	sp,sp,32
    22ac:	8082                	ret
    printf("%s: mkdir failed\n", s);
    22ae:	85a6                	mv	a1,s1
    22b0:	00005517          	auipc	a0,0x5
    22b4:	ae050513          	addi	a0,a0,-1312 # 6d90 <malloc+0x10e0>
    22b8:	00004097          	auipc	ra,0x4
    22bc:	93a080e7          	jalr	-1734(ra) # 5bf2 <printf>
    exit(1);
    22c0:	4505                	li	a0,1
    22c2:	00003097          	auipc	ra,0x3
    22c6:	55e080e7          	jalr	1374(ra) # 5820 <exit>
    printf("%s: chdir dir0 failed\n", s);
    22ca:	85a6                	mv	a1,s1
    22cc:	00005517          	auipc	a0,0x5
    22d0:	b6c50513          	addi	a0,a0,-1172 # 6e38 <malloc+0x1188>
    22d4:	00004097          	auipc	ra,0x4
    22d8:	91e080e7          	jalr	-1762(ra) # 5bf2 <printf>
    exit(1);
    22dc:	4505                	li	a0,1
    22de:	00003097          	auipc	ra,0x3
    22e2:	542080e7          	jalr	1346(ra) # 5820 <exit>
    printf("%s: chdir .. failed\n", s);
    22e6:	85a6                	mv	a1,s1
    22e8:	00005517          	auipc	a0,0x5
    22ec:	b7050513          	addi	a0,a0,-1168 # 6e58 <malloc+0x11a8>
    22f0:	00004097          	auipc	ra,0x4
    22f4:	902080e7          	jalr	-1790(ra) # 5bf2 <printf>
    exit(1);
    22f8:	4505                	li	a0,1
    22fa:	00003097          	auipc	ra,0x3
    22fe:	526080e7          	jalr	1318(ra) # 5820 <exit>
    printf("%s: unlink dir0 failed\n", s);
    2302:	85a6                	mv	a1,s1
    2304:	00005517          	auipc	a0,0x5
    2308:	b6c50513          	addi	a0,a0,-1172 # 6e70 <malloc+0x11c0>
    230c:	00004097          	auipc	ra,0x4
    2310:	8e6080e7          	jalr	-1818(ra) # 5bf2 <printf>
    exit(1);
    2314:	4505                	li	a0,1
    2316:	00003097          	auipc	ra,0x3
    231a:	50a080e7          	jalr	1290(ra) # 5820 <exit>

000000000000231e <subdir>:
{
    231e:	1101                	addi	sp,sp,-32
    2320:	ec06                	sd	ra,24(sp)
    2322:	e822                	sd	s0,16(sp)
    2324:	e426                	sd	s1,8(sp)
    2326:	e04a                	sd	s2,0(sp)
    2328:	1000                	addi	s0,sp,32
    232a:	892a                	mv	s2,a0
  unlink("ff");
    232c:	00005517          	auipc	a0,0x5
    2330:	c8c50513          	addi	a0,a0,-884 # 6fb8 <malloc+0x1308>
    2334:	00003097          	auipc	ra,0x3
    2338:	53c080e7          	jalr	1340(ra) # 5870 <unlink>
  if(mkdir("dd") != 0){
    233c:	00005517          	auipc	a0,0x5
    2340:	b4c50513          	addi	a0,a0,-1204 # 6e88 <malloc+0x11d8>
    2344:	00003097          	auipc	ra,0x3
    2348:	544080e7          	jalr	1348(ra) # 5888 <mkdir>
    234c:	38051663          	bnez	a0,26d8 <subdir+0x3ba>
  fd = open("dd/ff", O_CREATE | O_RDWR);
    2350:	20200593          	li	a1,514
    2354:	00005517          	auipc	a0,0x5
    2358:	b5450513          	addi	a0,a0,-1196 # 6ea8 <malloc+0x11f8>
    235c:	00003097          	auipc	ra,0x3
    2360:	504080e7          	jalr	1284(ra) # 5860 <open>
    2364:	84aa                	mv	s1,a0
  if(fd < 0){
    2366:	38054763          	bltz	a0,26f4 <subdir+0x3d6>
  write(fd, "ff", 2);
    236a:	4609                	li	a2,2
    236c:	00005597          	auipc	a1,0x5
    2370:	c4c58593          	addi	a1,a1,-948 # 6fb8 <malloc+0x1308>
    2374:	00003097          	auipc	ra,0x3
    2378:	4cc080e7          	jalr	1228(ra) # 5840 <write>
  close(fd);
    237c:	8526                	mv	a0,s1
    237e:	00003097          	auipc	ra,0x3
    2382:	4ca080e7          	jalr	1226(ra) # 5848 <close>
  if(unlink("dd") >= 0){
    2386:	00005517          	auipc	a0,0x5
    238a:	b0250513          	addi	a0,a0,-1278 # 6e88 <malloc+0x11d8>
    238e:	00003097          	auipc	ra,0x3
    2392:	4e2080e7          	jalr	1250(ra) # 5870 <unlink>
    2396:	36055d63          	bgez	a0,2710 <subdir+0x3f2>
  if(mkdir("/dd/dd") != 0){
    239a:	00005517          	auipc	a0,0x5
    239e:	b6650513          	addi	a0,a0,-1178 # 6f00 <malloc+0x1250>
    23a2:	00003097          	auipc	ra,0x3
    23a6:	4e6080e7          	jalr	1254(ra) # 5888 <mkdir>
    23aa:	38051163          	bnez	a0,272c <subdir+0x40e>
  fd = open("dd/dd/ff", O_CREATE | O_RDWR);
    23ae:	20200593          	li	a1,514
    23b2:	00005517          	auipc	a0,0x5
    23b6:	b7650513          	addi	a0,a0,-1162 # 6f28 <malloc+0x1278>
    23ba:	00003097          	auipc	ra,0x3
    23be:	4a6080e7          	jalr	1190(ra) # 5860 <open>
    23c2:	84aa                	mv	s1,a0
  if(fd < 0){
    23c4:	38054263          	bltz	a0,2748 <subdir+0x42a>
  write(fd, "FF", 2);
    23c8:	4609                	li	a2,2
    23ca:	00005597          	auipc	a1,0x5
    23ce:	b8e58593          	addi	a1,a1,-1138 # 6f58 <malloc+0x12a8>
    23d2:	00003097          	auipc	ra,0x3
    23d6:	46e080e7          	jalr	1134(ra) # 5840 <write>
  close(fd);
    23da:	8526                	mv	a0,s1
    23dc:	00003097          	auipc	ra,0x3
    23e0:	46c080e7          	jalr	1132(ra) # 5848 <close>
  fd = open("dd/dd/../ff", 0);
    23e4:	4581                	li	a1,0
    23e6:	00005517          	auipc	a0,0x5
    23ea:	b7a50513          	addi	a0,a0,-1158 # 6f60 <malloc+0x12b0>
    23ee:	00003097          	auipc	ra,0x3
    23f2:	472080e7          	jalr	1138(ra) # 5860 <open>
    23f6:	84aa                	mv	s1,a0
  if(fd < 0){
    23f8:	36054663          	bltz	a0,2764 <subdir+0x446>
  cc = read(fd, buf, sizeof(buf));
    23fc:	660d                	lui	a2,0x3
    23fe:	00009597          	auipc	a1,0x9
    2402:	7b258593          	addi	a1,a1,1970 # bbb0 <buf>
    2406:	00003097          	auipc	ra,0x3
    240a:	432080e7          	jalr	1074(ra) # 5838 <read>
  if(cc != 2 || buf[0] != 'f'){
    240e:	4789                	li	a5,2
    2410:	36f51863          	bne	a0,a5,2780 <subdir+0x462>
    2414:	00009717          	auipc	a4,0x9
    2418:	79c74703          	lbu	a4,1948(a4) # bbb0 <buf>
    241c:	06600793          	li	a5,102
    2420:	36f71063          	bne	a4,a5,2780 <subdir+0x462>
  close(fd);
    2424:	8526                	mv	a0,s1
    2426:	00003097          	auipc	ra,0x3
    242a:	422080e7          	jalr	1058(ra) # 5848 <close>
  if(link("dd/dd/ff", "dd/dd/ffff") != 0){
    242e:	00005597          	auipc	a1,0x5
    2432:	b8258593          	addi	a1,a1,-1150 # 6fb0 <malloc+0x1300>
    2436:	00005517          	auipc	a0,0x5
    243a:	af250513          	addi	a0,a0,-1294 # 6f28 <malloc+0x1278>
    243e:	00003097          	auipc	ra,0x3
    2442:	442080e7          	jalr	1090(ra) # 5880 <link>
    2446:	34051b63          	bnez	a0,279c <subdir+0x47e>
  if(unlink("dd/dd/ff") != 0){
    244a:	00005517          	auipc	a0,0x5
    244e:	ade50513          	addi	a0,a0,-1314 # 6f28 <malloc+0x1278>
    2452:	00003097          	auipc	ra,0x3
    2456:	41e080e7          	jalr	1054(ra) # 5870 <unlink>
    245a:	34051f63          	bnez	a0,27b8 <subdir+0x49a>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    245e:	4581                	li	a1,0
    2460:	00005517          	auipc	a0,0x5
    2464:	ac850513          	addi	a0,a0,-1336 # 6f28 <malloc+0x1278>
    2468:	00003097          	auipc	ra,0x3
    246c:	3f8080e7          	jalr	1016(ra) # 5860 <open>
    2470:	36055263          	bgez	a0,27d4 <subdir+0x4b6>
  if(chdir("dd") != 0){
    2474:	00005517          	auipc	a0,0x5
    2478:	a1450513          	addi	a0,a0,-1516 # 6e88 <malloc+0x11d8>
    247c:	00003097          	auipc	ra,0x3
    2480:	414080e7          	jalr	1044(ra) # 5890 <chdir>
    2484:	36051663          	bnez	a0,27f0 <subdir+0x4d2>
  if(chdir("dd/../../dd") != 0){
    2488:	00005517          	auipc	a0,0x5
    248c:	bc050513          	addi	a0,a0,-1088 # 7048 <malloc+0x1398>
    2490:	00003097          	auipc	ra,0x3
    2494:	400080e7          	jalr	1024(ra) # 5890 <chdir>
    2498:	36051a63          	bnez	a0,280c <subdir+0x4ee>
  if(chdir("dd/../../../dd") != 0){
    249c:	00005517          	auipc	a0,0x5
    24a0:	bdc50513          	addi	a0,a0,-1060 # 7078 <malloc+0x13c8>
    24a4:	00003097          	auipc	ra,0x3
    24a8:	3ec080e7          	jalr	1004(ra) # 5890 <chdir>
    24ac:	36051e63          	bnez	a0,2828 <subdir+0x50a>
  if(chdir("./..") != 0){
    24b0:	00005517          	auipc	a0,0x5
    24b4:	bf850513          	addi	a0,a0,-1032 # 70a8 <malloc+0x13f8>
    24b8:	00003097          	auipc	ra,0x3
    24bc:	3d8080e7          	jalr	984(ra) # 5890 <chdir>
    24c0:	38051263          	bnez	a0,2844 <subdir+0x526>
  fd = open("dd/dd/ffff", 0);
    24c4:	4581                	li	a1,0
    24c6:	00005517          	auipc	a0,0x5
    24ca:	aea50513          	addi	a0,a0,-1302 # 6fb0 <malloc+0x1300>
    24ce:	00003097          	auipc	ra,0x3
    24d2:	392080e7          	jalr	914(ra) # 5860 <open>
    24d6:	84aa                	mv	s1,a0
  if(fd < 0){
    24d8:	38054463          	bltz	a0,2860 <subdir+0x542>
  if(read(fd, buf, sizeof(buf)) != 2){
    24dc:	660d                	lui	a2,0x3
    24de:	00009597          	auipc	a1,0x9
    24e2:	6d258593          	addi	a1,a1,1746 # bbb0 <buf>
    24e6:	00003097          	auipc	ra,0x3
    24ea:	352080e7          	jalr	850(ra) # 5838 <read>
    24ee:	4789                	li	a5,2
    24f0:	38f51663          	bne	a0,a5,287c <subdir+0x55e>
  close(fd);
    24f4:	8526                	mv	a0,s1
    24f6:	00003097          	auipc	ra,0x3
    24fa:	352080e7          	jalr	850(ra) # 5848 <close>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    24fe:	4581                	li	a1,0
    2500:	00005517          	auipc	a0,0x5
    2504:	a2850513          	addi	a0,a0,-1496 # 6f28 <malloc+0x1278>
    2508:	00003097          	auipc	ra,0x3
    250c:	358080e7          	jalr	856(ra) # 5860 <open>
    2510:	38055463          	bgez	a0,2898 <subdir+0x57a>
  if(open("dd/ff/ff", O_CREATE|O_RDWR) >= 0){
    2514:	20200593          	li	a1,514
    2518:	00005517          	auipc	a0,0x5
    251c:	c2050513          	addi	a0,a0,-992 # 7138 <malloc+0x1488>
    2520:	00003097          	auipc	ra,0x3
    2524:	340080e7          	jalr	832(ra) # 5860 <open>
    2528:	38055663          	bgez	a0,28b4 <subdir+0x596>
  if(open("dd/xx/ff", O_CREATE|O_RDWR) >= 0){
    252c:	20200593          	li	a1,514
    2530:	00005517          	auipc	a0,0x5
    2534:	c3850513          	addi	a0,a0,-968 # 7168 <malloc+0x14b8>
    2538:	00003097          	auipc	ra,0x3
    253c:	328080e7          	jalr	808(ra) # 5860 <open>
    2540:	38055863          	bgez	a0,28d0 <subdir+0x5b2>
  if(open("dd", O_CREATE) >= 0){
    2544:	20000593          	li	a1,512
    2548:	00005517          	auipc	a0,0x5
    254c:	94050513          	addi	a0,a0,-1728 # 6e88 <malloc+0x11d8>
    2550:	00003097          	auipc	ra,0x3
    2554:	310080e7          	jalr	784(ra) # 5860 <open>
    2558:	38055a63          	bgez	a0,28ec <subdir+0x5ce>
  if(open("dd", O_RDWR) >= 0){
    255c:	4589                	li	a1,2
    255e:	00005517          	auipc	a0,0x5
    2562:	92a50513          	addi	a0,a0,-1750 # 6e88 <malloc+0x11d8>
    2566:	00003097          	auipc	ra,0x3
    256a:	2fa080e7          	jalr	762(ra) # 5860 <open>
    256e:	38055d63          	bgez	a0,2908 <subdir+0x5ea>
  if(open("dd", O_WRONLY) >= 0){
    2572:	4585                	li	a1,1
    2574:	00005517          	auipc	a0,0x5
    2578:	91450513          	addi	a0,a0,-1772 # 6e88 <malloc+0x11d8>
    257c:	00003097          	auipc	ra,0x3
    2580:	2e4080e7          	jalr	740(ra) # 5860 <open>
    2584:	3a055063          	bgez	a0,2924 <subdir+0x606>
  if(link("dd/ff/ff", "dd/dd/xx") == 0){
    2588:	00005597          	auipc	a1,0x5
    258c:	c7058593          	addi	a1,a1,-912 # 71f8 <malloc+0x1548>
    2590:	00005517          	auipc	a0,0x5
    2594:	ba850513          	addi	a0,a0,-1112 # 7138 <malloc+0x1488>
    2598:	00003097          	auipc	ra,0x3
    259c:	2e8080e7          	jalr	744(ra) # 5880 <link>
    25a0:	3a050063          	beqz	a0,2940 <subdir+0x622>
  if(link("dd/xx/ff", "dd/dd/xx") == 0){
    25a4:	00005597          	auipc	a1,0x5
    25a8:	c5458593          	addi	a1,a1,-940 # 71f8 <malloc+0x1548>
    25ac:	00005517          	auipc	a0,0x5
    25b0:	bbc50513          	addi	a0,a0,-1092 # 7168 <malloc+0x14b8>
    25b4:	00003097          	auipc	ra,0x3
    25b8:	2cc080e7          	jalr	716(ra) # 5880 <link>
    25bc:	3a050063          	beqz	a0,295c <subdir+0x63e>
  if(link("dd/ff", "dd/dd/ffff") == 0){
    25c0:	00005597          	auipc	a1,0x5
    25c4:	9f058593          	addi	a1,a1,-1552 # 6fb0 <malloc+0x1300>
    25c8:	00005517          	auipc	a0,0x5
    25cc:	8e050513          	addi	a0,a0,-1824 # 6ea8 <malloc+0x11f8>
    25d0:	00003097          	auipc	ra,0x3
    25d4:	2b0080e7          	jalr	688(ra) # 5880 <link>
    25d8:	3a050063          	beqz	a0,2978 <subdir+0x65a>
  if(mkdir("dd/ff/ff") == 0){
    25dc:	00005517          	auipc	a0,0x5
    25e0:	b5c50513          	addi	a0,a0,-1188 # 7138 <malloc+0x1488>
    25e4:	00003097          	auipc	ra,0x3
    25e8:	2a4080e7          	jalr	676(ra) # 5888 <mkdir>
    25ec:	3a050463          	beqz	a0,2994 <subdir+0x676>
  if(mkdir("dd/xx/ff") == 0){
    25f0:	00005517          	auipc	a0,0x5
    25f4:	b7850513          	addi	a0,a0,-1160 # 7168 <malloc+0x14b8>
    25f8:	00003097          	auipc	ra,0x3
    25fc:	290080e7          	jalr	656(ra) # 5888 <mkdir>
    2600:	3a050863          	beqz	a0,29b0 <subdir+0x692>
  if(mkdir("dd/dd/ffff") == 0){
    2604:	00005517          	auipc	a0,0x5
    2608:	9ac50513          	addi	a0,a0,-1620 # 6fb0 <malloc+0x1300>
    260c:	00003097          	auipc	ra,0x3
    2610:	27c080e7          	jalr	636(ra) # 5888 <mkdir>
    2614:	3a050c63          	beqz	a0,29cc <subdir+0x6ae>
  if(unlink("dd/xx/ff") == 0){
    2618:	00005517          	auipc	a0,0x5
    261c:	b5050513          	addi	a0,a0,-1200 # 7168 <malloc+0x14b8>
    2620:	00003097          	auipc	ra,0x3
    2624:	250080e7          	jalr	592(ra) # 5870 <unlink>
    2628:	3c050063          	beqz	a0,29e8 <subdir+0x6ca>
  if(unlink("dd/ff/ff") == 0){
    262c:	00005517          	auipc	a0,0x5
    2630:	b0c50513          	addi	a0,a0,-1268 # 7138 <malloc+0x1488>
    2634:	00003097          	auipc	ra,0x3
    2638:	23c080e7          	jalr	572(ra) # 5870 <unlink>
    263c:	3c050463          	beqz	a0,2a04 <subdir+0x6e6>
  if(chdir("dd/ff") == 0){
    2640:	00005517          	auipc	a0,0x5
    2644:	86850513          	addi	a0,a0,-1944 # 6ea8 <malloc+0x11f8>
    2648:	00003097          	auipc	ra,0x3
    264c:	248080e7          	jalr	584(ra) # 5890 <chdir>
    2650:	3c050863          	beqz	a0,2a20 <subdir+0x702>
  if(chdir("dd/xx") == 0){
    2654:	00005517          	auipc	a0,0x5
    2658:	cf450513          	addi	a0,a0,-780 # 7348 <malloc+0x1698>
    265c:	00003097          	auipc	ra,0x3
    2660:	234080e7          	jalr	564(ra) # 5890 <chdir>
    2664:	3c050c63          	beqz	a0,2a3c <subdir+0x71e>
  if(unlink("dd/dd/ffff") != 0){
    2668:	00005517          	auipc	a0,0x5
    266c:	94850513          	addi	a0,a0,-1720 # 6fb0 <malloc+0x1300>
    2670:	00003097          	auipc	ra,0x3
    2674:	200080e7          	jalr	512(ra) # 5870 <unlink>
    2678:	3e051063          	bnez	a0,2a58 <subdir+0x73a>
  if(unlink("dd/ff") != 0){
    267c:	00005517          	auipc	a0,0x5
    2680:	82c50513          	addi	a0,a0,-2004 # 6ea8 <malloc+0x11f8>
    2684:	00003097          	auipc	ra,0x3
    2688:	1ec080e7          	jalr	492(ra) # 5870 <unlink>
    268c:	3e051463          	bnez	a0,2a74 <subdir+0x756>
  if(unlink("dd") == 0){
    2690:	00004517          	auipc	a0,0x4
    2694:	7f850513          	addi	a0,a0,2040 # 6e88 <malloc+0x11d8>
    2698:	00003097          	auipc	ra,0x3
    269c:	1d8080e7          	jalr	472(ra) # 5870 <unlink>
    26a0:	3e050863          	beqz	a0,2a90 <subdir+0x772>
  if(unlink("dd/dd") < 0){
    26a4:	00005517          	auipc	a0,0x5
    26a8:	d1450513          	addi	a0,a0,-748 # 73b8 <malloc+0x1708>
    26ac:	00003097          	auipc	ra,0x3
    26b0:	1c4080e7          	jalr	452(ra) # 5870 <unlink>
    26b4:	3e054c63          	bltz	a0,2aac <subdir+0x78e>
  if(unlink("dd") < 0){
    26b8:	00004517          	auipc	a0,0x4
    26bc:	7d050513          	addi	a0,a0,2000 # 6e88 <malloc+0x11d8>
    26c0:	00003097          	auipc	ra,0x3
    26c4:	1b0080e7          	jalr	432(ra) # 5870 <unlink>
    26c8:	40054063          	bltz	a0,2ac8 <subdir+0x7aa>
}
    26cc:	60e2                	ld	ra,24(sp)
    26ce:	6442                	ld	s0,16(sp)
    26d0:	64a2                	ld	s1,8(sp)
    26d2:	6902                	ld	s2,0(sp)
    26d4:	6105                	addi	sp,sp,32
    26d6:	8082                	ret
    printf("%s: mkdir dd failed\n", s);
    26d8:	85ca                	mv	a1,s2
    26da:	00004517          	auipc	a0,0x4
    26de:	7b650513          	addi	a0,a0,1974 # 6e90 <malloc+0x11e0>
    26e2:	00003097          	auipc	ra,0x3
    26e6:	510080e7          	jalr	1296(ra) # 5bf2 <printf>
    exit(1);
    26ea:	4505                	li	a0,1
    26ec:	00003097          	auipc	ra,0x3
    26f0:	134080e7          	jalr	308(ra) # 5820 <exit>
    printf("%s: create dd/ff failed\n", s);
    26f4:	85ca                	mv	a1,s2
    26f6:	00004517          	auipc	a0,0x4
    26fa:	7ba50513          	addi	a0,a0,1978 # 6eb0 <malloc+0x1200>
    26fe:	00003097          	auipc	ra,0x3
    2702:	4f4080e7          	jalr	1268(ra) # 5bf2 <printf>
    exit(1);
    2706:	4505                	li	a0,1
    2708:	00003097          	auipc	ra,0x3
    270c:	118080e7          	jalr	280(ra) # 5820 <exit>
    printf("%s: unlink dd (non-empty dir) succeeded!\n", s);
    2710:	85ca                	mv	a1,s2
    2712:	00004517          	auipc	a0,0x4
    2716:	7be50513          	addi	a0,a0,1982 # 6ed0 <malloc+0x1220>
    271a:	00003097          	auipc	ra,0x3
    271e:	4d8080e7          	jalr	1240(ra) # 5bf2 <printf>
    exit(1);
    2722:	4505                	li	a0,1
    2724:	00003097          	auipc	ra,0x3
    2728:	0fc080e7          	jalr	252(ra) # 5820 <exit>
    printf("subdir mkdir dd/dd failed\n", s);
    272c:	85ca                	mv	a1,s2
    272e:	00004517          	auipc	a0,0x4
    2732:	7da50513          	addi	a0,a0,2010 # 6f08 <malloc+0x1258>
    2736:	00003097          	auipc	ra,0x3
    273a:	4bc080e7          	jalr	1212(ra) # 5bf2 <printf>
    exit(1);
    273e:	4505                	li	a0,1
    2740:	00003097          	auipc	ra,0x3
    2744:	0e0080e7          	jalr	224(ra) # 5820 <exit>
    printf("%s: create dd/dd/ff failed\n", s);
    2748:	85ca                	mv	a1,s2
    274a:	00004517          	auipc	a0,0x4
    274e:	7ee50513          	addi	a0,a0,2030 # 6f38 <malloc+0x1288>
    2752:	00003097          	auipc	ra,0x3
    2756:	4a0080e7          	jalr	1184(ra) # 5bf2 <printf>
    exit(1);
    275a:	4505                	li	a0,1
    275c:	00003097          	auipc	ra,0x3
    2760:	0c4080e7          	jalr	196(ra) # 5820 <exit>
    printf("%s: open dd/dd/../ff failed\n", s);
    2764:	85ca                	mv	a1,s2
    2766:	00005517          	auipc	a0,0x5
    276a:	80a50513          	addi	a0,a0,-2038 # 6f70 <malloc+0x12c0>
    276e:	00003097          	auipc	ra,0x3
    2772:	484080e7          	jalr	1156(ra) # 5bf2 <printf>
    exit(1);
    2776:	4505                	li	a0,1
    2778:	00003097          	auipc	ra,0x3
    277c:	0a8080e7          	jalr	168(ra) # 5820 <exit>
    printf("%s: dd/dd/../ff wrong content\n", s);
    2780:	85ca                	mv	a1,s2
    2782:	00005517          	auipc	a0,0x5
    2786:	80e50513          	addi	a0,a0,-2034 # 6f90 <malloc+0x12e0>
    278a:	00003097          	auipc	ra,0x3
    278e:	468080e7          	jalr	1128(ra) # 5bf2 <printf>
    exit(1);
    2792:	4505                	li	a0,1
    2794:	00003097          	auipc	ra,0x3
    2798:	08c080e7          	jalr	140(ra) # 5820 <exit>
    printf("link dd/dd/ff dd/dd/ffff failed\n", s);
    279c:	85ca                	mv	a1,s2
    279e:	00005517          	auipc	a0,0x5
    27a2:	82250513          	addi	a0,a0,-2014 # 6fc0 <malloc+0x1310>
    27a6:	00003097          	auipc	ra,0x3
    27aa:	44c080e7          	jalr	1100(ra) # 5bf2 <printf>
    exit(1);
    27ae:	4505                	li	a0,1
    27b0:	00003097          	auipc	ra,0x3
    27b4:	070080e7          	jalr	112(ra) # 5820 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    27b8:	85ca                	mv	a1,s2
    27ba:	00005517          	auipc	a0,0x5
    27be:	82e50513          	addi	a0,a0,-2002 # 6fe8 <malloc+0x1338>
    27c2:	00003097          	auipc	ra,0x3
    27c6:	430080e7          	jalr	1072(ra) # 5bf2 <printf>
    exit(1);
    27ca:	4505                	li	a0,1
    27cc:	00003097          	auipc	ra,0x3
    27d0:	054080e7          	jalr	84(ra) # 5820 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded\n", s);
    27d4:	85ca                	mv	a1,s2
    27d6:	00005517          	auipc	a0,0x5
    27da:	83250513          	addi	a0,a0,-1998 # 7008 <malloc+0x1358>
    27de:	00003097          	auipc	ra,0x3
    27e2:	414080e7          	jalr	1044(ra) # 5bf2 <printf>
    exit(1);
    27e6:	4505                	li	a0,1
    27e8:	00003097          	auipc	ra,0x3
    27ec:	038080e7          	jalr	56(ra) # 5820 <exit>
    printf("%s: chdir dd failed\n", s);
    27f0:	85ca                	mv	a1,s2
    27f2:	00005517          	auipc	a0,0x5
    27f6:	83e50513          	addi	a0,a0,-1986 # 7030 <malloc+0x1380>
    27fa:	00003097          	auipc	ra,0x3
    27fe:	3f8080e7          	jalr	1016(ra) # 5bf2 <printf>
    exit(1);
    2802:	4505                	li	a0,1
    2804:	00003097          	auipc	ra,0x3
    2808:	01c080e7          	jalr	28(ra) # 5820 <exit>
    printf("%s: chdir dd/../../dd failed\n", s);
    280c:	85ca                	mv	a1,s2
    280e:	00005517          	auipc	a0,0x5
    2812:	84a50513          	addi	a0,a0,-1974 # 7058 <malloc+0x13a8>
    2816:	00003097          	auipc	ra,0x3
    281a:	3dc080e7          	jalr	988(ra) # 5bf2 <printf>
    exit(1);
    281e:	4505                	li	a0,1
    2820:	00003097          	auipc	ra,0x3
    2824:	000080e7          	jalr	ra # 5820 <exit>
    printf("chdir dd/../../dd failed\n", s);
    2828:	85ca                	mv	a1,s2
    282a:	00005517          	auipc	a0,0x5
    282e:	85e50513          	addi	a0,a0,-1954 # 7088 <malloc+0x13d8>
    2832:	00003097          	auipc	ra,0x3
    2836:	3c0080e7          	jalr	960(ra) # 5bf2 <printf>
    exit(1);
    283a:	4505                	li	a0,1
    283c:	00003097          	auipc	ra,0x3
    2840:	fe4080e7          	jalr	-28(ra) # 5820 <exit>
    printf("%s: chdir ./.. failed\n", s);
    2844:	85ca                	mv	a1,s2
    2846:	00005517          	auipc	a0,0x5
    284a:	86a50513          	addi	a0,a0,-1942 # 70b0 <malloc+0x1400>
    284e:	00003097          	auipc	ra,0x3
    2852:	3a4080e7          	jalr	932(ra) # 5bf2 <printf>
    exit(1);
    2856:	4505                	li	a0,1
    2858:	00003097          	auipc	ra,0x3
    285c:	fc8080e7          	jalr	-56(ra) # 5820 <exit>
    printf("%s: open dd/dd/ffff failed\n", s);
    2860:	85ca                	mv	a1,s2
    2862:	00005517          	auipc	a0,0x5
    2866:	86650513          	addi	a0,a0,-1946 # 70c8 <malloc+0x1418>
    286a:	00003097          	auipc	ra,0x3
    286e:	388080e7          	jalr	904(ra) # 5bf2 <printf>
    exit(1);
    2872:	4505                	li	a0,1
    2874:	00003097          	auipc	ra,0x3
    2878:	fac080e7          	jalr	-84(ra) # 5820 <exit>
    printf("%s: read dd/dd/ffff wrong len\n", s);
    287c:	85ca                	mv	a1,s2
    287e:	00005517          	auipc	a0,0x5
    2882:	86a50513          	addi	a0,a0,-1942 # 70e8 <malloc+0x1438>
    2886:	00003097          	auipc	ra,0x3
    288a:	36c080e7          	jalr	876(ra) # 5bf2 <printf>
    exit(1);
    288e:	4505                	li	a0,1
    2890:	00003097          	auipc	ra,0x3
    2894:	f90080e7          	jalr	-112(ra) # 5820 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded!\n", s);
    2898:	85ca                	mv	a1,s2
    289a:	00005517          	auipc	a0,0x5
    289e:	86e50513          	addi	a0,a0,-1938 # 7108 <malloc+0x1458>
    28a2:	00003097          	auipc	ra,0x3
    28a6:	350080e7          	jalr	848(ra) # 5bf2 <printf>
    exit(1);
    28aa:	4505                	li	a0,1
    28ac:	00003097          	auipc	ra,0x3
    28b0:	f74080e7          	jalr	-140(ra) # 5820 <exit>
    printf("%s: create dd/ff/ff succeeded!\n", s);
    28b4:	85ca                	mv	a1,s2
    28b6:	00005517          	auipc	a0,0x5
    28ba:	89250513          	addi	a0,a0,-1902 # 7148 <malloc+0x1498>
    28be:	00003097          	auipc	ra,0x3
    28c2:	334080e7          	jalr	820(ra) # 5bf2 <printf>
    exit(1);
    28c6:	4505                	li	a0,1
    28c8:	00003097          	auipc	ra,0x3
    28cc:	f58080e7          	jalr	-168(ra) # 5820 <exit>
    printf("%s: create dd/xx/ff succeeded!\n", s);
    28d0:	85ca                	mv	a1,s2
    28d2:	00005517          	auipc	a0,0x5
    28d6:	8a650513          	addi	a0,a0,-1882 # 7178 <malloc+0x14c8>
    28da:	00003097          	auipc	ra,0x3
    28de:	318080e7          	jalr	792(ra) # 5bf2 <printf>
    exit(1);
    28e2:	4505                	li	a0,1
    28e4:	00003097          	auipc	ra,0x3
    28e8:	f3c080e7          	jalr	-196(ra) # 5820 <exit>
    printf("%s: create dd succeeded!\n", s);
    28ec:	85ca                	mv	a1,s2
    28ee:	00005517          	auipc	a0,0x5
    28f2:	8aa50513          	addi	a0,a0,-1878 # 7198 <malloc+0x14e8>
    28f6:	00003097          	auipc	ra,0x3
    28fa:	2fc080e7          	jalr	764(ra) # 5bf2 <printf>
    exit(1);
    28fe:	4505                	li	a0,1
    2900:	00003097          	auipc	ra,0x3
    2904:	f20080e7          	jalr	-224(ra) # 5820 <exit>
    printf("%s: open dd rdwr succeeded!\n", s);
    2908:	85ca                	mv	a1,s2
    290a:	00005517          	auipc	a0,0x5
    290e:	8ae50513          	addi	a0,a0,-1874 # 71b8 <malloc+0x1508>
    2912:	00003097          	auipc	ra,0x3
    2916:	2e0080e7          	jalr	736(ra) # 5bf2 <printf>
    exit(1);
    291a:	4505                	li	a0,1
    291c:	00003097          	auipc	ra,0x3
    2920:	f04080e7          	jalr	-252(ra) # 5820 <exit>
    printf("%s: open dd wronly succeeded!\n", s);
    2924:	85ca                	mv	a1,s2
    2926:	00005517          	auipc	a0,0x5
    292a:	8b250513          	addi	a0,a0,-1870 # 71d8 <malloc+0x1528>
    292e:	00003097          	auipc	ra,0x3
    2932:	2c4080e7          	jalr	708(ra) # 5bf2 <printf>
    exit(1);
    2936:	4505                	li	a0,1
    2938:	00003097          	auipc	ra,0x3
    293c:	ee8080e7          	jalr	-280(ra) # 5820 <exit>
    printf("%s: link dd/ff/ff dd/dd/xx succeeded!\n", s);
    2940:	85ca                	mv	a1,s2
    2942:	00005517          	auipc	a0,0x5
    2946:	8c650513          	addi	a0,a0,-1850 # 7208 <malloc+0x1558>
    294a:	00003097          	auipc	ra,0x3
    294e:	2a8080e7          	jalr	680(ra) # 5bf2 <printf>
    exit(1);
    2952:	4505                	li	a0,1
    2954:	00003097          	auipc	ra,0x3
    2958:	ecc080e7          	jalr	-308(ra) # 5820 <exit>
    printf("%s: link dd/xx/ff dd/dd/xx succeeded!\n", s);
    295c:	85ca                	mv	a1,s2
    295e:	00005517          	auipc	a0,0x5
    2962:	8d250513          	addi	a0,a0,-1838 # 7230 <malloc+0x1580>
    2966:	00003097          	auipc	ra,0x3
    296a:	28c080e7          	jalr	652(ra) # 5bf2 <printf>
    exit(1);
    296e:	4505                	li	a0,1
    2970:	00003097          	auipc	ra,0x3
    2974:	eb0080e7          	jalr	-336(ra) # 5820 <exit>
    printf("%s: link dd/ff dd/dd/ffff succeeded!\n", s);
    2978:	85ca                	mv	a1,s2
    297a:	00005517          	auipc	a0,0x5
    297e:	8de50513          	addi	a0,a0,-1826 # 7258 <malloc+0x15a8>
    2982:	00003097          	auipc	ra,0x3
    2986:	270080e7          	jalr	624(ra) # 5bf2 <printf>
    exit(1);
    298a:	4505                	li	a0,1
    298c:	00003097          	auipc	ra,0x3
    2990:	e94080e7          	jalr	-364(ra) # 5820 <exit>
    printf("%s: mkdir dd/ff/ff succeeded!\n", s);
    2994:	85ca                	mv	a1,s2
    2996:	00005517          	auipc	a0,0x5
    299a:	8ea50513          	addi	a0,a0,-1814 # 7280 <malloc+0x15d0>
    299e:	00003097          	auipc	ra,0x3
    29a2:	254080e7          	jalr	596(ra) # 5bf2 <printf>
    exit(1);
    29a6:	4505                	li	a0,1
    29a8:	00003097          	auipc	ra,0x3
    29ac:	e78080e7          	jalr	-392(ra) # 5820 <exit>
    printf("%s: mkdir dd/xx/ff succeeded!\n", s);
    29b0:	85ca                	mv	a1,s2
    29b2:	00005517          	auipc	a0,0x5
    29b6:	8ee50513          	addi	a0,a0,-1810 # 72a0 <malloc+0x15f0>
    29ba:	00003097          	auipc	ra,0x3
    29be:	238080e7          	jalr	568(ra) # 5bf2 <printf>
    exit(1);
    29c2:	4505                	li	a0,1
    29c4:	00003097          	auipc	ra,0x3
    29c8:	e5c080e7          	jalr	-420(ra) # 5820 <exit>
    printf("%s: mkdir dd/dd/ffff succeeded!\n", s);
    29cc:	85ca                	mv	a1,s2
    29ce:	00005517          	auipc	a0,0x5
    29d2:	8f250513          	addi	a0,a0,-1806 # 72c0 <malloc+0x1610>
    29d6:	00003097          	auipc	ra,0x3
    29da:	21c080e7          	jalr	540(ra) # 5bf2 <printf>
    exit(1);
    29de:	4505                	li	a0,1
    29e0:	00003097          	auipc	ra,0x3
    29e4:	e40080e7          	jalr	-448(ra) # 5820 <exit>
    printf("%s: unlink dd/xx/ff succeeded!\n", s);
    29e8:	85ca                	mv	a1,s2
    29ea:	00005517          	auipc	a0,0x5
    29ee:	8fe50513          	addi	a0,a0,-1794 # 72e8 <malloc+0x1638>
    29f2:	00003097          	auipc	ra,0x3
    29f6:	200080e7          	jalr	512(ra) # 5bf2 <printf>
    exit(1);
    29fa:	4505                	li	a0,1
    29fc:	00003097          	auipc	ra,0x3
    2a00:	e24080e7          	jalr	-476(ra) # 5820 <exit>
    printf("%s: unlink dd/ff/ff succeeded!\n", s);
    2a04:	85ca                	mv	a1,s2
    2a06:	00005517          	auipc	a0,0x5
    2a0a:	90250513          	addi	a0,a0,-1790 # 7308 <malloc+0x1658>
    2a0e:	00003097          	auipc	ra,0x3
    2a12:	1e4080e7          	jalr	484(ra) # 5bf2 <printf>
    exit(1);
    2a16:	4505                	li	a0,1
    2a18:	00003097          	auipc	ra,0x3
    2a1c:	e08080e7          	jalr	-504(ra) # 5820 <exit>
    printf("%s: chdir dd/ff succeeded!\n", s);
    2a20:	85ca                	mv	a1,s2
    2a22:	00005517          	auipc	a0,0x5
    2a26:	90650513          	addi	a0,a0,-1786 # 7328 <malloc+0x1678>
    2a2a:	00003097          	auipc	ra,0x3
    2a2e:	1c8080e7          	jalr	456(ra) # 5bf2 <printf>
    exit(1);
    2a32:	4505                	li	a0,1
    2a34:	00003097          	auipc	ra,0x3
    2a38:	dec080e7          	jalr	-532(ra) # 5820 <exit>
    printf("%s: chdir dd/xx succeeded!\n", s);
    2a3c:	85ca                	mv	a1,s2
    2a3e:	00005517          	auipc	a0,0x5
    2a42:	91250513          	addi	a0,a0,-1774 # 7350 <malloc+0x16a0>
    2a46:	00003097          	auipc	ra,0x3
    2a4a:	1ac080e7          	jalr	428(ra) # 5bf2 <printf>
    exit(1);
    2a4e:	4505                	li	a0,1
    2a50:	00003097          	auipc	ra,0x3
    2a54:	dd0080e7          	jalr	-560(ra) # 5820 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    2a58:	85ca                	mv	a1,s2
    2a5a:	00004517          	auipc	a0,0x4
    2a5e:	58e50513          	addi	a0,a0,1422 # 6fe8 <malloc+0x1338>
    2a62:	00003097          	auipc	ra,0x3
    2a66:	190080e7          	jalr	400(ra) # 5bf2 <printf>
    exit(1);
    2a6a:	4505                	li	a0,1
    2a6c:	00003097          	auipc	ra,0x3
    2a70:	db4080e7          	jalr	-588(ra) # 5820 <exit>
    printf("%s: unlink dd/ff failed\n", s);
    2a74:	85ca                	mv	a1,s2
    2a76:	00005517          	auipc	a0,0x5
    2a7a:	8fa50513          	addi	a0,a0,-1798 # 7370 <malloc+0x16c0>
    2a7e:	00003097          	auipc	ra,0x3
    2a82:	174080e7          	jalr	372(ra) # 5bf2 <printf>
    exit(1);
    2a86:	4505                	li	a0,1
    2a88:	00003097          	auipc	ra,0x3
    2a8c:	d98080e7          	jalr	-616(ra) # 5820 <exit>
    printf("%s: unlink non-empty dd succeeded!\n", s);
    2a90:	85ca                	mv	a1,s2
    2a92:	00005517          	auipc	a0,0x5
    2a96:	8fe50513          	addi	a0,a0,-1794 # 7390 <malloc+0x16e0>
    2a9a:	00003097          	auipc	ra,0x3
    2a9e:	158080e7          	jalr	344(ra) # 5bf2 <printf>
    exit(1);
    2aa2:	4505                	li	a0,1
    2aa4:	00003097          	auipc	ra,0x3
    2aa8:	d7c080e7          	jalr	-644(ra) # 5820 <exit>
    printf("%s: unlink dd/dd failed\n", s);
    2aac:	85ca                	mv	a1,s2
    2aae:	00005517          	auipc	a0,0x5
    2ab2:	91250513          	addi	a0,a0,-1774 # 73c0 <malloc+0x1710>
    2ab6:	00003097          	auipc	ra,0x3
    2aba:	13c080e7          	jalr	316(ra) # 5bf2 <printf>
    exit(1);
    2abe:	4505                	li	a0,1
    2ac0:	00003097          	auipc	ra,0x3
    2ac4:	d60080e7          	jalr	-672(ra) # 5820 <exit>
    printf("%s: unlink dd failed\n", s);
    2ac8:	85ca                	mv	a1,s2
    2aca:	00005517          	auipc	a0,0x5
    2ace:	91650513          	addi	a0,a0,-1770 # 73e0 <malloc+0x1730>
    2ad2:	00003097          	auipc	ra,0x3
    2ad6:	120080e7          	jalr	288(ra) # 5bf2 <printf>
    exit(1);
    2ada:	4505                	li	a0,1
    2adc:	00003097          	auipc	ra,0x3
    2ae0:	d44080e7          	jalr	-700(ra) # 5820 <exit>

0000000000002ae4 <rmdot>:
{
    2ae4:	1101                	addi	sp,sp,-32
    2ae6:	ec06                	sd	ra,24(sp)
    2ae8:	e822                	sd	s0,16(sp)
    2aea:	e426                	sd	s1,8(sp)
    2aec:	1000                	addi	s0,sp,32
    2aee:	84aa                	mv	s1,a0
  if(mkdir("dots") != 0){
    2af0:	00005517          	auipc	a0,0x5
    2af4:	90850513          	addi	a0,a0,-1784 # 73f8 <malloc+0x1748>
    2af8:	00003097          	auipc	ra,0x3
    2afc:	d90080e7          	jalr	-624(ra) # 5888 <mkdir>
    2b00:	e549                	bnez	a0,2b8a <rmdot+0xa6>
  if(chdir("dots") != 0){
    2b02:	00005517          	auipc	a0,0x5
    2b06:	8f650513          	addi	a0,a0,-1802 # 73f8 <malloc+0x1748>
    2b0a:	00003097          	auipc	ra,0x3
    2b0e:	d86080e7          	jalr	-634(ra) # 5890 <chdir>
    2b12:	e951                	bnez	a0,2ba6 <rmdot+0xc2>
  if(unlink(".") == 0){
    2b14:	00004517          	auipc	a0,0x4
    2b18:	bf450513          	addi	a0,a0,-1036 # 6708 <malloc+0xa58>
    2b1c:	00003097          	auipc	ra,0x3
    2b20:	d54080e7          	jalr	-684(ra) # 5870 <unlink>
    2b24:	cd59                	beqz	a0,2bc2 <rmdot+0xde>
  if(unlink("..") == 0){
    2b26:	00004517          	auipc	a0,0x4
    2b2a:	32a50513          	addi	a0,a0,810 # 6e50 <malloc+0x11a0>
    2b2e:	00003097          	auipc	ra,0x3
    2b32:	d42080e7          	jalr	-702(ra) # 5870 <unlink>
    2b36:	c545                	beqz	a0,2bde <rmdot+0xfa>
  if(chdir("/") != 0){
    2b38:	00004517          	auipc	a0,0x4
    2b3c:	2c050513          	addi	a0,a0,704 # 6df8 <malloc+0x1148>
    2b40:	00003097          	auipc	ra,0x3
    2b44:	d50080e7          	jalr	-688(ra) # 5890 <chdir>
    2b48:	e94d                	bnez	a0,2bfa <rmdot+0x116>
  if(unlink("dots/.") == 0){
    2b4a:	00005517          	auipc	a0,0x5
    2b4e:	91650513          	addi	a0,a0,-1770 # 7460 <malloc+0x17b0>
    2b52:	00003097          	auipc	ra,0x3
    2b56:	d1e080e7          	jalr	-738(ra) # 5870 <unlink>
    2b5a:	cd55                	beqz	a0,2c16 <rmdot+0x132>
  if(unlink("dots/..") == 0){
    2b5c:	00005517          	auipc	a0,0x5
    2b60:	92c50513          	addi	a0,a0,-1748 # 7488 <malloc+0x17d8>
    2b64:	00003097          	auipc	ra,0x3
    2b68:	d0c080e7          	jalr	-756(ra) # 5870 <unlink>
    2b6c:	c179                	beqz	a0,2c32 <rmdot+0x14e>
  if(unlink("dots") != 0){
    2b6e:	00005517          	auipc	a0,0x5
    2b72:	88a50513          	addi	a0,a0,-1910 # 73f8 <malloc+0x1748>
    2b76:	00003097          	auipc	ra,0x3
    2b7a:	cfa080e7          	jalr	-774(ra) # 5870 <unlink>
    2b7e:	e961                	bnez	a0,2c4e <rmdot+0x16a>
}
    2b80:	60e2                	ld	ra,24(sp)
    2b82:	6442                	ld	s0,16(sp)
    2b84:	64a2                	ld	s1,8(sp)
    2b86:	6105                	addi	sp,sp,32
    2b88:	8082                	ret
    printf("%s: mkdir dots failed\n", s);
    2b8a:	85a6                	mv	a1,s1
    2b8c:	00005517          	auipc	a0,0x5
    2b90:	87450513          	addi	a0,a0,-1932 # 7400 <malloc+0x1750>
    2b94:	00003097          	auipc	ra,0x3
    2b98:	05e080e7          	jalr	94(ra) # 5bf2 <printf>
    exit(1);
    2b9c:	4505                	li	a0,1
    2b9e:	00003097          	auipc	ra,0x3
    2ba2:	c82080e7          	jalr	-894(ra) # 5820 <exit>
    printf("%s: chdir dots failed\n", s);
    2ba6:	85a6                	mv	a1,s1
    2ba8:	00005517          	auipc	a0,0x5
    2bac:	87050513          	addi	a0,a0,-1936 # 7418 <malloc+0x1768>
    2bb0:	00003097          	auipc	ra,0x3
    2bb4:	042080e7          	jalr	66(ra) # 5bf2 <printf>
    exit(1);
    2bb8:	4505                	li	a0,1
    2bba:	00003097          	auipc	ra,0x3
    2bbe:	c66080e7          	jalr	-922(ra) # 5820 <exit>
    printf("%s: rm . worked!\n", s);
    2bc2:	85a6                	mv	a1,s1
    2bc4:	00005517          	auipc	a0,0x5
    2bc8:	86c50513          	addi	a0,a0,-1940 # 7430 <malloc+0x1780>
    2bcc:	00003097          	auipc	ra,0x3
    2bd0:	026080e7          	jalr	38(ra) # 5bf2 <printf>
    exit(1);
    2bd4:	4505                	li	a0,1
    2bd6:	00003097          	auipc	ra,0x3
    2bda:	c4a080e7          	jalr	-950(ra) # 5820 <exit>
    printf("%s: rm .. worked!\n", s);
    2bde:	85a6                	mv	a1,s1
    2be0:	00005517          	auipc	a0,0x5
    2be4:	86850513          	addi	a0,a0,-1944 # 7448 <malloc+0x1798>
    2be8:	00003097          	auipc	ra,0x3
    2bec:	00a080e7          	jalr	10(ra) # 5bf2 <printf>
    exit(1);
    2bf0:	4505                	li	a0,1
    2bf2:	00003097          	auipc	ra,0x3
    2bf6:	c2e080e7          	jalr	-978(ra) # 5820 <exit>
    printf("%s: chdir / failed\n", s);
    2bfa:	85a6                	mv	a1,s1
    2bfc:	00004517          	auipc	a0,0x4
    2c00:	20450513          	addi	a0,a0,516 # 6e00 <malloc+0x1150>
    2c04:	00003097          	auipc	ra,0x3
    2c08:	fee080e7          	jalr	-18(ra) # 5bf2 <printf>
    exit(1);
    2c0c:	4505                	li	a0,1
    2c0e:	00003097          	auipc	ra,0x3
    2c12:	c12080e7          	jalr	-1006(ra) # 5820 <exit>
    printf("%s: unlink dots/. worked!\n", s);
    2c16:	85a6                	mv	a1,s1
    2c18:	00005517          	auipc	a0,0x5
    2c1c:	85050513          	addi	a0,a0,-1968 # 7468 <malloc+0x17b8>
    2c20:	00003097          	auipc	ra,0x3
    2c24:	fd2080e7          	jalr	-46(ra) # 5bf2 <printf>
    exit(1);
    2c28:	4505                	li	a0,1
    2c2a:	00003097          	auipc	ra,0x3
    2c2e:	bf6080e7          	jalr	-1034(ra) # 5820 <exit>
    printf("%s: unlink dots/.. worked!\n", s);
    2c32:	85a6                	mv	a1,s1
    2c34:	00005517          	auipc	a0,0x5
    2c38:	85c50513          	addi	a0,a0,-1956 # 7490 <malloc+0x17e0>
    2c3c:	00003097          	auipc	ra,0x3
    2c40:	fb6080e7          	jalr	-74(ra) # 5bf2 <printf>
    exit(1);
    2c44:	4505                	li	a0,1
    2c46:	00003097          	auipc	ra,0x3
    2c4a:	bda080e7          	jalr	-1062(ra) # 5820 <exit>
    printf("%s: unlink dots failed!\n", s);
    2c4e:	85a6                	mv	a1,s1
    2c50:	00005517          	auipc	a0,0x5
    2c54:	86050513          	addi	a0,a0,-1952 # 74b0 <malloc+0x1800>
    2c58:	00003097          	auipc	ra,0x3
    2c5c:	f9a080e7          	jalr	-102(ra) # 5bf2 <printf>
    exit(1);
    2c60:	4505                	li	a0,1
    2c62:	00003097          	auipc	ra,0x3
    2c66:	bbe080e7          	jalr	-1090(ra) # 5820 <exit>

0000000000002c6a <dirfile>:
{
    2c6a:	1101                	addi	sp,sp,-32
    2c6c:	ec06                	sd	ra,24(sp)
    2c6e:	e822                	sd	s0,16(sp)
    2c70:	e426                	sd	s1,8(sp)
    2c72:	e04a                	sd	s2,0(sp)
    2c74:	1000                	addi	s0,sp,32
    2c76:	892a                	mv	s2,a0
  fd = open("dirfile", O_CREATE);
    2c78:	20000593          	li	a1,512
    2c7c:	00003517          	auipc	a0,0x3
    2c80:	32c50513          	addi	a0,a0,812 # 5fa8 <malloc+0x2f8>
    2c84:	00003097          	auipc	ra,0x3
    2c88:	bdc080e7          	jalr	-1060(ra) # 5860 <open>
  if(fd < 0){
    2c8c:	0e054d63          	bltz	a0,2d86 <dirfile+0x11c>
  close(fd);
    2c90:	00003097          	auipc	ra,0x3
    2c94:	bb8080e7          	jalr	-1096(ra) # 5848 <close>
  if(chdir("dirfile") == 0){
    2c98:	00003517          	auipc	a0,0x3
    2c9c:	31050513          	addi	a0,a0,784 # 5fa8 <malloc+0x2f8>
    2ca0:	00003097          	auipc	ra,0x3
    2ca4:	bf0080e7          	jalr	-1040(ra) # 5890 <chdir>
    2ca8:	cd6d                	beqz	a0,2da2 <dirfile+0x138>
  fd = open("dirfile/xx", 0);
    2caa:	4581                	li	a1,0
    2cac:	00005517          	auipc	a0,0x5
    2cb0:	86450513          	addi	a0,a0,-1948 # 7510 <malloc+0x1860>
    2cb4:	00003097          	auipc	ra,0x3
    2cb8:	bac080e7          	jalr	-1108(ra) # 5860 <open>
  if(fd >= 0){
    2cbc:	10055163          	bgez	a0,2dbe <dirfile+0x154>
  fd = open("dirfile/xx", O_CREATE);
    2cc0:	20000593          	li	a1,512
    2cc4:	00005517          	auipc	a0,0x5
    2cc8:	84c50513          	addi	a0,a0,-1972 # 7510 <malloc+0x1860>
    2ccc:	00003097          	auipc	ra,0x3
    2cd0:	b94080e7          	jalr	-1132(ra) # 5860 <open>
  if(fd >= 0){
    2cd4:	10055363          	bgez	a0,2dda <dirfile+0x170>
  if(mkdir("dirfile/xx") == 0){
    2cd8:	00005517          	auipc	a0,0x5
    2cdc:	83850513          	addi	a0,a0,-1992 # 7510 <malloc+0x1860>
    2ce0:	00003097          	auipc	ra,0x3
    2ce4:	ba8080e7          	jalr	-1112(ra) # 5888 <mkdir>
    2ce8:	10050763          	beqz	a0,2df6 <dirfile+0x18c>
  if(unlink("dirfile/xx") == 0){
    2cec:	00005517          	auipc	a0,0x5
    2cf0:	82450513          	addi	a0,a0,-2012 # 7510 <malloc+0x1860>
    2cf4:	00003097          	auipc	ra,0x3
    2cf8:	b7c080e7          	jalr	-1156(ra) # 5870 <unlink>
    2cfc:	10050b63          	beqz	a0,2e12 <dirfile+0x1a8>
  if(link("README", "dirfile/xx") == 0){
    2d00:	00005597          	auipc	a1,0x5
    2d04:	81058593          	addi	a1,a1,-2032 # 7510 <malloc+0x1860>
    2d08:	00003517          	auipc	a0,0x3
    2d0c:	61050513          	addi	a0,a0,1552 # 6318 <malloc+0x668>
    2d10:	00003097          	auipc	ra,0x3
    2d14:	b70080e7          	jalr	-1168(ra) # 5880 <link>
    2d18:	10050b63          	beqz	a0,2e2e <dirfile+0x1c4>
  if(unlink("dirfile") != 0){
    2d1c:	00003517          	auipc	a0,0x3
    2d20:	28c50513          	addi	a0,a0,652 # 5fa8 <malloc+0x2f8>
    2d24:	00003097          	auipc	ra,0x3
    2d28:	b4c080e7          	jalr	-1204(ra) # 5870 <unlink>
    2d2c:	10051f63          	bnez	a0,2e4a <dirfile+0x1e0>
  fd = open(".", O_RDWR);
    2d30:	4589                	li	a1,2
    2d32:	00004517          	auipc	a0,0x4
    2d36:	9d650513          	addi	a0,a0,-1578 # 6708 <malloc+0xa58>
    2d3a:	00003097          	auipc	ra,0x3
    2d3e:	b26080e7          	jalr	-1242(ra) # 5860 <open>
  if(fd >= 0){
    2d42:	12055263          	bgez	a0,2e66 <dirfile+0x1fc>
  fd = open(".", 0);
    2d46:	4581                	li	a1,0
    2d48:	00004517          	auipc	a0,0x4
    2d4c:	9c050513          	addi	a0,a0,-1600 # 6708 <malloc+0xa58>
    2d50:	00003097          	auipc	ra,0x3
    2d54:	b10080e7          	jalr	-1264(ra) # 5860 <open>
    2d58:	84aa                	mv	s1,a0
  if(write(fd, "x", 1) > 0){
    2d5a:	4605                	li	a2,1
    2d5c:	00003597          	auipc	a1,0x3
    2d60:	48458593          	addi	a1,a1,1156 # 61e0 <malloc+0x530>
    2d64:	00003097          	auipc	ra,0x3
    2d68:	adc080e7          	jalr	-1316(ra) # 5840 <write>
    2d6c:	10a04b63          	bgtz	a0,2e82 <dirfile+0x218>
  close(fd);
    2d70:	8526                	mv	a0,s1
    2d72:	00003097          	auipc	ra,0x3
    2d76:	ad6080e7          	jalr	-1322(ra) # 5848 <close>
}
    2d7a:	60e2                	ld	ra,24(sp)
    2d7c:	6442                	ld	s0,16(sp)
    2d7e:	64a2                	ld	s1,8(sp)
    2d80:	6902                	ld	s2,0(sp)
    2d82:	6105                	addi	sp,sp,32
    2d84:	8082                	ret
    printf("%s: create dirfile failed\n", s);
    2d86:	85ca                	mv	a1,s2
    2d88:	00004517          	auipc	a0,0x4
    2d8c:	74850513          	addi	a0,a0,1864 # 74d0 <malloc+0x1820>
    2d90:	00003097          	auipc	ra,0x3
    2d94:	e62080e7          	jalr	-414(ra) # 5bf2 <printf>
    exit(1);
    2d98:	4505                	li	a0,1
    2d9a:	00003097          	auipc	ra,0x3
    2d9e:	a86080e7          	jalr	-1402(ra) # 5820 <exit>
    printf("%s: chdir dirfile succeeded!\n", s);
    2da2:	85ca                	mv	a1,s2
    2da4:	00004517          	auipc	a0,0x4
    2da8:	74c50513          	addi	a0,a0,1868 # 74f0 <malloc+0x1840>
    2dac:	00003097          	auipc	ra,0x3
    2db0:	e46080e7          	jalr	-442(ra) # 5bf2 <printf>
    exit(1);
    2db4:	4505                	li	a0,1
    2db6:	00003097          	auipc	ra,0x3
    2dba:	a6a080e7          	jalr	-1430(ra) # 5820 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    2dbe:	85ca                	mv	a1,s2
    2dc0:	00004517          	auipc	a0,0x4
    2dc4:	76050513          	addi	a0,a0,1888 # 7520 <malloc+0x1870>
    2dc8:	00003097          	auipc	ra,0x3
    2dcc:	e2a080e7          	jalr	-470(ra) # 5bf2 <printf>
    exit(1);
    2dd0:	4505                	li	a0,1
    2dd2:	00003097          	auipc	ra,0x3
    2dd6:	a4e080e7          	jalr	-1458(ra) # 5820 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    2dda:	85ca                	mv	a1,s2
    2ddc:	00004517          	auipc	a0,0x4
    2de0:	74450513          	addi	a0,a0,1860 # 7520 <malloc+0x1870>
    2de4:	00003097          	auipc	ra,0x3
    2de8:	e0e080e7          	jalr	-498(ra) # 5bf2 <printf>
    exit(1);
    2dec:	4505                	li	a0,1
    2dee:	00003097          	auipc	ra,0x3
    2df2:	a32080e7          	jalr	-1486(ra) # 5820 <exit>
    printf("%s: mkdir dirfile/xx succeeded!\n", s);
    2df6:	85ca                	mv	a1,s2
    2df8:	00004517          	auipc	a0,0x4
    2dfc:	75050513          	addi	a0,a0,1872 # 7548 <malloc+0x1898>
    2e00:	00003097          	auipc	ra,0x3
    2e04:	df2080e7          	jalr	-526(ra) # 5bf2 <printf>
    exit(1);
    2e08:	4505                	li	a0,1
    2e0a:	00003097          	auipc	ra,0x3
    2e0e:	a16080e7          	jalr	-1514(ra) # 5820 <exit>
    printf("%s: unlink dirfile/xx succeeded!\n", s);
    2e12:	85ca                	mv	a1,s2
    2e14:	00004517          	auipc	a0,0x4
    2e18:	75c50513          	addi	a0,a0,1884 # 7570 <malloc+0x18c0>
    2e1c:	00003097          	auipc	ra,0x3
    2e20:	dd6080e7          	jalr	-554(ra) # 5bf2 <printf>
    exit(1);
    2e24:	4505                	li	a0,1
    2e26:	00003097          	auipc	ra,0x3
    2e2a:	9fa080e7          	jalr	-1542(ra) # 5820 <exit>
    printf("%s: link to dirfile/xx succeeded!\n", s);
    2e2e:	85ca                	mv	a1,s2
    2e30:	00004517          	auipc	a0,0x4
    2e34:	76850513          	addi	a0,a0,1896 # 7598 <malloc+0x18e8>
    2e38:	00003097          	auipc	ra,0x3
    2e3c:	dba080e7          	jalr	-582(ra) # 5bf2 <printf>
    exit(1);
    2e40:	4505                	li	a0,1
    2e42:	00003097          	auipc	ra,0x3
    2e46:	9de080e7          	jalr	-1570(ra) # 5820 <exit>
    printf("%s: unlink dirfile failed!\n", s);
    2e4a:	85ca                	mv	a1,s2
    2e4c:	00004517          	auipc	a0,0x4
    2e50:	77450513          	addi	a0,a0,1908 # 75c0 <malloc+0x1910>
    2e54:	00003097          	auipc	ra,0x3
    2e58:	d9e080e7          	jalr	-610(ra) # 5bf2 <printf>
    exit(1);
    2e5c:	4505                	li	a0,1
    2e5e:	00003097          	auipc	ra,0x3
    2e62:	9c2080e7          	jalr	-1598(ra) # 5820 <exit>
    printf("%s: open . for writing succeeded!\n", s);
    2e66:	85ca                	mv	a1,s2
    2e68:	00004517          	auipc	a0,0x4
    2e6c:	77850513          	addi	a0,a0,1912 # 75e0 <malloc+0x1930>
    2e70:	00003097          	auipc	ra,0x3
    2e74:	d82080e7          	jalr	-638(ra) # 5bf2 <printf>
    exit(1);
    2e78:	4505                	li	a0,1
    2e7a:	00003097          	auipc	ra,0x3
    2e7e:	9a6080e7          	jalr	-1626(ra) # 5820 <exit>
    printf("%s: write . succeeded!\n", s);
    2e82:	85ca                	mv	a1,s2
    2e84:	00004517          	auipc	a0,0x4
    2e88:	78450513          	addi	a0,a0,1924 # 7608 <malloc+0x1958>
    2e8c:	00003097          	auipc	ra,0x3
    2e90:	d66080e7          	jalr	-666(ra) # 5bf2 <printf>
    exit(1);
    2e94:	4505                	li	a0,1
    2e96:	00003097          	auipc	ra,0x3
    2e9a:	98a080e7          	jalr	-1654(ra) # 5820 <exit>

0000000000002e9e <reparent>:
{
    2e9e:	7179                	addi	sp,sp,-48
    2ea0:	f406                	sd	ra,40(sp)
    2ea2:	f022                	sd	s0,32(sp)
    2ea4:	ec26                	sd	s1,24(sp)
    2ea6:	e84a                	sd	s2,16(sp)
    2ea8:	e44e                	sd	s3,8(sp)
    2eaa:	e052                	sd	s4,0(sp)
    2eac:	1800                	addi	s0,sp,48
    2eae:	89aa                	mv	s3,a0
  int master_pid = getpid();
    2eb0:	00003097          	auipc	ra,0x3
    2eb4:	9f0080e7          	jalr	-1552(ra) # 58a0 <getpid>
    2eb8:	8a2a                	mv	s4,a0
    2eba:	0c800913          	li	s2,200
    int pid = fork();
    2ebe:	00003097          	auipc	ra,0x3
    2ec2:	95a080e7          	jalr	-1702(ra) # 5818 <fork>
    2ec6:	84aa                	mv	s1,a0
    if(pid < 0){
    2ec8:	02054263          	bltz	a0,2eec <reparent+0x4e>
    if(pid){
    2ecc:	cd21                	beqz	a0,2f24 <reparent+0x86>
      if(wait(0) != pid){
    2ece:	4501                	li	a0,0
    2ed0:	00003097          	auipc	ra,0x3
    2ed4:	958080e7          	jalr	-1704(ra) # 5828 <wait>
    2ed8:	02951863          	bne	a0,s1,2f08 <reparent+0x6a>
  for(int i = 0; i < 200; i++){
    2edc:	397d                	addiw	s2,s2,-1
    2ede:	fe0910e3          	bnez	s2,2ebe <reparent+0x20>
  exit(0);
    2ee2:	4501                	li	a0,0
    2ee4:	00003097          	auipc	ra,0x3
    2ee8:	93c080e7          	jalr	-1732(ra) # 5820 <exit>
      printf("%s: fork failed\n", s);
    2eec:	85ce                	mv	a1,s3
    2eee:	00003517          	auipc	a0,0x3
    2ef2:	13a50513          	addi	a0,a0,314 # 6028 <malloc+0x378>
    2ef6:	00003097          	auipc	ra,0x3
    2efa:	cfc080e7          	jalr	-772(ra) # 5bf2 <printf>
      exit(1);
    2efe:	4505                	li	a0,1
    2f00:	00003097          	auipc	ra,0x3
    2f04:	920080e7          	jalr	-1760(ra) # 5820 <exit>
        printf("%s: wait wrong pid\n", s);
    2f08:	85ce                	mv	a1,s3
    2f0a:	00003517          	auipc	a0,0x3
    2f0e:	13650513          	addi	a0,a0,310 # 6040 <malloc+0x390>
    2f12:	00003097          	auipc	ra,0x3
    2f16:	ce0080e7          	jalr	-800(ra) # 5bf2 <printf>
        exit(1);
    2f1a:	4505                	li	a0,1
    2f1c:	00003097          	auipc	ra,0x3
    2f20:	904080e7          	jalr	-1788(ra) # 5820 <exit>
      int pid2 = fork();
    2f24:	00003097          	auipc	ra,0x3
    2f28:	8f4080e7          	jalr	-1804(ra) # 5818 <fork>
      if(pid2 < 0){
    2f2c:	00054763          	bltz	a0,2f3a <reparent+0x9c>
      exit(0);
    2f30:	4501                	li	a0,0
    2f32:	00003097          	auipc	ra,0x3
    2f36:	8ee080e7          	jalr	-1810(ra) # 5820 <exit>
        kill(master_pid, SIGKILL);
    2f3a:	45a5                	li	a1,9
    2f3c:	8552                	mv	a0,s4
    2f3e:	00003097          	auipc	ra,0x3
    2f42:	912080e7          	jalr	-1774(ra) # 5850 <kill>
        exit(1);
    2f46:	4505                	li	a0,1
    2f48:	00003097          	auipc	ra,0x3
    2f4c:	8d8080e7          	jalr	-1832(ra) # 5820 <exit>

0000000000002f50 <fourfiles>:
{
    2f50:	7171                	addi	sp,sp,-176
    2f52:	f506                	sd	ra,168(sp)
    2f54:	f122                	sd	s0,160(sp)
    2f56:	ed26                	sd	s1,152(sp)
    2f58:	e94a                	sd	s2,144(sp)
    2f5a:	e54e                	sd	s3,136(sp)
    2f5c:	e152                	sd	s4,128(sp)
    2f5e:	fcd6                	sd	s5,120(sp)
    2f60:	f8da                	sd	s6,112(sp)
    2f62:	f4de                	sd	s7,104(sp)
    2f64:	f0e2                	sd	s8,96(sp)
    2f66:	ece6                	sd	s9,88(sp)
    2f68:	e8ea                	sd	s10,80(sp)
    2f6a:	e4ee                	sd	s11,72(sp)
    2f6c:	1900                	addi	s0,sp,176
    2f6e:	f4a43c23          	sd	a0,-168(s0)
  char *names[] = { "f0", "f1", "f2", "f3" };
    2f72:	00003797          	auipc	a5,0x3
    2f76:	e2678793          	addi	a5,a5,-474 # 5d98 <malloc+0xe8>
    2f7a:	f6f43823          	sd	a5,-144(s0)
    2f7e:	00003797          	auipc	a5,0x3
    2f82:	e2278793          	addi	a5,a5,-478 # 5da0 <malloc+0xf0>
    2f86:	f6f43c23          	sd	a5,-136(s0)
    2f8a:	00003797          	auipc	a5,0x3
    2f8e:	e1e78793          	addi	a5,a5,-482 # 5da8 <malloc+0xf8>
    2f92:	f8f43023          	sd	a5,-128(s0)
    2f96:	00003797          	auipc	a5,0x3
    2f9a:	e1a78793          	addi	a5,a5,-486 # 5db0 <malloc+0x100>
    2f9e:	f8f43423          	sd	a5,-120(s0)
  for(pi = 0; pi < NCHILD; pi++){
    2fa2:	f7040c13          	addi	s8,s0,-144
  char *names[] = { "f0", "f1", "f2", "f3" };
    2fa6:	8962                	mv	s2,s8
  for(pi = 0; pi < NCHILD; pi++){
    2fa8:	4481                	li	s1,0
    2faa:	4a11                	li	s4,4
    fname = names[pi];
    2fac:	00093983          	ld	s3,0(s2)
    unlink(fname);
    2fb0:	854e                	mv	a0,s3
    2fb2:	00003097          	auipc	ra,0x3
    2fb6:	8be080e7          	jalr	-1858(ra) # 5870 <unlink>
    pid = fork();
    2fba:	00003097          	auipc	ra,0x3
    2fbe:	85e080e7          	jalr	-1954(ra) # 5818 <fork>
    if(pid < 0){
    2fc2:	04054463          	bltz	a0,300a <fourfiles+0xba>
    if(pid == 0){
    2fc6:	c12d                	beqz	a0,3028 <fourfiles+0xd8>
  for(pi = 0; pi < NCHILD; pi++){
    2fc8:	2485                	addiw	s1,s1,1
    2fca:	0921                	addi	s2,s2,8
    2fcc:	ff4490e3          	bne	s1,s4,2fac <fourfiles+0x5c>
    2fd0:	4491                	li	s1,4
    wait(&xstatus);
    2fd2:	f6c40513          	addi	a0,s0,-148
    2fd6:	00003097          	auipc	ra,0x3
    2fda:	852080e7          	jalr	-1966(ra) # 5828 <wait>
    if(xstatus != 0)
    2fde:	f6c42b03          	lw	s6,-148(s0)
    2fe2:	0c0b1e63          	bnez	s6,30be <fourfiles+0x16e>
  for(pi = 0; pi < NCHILD; pi++){
    2fe6:	34fd                	addiw	s1,s1,-1
    2fe8:	f4ed                	bnez	s1,2fd2 <fourfiles+0x82>
    2fea:	03000b93          	li	s7,48
    while((n = read(fd, buf, sizeof(buf))) > 0){
    2fee:	00009a17          	auipc	s4,0x9
    2ff2:	bc2a0a13          	addi	s4,s4,-1086 # bbb0 <buf>
    2ff6:	00009a97          	auipc	s5,0x9
    2ffa:	bbba8a93          	addi	s5,s5,-1093 # bbb1 <buf+0x1>
    if(total != N*SZ){
    2ffe:	6d85                	lui	s11,0x1
    3000:	770d8d93          	addi	s11,s11,1904 # 1770 <exectest+0xcc>
  for(i = 0; i < NCHILD; i++){
    3004:	03400d13          	li	s10,52
    3008:	aa1d                	j	313e <fourfiles+0x1ee>
      printf("fork failed\n", s);
    300a:	f5843583          	ld	a1,-168(s0)
    300e:	00004517          	auipc	a0,0x4
    3012:	9e250513          	addi	a0,a0,-1566 # 69f0 <malloc+0xd40>
    3016:	00003097          	auipc	ra,0x3
    301a:	bdc080e7          	jalr	-1060(ra) # 5bf2 <printf>
      exit(1);
    301e:	4505                	li	a0,1
    3020:	00003097          	auipc	ra,0x3
    3024:	800080e7          	jalr	-2048(ra) # 5820 <exit>
      fd = open(fname, O_CREATE | O_RDWR);
    3028:	20200593          	li	a1,514
    302c:	854e                	mv	a0,s3
    302e:	00003097          	auipc	ra,0x3
    3032:	832080e7          	jalr	-1998(ra) # 5860 <open>
    3036:	892a                	mv	s2,a0
      if(fd < 0){
    3038:	04054763          	bltz	a0,3086 <fourfiles+0x136>
      memset(buf, '0'+pi, SZ);
    303c:	1f400613          	li	a2,500
    3040:	0304859b          	addiw	a1,s1,48
    3044:	00009517          	auipc	a0,0x9
    3048:	b6c50513          	addi	a0,a0,-1172 # bbb0 <buf>
    304c:	00002097          	auipc	ra,0x2
    3050:	5d8080e7          	jalr	1496(ra) # 5624 <memset>
    3054:	44b1                	li	s1,12
        if((n = write(fd, buf, SZ)) != SZ){
    3056:	00009997          	auipc	s3,0x9
    305a:	b5a98993          	addi	s3,s3,-1190 # bbb0 <buf>
    305e:	1f400613          	li	a2,500
    3062:	85ce                	mv	a1,s3
    3064:	854a                	mv	a0,s2
    3066:	00002097          	auipc	ra,0x2
    306a:	7da080e7          	jalr	2010(ra) # 5840 <write>
    306e:	85aa                	mv	a1,a0
    3070:	1f400793          	li	a5,500
    3074:	02f51863          	bne	a0,a5,30a4 <fourfiles+0x154>
      for(i = 0; i < N; i++){
    3078:	34fd                	addiw	s1,s1,-1
    307a:	f0f5                	bnez	s1,305e <fourfiles+0x10e>
      exit(0);
    307c:	4501                	li	a0,0
    307e:	00002097          	auipc	ra,0x2
    3082:	7a2080e7          	jalr	1954(ra) # 5820 <exit>
        printf("create failed\n", s);
    3086:	f5843583          	ld	a1,-168(s0)
    308a:	00004517          	auipc	a0,0x4
    308e:	59650513          	addi	a0,a0,1430 # 7620 <malloc+0x1970>
    3092:	00003097          	auipc	ra,0x3
    3096:	b60080e7          	jalr	-1184(ra) # 5bf2 <printf>
        exit(1);
    309a:	4505                	li	a0,1
    309c:	00002097          	auipc	ra,0x2
    30a0:	784080e7          	jalr	1924(ra) # 5820 <exit>
          printf("write failed %d\n", n);
    30a4:	00004517          	auipc	a0,0x4
    30a8:	58c50513          	addi	a0,a0,1420 # 7630 <malloc+0x1980>
    30ac:	00003097          	auipc	ra,0x3
    30b0:	b46080e7          	jalr	-1210(ra) # 5bf2 <printf>
          exit(1);
    30b4:	4505                	li	a0,1
    30b6:	00002097          	auipc	ra,0x2
    30ba:	76a080e7          	jalr	1898(ra) # 5820 <exit>
      exit(xstatus);
    30be:	855a                	mv	a0,s6
    30c0:	00002097          	auipc	ra,0x2
    30c4:	760080e7          	jalr	1888(ra) # 5820 <exit>
          printf("wrong char\n", s);
    30c8:	f5843583          	ld	a1,-168(s0)
    30cc:	00004517          	auipc	a0,0x4
    30d0:	57c50513          	addi	a0,a0,1404 # 7648 <malloc+0x1998>
    30d4:	00003097          	auipc	ra,0x3
    30d8:	b1e080e7          	jalr	-1250(ra) # 5bf2 <printf>
          exit(1);
    30dc:	4505                	li	a0,1
    30de:	00002097          	auipc	ra,0x2
    30e2:	742080e7          	jalr	1858(ra) # 5820 <exit>
      total += n;
    30e6:	00a9093b          	addw	s2,s2,a0
    while((n = read(fd, buf, sizeof(buf))) > 0){
    30ea:	660d                	lui	a2,0x3
    30ec:	85d2                	mv	a1,s4
    30ee:	854e                	mv	a0,s3
    30f0:	00002097          	auipc	ra,0x2
    30f4:	748080e7          	jalr	1864(ra) # 5838 <read>
    30f8:	02a05363          	blez	a0,311e <fourfiles+0x1ce>
    30fc:	00009797          	auipc	a5,0x9
    3100:	ab478793          	addi	a5,a5,-1356 # bbb0 <buf>
    3104:	fff5069b          	addiw	a3,a0,-1
    3108:	1682                	slli	a3,a3,0x20
    310a:	9281                	srli	a3,a3,0x20
    310c:	96d6                	add	a3,a3,s5
        if(buf[j] != '0'+i){
    310e:	0007c703          	lbu	a4,0(a5)
    3112:	fa971be3          	bne	a4,s1,30c8 <fourfiles+0x178>
      for(j = 0; j < n; j++){
    3116:	0785                	addi	a5,a5,1
    3118:	fed79be3          	bne	a5,a3,310e <fourfiles+0x1be>
    311c:	b7e9                	j	30e6 <fourfiles+0x196>
    close(fd);
    311e:	854e                	mv	a0,s3
    3120:	00002097          	auipc	ra,0x2
    3124:	728080e7          	jalr	1832(ra) # 5848 <close>
    if(total != N*SZ){
    3128:	03b91863          	bne	s2,s11,3158 <fourfiles+0x208>
    unlink(fname);
    312c:	8566                	mv	a0,s9
    312e:	00002097          	auipc	ra,0x2
    3132:	742080e7          	jalr	1858(ra) # 5870 <unlink>
  for(i = 0; i < NCHILD; i++){
    3136:	0c21                	addi	s8,s8,8
    3138:	2b85                	addiw	s7,s7,1
    313a:	03ab8d63          	beq	s7,s10,3174 <fourfiles+0x224>
    fname = names[i];
    313e:	000c3c83          	ld	s9,0(s8)
    fd = open(fname, 0);
    3142:	4581                	li	a1,0
    3144:	8566                	mv	a0,s9
    3146:	00002097          	auipc	ra,0x2
    314a:	71a080e7          	jalr	1818(ra) # 5860 <open>
    314e:	89aa                	mv	s3,a0
    total = 0;
    3150:	895a                	mv	s2,s6
        if(buf[j] != '0'+i){
    3152:	000b849b          	sext.w	s1,s7
    while((n = read(fd, buf, sizeof(buf))) > 0){
    3156:	bf51                	j	30ea <fourfiles+0x19a>
      printf("wrong length %d\n", total);
    3158:	85ca                	mv	a1,s2
    315a:	00004517          	auipc	a0,0x4
    315e:	4fe50513          	addi	a0,a0,1278 # 7658 <malloc+0x19a8>
    3162:	00003097          	auipc	ra,0x3
    3166:	a90080e7          	jalr	-1392(ra) # 5bf2 <printf>
      exit(1);
    316a:	4505                	li	a0,1
    316c:	00002097          	auipc	ra,0x2
    3170:	6b4080e7          	jalr	1716(ra) # 5820 <exit>
}
    3174:	70aa                	ld	ra,168(sp)
    3176:	740a                	ld	s0,160(sp)
    3178:	64ea                	ld	s1,152(sp)
    317a:	694a                	ld	s2,144(sp)
    317c:	69aa                	ld	s3,136(sp)
    317e:	6a0a                	ld	s4,128(sp)
    3180:	7ae6                	ld	s5,120(sp)
    3182:	7b46                	ld	s6,112(sp)
    3184:	7ba6                	ld	s7,104(sp)
    3186:	7c06                	ld	s8,96(sp)
    3188:	6ce6                	ld	s9,88(sp)
    318a:	6d46                	ld	s10,80(sp)
    318c:	6da6                	ld	s11,72(sp)
    318e:	614d                	addi	sp,sp,176
    3190:	8082                	ret

0000000000003192 <bigfile>:
{
    3192:	7139                	addi	sp,sp,-64
    3194:	fc06                	sd	ra,56(sp)
    3196:	f822                	sd	s0,48(sp)
    3198:	f426                	sd	s1,40(sp)
    319a:	f04a                	sd	s2,32(sp)
    319c:	ec4e                	sd	s3,24(sp)
    319e:	e852                	sd	s4,16(sp)
    31a0:	e456                	sd	s5,8(sp)
    31a2:	0080                	addi	s0,sp,64
    31a4:	8aaa                	mv	s5,a0
  unlink("bigfile.dat");
    31a6:	00004517          	auipc	a0,0x4
    31aa:	4ca50513          	addi	a0,a0,1226 # 7670 <malloc+0x19c0>
    31ae:	00002097          	auipc	ra,0x2
    31b2:	6c2080e7          	jalr	1730(ra) # 5870 <unlink>
  fd = open("bigfile.dat", O_CREATE | O_RDWR);
    31b6:	20200593          	li	a1,514
    31ba:	00004517          	auipc	a0,0x4
    31be:	4b650513          	addi	a0,a0,1206 # 7670 <malloc+0x19c0>
    31c2:	00002097          	auipc	ra,0x2
    31c6:	69e080e7          	jalr	1694(ra) # 5860 <open>
    31ca:	89aa                	mv	s3,a0
  for(i = 0; i < N; i++){
    31cc:	4481                	li	s1,0
    memset(buf, i, SZ);
    31ce:	00009917          	auipc	s2,0x9
    31d2:	9e290913          	addi	s2,s2,-1566 # bbb0 <buf>
  for(i = 0; i < N; i++){
    31d6:	4a51                	li	s4,20
  if(fd < 0){
    31d8:	0a054063          	bltz	a0,3278 <bigfile+0xe6>
    memset(buf, i, SZ);
    31dc:	25800613          	li	a2,600
    31e0:	85a6                	mv	a1,s1
    31e2:	854a                	mv	a0,s2
    31e4:	00002097          	auipc	ra,0x2
    31e8:	440080e7          	jalr	1088(ra) # 5624 <memset>
    if(write(fd, buf, SZ) != SZ){
    31ec:	25800613          	li	a2,600
    31f0:	85ca                	mv	a1,s2
    31f2:	854e                	mv	a0,s3
    31f4:	00002097          	auipc	ra,0x2
    31f8:	64c080e7          	jalr	1612(ra) # 5840 <write>
    31fc:	25800793          	li	a5,600
    3200:	08f51a63          	bne	a0,a5,3294 <bigfile+0x102>
  for(i = 0; i < N; i++){
    3204:	2485                	addiw	s1,s1,1
    3206:	fd449be3          	bne	s1,s4,31dc <bigfile+0x4a>
  close(fd);
    320a:	854e                	mv	a0,s3
    320c:	00002097          	auipc	ra,0x2
    3210:	63c080e7          	jalr	1596(ra) # 5848 <close>
  fd = open("bigfile.dat", 0);
    3214:	4581                	li	a1,0
    3216:	00004517          	auipc	a0,0x4
    321a:	45a50513          	addi	a0,a0,1114 # 7670 <malloc+0x19c0>
    321e:	00002097          	auipc	ra,0x2
    3222:	642080e7          	jalr	1602(ra) # 5860 <open>
    3226:	8a2a                	mv	s4,a0
  total = 0;
    3228:	4981                	li	s3,0
  for(i = 0; ; i++){
    322a:	4481                	li	s1,0
    cc = read(fd, buf, SZ/2);
    322c:	00009917          	auipc	s2,0x9
    3230:	98490913          	addi	s2,s2,-1660 # bbb0 <buf>
  if(fd < 0){
    3234:	06054e63          	bltz	a0,32b0 <bigfile+0x11e>
    cc = read(fd, buf, SZ/2);
    3238:	12c00613          	li	a2,300
    323c:	85ca                	mv	a1,s2
    323e:	8552                	mv	a0,s4
    3240:	00002097          	auipc	ra,0x2
    3244:	5f8080e7          	jalr	1528(ra) # 5838 <read>
    if(cc < 0){
    3248:	08054263          	bltz	a0,32cc <bigfile+0x13a>
    if(cc == 0)
    324c:	c971                	beqz	a0,3320 <bigfile+0x18e>
    if(cc != SZ/2){
    324e:	12c00793          	li	a5,300
    3252:	08f51b63          	bne	a0,a5,32e8 <bigfile+0x156>
    if(buf[0] != i/2 || buf[SZ/2-1] != i/2){
    3256:	01f4d79b          	srliw	a5,s1,0x1f
    325a:	9fa5                	addw	a5,a5,s1
    325c:	4017d79b          	sraiw	a5,a5,0x1
    3260:	00094703          	lbu	a4,0(s2)
    3264:	0af71063          	bne	a4,a5,3304 <bigfile+0x172>
    3268:	12b94703          	lbu	a4,299(s2)
    326c:	08f71c63          	bne	a4,a5,3304 <bigfile+0x172>
    total += cc;
    3270:	12c9899b          	addiw	s3,s3,300
  for(i = 0; ; i++){
    3274:	2485                	addiw	s1,s1,1
    cc = read(fd, buf, SZ/2);
    3276:	b7c9                	j	3238 <bigfile+0xa6>
    printf("%s: cannot create bigfile", s);
    3278:	85d6                	mv	a1,s5
    327a:	00004517          	auipc	a0,0x4
    327e:	40650513          	addi	a0,a0,1030 # 7680 <malloc+0x19d0>
    3282:	00003097          	auipc	ra,0x3
    3286:	970080e7          	jalr	-1680(ra) # 5bf2 <printf>
    exit(1);
    328a:	4505                	li	a0,1
    328c:	00002097          	auipc	ra,0x2
    3290:	594080e7          	jalr	1428(ra) # 5820 <exit>
      printf("%s: write bigfile failed\n", s);
    3294:	85d6                	mv	a1,s5
    3296:	00004517          	auipc	a0,0x4
    329a:	40a50513          	addi	a0,a0,1034 # 76a0 <malloc+0x19f0>
    329e:	00003097          	auipc	ra,0x3
    32a2:	954080e7          	jalr	-1708(ra) # 5bf2 <printf>
      exit(1);
    32a6:	4505                	li	a0,1
    32a8:	00002097          	auipc	ra,0x2
    32ac:	578080e7          	jalr	1400(ra) # 5820 <exit>
    printf("%s: cannot open bigfile\n", s);
    32b0:	85d6                	mv	a1,s5
    32b2:	00004517          	auipc	a0,0x4
    32b6:	40e50513          	addi	a0,a0,1038 # 76c0 <malloc+0x1a10>
    32ba:	00003097          	auipc	ra,0x3
    32be:	938080e7          	jalr	-1736(ra) # 5bf2 <printf>
    exit(1);
    32c2:	4505                	li	a0,1
    32c4:	00002097          	auipc	ra,0x2
    32c8:	55c080e7          	jalr	1372(ra) # 5820 <exit>
      printf("%s: read bigfile failed\n", s);
    32cc:	85d6                	mv	a1,s5
    32ce:	00004517          	auipc	a0,0x4
    32d2:	41250513          	addi	a0,a0,1042 # 76e0 <malloc+0x1a30>
    32d6:	00003097          	auipc	ra,0x3
    32da:	91c080e7          	jalr	-1764(ra) # 5bf2 <printf>
      exit(1);
    32de:	4505                	li	a0,1
    32e0:	00002097          	auipc	ra,0x2
    32e4:	540080e7          	jalr	1344(ra) # 5820 <exit>
      printf("%s: short read bigfile\n", s);
    32e8:	85d6                	mv	a1,s5
    32ea:	00004517          	auipc	a0,0x4
    32ee:	41650513          	addi	a0,a0,1046 # 7700 <malloc+0x1a50>
    32f2:	00003097          	auipc	ra,0x3
    32f6:	900080e7          	jalr	-1792(ra) # 5bf2 <printf>
      exit(1);
    32fa:	4505                	li	a0,1
    32fc:	00002097          	auipc	ra,0x2
    3300:	524080e7          	jalr	1316(ra) # 5820 <exit>
      printf("%s: read bigfile wrong data\n", s);
    3304:	85d6                	mv	a1,s5
    3306:	00004517          	auipc	a0,0x4
    330a:	41250513          	addi	a0,a0,1042 # 7718 <malloc+0x1a68>
    330e:	00003097          	auipc	ra,0x3
    3312:	8e4080e7          	jalr	-1820(ra) # 5bf2 <printf>
      exit(1);
    3316:	4505                	li	a0,1
    3318:	00002097          	auipc	ra,0x2
    331c:	508080e7          	jalr	1288(ra) # 5820 <exit>
  close(fd);
    3320:	8552                	mv	a0,s4
    3322:	00002097          	auipc	ra,0x2
    3326:	526080e7          	jalr	1318(ra) # 5848 <close>
  if(total != N*SZ){
    332a:	678d                	lui	a5,0x3
    332c:	ee078793          	addi	a5,a5,-288 # 2ee0 <reparent+0x42>
    3330:	02f99363          	bne	s3,a5,3356 <bigfile+0x1c4>
  unlink("bigfile.dat");
    3334:	00004517          	auipc	a0,0x4
    3338:	33c50513          	addi	a0,a0,828 # 7670 <malloc+0x19c0>
    333c:	00002097          	auipc	ra,0x2
    3340:	534080e7          	jalr	1332(ra) # 5870 <unlink>
}
    3344:	70e2                	ld	ra,56(sp)
    3346:	7442                	ld	s0,48(sp)
    3348:	74a2                	ld	s1,40(sp)
    334a:	7902                	ld	s2,32(sp)
    334c:	69e2                	ld	s3,24(sp)
    334e:	6a42                	ld	s4,16(sp)
    3350:	6aa2                	ld	s5,8(sp)
    3352:	6121                	addi	sp,sp,64
    3354:	8082                	ret
    printf("%s: read bigfile wrong total\n", s);
    3356:	85d6                	mv	a1,s5
    3358:	00004517          	auipc	a0,0x4
    335c:	3e050513          	addi	a0,a0,992 # 7738 <malloc+0x1a88>
    3360:	00003097          	auipc	ra,0x3
    3364:	892080e7          	jalr	-1902(ra) # 5bf2 <printf>
    exit(1);
    3368:	4505                	li	a0,1
    336a:	00002097          	auipc	ra,0x2
    336e:	4b6080e7          	jalr	1206(ra) # 5820 <exit>

0000000000003372 <truncate3>:
{
    3372:	7159                	addi	sp,sp,-112
    3374:	f486                	sd	ra,104(sp)
    3376:	f0a2                	sd	s0,96(sp)
    3378:	eca6                	sd	s1,88(sp)
    337a:	e8ca                	sd	s2,80(sp)
    337c:	e4ce                	sd	s3,72(sp)
    337e:	e0d2                	sd	s4,64(sp)
    3380:	fc56                	sd	s5,56(sp)
    3382:	1880                	addi	s0,sp,112
    3384:	892a                	mv	s2,a0
  close(open("truncfile", O_CREATE|O_TRUNC|O_WRONLY));
    3386:	60100593          	li	a1,1537
    338a:	00003517          	auipc	a0,0x3
    338e:	e3e50513          	addi	a0,a0,-450 # 61c8 <malloc+0x518>
    3392:	00002097          	auipc	ra,0x2
    3396:	4ce080e7          	jalr	1230(ra) # 5860 <open>
    339a:	00002097          	auipc	ra,0x2
    339e:	4ae080e7          	jalr	1198(ra) # 5848 <close>
  pid = fork();
    33a2:	00002097          	auipc	ra,0x2
    33a6:	476080e7          	jalr	1142(ra) # 5818 <fork>
  if(pid < 0){
    33aa:	08054063          	bltz	a0,342a <truncate3+0xb8>
  if(pid == 0){
    33ae:	e969                	bnez	a0,3480 <truncate3+0x10e>
    33b0:	06400993          	li	s3,100
      int fd = open("truncfile", O_WRONLY);
    33b4:	00003a17          	auipc	s4,0x3
    33b8:	e14a0a13          	addi	s4,s4,-492 # 61c8 <malloc+0x518>
      int n = write(fd, "1234567890", 10);
    33bc:	00004a97          	auipc	s5,0x4
    33c0:	39ca8a93          	addi	s5,s5,924 # 7758 <malloc+0x1aa8>
      int fd = open("truncfile", O_WRONLY);
    33c4:	4585                	li	a1,1
    33c6:	8552                	mv	a0,s4
    33c8:	00002097          	auipc	ra,0x2
    33cc:	498080e7          	jalr	1176(ra) # 5860 <open>
    33d0:	84aa                	mv	s1,a0
      if(fd < 0){
    33d2:	06054a63          	bltz	a0,3446 <truncate3+0xd4>
      int n = write(fd, "1234567890", 10);
    33d6:	4629                	li	a2,10
    33d8:	85d6                	mv	a1,s5
    33da:	00002097          	auipc	ra,0x2
    33de:	466080e7          	jalr	1126(ra) # 5840 <write>
      if(n != 10){
    33e2:	47a9                	li	a5,10
    33e4:	06f51f63          	bne	a0,a5,3462 <truncate3+0xf0>
      close(fd);
    33e8:	8526                	mv	a0,s1
    33ea:	00002097          	auipc	ra,0x2
    33ee:	45e080e7          	jalr	1118(ra) # 5848 <close>
      fd = open("truncfile", O_RDONLY);
    33f2:	4581                	li	a1,0
    33f4:	8552                	mv	a0,s4
    33f6:	00002097          	auipc	ra,0x2
    33fa:	46a080e7          	jalr	1130(ra) # 5860 <open>
    33fe:	84aa                	mv	s1,a0
      read(fd, buf, sizeof(buf));
    3400:	02000613          	li	a2,32
    3404:	f9840593          	addi	a1,s0,-104
    3408:	00002097          	auipc	ra,0x2
    340c:	430080e7          	jalr	1072(ra) # 5838 <read>
      close(fd);
    3410:	8526                	mv	a0,s1
    3412:	00002097          	auipc	ra,0x2
    3416:	436080e7          	jalr	1078(ra) # 5848 <close>
    for(int i = 0; i < 100; i++){
    341a:	39fd                	addiw	s3,s3,-1
    341c:	fa0994e3          	bnez	s3,33c4 <truncate3+0x52>
    exit(0);
    3420:	4501                	li	a0,0
    3422:	00002097          	auipc	ra,0x2
    3426:	3fe080e7          	jalr	1022(ra) # 5820 <exit>
    printf("%s: fork failed\n", s);
    342a:	85ca                	mv	a1,s2
    342c:	00003517          	auipc	a0,0x3
    3430:	bfc50513          	addi	a0,a0,-1028 # 6028 <malloc+0x378>
    3434:	00002097          	auipc	ra,0x2
    3438:	7be080e7          	jalr	1982(ra) # 5bf2 <printf>
    exit(1);
    343c:	4505                	li	a0,1
    343e:	00002097          	auipc	ra,0x2
    3442:	3e2080e7          	jalr	994(ra) # 5820 <exit>
        printf("%s: open failed\n", s);
    3446:	85ca                	mv	a1,s2
    3448:	00003517          	auipc	a0,0x3
    344c:	46050513          	addi	a0,a0,1120 # 68a8 <malloc+0xbf8>
    3450:	00002097          	auipc	ra,0x2
    3454:	7a2080e7          	jalr	1954(ra) # 5bf2 <printf>
        exit(1);
    3458:	4505                	li	a0,1
    345a:	00002097          	auipc	ra,0x2
    345e:	3c6080e7          	jalr	966(ra) # 5820 <exit>
        printf("%s: write got %d, expected 10\n", s, n);
    3462:	862a                	mv	a2,a0
    3464:	85ca                	mv	a1,s2
    3466:	00004517          	auipc	a0,0x4
    346a:	30250513          	addi	a0,a0,770 # 7768 <malloc+0x1ab8>
    346e:	00002097          	auipc	ra,0x2
    3472:	784080e7          	jalr	1924(ra) # 5bf2 <printf>
        exit(1);
    3476:	4505                	li	a0,1
    3478:	00002097          	auipc	ra,0x2
    347c:	3a8080e7          	jalr	936(ra) # 5820 <exit>
    3480:	09600993          	li	s3,150
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    3484:	00003a17          	auipc	s4,0x3
    3488:	d44a0a13          	addi	s4,s4,-700 # 61c8 <malloc+0x518>
    int n = write(fd, "xxx", 3);
    348c:	00004a97          	auipc	s5,0x4
    3490:	2fca8a93          	addi	s5,s5,764 # 7788 <malloc+0x1ad8>
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    3494:	60100593          	li	a1,1537
    3498:	8552                	mv	a0,s4
    349a:	00002097          	auipc	ra,0x2
    349e:	3c6080e7          	jalr	966(ra) # 5860 <open>
    34a2:	84aa                	mv	s1,a0
    if(fd < 0){
    34a4:	04054763          	bltz	a0,34f2 <truncate3+0x180>
    int n = write(fd, "xxx", 3);
    34a8:	460d                	li	a2,3
    34aa:	85d6                	mv	a1,s5
    34ac:	00002097          	auipc	ra,0x2
    34b0:	394080e7          	jalr	916(ra) # 5840 <write>
    if(n != 3){
    34b4:	478d                	li	a5,3
    34b6:	04f51c63          	bne	a0,a5,350e <truncate3+0x19c>
    close(fd);
    34ba:	8526                	mv	a0,s1
    34bc:	00002097          	auipc	ra,0x2
    34c0:	38c080e7          	jalr	908(ra) # 5848 <close>
  for(int i = 0; i < 150; i++){
    34c4:	39fd                	addiw	s3,s3,-1
    34c6:	fc0997e3          	bnez	s3,3494 <truncate3+0x122>
  wait(&xstatus);
    34ca:	fbc40513          	addi	a0,s0,-68
    34ce:	00002097          	auipc	ra,0x2
    34d2:	35a080e7          	jalr	858(ra) # 5828 <wait>
  unlink("truncfile");
    34d6:	00003517          	auipc	a0,0x3
    34da:	cf250513          	addi	a0,a0,-782 # 61c8 <malloc+0x518>
    34de:	00002097          	auipc	ra,0x2
    34e2:	392080e7          	jalr	914(ra) # 5870 <unlink>
  exit(xstatus);
    34e6:	fbc42503          	lw	a0,-68(s0)
    34ea:	00002097          	auipc	ra,0x2
    34ee:	336080e7          	jalr	822(ra) # 5820 <exit>
      printf("%s: open failed\n", s);
    34f2:	85ca                	mv	a1,s2
    34f4:	00003517          	auipc	a0,0x3
    34f8:	3b450513          	addi	a0,a0,948 # 68a8 <malloc+0xbf8>
    34fc:	00002097          	auipc	ra,0x2
    3500:	6f6080e7          	jalr	1782(ra) # 5bf2 <printf>
      exit(1);
    3504:	4505                	li	a0,1
    3506:	00002097          	auipc	ra,0x2
    350a:	31a080e7          	jalr	794(ra) # 5820 <exit>
      printf("%s: write got %d, expected 3\n", s, n);
    350e:	862a                	mv	a2,a0
    3510:	85ca                	mv	a1,s2
    3512:	00004517          	auipc	a0,0x4
    3516:	27e50513          	addi	a0,a0,638 # 7790 <malloc+0x1ae0>
    351a:	00002097          	auipc	ra,0x2
    351e:	6d8080e7          	jalr	1752(ra) # 5bf2 <printf>
      exit(1);
    3522:	4505                	li	a0,1
    3524:	00002097          	auipc	ra,0x2
    3528:	2fc080e7          	jalr	764(ra) # 5820 <exit>

000000000000352c <writetest>:
{
    352c:	7139                	addi	sp,sp,-64
    352e:	fc06                	sd	ra,56(sp)
    3530:	f822                	sd	s0,48(sp)
    3532:	f426                	sd	s1,40(sp)
    3534:	f04a                	sd	s2,32(sp)
    3536:	ec4e                	sd	s3,24(sp)
    3538:	e852                	sd	s4,16(sp)
    353a:	e456                	sd	s5,8(sp)
    353c:	e05a                	sd	s6,0(sp)
    353e:	0080                	addi	s0,sp,64
    3540:	8b2a                	mv	s6,a0
  fd = open("small", O_CREATE|O_RDWR);
    3542:	20200593          	li	a1,514
    3546:	00004517          	auipc	a0,0x4
    354a:	26a50513          	addi	a0,a0,618 # 77b0 <malloc+0x1b00>
    354e:	00002097          	auipc	ra,0x2
    3552:	312080e7          	jalr	786(ra) # 5860 <open>
  if(fd < 0){
    3556:	0a054d63          	bltz	a0,3610 <writetest+0xe4>
    355a:	892a                	mv	s2,a0
    355c:	4481                	li	s1,0
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
    355e:	00004997          	auipc	s3,0x4
    3562:	27a98993          	addi	s3,s3,634 # 77d8 <malloc+0x1b28>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
    3566:	00004a97          	auipc	s5,0x4
    356a:	2aaa8a93          	addi	s5,s5,682 # 7810 <malloc+0x1b60>
  for(i = 0; i < N; i++){
    356e:	06400a13          	li	s4,100
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
    3572:	4629                	li	a2,10
    3574:	85ce                	mv	a1,s3
    3576:	854a                	mv	a0,s2
    3578:	00002097          	auipc	ra,0x2
    357c:	2c8080e7          	jalr	712(ra) # 5840 <write>
    3580:	47a9                	li	a5,10
    3582:	0af51563          	bne	a0,a5,362c <writetest+0x100>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
    3586:	4629                	li	a2,10
    3588:	85d6                	mv	a1,s5
    358a:	854a                	mv	a0,s2
    358c:	00002097          	auipc	ra,0x2
    3590:	2b4080e7          	jalr	692(ra) # 5840 <write>
    3594:	47a9                	li	a5,10
    3596:	0af51a63          	bne	a0,a5,364a <writetest+0x11e>
  for(i = 0; i < N; i++){
    359a:	2485                	addiw	s1,s1,1
    359c:	fd449be3          	bne	s1,s4,3572 <writetest+0x46>
  close(fd);
    35a0:	854a                	mv	a0,s2
    35a2:	00002097          	auipc	ra,0x2
    35a6:	2a6080e7          	jalr	678(ra) # 5848 <close>
  fd = open("small", O_RDONLY);
    35aa:	4581                	li	a1,0
    35ac:	00004517          	auipc	a0,0x4
    35b0:	20450513          	addi	a0,a0,516 # 77b0 <malloc+0x1b00>
    35b4:	00002097          	auipc	ra,0x2
    35b8:	2ac080e7          	jalr	684(ra) # 5860 <open>
    35bc:	84aa                	mv	s1,a0
  if(fd < 0){
    35be:	0a054563          	bltz	a0,3668 <writetest+0x13c>
  i = read(fd, buf, N*SZ*2);
    35c2:	7d000613          	li	a2,2000
    35c6:	00008597          	auipc	a1,0x8
    35ca:	5ea58593          	addi	a1,a1,1514 # bbb0 <buf>
    35ce:	00002097          	auipc	ra,0x2
    35d2:	26a080e7          	jalr	618(ra) # 5838 <read>
  if(i != N*SZ*2){
    35d6:	7d000793          	li	a5,2000
    35da:	0af51563          	bne	a0,a5,3684 <writetest+0x158>
  close(fd);
    35de:	8526                	mv	a0,s1
    35e0:	00002097          	auipc	ra,0x2
    35e4:	268080e7          	jalr	616(ra) # 5848 <close>
  if(unlink("small") < 0){
    35e8:	00004517          	auipc	a0,0x4
    35ec:	1c850513          	addi	a0,a0,456 # 77b0 <malloc+0x1b00>
    35f0:	00002097          	auipc	ra,0x2
    35f4:	280080e7          	jalr	640(ra) # 5870 <unlink>
    35f8:	0a054463          	bltz	a0,36a0 <writetest+0x174>
}
    35fc:	70e2                	ld	ra,56(sp)
    35fe:	7442                	ld	s0,48(sp)
    3600:	74a2                	ld	s1,40(sp)
    3602:	7902                	ld	s2,32(sp)
    3604:	69e2                	ld	s3,24(sp)
    3606:	6a42                	ld	s4,16(sp)
    3608:	6aa2                	ld	s5,8(sp)
    360a:	6b02                	ld	s6,0(sp)
    360c:	6121                	addi	sp,sp,64
    360e:	8082                	ret
    printf("%s: error: creat small failed!\n", s);
    3610:	85da                	mv	a1,s6
    3612:	00004517          	auipc	a0,0x4
    3616:	1a650513          	addi	a0,a0,422 # 77b8 <malloc+0x1b08>
    361a:	00002097          	auipc	ra,0x2
    361e:	5d8080e7          	jalr	1496(ra) # 5bf2 <printf>
    exit(1);
    3622:	4505                	li	a0,1
    3624:	00002097          	auipc	ra,0x2
    3628:	1fc080e7          	jalr	508(ra) # 5820 <exit>
      printf("%s: error: write aa %d new file failed\n", s, i);
    362c:	8626                	mv	a2,s1
    362e:	85da                	mv	a1,s6
    3630:	00004517          	auipc	a0,0x4
    3634:	1b850513          	addi	a0,a0,440 # 77e8 <malloc+0x1b38>
    3638:	00002097          	auipc	ra,0x2
    363c:	5ba080e7          	jalr	1466(ra) # 5bf2 <printf>
      exit(1);
    3640:	4505                	li	a0,1
    3642:	00002097          	auipc	ra,0x2
    3646:	1de080e7          	jalr	478(ra) # 5820 <exit>
      printf("%s: error: write bb %d new file failed\n", s, i);
    364a:	8626                	mv	a2,s1
    364c:	85da                	mv	a1,s6
    364e:	00004517          	auipc	a0,0x4
    3652:	1d250513          	addi	a0,a0,466 # 7820 <malloc+0x1b70>
    3656:	00002097          	auipc	ra,0x2
    365a:	59c080e7          	jalr	1436(ra) # 5bf2 <printf>
      exit(1);
    365e:	4505                	li	a0,1
    3660:	00002097          	auipc	ra,0x2
    3664:	1c0080e7          	jalr	448(ra) # 5820 <exit>
    printf("%s: error: open small failed!\n", s);
    3668:	85da                	mv	a1,s6
    366a:	00004517          	auipc	a0,0x4
    366e:	1de50513          	addi	a0,a0,478 # 7848 <malloc+0x1b98>
    3672:	00002097          	auipc	ra,0x2
    3676:	580080e7          	jalr	1408(ra) # 5bf2 <printf>
    exit(1);
    367a:	4505                	li	a0,1
    367c:	00002097          	auipc	ra,0x2
    3680:	1a4080e7          	jalr	420(ra) # 5820 <exit>
    printf("%s: read failed\n", s);
    3684:	85da                	mv	a1,s6
    3686:	00003517          	auipc	a0,0x3
    368a:	23a50513          	addi	a0,a0,570 # 68c0 <malloc+0xc10>
    368e:	00002097          	auipc	ra,0x2
    3692:	564080e7          	jalr	1380(ra) # 5bf2 <printf>
    exit(1);
    3696:	4505                	li	a0,1
    3698:	00002097          	auipc	ra,0x2
    369c:	188080e7          	jalr	392(ra) # 5820 <exit>
    printf("%s: unlink small failed\n", s);
    36a0:	85da                	mv	a1,s6
    36a2:	00004517          	auipc	a0,0x4
    36a6:	1c650513          	addi	a0,a0,454 # 7868 <malloc+0x1bb8>
    36aa:	00002097          	auipc	ra,0x2
    36ae:	548080e7          	jalr	1352(ra) # 5bf2 <printf>
    exit(1);
    36b2:	4505                	li	a0,1
    36b4:	00002097          	auipc	ra,0x2
    36b8:	16c080e7          	jalr	364(ra) # 5820 <exit>

00000000000036bc <writebig>:
{
    36bc:	7139                	addi	sp,sp,-64
    36be:	fc06                	sd	ra,56(sp)
    36c0:	f822                	sd	s0,48(sp)
    36c2:	f426                	sd	s1,40(sp)
    36c4:	f04a                	sd	s2,32(sp)
    36c6:	ec4e                	sd	s3,24(sp)
    36c8:	e852                	sd	s4,16(sp)
    36ca:	e456                	sd	s5,8(sp)
    36cc:	0080                	addi	s0,sp,64
    36ce:	8aaa                	mv	s5,a0
  fd = open("big", O_CREATE|O_RDWR);
    36d0:	20200593          	li	a1,514
    36d4:	00004517          	auipc	a0,0x4
    36d8:	1b450513          	addi	a0,a0,436 # 7888 <malloc+0x1bd8>
    36dc:	00002097          	auipc	ra,0x2
    36e0:	184080e7          	jalr	388(ra) # 5860 <open>
    36e4:	89aa                	mv	s3,a0
  for(i = 0; i < MAXFILE; i++){
    36e6:	4481                	li	s1,0
    ((int*)buf)[0] = i;
    36e8:	00008917          	auipc	s2,0x8
    36ec:	4c890913          	addi	s2,s2,1224 # bbb0 <buf>
  for(i = 0; i < MAXFILE; i++){
    36f0:	10c00a13          	li	s4,268
  if(fd < 0){
    36f4:	06054c63          	bltz	a0,376c <writebig+0xb0>
    ((int*)buf)[0] = i;
    36f8:	00992023          	sw	s1,0(s2)
    if(write(fd, buf, BSIZE) != BSIZE){
    36fc:	40000613          	li	a2,1024
    3700:	85ca                	mv	a1,s2
    3702:	854e                	mv	a0,s3
    3704:	00002097          	auipc	ra,0x2
    3708:	13c080e7          	jalr	316(ra) # 5840 <write>
    370c:	40000793          	li	a5,1024
    3710:	06f51c63          	bne	a0,a5,3788 <writebig+0xcc>
  for(i = 0; i < MAXFILE; i++){
    3714:	2485                	addiw	s1,s1,1
    3716:	ff4491e3          	bne	s1,s4,36f8 <writebig+0x3c>
  close(fd);
    371a:	854e                	mv	a0,s3
    371c:	00002097          	auipc	ra,0x2
    3720:	12c080e7          	jalr	300(ra) # 5848 <close>
  fd = open("big", O_RDONLY);
    3724:	4581                	li	a1,0
    3726:	00004517          	auipc	a0,0x4
    372a:	16250513          	addi	a0,a0,354 # 7888 <malloc+0x1bd8>
    372e:	00002097          	auipc	ra,0x2
    3732:	132080e7          	jalr	306(ra) # 5860 <open>
    3736:	89aa                	mv	s3,a0
  n = 0;
    3738:	4481                	li	s1,0
    i = read(fd, buf, BSIZE);
    373a:	00008917          	auipc	s2,0x8
    373e:	47690913          	addi	s2,s2,1142 # bbb0 <buf>
  if(fd < 0){
    3742:	06054263          	bltz	a0,37a6 <writebig+0xea>
    i = read(fd, buf, BSIZE);
    3746:	40000613          	li	a2,1024
    374a:	85ca                	mv	a1,s2
    374c:	854e                	mv	a0,s3
    374e:	00002097          	auipc	ra,0x2
    3752:	0ea080e7          	jalr	234(ra) # 5838 <read>
    if(i == 0){
    3756:	c535                	beqz	a0,37c2 <writebig+0x106>
    } else if(i != BSIZE){
    3758:	40000793          	li	a5,1024
    375c:	0af51f63          	bne	a0,a5,381a <writebig+0x15e>
    if(((int*)buf)[0] != n){
    3760:	00092683          	lw	a3,0(s2)
    3764:	0c969a63          	bne	a3,s1,3838 <writebig+0x17c>
    n++;
    3768:	2485                	addiw	s1,s1,1
    i = read(fd, buf, BSIZE);
    376a:	bff1                	j	3746 <writebig+0x8a>
    printf("%s: error: creat big failed!\n", s);
    376c:	85d6                	mv	a1,s5
    376e:	00004517          	auipc	a0,0x4
    3772:	12250513          	addi	a0,a0,290 # 7890 <malloc+0x1be0>
    3776:	00002097          	auipc	ra,0x2
    377a:	47c080e7          	jalr	1148(ra) # 5bf2 <printf>
    exit(1);
    377e:	4505                	li	a0,1
    3780:	00002097          	auipc	ra,0x2
    3784:	0a0080e7          	jalr	160(ra) # 5820 <exit>
      printf("%s: error: write big file failed\n", s, i);
    3788:	8626                	mv	a2,s1
    378a:	85d6                	mv	a1,s5
    378c:	00004517          	auipc	a0,0x4
    3790:	12450513          	addi	a0,a0,292 # 78b0 <malloc+0x1c00>
    3794:	00002097          	auipc	ra,0x2
    3798:	45e080e7          	jalr	1118(ra) # 5bf2 <printf>
      exit(1);
    379c:	4505                	li	a0,1
    379e:	00002097          	auipc	ra,0x2
    37a2:	082080e7          	jalr	130(ra) # 5820 <exit>
    printf("%s: error: open big failed!\n", s);
    37a6:	85d6                	mv	a1,s5
    37a8:	00004517          	auipc	a0,0x4
    37ac:	13050513          	addi	a0,a0,304 # 78d8 <malloc+0x1c28>
    37b0:	00002097          	auipc	ra,0x2
    37b4:	442080e7          	jalr	1090(ra) # 5bf2 <printf>
    exit(1);
    37b8:	4505                	li	a0,1
    37ba:	00002097          	auipc	ra,0x2
    37be:	066080e7          	jalr	102(ra) # 5820 <exit>
      if(n == MAXFILE - 1){
    37c2:	10b00793          	li	a5,267
    37c6:	02f48a63          	beq	s1,a5,37fa <writebig+0x13e>
  close(fd);
    37ca:	854e                	mv	a0,s3
    37cc:	00002097          	auipc	ra,0x2
    37d0:	07c080e7          	jalr	124(ra) # 5848 <close>
  if(unlink("big") < 0){
    37d4:	00004517          	auipc	a0,0x4
    37d8:	0b450513          	addi	a0,a0,180 # 7888 <malloc+0x1bd8>
    37dc:	00002097          	auipc	ra,0x2
    37e0:	094080e7          	jalr	148(ra) # 5870 <unlink>
    37e4:	06054963          	bltz	a0,3856 <writebig+0x19a>
}
    37e8:	70e2                	ld	ra,56(sp)
    37ea:	7442                	ld	s0,48(sp)
    37ec:	74a2                	ld	s1,40(sp)
    37ee:	7902                	ld	s2,32(sp)
    37f0:	69e2                	ld	s3,24(sp)
    37f2:	6a42                	ld	s4,16(sp)
    37f4:	6aa2                	ld	s5,8(sp)
    37f6:	6121                	addi	sp,sp,64
    37f8:	8082                	ret
        printf("%s: read only %d blocks from big", s, n);
    37fa:	10b00613          	li	a2,267
    37fe:	85d6                	mv	a1,s5
    3800:	00004517          	auipc	a0,0x4
    3804:	0f850513          	addi	a0,a0,248 # 78f8 <malloc+0x1c48>
    3808:	00002097          	auipc	ra,0x2
    380c:	3ea080e7          	jalr	1002(ra) # 5bf2 <printf>
        exit(1);
    3810:	4505                	li	a0,1
    3812:	00002097          	auipc	ra,0x2
    3816:	00e080e7          	jalr	14(ra) # 5820 <exit>
      printf("%s: read failed %d\n", s, i);
    381a:	862a                	mv	a2,a0
    381c:	85d6                	mv	a1,s5
    381e:	00004517          	auipc	a0,0x4
    3822:	10250513          	addi	a0,a0,258 # 7920 <malloc+0x1c70>
    3826:	00002097          	auipc	ra,0x2
    382a:	3cc080e7          	jalr	972(ra) # 5bf2 <printf>
      exit(1);
    382e:	4505                	li	a0,1
    3830:	00002097          	auipc	ra,0x2
    3834:	ff0080e7          	jalr	-16(ra) # 5820 <exit>
      printf("%s: read content of block %d is %d\n", s,
    3838:	8626                	mv	a2,s1
    383a:	85d6                	mv	a1,s5
    383c:	00004517          	auipc	a0,0x4
    3840:	0fc50513          	addi	a0,a0,252 # 7938 <malloc+0x1c88>
    3844:	00002097          	auipc	ra,0x2
    3848:	3ae080e7          	jalr	942(ra) # 5bf2 <printf>
      exit(1);
    384c:	4505                	li	a0,1
    384e:	00002097          	auipc	ra,0x2
    3852:	fd2080e7          	jalr	-46(ra) # 5820 <exit>
    printf("%s: unlink big failed\n", s);
    3856:	85d6                	mv	a1,s5
    3858:	00004517          	auipc	a0,0x4
    385c:	10850513          	addi	a0,a0,264 # 7960 <malloc+0x1cb0>
    3860:	00002097          	auipc	ra,0x2
    3864:	392080e7          	jalr	914(ra) # 5bf2 <printf>
    exit(1);
    3868:	4505                	li	a0,1
    386a:	00002097          	auipc	ra,0x2
    386e:	fb6080e7          	jalr	-74(ra) # 5820 <exit>

0000000000003872 <createtest>:
{
    3872:	7179                	addi	sp,sp,-48
    3874:	f406                	sd	ra,40(sp)
    3876:	f022                	sd	s0,32(sp)
    3878:	ec26                	sd	s1,24(sp)
    387a:	e84a                	sd	s2,16(sp)
    387c:	1800                	addi	s0,sp,48
  name[0] = 'a';
    387e:	06100793          	li	a5,97
    3882:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
    3886:	fc040d23          	sb	zero,-38(s0)
    388a:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
    388e:	06400913          	li	s2,100
    name[1] = '0' + i;
    3892:	fc940ca3          	sb	s1,-39(s0)
    fd = open(name, O_CREATE|O_RDWR);
    3896:	20200593          	li	a1,514
    389a:	fd840513          	addi	a0,s0,-40
    389e:	00002097          	auipc	ra,0x2
    38a2:	fc2080e7          	jalr	-62(ra) # 5860 <open>
    close(fd);
    38a6:	00002097          	auipc	ra,0x2
    38aa:	fa2080e7          	jalr	-94(ra) # 5848 <close>
  for(i = 0; i < N; i++){
    38ae:	2485                	addiw	s1,s1,1
    38b0:	0ff4f493          	andi	s1,s1,255
    38b4:	fd249fe3          	bne	s1,s2,3892 <createtest+0x20>
  name[0] = 'a';
    38b8:	06100793          	li	a5,97
    38bc:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
    38c0:	fc040d23          	sb	zero,-38(s0)
    38c4:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
    38c8:	06400913          	li	s2,100
    name[1] = '0' + i;
    38cc:	fc940ca3          	sb	s1,-39(s0)
    unlink(name);
    38d0:	fd840513          	addi	a0,s0,-40
    38d4:	00002097          	auipc	ra,0x2
    38d8:	f9c080e7          	jalr	-100(ra) # 5870 <unlink>
  for(i = 0; i < N; i++){
    38dc:	2485                	addiw	s1,s1,1
    38de:	0ff4f493          	andi	s1,s1,255
    38e2:	ff2495e3          	bne	s1,s2,38cc <createtest+0x5a>
}
    38e6:	70a2                	ld	ra,40(sp)
    38e8:	7402                	ld	s0,32(sp)
    38ea:	64e2                	ld	s1,24(sp)
    38ec:	6942                	ld	s2,16(sp)
    38ee:	6145                	addi	sp,sp,48
    38f0:	8082                	ret

00000000000038f2 <killstatus>:
{
    38f2:	7139                	addi	sp,sp,-64
    38f4:	fc06                	sd	ra,56(sp)
    38f6:	f822                	sd	s0,48(sp)
    38f8:	f426                	sd	s1,40(sp)
    38fa:	f04a                	sd	s2,32(sp)
    38fc:	ec4e                	sd	s3,24(sp)
    38fe:	e852                	sd	s4,16(sp)
    3900:	0080                	addi	s0,sp,64
    3902:	8a2a                	mv	s4,a0
    3904:	06400913          	li	s2,100
    if(xst != -1) {
    3908:	59fd                	li	s3,-1
    int pid1 = fork();
    390a:	00002097          	auipc	ra,0x2
    390e:	f0e080e7          	jalr	-242(ra) # 5818 <fork>
    3912:	84aa                	mv	s1,a0
    if(pid1 < 0){
    3914:	04054063          	bltz	a0,3954 <killstatus+0x62>
    if(pid1 == 0){
    3918:	cd21                	beqz	a0,3970 <killstatus+0x7e>
    sleep(1);
    391a:	4505                	li	a0,1
    391c:	00002097          	auipc	ra,0x2
    3920:	f94080e7          	jalr	-108(ra) # 58b0 <sleep>
    kill(pid1, SIGKILL);
    3924:	45a5                	li	a1,9
    3926:	8526                	mv	a0,s1
    3928:	00002097          	auipc	ra,0x2
    392c:	f28080e7          	jalr	-216(ra) # 5850 <kill>
    wait(&xst);
    3930:	fcc40513          	addi	a0,s0,-52
    3934:	00002097          	auipc	ra,0x2
    3938:	ef4080e7          	jalr	-268(ra) # 5828 <wait>
    if(xst != -1) {
    393c:	fcc42783          	lw	a5,-52(s0)
    3940:	03379d63          	bne	a5,s3,397a <killstatus+0x88>
  for(int i = 0; i < 100; i++){
    3944:	397d                	addiw	s2,s2,-1
    3946:	fc0912e3          	bnez	s2,390a <killstatus+0x18>
  exit(0);
    394a:	4501                	li	a0,0
    394c:	00002097          	auipc	ra,0x2
    3950:	ed4080e7          	jalr	-300(ra) # 5820 <exit>
      printf("%s: fork failed\n", s);
    3954:	85d2                	mv	a1,s4
    3956:	00002517          	auipc	a0,0x2
    395a:	6d250513          	addi	a0,a0,1746 # 6028 <malloc+0x378>
    395e:	00002097          	auipc	ra,0x2
    3962:	294080e7          	jalr	660(ra) # 5bf2 <printf>
      exit(1);
    3966:	4505                	li	a0,1
    3968:	00002097          	auipc	ra,0x2
    396c:	eb8080e7          	jalr	-328(ra) # 5820 <exit>
        getpid();
    3970:	00002097          	auipc	ra,0x2
    3974:	f30080e7          	jalr	-208(ra) # 58a0 <getpid>
      while(1) {
    3978:	bfe5                	j	3970 <killstatus+0x7e>
       printf("%s: status should be -1\n", s);
    397a:	85d2                	mv	a1,s4
    397c:	00004517          	auipc	a0,0x4
    3980:	ffc50513          	addi	a0,a0,-4 # 7978 <malloc+0x1cc8>
    3984:	00002097          	auipc	ra,0x2
    3988:	26e080e7          	jalr	622(ra) # 5bf2 <printf>
       exit(1);
    398c:	4505                	li	a0,1
    398e:	00002097          	auipc	ra,0x2
    3992:	e92080e7          	jalr	-366(ra) # 5820 <exit>

0000000000003996 <reparent2>:
{
    3996:	1101                	addi	sp,sp,-32
    3998:	ec06                	sd	ra,24(sp)
    399a:	e822                	sd	s0,16(sp)
    399c:	e426                	sd	s1,8(sp)
    399e:	1000                	addi	s0,sp,32
    39a0:	32000493          	li	s1,800
    int pid1 = fork();
    39a4:	00002097          	auipc	ra,0x2
    39a8:	e74080e7          	jalr	-396(ra) # 5818 <fork>
    if(pid1 < 0){
    39ac:	00054f63          	bltz	a0,39ca <reparent2+0x34>
    if(pid1 == 0){
    39b0:	c915                	beqz	a0,39e4 <reparent2+0x4e>
    wait(0);
    39b2:	4501                	li	a0,0
    39b4:	00002097          	auipc	ra,0x2
    39b8:	e74080e7          	jalr	-396(ra) # 5828 <wait>
  for(int i = 0; i < 800; i++){
    39bc:	34fd                	addiw	s1,s1,-1
    39be:	f0fd                	bnez	s1,39a4 <reparent2+0xe>
  exit(0);
    39c0:	4501                	li	a0,0
    39c2:	00002097          	auipc	ra,0x2
    39c6:	e5e080e7          	jalr	-418(ra) # 5820 <exit>
      printf("fork failed\n");
    39ca:	00003517          	auipc	a0,0x3
    39ce:	02650513          	addi	a0,a0,38 # 69f0 <malloc+0xd40>
    39d2:	00002097          	auipc	ra,0x2
    39d6:	220080e7          	jalr	544(ra) # 5bf2 <printf>
      exit(1);
    39da:	4505                	li	a0,1
    39dc:	00002097          	auipc	ra,0x2
    39e0:	e44080e7          	jalr	-444(ra) # 5820 <exit>
      fork();
    39e4:	00002097          	auipc	ra,0x2
    39e8:	e34080e7          	jalr	-460(ra) # 5818 <fork>
      fork();
    39ec:	00002097          	auipc	ra,0x2
    39f0:	e2c080e7          	jalr	-468(ra) # 5818 <fork>
      exit(0);
    39f4:	4501                	li	a0,0
    39f6:	00002097          	auipc	ra,0x2
    39fa:	e2a080e7          	jalr	-470(ra) # 5820 <exit>

00000000000039fe <mem>:
{
    39fe:	7139                	addi	sp,sp,-64
    3a00:	fc06                	sd	ra,56(sp)
    3a02:	f822                	sd	s0,48(sp)
    3a04:	f426                	sd	s1,40(sp)
    3a06:	f04a                	sd	s2,32(sp)
    3a08:	ec4e                	sd	s3,24(sp)
    3a0a:	0080                	addi	s0,sp,64
    3a0c:	89aa                	mv	s3,a0
  if((pid = fork()) == 0){
    3a0e:	00002097          	auipc	ra,0x2
    3a12:	e0a080e7          	jalr	-502(ra) # 5818 <fork>
    m1 = 0;
    3a16:	4481                	li	s1,0
    while((m2 = malloc(10001)) != 0){
    3a18:	6909                	lui	s2,0x2
    3a1a:	71190913          	addi	s2,s2,1809 # 2711 <subdir+0x3f3>
  if((pid = fork()) == 0){
    3a1e:	c115                	beqz	a0,3a42 <mem+0x44>
    wait(&xstatus);
    3a20:	fcc40513          	addi	a0,s0,-52
    3a24:	00002097          	auipc	ra,0x2
    3a28:	e04080e7          	jalr	-508(ra) # 5828 <wait>
    if(xstatus == -1){
    3a2c:	fcc42503          	lw	a0,-52(s0)
    3a30:	57fd                	li	a5,-1
    3a32:	06f50363          	beq	a0,a5,3a98 <mem+0x9a>
    exit(xstatus);
    3a36:	00002097          	auipc	ra,0x2
    3a3a:	dea080e7          	jalr	-534(ra) # 5820 <exit>
      *(char**)m2 = m1;
    3a3e:	e104                	sd	s1,0(a0)
      m1 = m2;
    3a40:	84aa                	mv	s1,a0
    while((m2 = malloc(10001)) != 0){
    3a42:	854a                	mv	a0,s2
    3a44:	00002097          	auipc	ra,0x2
    3a48:	26c080e7          	jalr	620(ra) # 5cb0 <malloc>
    3a4c:	f96d                	bnez	a0,3a3e <mem+0x40>
    while(m1){
    3a4e:	c881                	beqz	s1,3a5e <mem+0x60>
      m2 = *(char**)m1;
    3a50:	8526                	mv	a0,s1
    3a52:	6084                	ld	s1,0(s1)
      free(m1);
    3a54:	00002097          	auipc	ra,0x2
    3a58:	1d4080e7          	jalr	468(ra) # 5c28 <free>
    while(m1){
    3a5c:	f8f5                	bnez	s1,3a50 <mem+0x52>
    m1 = malloc(1024*20);
    3a5e:	6515                	lui	a0,0x5
    3a60:	00002097          	auipc	ra,0x2
    3a64:	250080e7          	jalr	592(ra) # 5cb0 <malloc>
    if(m1 == 0){
    3a68:	c911                	beqz	a0,3a7c <mem+0x7e>
    free(m1);
    3a6a:	00002097          	auipc	ra,0x2
    3a6e:	1be080e7          	jalr	446(ra) # 5c28 <free>
    exit(0);
    3a72:	4501                	li	a0,0
    3a74:	00002097          	auipc	ra,0x2
    3a78:	dac080e7          	jalr	-596(ra) # 5820 <exit>
      printf("couldn't allocate mem?!!\n", s);
    3a7c:	85ce                	mv	a1,s3
    3a7e:	00004517          	auipc	a0,0x4
    3a82:	f1a50513          	addi	a0,a0,-230 # 7998 <malloc+0x1ce8>
    3a86:	00002097          	auipc	ra,0x2
    3a8a:	16c080e7          	jalr	364(ra) # 5bf2 <printf>
      exit(1);
    3a8e:	4505                	li	a0,1
    3a90:	00002097          	auipc	ra,0x2
    3a94:	d90080e7          	jalr	-624(ra) # 5820 <exit>
      exit(0);
    3a98:	4501                	li	a0,0
    3a9a:	00002097          	auipc	ra,0x2
    3a9e:	d86080e7          	jalr	-634(ra) # 5820 <exit>

0000000000003aa2 <sharedfd>:
{
    3aa2:	7159                	addi	sp,sp,-112
    3aa4:	f486                	sd	ra,104(sp)
    3aa6:	f0a2                	sd	s0,96(sp)
    3aa8:	eca6                	sd	s1,88(sp)
    3aaa:	e8ca                	sd	s2,80(sp)
    3aac:	e4ce                	sd	s3,72(sp)
    3aae:	e0d2                	sd	s4,64(sp)
    3ab0:	fc56                	sd	s5,56(sp)
    3ab2:	f85a                	sd	s6,48(sp)
    3ab4:	f45e                	sd	s7,40(sp)
    3ab6:	1880                	addi	s0,sp,112
    3ab8:	8a2a                	mv	s4,a0
  unlink("sharedfd");
    3aba:	00004517          	auipc	a0,0x4
    3abe:	efe50513          	addi	a0,a0,-258 # 79b8 <malloc+0x1d08>
    3ac2:	00002097          	auipc	ra,0x2
    3ac6:	dae080e7          	jalr	-594(ra) # 5870 <unlink>
  fd = open("sharedfd", O_CREATE|O_RDWR);
    3aca:	20200593          	li	a1,514
    3ace:	00004517          	auipc	a0,0x4
    3ad2:	eea50513          	addi	a0,a0,-278 # 79b8 <malloc+0x1d08>
    3ad6:	00002097          	auipc	ra,0x2
    3ada:	d8a080e7          	jalr	-630(ra) # 5860 <open>
  if(fd < 0){
    3ade:	04054a63          	bltz	a0,3b32 <sharedfd+0x90>
    3ae2:	892a                	mv	s2,a0
  pid = fork();
    3ae4:	00002097          	auipc	ra,0x2
    3ae8:	d34080e7          	jalr	-716(ra) # 5818 <fork>
    3aec:	89aa                	mv	s3,a0
  memset(buf, pid==0?'c':'p', sizeof(buf));
    3aee:	06300593          	li	a1,99
    3af2:	c119                	beqz	a0,3af8 <sharedfd+0x56>
    3af4:	07000593          	li	a1,112
    3af8:	4629                	li	a2,10
    3afa:	fa040513          	addi	a0,s0,-96
    3afe:	00002097          	auipc	ra,0x2
    3b02:	b26080e7          	jalr	-1242(ra) # 5624 <memset>
    3b06:	3e800493          	li	s1,1000
    if(write(fd, buf, sizeof(buf)) != sizeof(buf)){
    3b0a:	4629                	li	a2,10
    3b0c:	fa040593          	addi	a1,s0,-96
    3b10:	854a                	mv	a0,s2
    3b12:	00002097          	auipc	ra,0x2
    3b16:	d2e080e7          	jalr	-722(ra) # 5840 <write>
    3b1a:	47a9                	li	a5,10
    3b1c:	02f51963          	bne	a0,a5,3b4e <sharedfd+0xac>
  for(i = 0; i < N; i++){
    3b20:	34fd                	addiw	s1,s1,-1
    3b22:	f4e5                	bnez	s1,3b0a <sharedfd+0x68>
  if(pid == 0) {
    3b24:	04099363          	bnez	s3,3b6a <sharedfd+0xc8>
    exit(0);
    3b28:	4501                	li	a0,0
    3b2a:	00002097          	auipc	ra,0x2
    3b2e:	cf6080e7          	jalr	-778(ra) # 5820 <exit>
    printf("%s: cannot open sharedfd for writing", s);
    3b32:	85d2                	mv	a1,s4
    3b34:	00004517          	auipc	a0,0x4
    3b38:	e9450513          	addi	a0,a0,-364 # 79c8 <malloc+0x1d18>
    3b3c:	00002097          	auipc	ra,0x2
    3b40:	0b6080e7          	jalr	182(ra) # 5bf2 <printf>
    exit(1);
    3b44:	4505                	li	a0,1
    3b46:	00002097          	auipc	ra,0x2
    3b4a:	cda080e7          	jalr	-806(ra) # 5820 <exit>
      printf("%s: write sharedfd failed\n", s);
    3b4e:	85d2                	mv	a1,s4
    3b50:	00004517          	auipc	a0,0x4
    3b54:	ea050513          	addi	a0,a0,-352 # 79f0 <malloc+0x1d40>
    3b58:	00002097          	auipc	ra,0x2
    3b5c:	09a080e7          	jalr	154(ra) # 5bf2 <printf>
      exit(1);
    3b60:	4505                	li	a0,1
    3b62:	00002097          	auipc	ra,0x2
    3b66:	cbe080e7          	jalr	-834(ra) # 5820 <exit>
    wait(&xstatus);
    3b6a:	f9c40513          	addi	a0,s0,-100
    3b6e:	00002097          	auipc	ra,0x2
    3b72:	cba080e7          	jalr	-838(ra) # 5828 <wait>
    if(xstatus != 0)
    3b76:	f9c42983          	lw	s3,-100(s0)
    3b7a:	00098763          	beqz	s3,3b88 <sharedfd+0xe6>
      exit(xstatus);
    3b7e:	854e                	mv	a0,s3
    3b80:	00002097          	auipc	ra,0x2
    3b84:	ca0080e7          	jalr	-864(ra) # 5820 <exit>
  close(fd);
    3b88:	854a                	mv	a0,s2
    3b8a:	00002097          	auipc	ra,0x2
    3b8e:	cbe080e7          	jalr	-834(ra) # 5848 <close>
  fd = open("sharedfd", 0);
    3b92:	4581                	li	a1,0
    3b94:	00004517          	auipc	a0,0x4
    3b98:	e2450513          	addi	a0,a0,-476 # 79b8 <malloc+0x1d08>
    3b9c:	00002097          	auipc	ra,0x2
    3ba0:	cc4080e7          	jalr	-828(ra) # 5860 <open>
    3ba4:	8baa                	mv	s7,a0
  nc = np = 0;
    3ba6:	8ace                	mv	s5,s3
  if(fd < 0){
    3ba8:	02054563          	bltz	a0,3bd2 <sharedfd+0x130>
    3bac:	faa40913          	addi	s2,s0,-86
      if(buf[i] == 'c')
    3bb0:	06300493          	li	s1,99
      if(buf[i] == 'p')
    3bb4:	07000b13          	li	s6,112
  while((n = read(fd, buf, sizeof(buf))) > 0){
    3bb8:	4629                	li	a2,10
    3bba:	fa040593          	addi	a1,s0,-96
    3bbe:	855e                	mv	a0,s7
    3bc0:	00002097          	auipc	ra,0x2
    3bc4:	c78080e7          	jalr	-904(ra) # 5838 <read>
    3bc8:	02a05f63          	blez	a0,3c06 <sharedfd+0x164>
    3bcc:	fa040793          	addi	a5,s0,-96
    3bd0:	a01d                	j	3bf6 <sharedfd+0x154>
    printf("%s: cannot open sharedfd for reading\n", s);
    3bd2:	85d2                	mv	a1,s4
    3bd4:	00004517          	auipc	a0,0x4
    3bd8:	e3c50513          	addi	a0,a0,-452 # 7a10 <malloc+0x1d60>
    3bdc:	00002097          	auipc	ra,0x2
    3be0:	016080e7          	jalr	22(ra) # 5bf2 <printf>
    exit(1);
    3be4:	4505                	li	a0,1
    3be6:	00002097          	auipc	ra,0x2
    3bea:	c3a080e7          	jalr	-966(ra) # 5820 <exit>
        nc++;
    3bee:	2985                	addiw	s3,s3,1
    for(i = 0; i < sizeof(buf); i++){
    3bf0:	0785                	addi	a5,a5,1
    3bf2:	fd2783e3          	beq	a5,s2,3bb8 <sharedfd+0x116>
      if(buf[i] == 'c')
    3bf6:	0007c703          	lbu	a4,0(a5)
    3bfa:	fe970ae3          	beq	a4,s1,3bee <sharedfd+0x14c>
      if(buf[i] == 'p')
    3bfe:	ff6719e3          	bne	a4,s6,3bf0 <sharedfd+0x14e>
        np++;
    3c02:	2a85                	addiw	s5,s5,1
    3c04:	b7f5                	j	3bf0 <sharedfd+0x14e>
  close(fd);
    3c06:	855e                	mv	a0,s7
    3c08:	00002097          	auipc	ra,0x2
    3c0c:	c40080e7          	jalr	-960(ra) # 5848 <close>
  unlink("sharedfd");
    3c10:	00004517          	auipc	a0,0x4
    3c14:	da850513          	addi	a0,a0,-600 # 79b8 <malloc+0x1d08>
    3c18:	00002097          	auipc	ra,0x2
    3c1c:	c58080e7          	jalr	-936(ra) # 5870 <unlink>
  if(nc == N*SZ && np == N*SZ){
    3c20:	6789                	lui	a5,0x2
    3c22:	71078793          	addi	a5,a5,1808 # 2710 <subdir+0x3f2>
    3c26:	00f99763          	bne	s3,a5,3c34 <sharedfd+0x192>
    3c2a:	6789                	lui	a5,0x2
    3c2c:	71078793          	addi	a5,a5,1808 # 2710 <subdir+0x3f2>
    3c30:	02fa8063          	beq	s5,a5,3c50 <sharedfd+0x1ae>
    printf("%s: nc/np test fails\n", s);
    3c34:	85d2                	mv	a1,s4
    3c36:	00004517          	auipc	a0,0x4
    3c3a:	e0250513          	addi	a0,a0,-510 # 7a38 <malloc+0x1d88>
    3c3e:	00002097          	auipc	ra,0x2
    3c42:	fb4080e7          	jalr	-76(ra) # 5bf2 <printf>
    exit(1);
    3c46:	4505                	li	a0,1
    3c48:	00002097          	auipc	ra,0x2
    3c4c:	bd8080e7          	jalr	-1064(ra) # 5820 <exit>
    exit(0);
    3c50:	4501                	li	a0,0
    3c52:	00002097          	auipc	ra,0x2
    3c56:	bce080e7          	jalr	-1074(ra) # 5820 <exit>

0000000000003c5a <createdelete>:
{
    3c5a:	7175                	addi	sp,sp,-144
    3c5c:	e506                	sd	ra,136(sp)
    3c5e:	e122                	sd	s0,128(sp)
    3c60:	fca6                	sd	s1,120(sp)
    3c62:	f8ca                	sd	s2,112(sp)
    3c64:	f4ce                	sd	s3,104(sp)
    3c66:	f0d2                	sd	s4,96(sp)
    3c68:	ecd6                	sd	s5,88(sp)
    3c6a:	e8da                	sd	s6,80(sp)
    3c6c:	e4de                	sd	s7,72(sp)
    3c6e:	e0e2                	sd	s8,64(sp)
    3c70:	fc66                	sd	s9,56(sp)
    3c72:	0900                	addi	s0,sp,144
    3c74:	8caa                	mv	s9,a0
  for(pi = 0; pi < NCHILD; pi++){
    3c76:	4901                	li	s2,0
    3c78:	4991                	li	s3,4
    pid = fork();
    3c7a:	00002097          	auipc	ra,0x2
    3c7e:	b9e080e7          	jalr	-1122(ra) # 5818 <fork>
    3c82:	84aa                	mv	s1,a0
    if(pid < 0){
    3c84:	02054f63          	bltz	a0,3cc2 <createdelete+0x68>
    if(pid == 0){
    3c88:	c939                	beqz	a0,3cde <createdelete+0x84>
  for(pi = 0; pi < NCHILD; pi++){
    3c8a:	2905                	addiw	s2,s2,1
    3c8c:	ff3917e3          	bne	s2,s3,3c7a <createdelete+0x20>
    3c90:	4491                	li	s1,4
    wait(&xstatus);
    3c92:	f7c40513          	addi	a0,s0,-132
    3c96:	00002097          	auipc	ra,0x2
    3c9a:	b92080e7          	jalr	-1134(ra) # 5828 <wait>
    if(xstatus != 0)
    3c9e:	f7c42903          	lw	s2,-132(s0)
    3ca2:	0e091263          	bnez	s2,3d86 <createdelete+0x12c>
  for(pi = 0; pi < NCHILD; pi++){
    3ca6:	34fd                	addiw	s1,s1,-1
    3ca8:	f4ed                	bnez	s1,3c92 <createdelete+0x38>
  name[0] = name[1] = name[2] = 0;
    3caa:	f8040123          	sb	zero,-126(s0)
    3cae:	03000993          	li	s3,48
    3cb2:	5a7d                	li	s4,-1
    3cb4:	07000c13          	li	s8,112
      } else if((i >= 1 && i < N/2) && fd >= 0){
    3cb8:	4b21                	li	s6,8
      if((i == 0 || i >= N/2) && fd < 0){
    3cba:	4ba5                	li	s7,9
    for(pi = 0; pi < NCHILD; pi++){
    3cbc:	07400a93          	li	s5,116
    3cc0:	a29d                	j	3e26 <createdelete+0x1cc>
      printf("fork failed\n", s);
    3cc2:	85e6                	mv	a1,s9
    3cc4:	00003517          	auipc	a0,0x3
    3cc8:	d2c50513          	addi	a0,a0,-724 # 69f0 <malloc+0xd40>
    3ccc:	00002097          	auipc	ra,0x2
    3cd0:	f26080e7          	jalr	-218(ra) # 5bf2 <printf>
      exit(1);
    3cd4:	4505                	li	a0,1
    3cd6:	00002097          	auipc	ra,0x2
    3cda:	b4a080e7          	jalr	-1206(ra) # 5820 <exit>
      name[0] = 'p' + pi;
    3cde:	0709091b          	addiw	s2,s2,112
    3ce2:	f9240023          	sb	s2,-128(s0)
      name[2] = '\0';
    3ce6:	f8040123          	sb	zero,-126(s0)
      for(i = 0; i < N; i++){
    3cea:	4951                	li	s2,20
    3cec:	a015                	j	3d10 <createdelete+0xb6>
          printf("%s: create failed\n", s);
    3cee:	85e6                	mv	a1,s9
    3cf0:	00003517          	auipc	a0,0x3
    3cf4:	b6050513          	addi	a0,a0,-1184 # 6850 <malloc+0xba0>
    3cf8:	00002097          	auipc	ra,0x2
    3cfc:	efa080e7          	jalr	-262(ra) # 5bf2 <printf>
          exit(1);
    3d00:	4505                	li	a0,1
    3d02:	00002097          	auipc	ra,0x2
    3d06:	b1e080e7          	jalr	-1250(ra) # 5820 <exit>
      for(i = 0; i < N; i++){
    3d0a:	2485                	addiw	s1,s1,1
    3d0c:	07248863          	beq	s1,s2,3d7c <createdelete+0x122>
        name[1] = '0' + i;
    3d10:	0304879b          	addiw	a5,s1,48
    3d14:	f8f400a3          	sb	a5,-127(s0)
        fd = open(name, O_CREATE | O_RDWR);
    3d18:	20200593          	li	a1,514
    3d1c:	f8040513          	addi	a0,s0,-128
    3d20:	00002097          	auipc	ra,0x2
    3d24:	b40080e7          	jalr	-1216(ra) # 5860 <open>
        if(fd < 0){
    3d28:	fc0543e3          	bltz	a0,3cee <createdelete+0x94>
        close(fd);
    3d2c:	00002097          	auipc	ra,0x2
    3d30:	b1c080e7          	jalr	-1252(ra) # 5848 <close>
        if(i > 0 && (i % 2 ) == 0){
    3d34:	fc905be3          	blez	s1,3d0a <createdelete+0xb0>
    3d38:	0014f793          	andi	a5,s1,1
    3d3c:	f7f9                	bnez	a5,3d0a <createdelete+0xb0>
          name[1] = '0' + (i / 2);
    3d3e:	01f4d79b          	srliw	a5,s1,0x1f
    3d42:	9fa5                	addw	a5,a5,s1
    3d44:	4017d79b          	sraiw	a5,a5,0x1
    3d48:	0307879b          	addiw	a5,a5,48
    3d4c:	f8f400a3          	sb	a5,-127(s0)
          if(unlink(name) < 0){
    3d50:	f8040513          	addi	a0,s0,-128
    3d54:	00002097          	auipc	ra,0x2
    3d58:	b1c080e7          	jalr	-1252(ra) # 5870 <unlink>
    3d5c:	fa0557e3          	bgez	a0,3d0a <createdelete+0xb0>
            printf("%s: unlink failed\n", s);
    3d60:	85e6                	mv	a1,s9
    3d62:	00003517          	auipc	a0,0x3
    3d66:	df650513          	addi	a0,a0,-522 # 6b58 <malloc+0xea8>
    3d6a:	00002097          	auipc	ra,0x2
    3d6e:	e88080e7          	jalr	-376(ra) # 5bf2 <printf>
            exit(1);
    3d72:	4505                	li	a0,1
    3d74:	00002097          	auipc	ra,0x2
    3d78:	aac080e7          	jalr	-1364(ra) # 5820 <exit>
      exit(0);
    3d7c:	4501                	li	a0,0
    3d7e:	00002097          	auipc	ra,0x2
    3d82:	aa2080e7          	jalr	-1374(ra) # 5820 <exit>
      exit(1);
    3d86:	4505                	li	a0,1
    3d88:	00002097          	auipc	ra,0x2
    3d8c:	a98080e7          	jalr	-1384(ra) # 5820 <exit>
        printf("%s: oops createdelete %s didn't exist\n", s, name);
    3d90:	f8040613          	addi	a2,s0,-128
    3d94:	85e6                	mv	a1,s9
    3d96:	00004517          	auipc	a0,0x4
    3d9a:	cba50513          	addi	a0,a0,-838 # 7a50 <malloc+0x1da0>
    3d9e:	00002097          	auipc	ra,0x2
    3da2:	e54080e7          	jalr	-428(ra) # 5bf2 <printf>
        exit(1);
    3da6:	4505                	li	a0,1
    3da8:	00002097          	auipc	ra,0x2
    3dac:	a78080e7          	jalr	-1416(ra) # 5820 <exit>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    3db0:	054b7163          	bgeu	s6,s4,3df2 <createdelete+0x198>
      if(fd >= 0)
    3db4:	02055a63          	bgez	a0,3de8 <createdelete+0x18e>
    for(pi = 0; pi < NCHILD; pi++){
    3db8:	2485                	addiw	s1,s1,1
    3dba:	0ff4f493          	andi	s1,s1,255
    3dbe:	05548c63          	beq	s1,s5,3e16 <createdelete+0x1bc>
      name[0] = 'p' + pi;
    3dc2:	f8940023          	sb	s1,-128(s0)
      name[1] = '0' + i;
    3dc6:	f93400a3          	sb	s3,-127(s0)
      fd = open(name, 0);
    3dca:	4581                	li	a1,0
    3dcc:	f8040513          	addi	a0,s0,-128
    3dd0:	00002097          	auipc	ra,0x2
    3dd4:	a90080e7          	jalr	-1392(ra) # 5860 <open>
      if((i == 0 || i >= N/2) && fd < 0){
    3dd8:	00090463          	beqz	s2,3de0 <createdelete+0x186>
    3ddc:	fd2bdae3          	bge	s7,s2,3db0 <createdelete+0x156>
    3de0:	fa0548e3          	bltz	a0,3d90 <createdelete+0x136>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    3de4:	014b7963          	bgeu	s6,s4,3df6 <createdelete+0x19c>
        close(fd);
    3de8:	00002097          	auipc	ra,0x2
    3dec:	a60080e7          	jalr	-1440(ra) # 5848 <close>
    3df0:	b7e1                	j	3db8 <createdelete+0x15e>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    3df2:	fc0543e3          	bltz	a0,3db8 <createdelete+0x15e>
        printf("%s: oops createdelete %s did exist\n", s, name);
    3df6:	f8040613          	addi	a2,s0,-128
    3dfa:	85e6                	mv	a1,s9
    3dfc:	00004517          	auipc	a0,0x4
    3e00:	c7c50513          	addi	a0,a0,-900 # 7a78 <malloc+0x1dc8>
    3e04:	00002097          	auipc	ra,0x2
    3e08:	dee080e7          	jalr	-530(ra) # 5bf2 <printf>
        exit(1);
    3e0c:	4505                	li	a0,1
    3e0e:	00002097          	auipc	ra,0x2
    3e12:	a12080e7          	jalr	-1518(ra) # 5820 <exit>
  for(i = 0; i < N; i++){
    3e16:	2905                	addiw	s2,s2,1
    3e18:	2a05                	addiw	s4,s4,1
    3e1a:	2985                	addiw	s3,s3,1
    3e1c:	0ff9f993          	andi	s3,s3,255
    3e20:	47d1                	li	a5,20
    3e22:	02f90a63          	beq	s2,a5,3e56 <createdelete+0x1fc>
    for(pi = 0; pi < NCHILD; pi++){
    3e26:	84e2                	mv	s1,s8
    3e28:	bf69                	j	3dc2 <createdelete+0x168>
  for(i = 0; i < N; i++){
    3e2a:	2905                	addiw	s2,s2,1
    3e2c:	0ff97913          	andi	s2,s2,255
    3e30:	2985                	addiw	s3,s3,1
    3e32:	0ff9f993          	andi	s3,s3,255
    3e36:	03490863          	beq	s2,s4,3e66 <createdelete+0x20c>
  name[0] = name[1] = name[2] = 0;
    3e3a:	84d6                	mv	s1,s5
      name[0] = 'p' + i;
    3e3c:	f9240023          	sb	s2,-128(s0)
      name[1] = '0' + i;
    3e40:	f93400a3          	sb	s3,-127(s0)
      unlink(name);
    3e44:	f8040513          	addi	a0,s0,-128
    3e48:	00002097          	auipc	ra,0x2
    3e4c:	a28080e7          	jalr	-1496(ra) # 5870 <unlink>
    for(pi = 0; pi < NCHILD; pi++){
    3e50:	34fd                	addiw	s1,s1,-1
    3e52:	f4ed                	bnez	s1,3e3c <createdelete+0x1e2>
    3e54:	bfd9                	j	3e2a <createdelete+0x1d0>
    3e56:	03000993          	li	s3,48
    3e5a:	07000913          	li	s2,112
  name[0] = name[1] = name[2] = 0;
    3e5e:	4a91                	li	s5,4
  for(i = 0; i < N; i++){
    3e60:	08400a13          	li	s4,132
    3e64:	bfd9                	j	3e3a <createdelete+0x1e0>
}
    3e66:	60aa                	ld	ra,136(sp)
    3e68:	640a                	ld	s0,128(sp)
    3e6a:	74e6                	ld	s1,120(sp)
    3e6c:	7946                	ld	s2,112(sp)
    3e6e:	79a6                	ld	s3,104(sp)
    3e70:	7a06                	ld	s4,96(sp)
    3e72:	6ae6                	ld	s5,88(sp)
    3e74:	6b46                	ld	s6,80(sp)
    3e76:	6ba6                	ld	s7,72(sp)
    3e78:	6c06                	ld	s8,64(sp)
    3e7a:	7ce2                	ld	s9,56(sp)
    3e7c:	6149                	addi	sp,sp,144
    3e7e:	8082                	ret

0000000000003e80 <concreate>:
{
    3e80:	7135                	addi	sp,sp,-160
    3e82:	ed06                	sd	ra,152(sp)
    3e84:	e922                	sd	s0,144(sp)
    3e86:	e526                	sd	s1,136(sp)
    3e88:	e14a                	sd	s2,128(sp)
    3e8a:	fcce                	sd	s3,120(sp)
    3e8c:	f8d2                	sd	s4,112(sp)
    3e8e:	f4d6                	sd	s5,104(sp)
    3e90:	f0da                	sd	s6,96(sp)
    3e92:	ecde                	sd	s7,88(sp)
    3e94:	1100                	addi	s0,sp,160
    3e96:	89aa                	mv	s3,a0
  file[0] = 'C';
    3e98:	04300793          	li	a5,67
    3e9c:	faf40423          	sb	a5,-88(s0)
  file[2] = '\0';
    3ea0:	fa040523          	sb	zero,-86(s0)
  for(i = 0; i < N; i++){
    3ea4:	4901                	li	s2,0
    if(pid && (i % 3) == 1){
    3ea6:	4b0d                	li	s6,3
    3ea8:	4a85                	li	s5,1
      link("C0", file);
    3eaa:	00004b97          	auipc	s7,0x4
    3eae:	bf6b8b93          	addi	s7,s7,-1034 # 7aa0 <malloc+0x1df0>
  for(i = 0; i < N; i++){
    3eb2:	02800a13          	li	s4,40
    3eb6:	acc1                	j	4186 <concreate+0x306>
      link("C0", file);
    3eb8:	fa840593          	addi	a1,s0,-88
    3ebc:	855e                	mv	a0,s7
    3ebe:	00002097          	auipc	ra,0x2
    3ec2:	9c2080e7          	jalr	-1598(ra) # 5880 <link>
    if(pid == 0) {
    3ec6:	a45d                	j	416c <concreate+0x2ec>
    } else if(pid == 0 && (i % 5) == 1){
    3ec8:	4795                	li	a5,5
    3eca:	02f9693b          	remw	s2,s2,a5
    3ece:	4785                	li	a5,1
    3ed0:	02f90b63          	beq	s2,a5,3f06 <concreate+0x86>
      fd = open(file, O_CREATE | O_RDWR);
    3ed4:	20200593          	li	a1,514
    3ed8:	fa840513          	addi	a0,s0,-88
    3edc:	00002097          	auipc	ra,0x2
    3ee0:	984080e7          	jalr	-1660(ra) # 5860 <open>
      if(fd < 0){
    3ee4:	26055b63          	bgez	a0,415a <concreate+0x2da>
        printf("concreate create %s failed\n", file);
    3ee8:	fa840593          	addi	a1,s0,-88
    3eec:	00004517          	auipc	a0,0x4
    3ef0:	bbc50513          	addi	a0,a0,-1092 # 7aa8 <malloc+0x1df8>
    3ef4:	00002097          	auipc	ra,0x2
    3ef8:	cfe080e7          	jalr	-770(ra) # 5bf2 <printf>
        exit(1);
    3efc:	4505                	li	a0,1
    3efe:	00002097          	auipc	ra,0x2
    3f02:	922080e7          	jalr	-1758(ra) # 5820 <exit>
      link("C0", file);
    3f06:	fa840593          	addi	a1,s0,-88
    3f0a:	00004517          	auipc	a0,0x4
    3f0e:	b9650513          	addi	a0,a0,-1130 # 7aa0 <malloc+0x1df0>
    3f12:	00002097          	auipc	ra,0x2
    3f16:	96e080e7          	jalr	-1682(ra) # 5880 <link>
      exit(0);
    3f1a:	4501                	li	a0,0
    3f1c:	00002097          	auipc	ra,0x2
    3f20:	904080e7          	jalr	-1788(ra) # 5820 <exit>
        exit(1);
    3f24:	4505                	li	a0,1
    3f26:	00002097          	auipc	ra,0x2
    3f2a:	8fa080e7          	jalr	-1798(ra) # 5820 <exit>
  memset(fa, 0, sizeof(fa));
    3f2e:	02800613          	li	a2,40
    3f32:	4581                	li	a1,0
    3f34:	f8040513          	addi	a0,s0,-128
    3f38:	00001097          	auipc	ra,0x1
    3f3c:	6ec080e7          	jalr	1772(ra) # 5624 <memset>
  fd = open(".", 0);
    3f40:	4581                	li	a1,0
    3f42:	00002517          	auipc	a0,0x2
    3f46:	7c650513          	addi	a0,a0,1990 # 6708 <malloc+0xa58>
    3f4a:	00002097          	auipc	ra,0x2
    3f4e:	916080e7          	jalr	-1770(ra) # 5860 <open>
    3f52:	892a                	mv	s2,a0
  n = 0;
    3f54:	8aa6                	mv	s5,s1
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    3f56:	04300a13          	li	s4,67
      if(i < 0 || i >= sizeof(fa)){
    3f5a:	02700b13          	li	s6,39
      fa[i] = 1;
    3f5e:	4b85                	li	s7,1
  while(read(fd, &de, sizeof(de)) > 0){
    3f60:	4641                	li	a2,16
    3f62:	f7040593          	addi	a1,s0,-144
    3f66:	854a                	mv	a0,s2
    3f68:	00002097          	auipc	ra,0x2
    3f6c:	8d0080e7          	jalr	-1840(ra) # 5838 <read>
    3f70:	08a05163          	blez	a0,3ff2 <concreate+0x172>
    if(de.inum == 0)
    3f74:	f7045783          	lhu	a5,-144(s0)
    3f78:	d7e5                	beqz	a5,3f60 <concreate+0xe0>
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    3f7a:	f7244783          	lbu	a5,-142(s0)
    3f7e:	ff4791e3          	bne	a5,s4,3f60 <concreate+0xe0>
    3f82:	f7444783          	lbu	a5,-140(s0)
    3f86:	ffe9                	bnez	a5,3f60 <concreate+0xe0>
      i = de.name[1] - '0';
    3f88:	f7344783          	lbu	a5,-141(s0)
    3f8c:	fd07879b          	addiw	a5,a5,-48
    3f90:	0007871b          	sext.w	a4,a5
      if(i < 0 || i >= sizeof(fa)){
    3f94:	00eb6f63          	bltu	s6,a4,3fb2 <concreate+0x132>
      if(fa[i]){
    3f98:	fb040793          	addi	a5,s0,-80
    3f9c:	97ba                	add	a5,a5,a4
    3f9e:	fd07c783          	lbu	a5,-48(a5)
    3fa2:	eb85                	bnez	a5,3fd2 <concreate+0x152>
      fa[i] = 1;
    3fa4:	fb040793          	addi	a5,s0,-80
    3fa8:	973e                	add	a4,a4,a5
    3faa:	fd770823          	sb	s7,-48(a4)
      n++;
    3fae:	2a85                	addiw	s5,s5,1
    3fb0:	bf45                	j	3f60 <concreate+0xe0>
        printf("%s: concreate weird file %s\n", s, de.name);
    3fb2:	f7240613          	addi	a2,s0,-142
    3fb6:	85ce                	mv	a1,s3
    3fb8:	00004517          	auipc	a0,0x4
    3fbc:	b1050513          	addi	a0,a0,-1264 # 7ac8 <malloc+0x1e18>
    3fc0:	00002097          	auipc	ra,0x2
    3fc4:	c32080e7          	jalr	-974(ra) # 5bf2 <printf>
        exit(1);
    3fc8:	4505                	li	a0,1
    3fca:	00002097          	auipc	ra,0x2
    3fce:	856080e7          	jalr	-1962(ra) # 5820 <exit>
        printf("%s: concreate duplicate file %s\n", s, de.name);
    3fd2:	f7240613          	addi	a2,s0,-142
    3fd6:	85ce                	mv	a1,s3
    3fd8:	00004517          	auipc	a0,0x4
    3fdc:	b1050513          	addi	a0,a0,-1264 # 7ae8 <malloc+0x1e38>
    3fe0:	00002097          	auipc	ra,0x2
    3fe4:	c12080e7          	jalr	-1006(ra) # 5bf2 <printf>
        exit(1);
    3fe8:	4505                	li	a0,1
    3fea:	00002097          	auipc	ra,0x2
    3fee:	836080e7          	jalr	-1994(ra) # 5820 <exit>
  close(fd);
    3ff2:	854a                	mv	a0,s2
    3ff4:	00002097          	auipc	ra,0x2
    3ff8:	854080e7          	jalr	-1964(ra) # 5848 <close>
  if(n != N){
    3ffc:	02800793          	li	a5,40
    4000:	00fa9763          	bne	s5,a5,400e <concreate+0x18e>
    if(((i % 3) == 0 && pid == 0) ||
    4004:	4a8d                	li	s5,3
    4006:	4b05                	li	s6,1
  for(i = 0; i < N; i++){
    4008:	02800a13          	li	s4,40
    400c:	a8c9                	j	40de <concreate+0x25e>
    printf("%s: concreate not enough files in directory listing\n", s);
    400e:	85ce                	mv	a1,s3
    4010:	00004517          	auipc	a0,0x4
    4014:	b0050513          	addi	a0,a0,-1280 # 7b10 <malloc+0x1e60>
    4018:	00002097          	auipc	ra,0x2
    401c:	bda080e7          	jalr	-1062(ra) # 5bf2 <printf>
    exit(1);
    4020:	4505                	li	a0,1
    4022:	00001097          	auipc	ra,0x1
    4026:	7fe080e7          	jalr	2046(ra) # 5820 <exit>
      printf("%s: fork failed\n", s);
    402a:	85ce                	mv	a1,s3
    402c:	00002517          	auipc	a0,0x2
    4030:	ffc50513          	addi	a0,a0,-4 # 6028 <malloc+0x378>
    4034:	00002097          	auipc	ra,0x2
    4038:	bbe080e7          	jalr	-1090(ra) # 5bf2 <printf>
      exit(1);
    403c:	4505                	li	a0,1
    403e:	00001097          	auipc	ra,0x1
    4042:	7e2080e7          	jalr	2018(ra) # 5820 <exit>
      close(open(file, 0));
    4046:	4581                	li	a1,0
    4048:	fa840513          	addi	a0,s0,-88
    404c:	00002097          	auipc	ra,0x2
    4050:	814080e7          	jalr	-2028(ra) # 5860 <open>
    4054:	00001097          	auipc	ra,0x1
    4058:	7f4080e7          	jalr	2036(ra) # 5848 <close>
      close(open(file, 0));
    405c:	4581                	li	a1,0
    405e:	fa840513          	addi	a0,s0,-88
    4062:	00001097          	auipc	ra,0x1
    4066:	7fe080e7          	jalr	2046(ra) # 5860 <open>
    406a:	00001097          	auipc	ra,0x1
    406e:	7de080e7          	jalr	2014(ra) # 5848 <close>
      close(open(file, 0));
    4072:	4581                	li	a1,0
    4074:	fa840513          	addi	a0,s0,-88
    4078:	00001097          	auipc	ra,0x1
    407c:	7e8080e7          	jalr	2024(ra) # 5860 <open>
    4080:	00001097          	auipc	ra,0x1
    4084:	7c8080e7          	jalr	1992(ra) # 5848 <close>
      close(open(file, 0));
    4088:	4581                	li	a1,0
    408a:	fa840513          	addi	a0,s0,-88
    408e:	00001097          	auipc	ra,0x1
    4092:	7d2080e7          	jalr	2002(ra) # 5860 <open>
    4096:	00001097          	auipc	ra,0x1
    409a:	7b2080e7          	jalr	1970(ra) # 5848 <close>
      close(open(file, 0));
    409e:	4581                	li	a1,0
    40a0:	fa840513          	addi	a0,s0,-88
    40a4:	00001097          	auipc	ra,0x1
    40a8:	7bc080e7          	jalr	1980(ra) # 5860 <open>
    40ac:	00001097          	auipc	ra,0x1
    40b0:	79c080e7          	jalr	1948(ra) # 5848 <close>
      close(open(file, 0));
    40b4:	4581                	li	a1,0
    40b6:	fa840513          	addi	a0,s0,-88
    40ba:	00001097          	auipc	ra,0x1
    40be:	7a6080e7          	jalr	1958(ra) # 5860 <open>
    40c2:	00001097          	auipc	ra,0x1
    40c6:	786080e7          	jalr	1926(ra) # 5848 <close>
    if(pid == 0)
    40ca:	08090363          	beqz	s2,4150 <concreate+0x2d0>
      wait(0);
    40ce:	4501                	li	a0,0
    40d0:	00001097          	auipc	ra,0x1
    40d4:	758080e7          	jalr	1880(ra) # 5828 <wait>
  for(i = 0; i < N; i++){
    40d8:	2485                	addiw	s1,s1,1
    40da:	0f448563          	beq	s1,s4,41c4 <concreate+0x344>
    file[1] = '0' + i;
    40de:	0304879b          	addiw	a5,s1,48
    40e2:	faf404a3          	sb	a5,-87(s0)
    pid = fork();
    40e6:	00001097          	auipc	ra,0x1
    40ea:	732080e7          	jalr	1842(ra) # 5818 <fork>
    40ee:	892a                	mv	s2,a0
    if(pid < 0){
    40f0:	f2054de3          	bltz	a0,402a <concreate+0x1aa>
    if(((i % 3) == 0 && pid == 0) ||
    40f4:	0354e73b          	remw	a4,s1,s5
    40f8:	00a767b3          	or	a5,a4,a0
    40fc:	2781                	sext.w	a5,a5
    40fe:	d7a1                	beqz	a5,4046 <concreate+0x1c6>
    4100:	01671363          	bne	a4,s6,4106 <concreate+0x286>
       ((i % 3) == 1 && pid != 0)){
    4104:	f129                	bnez	a0,4046 <concreate+0x1c6>
      unlink(file);
    4106:	fa840513          	addi	a0,s0,-88
    410a:	00001097          	auipc	ra,0x1
    410e:	766080e7          	jalr	1894(ra) # 5870 <unlink>
      unlink(file);
    4112:	fa840513          	addi	a0,s0,-88
    4116:	00001097          	auipc	ra,0x1
    411a:	75a080e7          	jalr	1882(ra) # 5870 <unlink>
      unlink(file);
    411e:	fa840513          	addi	a0,s0,-88
    4122:	00001097          	auipc	ra,0x1
    4126:	74e080e7          	jalr	1870(ra) # 5870 <unlink>
      unlink(file);
    412a:	fa840513          	addi	a0,s0,-88
    412e:	00001097          	auipc	ra,0x1
    4132:	742080e7          	jalr	1858(ra) # 5870 <unlink>
      unlink(file);
    4136:	fa840513          	addi	a0,s0,-88
    413a:	00001097          	auipc	ra,0x1
    413e:	736080e7          	jalr	1846(ra) # 5870 <unlink>
      unlink(file);
    4142:	fa840513          	addi	a0,s0,-88
    4146:	00001097          	auipc	ra,0x1
    414a:	72a080e7          	jalr	1834(ra) # 5870 <unlink>
    414e:	bfb5                	j	40ca <concreate+0x24a>
      exit(0);
    4150:	4501                	li	a0,0
    4152:	00001097          	auipc	ra,0x1
    4156:	6ce080e7          	jalr	1742(ra) # 5820 <exit>
      close(fd);
    415a:	00001097          	auipc	ra,0x1
    415e:	6ee080e7          	jalr	1774(ra) # 5848 <close>
    if(pid == 0) {
    4162:	bb65                	j	3f1a <concreate+0x9a>
      close(fd);
    4164:	00001097          	auipc	ra,0x1
    4168:	6e4080e7          	jalr	1764(ra) # 5848 <close>
      wait(&xstatus);
    416c:	f6c40513          	addi	a0,s0,-148
    4170:	00001097          	auipc	ra,0x1
    4174:	6b8080e7          	jalr	1720(ra) # 5828 <wait>
      if(xstatus != 0)
    4178:	f6c42483          	lw	s1,-148(s0)
    417c:	da0494e3          	bnez	s1,3f24 <concreate+0xa4>
  for(i = 0; i < N; i++){
    4180:	2905                	addiw	s2,s2,1
    4182:	db4906e3          	beq	s2,s4,3f2e <concreate+0xae>
    file[1] = '0' + i;
    4186:	0309079b          	addiw	a5,s2,48
    418a:	faf404a3          	sb	a5,-87(s0)
    unlink(file);
    418e:	fa840513          	addi	a0,s0,-88
    4192:	00001097          	auipc	ra,0x1
    4196:	6de080e7          	jalr	1758(ra) # 5870 <unlink>
    pid = fork();
    419a:	00001097          	auipc	ra,0x1
    419e:	67e080e7          	jalr	1662(ra) # 5818 <fork>
    if(pid && (i % 3) == 1){
    41a2:	d20503e3          	beqz	a0,3ec8 <concreate+0x48>
    41a6:	036967bb          	remw	a5,s2,s6
    41aa:	d15787e3          	beq	a5,s5,3eb8 <concreate+0x38>
      fd = open(file, O_CREATE | O_RDWR);
    41ae:	20200593          	li	a1,514
    41b2:	fa840513          	addi	a0,s0,-88
    41b6:	00001097          	auipc	ra,0x1
    41ba:	6aa080e7          	jalr	1706(ra) # 5860 <open>
      if(fd < 0){
    41be:	fa0553e3          	bgez	a0,4164 <concreate+0x2e4>
    41c2:	b31d                	j	3ee8 <concreate+0x68>
}
    41c4:	60ea                	ld	ra,152(sp)
    41c6:	644a                	ld	s0,144(sp)
    41c8:	64aa                	ld	s1,136(sp)
    41ca:	690a                	ld	s2,128(sp)
    41cc:	79e6                	ld	s3,120(sp)
    41ce:	7a46                	ld	s4,112(sp)
    41d0:	7aa6                	ld	s5,104(sp)
    41d2:	7b06                	ld	s6,96(sp)
    41d4:	6be6                	ld	s7,88(sp)
    41d6:	610d                	addi	sp,sp,160
    41d8:	8082                	ret

00000000000041da <linkunlink>:
{
    41da:	711d                	addi	sp,sp,-96
    41dc:	ec86                	sd	ra,88(sp)
    41de:	e8a2                	sd	s0,80(sp)
    41e0:	e4a6                	sd	s1,72(sp)
    41e2:	e0ca                	sd	s2,64(sp)
    41e4:	fc4e                	sd	s3,56(sp)
    41e6:	f852                	sd	s4,48(sp)
    41e8:	f456                	sd	s5,40(sp)
    41ea:	f05a                	sd	s6,32(sp)
    41ec:	ec5e                	sd	s7,24(sp)
    41ee:	e862                	sd	s8,16(sp)
    41f0:	e466                	sd	s9,8(sp)
    41f2:	1080                	addi	s0,sp,96
    41f4:	84aa                	mv	s1,a0
  unlink("x");
    41f6:	00002517          	auipc	a0,0x2
    41fa:	fea50513          	addi	a0,a0,-22 # 61e0 <malloc+0x530>
    41fe:	00001097          	auipc	ra,0x1
    4202:	672080e7          	jalr	1650(ra) # 5870 <unlink>
  pid = fork();
    4206:	00001097          	auipc	ra,0x1
    420a:	612080e7          	jalr	1554(ra) # 5818 <fork>
  if(pid < 0){
    420e:	02054b63          	bltz	a0,4244 <linkunlink+0x6a>
    4212:	8c2a                	mv	s8,a0
  unsigned int x = (pid ? 1 : 97);
    4214:	4c85                	li	s9,1
    4216:	e119                	bnez	a0,421c <linkunlink+0x42>
    4218:	06100c93          	li	s9,97
    421c:	06400493          	li	s1,100
    x = x * 1103515245 + 12345;
    4220:	41c659b7          	lui	s3,0x41c65
    4224:	e6d9899b          	addiw	s3,s3,-403
    4228:	690d                	lui	s2,0x3
    422a:	0399091b          	addiw	s2,s2,57
    if((x % 3) == 0){
    422e:	4a0d                	li	s4,3
    } else if((x % 3) == 1){
    4230:	4b05                	li	s6,1
      unlink("x");
    4232:	00002a97          	auipc	s5,0x2
    4236:	faea8a93          	addi	s5,s5,-82 # 61e0 <malloc+0x530>
      link("cat", "x");
    423a:	00004b97          	auipc	s7,0x4
    423e:	90eb8b93          	addi	s7,s7,-1778 # 7b48 <malloc+0x1e98>
    4242:	a825                	j	427a <linkunlink+0xa0>
    printf("%s: fork failed\n", s);
    4244:	85a6                	mv	a1,s1
    4246:	00002517          	auipc	a0,0x2
    424a:	de250513          	addi	a0,a0,-542 # 6028 <malloc+0x378>
    424e:	00002097          	auipc	ra,0x2
    4252:	9a4080e7          	jalr	-1628(ra) # 5bf2 <printf>
    exit(1);
    4256:	4505                	li	a0,1
    4258:	00001097          	auipc	ra,0x1
    425c:	5c8080e7          	jalr	1480(ra) # 5820 <exit>
      close(open("x", O_RDWR | O_CREATE));
    4260:	20200593          	li	a1,514
    4264:	8556                	mv	a0,s5
    4266:	00001097          	auipc	ra,0x1
    426a:	5fa080e7          	jalr	1530(ra) # 5860 <open>
    426e:	00001097          	auipc	ra,0x1
    4272:	5da080e7          	jalr	1498(ra) # 5848 <close>
  for(i = 0; i < 100; i++){
    4276:	34fd                	addiw	s1,s1,-1
    4278:	c88d                	beqz	s1,42aa <linkunlink+0xd0>
    x = x * 1103515245 + 12345;
    427a:	033c87bb          	mulw	a5,s9,s3
    427e:	012787bb          	addw	a5,a5,s2
    4282:	00078c9b          	sext.w	s9,a5
    if((x % 3) == 0){
    4286:	0347f7bb          	remuw	a5,a5,s4
    428a:	dbf9                	beqz	a5,4260 <linkunlink+0x86>
    } else if((x % 3) == 1){
    428c:	01678863          	beq	a5,s6,429c <linkunlink+0xc2>
      unlink("x");
    4290:	8556                	mv	a0,s5
    4292:	00001097          	auipc	ra,0x1
    4296:	5de080e7          	jalr	1502(ra) # 5870 <unlink>
    429a:	bff1                	j	4276 <linkunlink+0x9c>
      link("cat", "x");
    429c:	85d6                	mv	a1,s5
    429e:	855e                	mv	a0,s7
    42a0:	00001097          	auipc	ra,0x1
    42a4:	5e0080e7          	jalr	1504(ra) # 5880 <link>
    42a8:	b7f9                	j	4276 <linkunlink+0x9c>
  if(pid)
    42aa:	020c0463          	beqz	s8,42d2 <linkunlink+0xf8>
    wait(0);
    42ae:	4501                	li	a0,0
    42b0:	00001097          	auipc	ra,0x1
    42b4:	578080e7          	jalr	1400(ra) # 5828 <wait>
}
    42b8:	60e6                	ld	ra,88(sp)
    42ba:	6446                	ld	s0,80(sp)
    42bc:	64a6                	ld	s1,72(sp)
    42be:	6906                	ld	s2,64(sp)
    42c0:	79e2                	ld	s3,56(sp)
    42c2:	7a42                	ld	s4,48(sp)
    42c4:	7aa2                	ld	s5,40(sp)
    42c6:	7b02                	ld	s6,32(sp)
    42c8:	6be2                	ld	s7,24(sp)
    42ca:	6c42                	ld	s8,16(sp)
    42cc:	6ca2                	ld	s9,8(sp)
    42ce:	6125                	addi	sp,sp,96
    42d0:	8082                	ret
    exit(0);
    42d2:	4501                	li	a0,0
    42d4:	00001097          	auipc	ra,0x1
    42d8:	54c080e7          	jalr	1356(ra) # 5820 <exit>

00000000000042dc <bigdir>:
{
    42dc:	715d                	addi	sp,sp,-80
    42de:	e486                	sd	ra,72(sp)
    42e0:	e0a2                	sd	s0,64(sp)
    42e2:	fc26                	sd	s1,56(sp)
    42e4:	f84a                	sd	s2,48(sp)
    42e6:	f44e                	sd	s3,40(sp)
    42e8:	f052                	sd	s4,32(sp)
    42ea:	ec56                	sd	s5,24(sp)
    42ec:	e85a                	sd	s6,16(sp)
    42ee:	0880                	addi	s0,sp,80
    42f0:	89aa                	mv	s3,a0
  unlink("bd");
    42f2:	00004517          	auipc	a0,0x4
    42f6:	85e50513          	addi	a0,a0,-1954 # 7b50 <malloc+0x1ea0>
    42fa:	00001097          	auipc	ra,0x1
    42fe:	576080e7          	jalr	1398(ra) # 5870 <unlink>
  fd = open("bd", O_CREATE);
    4302:	20000593          	li	a1,512
    4306:	00004517          	auipc	a0,0x4
    430a:	84a50513          	addi	a0,a0,-1974 # 7b50 <malloc+0x1ea0>
    430e:	00001097          	auipc	ra,0x1
    4312:	552080e7          	jalr	1362(ra) # 5860 <open>
  if(fd < 0){
    4316:	0c054963          	bltz	a0,43e8 <bigdir+0x10c>
  close(fd);
    431a:	00001097          	auipc	ra,0x1
    431e:	52e080e7          	jalr	1326(ra) # 5848 <close>
  for(i = 0; i < N; i++){
    4322:	4901                	li	s2,0
    name[0] = 'x';
    4324:	07800a93          	li	s5,120
    if(link("bd", name) != 0){
    4328:	00004a17          	auipc	s4,0x4
    432c:	828a0a13          	addi	s4,s4,-2008 # 7b50 <malloc+0x1ea0>
  for(i = 0; i < N; i++){
    4330:	1f400b13          	li	s6,500
    name[0] = 'x';
    4334:	fb540823          	sb	s5,-80(s0)
    name[1] = '0' + (i / 64);
    4338:	41f9579b          	sraiw	a5,s2,0x1f
    433c:	01a7d71b          	srliw	a4,a5,0x1a
    4340:	012707bb          	addw	a5,a4,s2
    4344:	4067d69b          	sraiw	a3,a5,0x6
    4348:	0306869b          	addiw	a3,a3,48
    434c:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
    4350:	03f7f793          	andi	a5,a5,63
    4354:	9f99                	subw	a5,a5,a4
    4356:	0307879b          	addiw	a5,a5,48
    435a:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
    435e:	fa0409a3          	sb	zero,-77(s0)
    if(link("bd", name) != 0){
    4362:	fb040593          	addi	a1,s0,-80
    4366:	8552                	mv	a0,s4
    4368:	00001097          	auipc	ra,0x1
    436c:	518080e7          	jalr	1304(ra) # 5880 <link>
    4370:	84aa                	mv	s1,a0
    4372:	e949                	bnez	a0,4404 <bigdir+0x128>
  for(i = 0; i < N; i++){
    4374:	2905                	addiw	s2,s2,1
    4376:	fb691fe3          	bne	s2,s6,4334 <bigdir+0x58>
  unlink("bd");
    437a:	00003517          	auipc	a0,0x3
    437e:	7d650513          	addi	a0,a0,2006 # 7b50 <malloc+0x1ea0>
    4382:	00001097          	auipc	ra,0x1
    4386:	4ee080e7          	jalr	1262(ra) # 5870 <unlink>
    name[0] = 'x';
    438a:	07800913          	li	s2,120
  for(i = 0; i < N; i++){
    438e:	1f400a13          	li	s4,500
    name[0] = 'x';
    4392:	fb240823          	sb	s2,-80(s0)
    name[1] = '0' + (i / 64);
    4396:	41f4d79b          	sraiw	a5,s1,0x1f
    439a:	01a7d71b          	srliw	a4,a5,0x1a
    439e:	009707bb          	addw	a5,a4,s1
    43a2:	4067d69b          	sraiw	a3,a5,0x6
    43a6:	0306869b          	addiw	a3,a3,48
    43aa:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
    43ae:	03f7f793          	andi	a5,a5,63
    43b2:	9f99                	subw	a5,a5,a4
    43b4:	0307879b          	addiw	a5,a5,48
    43b8:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
    43bc:	fa0409a3          	sb	zero,-77(s0)
    if(unlink(name) != 0){
    43c0:	fb040513          	addi	a0,s0,-80
    43c4:	00001097          	auipc	ra,0x1
    43c8:	4ac080e7          	jalr	1196(ra) # 5870 <unlink>
    43cc:	ed21                	bnez	a0,4424 <bigdir+0x148>
  for(i = 0; i < N; i++){
    43ce:	2485                	addiw	s1,s1,1
    43d0:	fd4491e3          	bne	s1,s4,4392 <bigdir+0xb6>
}
    43d4:	60a6                	ld	ra,72(sp)
    43d6:	6406                	ld	s0,64(sp)
    43d8:	74e2                	ld	s1,56(sp)
    43da:	7942                	ld	s2,48(sp)
    43dc:	79a2                	ld	s3,40(sp)
    43de:	7a02                	ld	s4,32(sp)
    43e0:	6ae2                	ld	s5,24(sp)
    43e2:	6b42                	ld	s6,16(sp)
    43e4:	6161                	addi	sp,sp,80
    43e6:	8082                	ret
    printf("%s: bigdir create failed\n", s);
    43e8:	85ce                	mv	a1,s3
    43ea:	00003517          	auipc	a0,0x3
    43ee:	76e50513          	addi	a0,a0,1902 # 7b58 <malloc+0x1ea8>
    43f2:	00002097          	auipc	ra,0x2
    43f6:	800080e7          	jalr	-2048(ra) # 5bf2 <printf>
    exit(1);
    43fa:	4505                	li	a0,1
    43fc:	00001097          	auipc	ra,0x1
    4400:	424080e7          	jalr	1060(ra) # 5820 <exit>
      printf("%s: bigdir link(bd, %s) failed\n", s, name);
    4404:	fb040613          	addi	a2,s0,-80
    4408:	85ce                	mv	a1,s3
    440a:	00003517          	auipc	a0,0x3
    440e:	76e50513          	addi	a0,a0,1902 # 7b78 <malloc+0x1ec8>
    4412:	00001097          	auipc	ra,0x1
    4416:	7e0080e7          	jalr	2016(ra) # 5bf2 <printf>
      exit(1);
    441a:	4505                	li	a0,1
    441c:	00001097          	auipc	ra,0x1
    4420:	404080e7          	jalr	1028(ra) # 5820 <exit>
      printf("%s: bigdir unlink failed", s);
    4424:	85ce                	mv	a1,s3
    4426:	00003517          	auipc	a0,0x3
    442a:	77250513          	addi	a0,a0,1906 # 7b98 <malloc+0x1ee8>
    442e:	00001097          	auipc	ra,0x1
    4432:	7c4080e7          	jalr	1988(ra) # 5bf2 <printf>
      exit(1);
    4436:	4505                	li	a0,1
    4438:	00001097          	auipc	ra,0x1
    443c:	3e8080e7          	jalr	1000(ra) # 5820 <exit>

0000000000004440 <manywrites>:
{
    4440:	711d                	addi	sp,sp,-96
    4442:	ec86                	sd	ra,88(sp)
    4444:	e8a2                	sd	s0,80(sp)
    4446:	e4a6                	sd	s1,72(sp)
    4448:	e0ca                	sd	s2,64(sp)
    444a:	fc4e                	sd	s3,56(sp)
    444c:	f852                	sd	s4,48(sp)
    444e:	f456                	sd	s5,40(sp)
    4450:	f05a                	sd	s6,32(sp)
    4452:	ec5e                	sd	s7,24(sp)
    4454:	1080                	addi	s0,sp,96
    4456:	8aaa                	mv	s5,a0
  for(int ci = 0; ci < nchildren; ci++){
    4458:	4981                	li	s3,0
    445a:	4911                	li	s2,4
    int pid = fork();
    445c:	00001097          	auipc	ra,0x1
    4460:	3bc080e7          	jalr	956(ra) # 5818 <fork>
    4464:	84aa                	mv	s1,a0
    if(pid < 0){
    4466:	02054963          	bltz	a0,4498 <manywrites+0x58>
    if(pid == 0){
    446a:	c521                	beqz	a0,44b2 <manywrites+0x72>
  for(int ci = 0; ci < nchildren; ci++){
    446c:	2985                	addiw	s3,s3,1
    446e:	ff2997e3          	bne	s3,s2,445c <manywrites+0x1c>
    4472:	4491                	li	s1,4
    int st = 0;
    4474:	fa042423          	sw	zero,-88(s0)
    wait(&st);
    4478:	fa840513          	addi	a0,s0,-88
    447c:	00001097          	auipc	ra,0x1
    4480:	3ac080e7          	jalr	940(ra) # 5828 <wait>
    if(st != 0)
    4484:	fa842503          	lw	a0,-88(s0)
    4488:	ed6d                	bnez	a0,4582 <manywrites+0x142>
  for(int ci = 0; ci < nchildren; ci++){
    448a:	34fd                	addiw	s1,s1,-1
    448c:	f4e5                	bnez	s1,4474 <manywrites+0x34>
  exit(0);
    448e:	4501                	li	a0,0
    4490:	00001097          	auipc	ra,0x1
    4494:	390080e7          	jalr	912(ra) # 5820 <exit>
      printf("fork failed\n");
    4498:	00002517          	auipc	a0,0x2
    449c:	55850513          	addi	a0,a0,1368 # 69f0 <malloc+0xd40>
    44a0:	00001097          	auipc	ra,0x1
    44a4:	752080e7          	jalr	1874(ra) # 5bf2 <printf>
      exit(1);
    44a8:	4505                	li	a0,1
    44aa:	00001097          	auipc	ra,0x1
    44ae:	376080e7          	jalr	886(ra) # 5820 <exit>
      name[0] = 'b';
    44b2:	06200793          	li	a5,98
    44b6:	faf40423          	sb	a5,-88(s0)
      name[1] = 'a' + ci;
    44ba:	0619879b          	addiw	a5,s3,97
    44be:	faf404a3          	sb	a5,-87(s0)
      name[2] = '\0';
    44c2:	fa040523          	sb	zero,-86(s0)
      unlink(name);
    44c6:	fa840513          	addi	a0,s0,-88
    44ca:	00001097          	auipc	ra,0x1
    44ce:	3a6080e7          	jalr	934(ra) # 5870 <unlink>
    44d2:	4bf9                	li	s7,30
          int cc = write(fd, buf, sz);
    44d4:	00007b17          	auipc	s6,0x7
    44d8:	6dcb0b13          	addi	s6,s6,1756 # bbb0 <buf>
        for(int i = 0; i < ci+1; i++){
    44dc:	8a26                	mv	s4,s1
    44de:	0209ce63          	bltz	s3,451a <manywrites+0xda>
          int fd = open(name, O_CREATE | O_RDWR);
    44e2:	20200593          	li	a1,514
    44e6:	fa840513          	addi	a0,s0,-88
    44ea:	00001097          	auipc	ra,0x1
    44ee:	376080e7          	jalr	886(ra) # 5860 <open>
    44f2:	892a                	mv	s2,a0
          if(fd < 0){
    44f4:	04054763          	bltz	a0,4542 <manywrites+0x102>
          int cc = write(fd, buf, sz);
    44f8:	660d                	lui	a2,0x3
    44fa:	85da                	mv	a1,s6
    44fc:	00001097          	auipc	ra,0x1
    4500:	344080e7          	jalr	836(ra) # 5840 <write>
          if(cc != sz){
    4504:	678d                	lui	a5,0x3
    4506:	04f51e63          	bne	a0,a5,4562 <manywrites+0x122>
          close(fd);
    450a:	854a                	mv	a0,s2
    450c:	00001097          	auipc	ra,0x1
    4510:	33c080e7          	jalr	828(ra) # 5848 <close>
        for(int i = 0; i < ci+1; i++){
    4514:	2a05                	addiw	s4,s4,1
    4516:	fd49d6e3          	bge	s3,s4,44e2 <manywrites+0xa2>
        unlink(name);
    451a:	fa840513          	addi	a0,s0,-88
    451e:	00001097          	auipc	ra,0x1
    4522:	352080e7          	jalr	850(ra) # 5870 <unlink>
      for(int iters = 0; iters < howmany; iters++){
    4526:	3bfd                	addiw	s7,s7,-1
    4528:	fa0b9ae3          	bnez	s7,44dc <manywrites+0x9c>
      unlink(name);
    452c:	fa840513          	addi	a0,s0,-88
    4530:	00001097          	auipc	ra,0x1
    4534:	340080e7          	jalr	832(ra) # 5870 <unlink>
      exit(0);
    4538:	4501                	li	a0,0
    453a:	00001097          	auipc	ra,0x1
    453e:	2e6080e7          	jalr	742(ra) # 5820 <exit>
            printf("%s: cannot create %s\n", s, name);
    4542:	fa840613          	addi	a2,s0,-88
    4546:	85d6                	mv	a1,s5
    4548:	00003517          	auipc	a0,0x3
    454c:	67050513          	addi	a0,a0,1648 # 7bb8 <malloc+0x1f08>
    4550:	00001097          	auipc	ra,0x1
    4554:	6a2080e7          	jalr	1698(ra) # 5bf2 <printf>
            exit(1);
    4558:	4505                	li	a0,1
    455a:	00001097          	auipc	ra,0x1
    455e:	2c6080e7          	jalr	710(ra) # 5820 <exit>
            printf("%s: write(%d) ret %d\n", s, sz, cc);
    4562:	86aa                	mv	a3,a0
    4564:	660d                	lui	a2,0x3
    4566:	85d6                	mv	a1,s5
    4568:	00002517          	auipc	a0,0x2
    456c:	cd850513          	addi	a0,a0,-808 # 6240 <malloc+0x590>
    4570:	00001097          	auipc	ra,0x1
    4574:	682080e7          	jalr	1666(ra) # 5bf2 <printf>
            exit(1);
    4578:	4505                	li	a0,1
    457a:	00001097          	auipc	ra,0x1
    457e:	2a6080e7          	jalr	678(ra) # 5820 <exit>
      exit(st);
    4582:	00001097          	auipc	ra,0x1
    4586:	29e080e7          	jalr	670(ra) # 5820 <exit>

000000000000458a <iref>:
{
    458a:	7139                	addi	sp,sp,-64
    458c:	fc06                	sd	ra,56(sp)
    458e:	f822                	sd	s0,48(sp)
    4590:	f426                	sd	s1,40(sp)
    4592:	f04a                	sd	s2,32(sp)
    4594:	ec4e                	sd	s3,24(sp)
    4596:	e852                	sd	s4,16(sp)
    4598:	e456                	sd	s5,8(sp)
    459a:	e05a                	sd	s6,0(sp)
    459c:	0080                	addi	s0,sp,64
    459e:	8b2a                	mv	s6,a0
    45a0:	03300913          	li	s2,51
    if(mkdir("irefd") != 0){
    45a4:	00003a17          	auipc	s4,0x3
    45a8:	62ca0a13          	addi	s4,s4,1580 # 7bd0 <malloc+0x1f20>
    mkdir("");
    45ac:	00003497          	auipc	s1,0x3
    45b0:	b8448493          	addi	s1,s1,-1148 # 7130 <malloc+0x1480>
    link("README", "");
    45b4:	00002a97          	auipc	s5,0x2
    45b8:	d64a8a93          	addi	s5,s5,-668 # 6318 <malloc+0x668>
    fd = open("xx", O_CREATE);
    45bc:	00003997          	auipc	s3,0x3
    45c0:	f5c98993          	addi	s3,s3,-164 # 7518 <malloc+0x1868>
    45c4:	a891                	j	4618 <iref+0x8e>
      printf("%s: mkdir irefd failed\n", s);
    45c6:	85da                	mv	a1,s6
    45c8:	00003517          	auipc	a0,0x3
    45cc:	61050513          	addi	a0,a0,1552 # 7bd8 <malloc+0x1f28>
    45d0:	00001097          	auipc	ra,0x1
    45d4:	622080e7          	jalr	1570(ra) # 5bf2 <printf>
      exit(1);
    45d8:	4505                	li	a0,1
    45da:	00001097          	auipc	ra,0x1
    45de:	246080e7          	jalr	582(ra) # 5820 <exit>
      printf("%s: chdir irefd failed\n", s);
    45e2:	85da                	mv	a1,s6
    45e4:	00003517          	auipc	a0,0x3
    45e8:	60c50513          	addi	a0,a0,1548 # 7bf0 <malloc+0x1f40>
    45ec:	00001097          	auipc	ra,0x1
    45f0:	606080e7          	jalr	1542(ra) # 5bf2 <printf>
      exit(1);
    45f4:	4505                	li	a0,1
    45f6:	00001097          	auipc	ra,0x1
    45fa:	22a080e7          	jalr	554(ra) # 5820 <exit>
      close(fd);
    45fe:	00001097          	auipc	ra,0x1
    4602:	24a080e7          	jalr	586(ra) # 5848 <close>
    4606:	a889                	j	4658 <iref+0xce>
    unlink("xx");
    4608:	854e                	mv	a0,s3
    460a:	00001097          	auipc	ra,0x1
    460e:	266080e7          	jalr	614(ra) # 5870 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    4612:	397d                	addiw	s2,s2,-1
    4614:	06090063          	beqz	s2,4674 <iref+0xea>
    if(mkdir("irefd") != 0){
    4618:	8552                	mv	a0,s4
    461a:	00001097          	auipc	ra,0x1
    461e:	26e080e7          	jalr	622(ra) # 5888 <mkdir>
    4622:	f155                	bnez	a0,45c6 <iref+0x3c>
    if(chdir("irefd") != 0){
    4624:	8552                	mv	a0,s4
    4626:	00001097          	auipc	ra,0x1
    462a:	26a080e7          	jalr	618(ra) # 5890 <chdir>
    462e:	f955                	bnez	a0,45e2 <iref+0x58>
    mkdir("");
    4630:	8526                	mv	a0,s1
    4632:	00001097          	auipc	ra,0x1
    4636:	256080e7          	jalr	598(ra) # 5888 <mkdir>
    link("README", "");
    463a:	85a6                	mv	a1,s1
    463c:	8556                	mv	a0,s5
    463e:	00001097          	auipc	ra,0x1
    4642:	242080e7          	jalr	578(ra) # 5880 <link>
    fd = open("", O_CREATE);
    4646:	20000593          	li	a1,512
    464a:	8526                	mv	a0,s1
    464c:	00001097          	auipc	ra,0x1
    4650:	214080e7          	jalr	532(ra) # 5860 <open>
    if(fd >= 0)
    4654:	fa0555e3          	bgez	a0,45fe <iref+0x74>
    fd = open("xx", O_CREATE);
    4658:	20000593          	li	a1,512
    465c:	854e                	mv	a0,s3
    465e:	00001097          	auipc	ra,0x1
    4662:	202080e7          	jalr	514(ra) # 5860 <open>
    if(fd >= 0)
    4666:	fa0541e3          	bltz	a0,4608 <iref+0x7e>
      close(fd);
    466a:	00001097          	auipc	ra,0x1
    466e:	1de080e7          	jalr	478(ra) # 5848 <close>
    4672:	bf59                	j	4608 <iref+0x7e>
    4674:	03300493          	li	s1,51
    chdir("..");
    4678:	00002997          	auipc	s3,0x2
    467c:	7d898993          	addi	s3,s3,2008 # 6e50 <malloc+0x11a0>
    unlink("irefd");
    4680:	00003917          	auipc	s2,0x3
    4684:	55090913          	addi	s2,s2,1360 # 7bd0 <malloc+0x1f20>
    chdir("..");
    4688:	854e                	mv	a0,s3
    468a:	00001097          	auipc	ra,0x1
    468e:	206080e7          	jalr	518(ra) # 5890 <chdir>
    unlink("irefd");
    4692:	854a                	mv	a0,s2
    4694:	00001097          	auipc	ra,0x1
    4698:	1dc080e7          	jalr	476(ra) # 5870 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    469c:	34fd                	addiw	s1,s1,-1
    469e:	f4ed                	bnez	s1,4688 <iref+0xfe>
  chdir("/");
    46a0:	00002517          	auipc	a0,0x2
    46a4:	75850513          	addi	a0,a0,1880 # 6df8 <malloc+0x1148>
    46a8:	00001097          	auipc	ra,0x1
    46ac:	1e8080e7          	jalr	488(ra) # 5890 <chdir>
}
    46b0:	70e2                	ld	ra,56(sp)
    46b2:	7442                	ld	s0,48(sp)
    46b4:	74a2                	ld	s1,40(sp)
    46b6:	7902                	ld	s2,32(sp)
    46b8:	69e2                	ld	s3,24(sp)
    46ba:	6a42                	ld	s4,16(sp)
    46bc:	6aa2                	ld	s5,8(sp)
    46be:	6b02                	ld	s6,0(sp)
    46c0:	6121                	addi	sp,sp,64
    46c2:	8082                	ret

00000000000046c4 <sbrkbasic>:
{
    46c4:	7139                	addi	sp,sp,-64
    46c6:	fc06                	sd	ra,56(sp)
    46c8:	f822                	sd	s0,48(sp)
    46ca:	f426                	sd	s1,40(sp)
    46cc:	f04a                	sd	s2,32(sp)
    46ce:	ec4e                	sd	s3,24(sp)
    46d0:	e852                	sd	s4,16(sp)
    46d2:	0080                	addi	s0,sp,64
    46d4:	8a2a                	mv	s4,a0
  pid = fork();
    46d6:	00001097          	auipc	ra,0x1
    46da:	142080e7          	jalr	322(ra) # 5818 <fork>
  if(pid < 0){
    46de:	02054c63          	bltz	a0,4716 <sbrkbasic+0x52>
  if(pid == 0){
    46e2:	ed21                	bnez	a0,473a <sbrkbasic+0x76>
    a = sbrk(TOOMUCH);
    46e4:	40000537          	lui	a0,0x40000
    46e8:	00001097          	auipc	ra,0x1
    46ec:	1c0080e7          	jalr	448(ra) # 58a8 <sbrk>
    if(a == (char*)0xffffffffffffffffL){
    46f0:	57fd                	li	a5,-1
    46f2:	02f50f63          	beq	a0,a5,4730 <sbrkbasic+0x6c>
    for(b = a; b < a+TOOMUCH; b += 4096){
    46f6:	400007b7          	lui	a5,0x40000
    46fa:	97aa                	add	a5,a5,a0
      *b = 99;
    46fc:	06300693          	li	a3,99
    for(b = a; b < a+TOOMUCH; b += 4096){
    4700:	6705                	lui	a4,0x1
      *b = 99;
    4702:	00d50023          	sb	a3,0(a0) # 40000000 <__BSS_END__+0x3fff1440>
    for(b = a; b < a+TOOMUCH; b += 4096){
    4706:	953a                	add	a0,a0,a4
    4708:	fef51de3          	bne	a0,a5,4702 <sbrkbasic+0x3e>
    exit(1);
    470c:	4505                	li	a0,1
    470e:	00001097          	auipc	ra,0x1
    4712:	112080e7          	jalr	274(ra) # 5820 <exit>
    printf("fork failed in sbrkbasic\n");
    4716:	00003517          	auipc	a0,0x3
    471a:	4f250513          	addi	a0,a0,1266 # 7c08 <malloc+0x1f58>
    471e:	00001097          	auipc	ra,0x1
    4722:	4d4080e7          	jalr	1236(ra) # 5bf2 <printf>
    exit(1);
    4726:	4505                	li	a0,1
    4728:	00001097          	auipc	ra,0x1
    472c:	0f8080e7          	jalr	248(ra) # 5820 <exit>
      exit(0);
    4730:	4501                	li	a0,0
    4732:	00001097          	auipc	ra,0x1
    4736:	0ee080e7          	jalr	238(ra) # 5820 <exit>
  wait(&xstatus);
    473a:	fcc40513          	addi	a0,s0,-52
    473e:	00001097          	auipc	ra,0x1
    4742:	0ea080e7          	jalr	234(ra) # 5828 <wait>
  if(xstatus == 1){
    4746:	fcc42703          	lw	a4,-52(s0)
    474a:	4785                	li	a5,1
    474c:	00f70d63          	beq	a4,a5,4766 <sbrkbasic+0xa2>
  a = sbrk(0);
    4750:	4501                	li	a0,0
    4752:	00001097          	auipc	ra,0x1
    4756:	156080e7          	jalr	342(ra) # 58a8 <sbrk>
    475a:	84aa                	mv	s1,a0
  for(i = 0; i < 5000; i++){
    475c:	4901                	li	s2,0
    475e:	6985                	lui	s3,0x1
    4760:	38898993          	addi	s3,s3,904 # 1388 <linktest+0x194>
    4764:	a005                	j	4784 <sbrkbasic+0xc0>
    printf("%s: too much memory allocated!\n", s);
    4766:	85d2                	mv	a1,s4
    4768:	00003517          	auipc	a0,0x3
    476c:	4c050513          	addi	a0,a0,1216 # 7c28 <malloc+0x1f78>
    4770:	00001097          	auipc	ra,0x1
    4774:	482080e7          	jalr	1154(ra) # 5bf2 <printf>
    exit(1);
    4778:	4505                	li	a0,1
    477a:	00001097          	auipc	ra,0x1
    477e:	0a6080e7          	jalr	166(ra) # 5820 <exit>
    a = b + 1;
    4782:	84be                	mv	s1,a5
    b = sbrk(1);
    4784:	4505                	li	a0,1
    4786:	00001097          	auipc	ra,0x1
    478a:	122080e7          	jalr	290(ra) # 58a8 <sbrk>
    if(b != a){
    478e:	04951c63          	bne	a0,s1,47e6 <sbrkbasic+0x122>
    *b = 1;
    4792:	4785                	li	a5,1
    4794:	00f48023          	sb	a5,0(s1)
    a = b + 1;
    4798:	00148793          	addi	a5,s1,1
  for(i = 0; i < 5000; i++){
    479c:	2905                	addiw	s2,s2,1
    479e:	ff3912e3          	bne	s2,s3,4782 <sbrkbasic+0xbe>
  pid = fork();
    47a2:	00001097          	auipc	ra,0x1
    47a6:	076080e7          	jalr	118(ra) # 5818 <fork>
    47aa:	892a                	mv	s2,a0
  if(pid < 0){
    47ac:	04054d63          	bltz	a0,4806 <sbrkbasic+0x142>
  c = sbrk(1);
    47b0:	4505                	li	a0,1
    47b2:	00001097          	auipc	ra,0x1
    47b6:	0f6080e7          	jalr	246(ra) # 58a8 <sbrk>
  c = sbrk(1);
    47ba:	4505                	li	a0,1
    47bc:	00001097          	auipc	ra,0x1
    47c0:	0ec080e7          	jalr	236(ra) # 58a8 <sbrk>
  if(c != a + 1){
    47c4:	0489                	addi	s1,s1,2
    47c6:	04a48e63          	beq	s1,a0,4822 <sbrkbasic+0x15e>
    printf("%s: sbrk test failed post-fork\n", s);
    47ca:	85d2                	mv	a1,s4
    47cc:	00003517          	auipc	a0,0x3
    47d0:	4bc50513          	addi	a0,a0,1212 # 7c88 <malloc+0x1fd8>
    47d4:	00001097          	auipc	ra,0x1
    47d8:	41e080e7          	jalr	1054(ra) # 5bf2 <printf>
    exit(1);
    47dc:	4505                	li	a0,1
    47de:	00001097          	auipc	ra,0x1
    47e2:	042080e7          	jalr	66(ra) # 5820 <exit>
      printf("%s: sbrk test failed %d %x %x\n", i, a, b);
    47e6:	86aa                	mv	a3,a0
    47e8:	8626                	mv	a2,s1
    47ea:	85ca                	mv	a1,s2
    47ec:	00003517          	auipc	a0,0x3
    47f0:	45c50513          	addi	a0,a0,1116 # 7c48 <malloc+0x1f98>
    47f4:	00001097          	auipc	ra,0x1
    47f8:	3fe080e7          	jalr	1022(ra) # 5bf2 <printf>
      exit(1);
    47fc:	4505                	li	a0,1
    47fe:	00001097          	auipc	ra,0x1
    4802:	022080e7          	jalr	34(ra) # 5820 <exit>
    printf("%s: sbrk test fork failed\n", s);
    4806:	85d2                	mv	a1,s4
    4808:	00003517          	auipc	a0,0x3
    480c:	46050513          	addi	a0,a0,1120 # 7c68 <malloc+0x1fb8>
    4810:	00001097          	auipc	ra,0x1
    4814:	3e2080e7          	jalr	994(ra) # 5bf2 <printf>
    exit(1);
    4818:	4505                	li	a0,1
    481a:	00001097          	auipc	ra,0x1
    481e:	006080e7          	jalr	6(ra) # 5820 <exit>
  if(pid == 0)
    4822:	00091763          	bnez	s2,4830 <sbrkbasic+0x16c>
    exit(0);
    4826:	4501                	li	a0,0
    4828:	00001097          	auipc	ra,0x1
    482c:	ff8080e7          	jalr	-8(ra) # 5820 <exit>
  wait(&xstatus);
    4830:	fcc40513          	addi	a0,s0,-52
    4834:	00001097          	auipc	ra,0x1
    4838:	ff4080e7          	jalr	-12(ra) # 5828 <wait>
  exit(xstatus);
    483c:	fcc42503          	lw	a0,-52(s0)
    4840:	00001097          	auipc	ra,0x1
    4844:	fe0080e7          	jalr	-32(ra) # 5820 <exit>

0000000000004848 <sbrkmuch>:
{
    4848:	7179                	addi	sp,sp,-48
    484a:	f406                	sd	ra,40(sp)
    484c:	f022                	sd	s0,32(sp)
    484e:	ec26                	sd	s1,24(sp)
    4850:	e84a                	sd	s2,16(sp)
    4852:	e44e                	sd	s3,8(sp)
    4854:	e052                	sd	s4,0(sp)
    4856:	1800                	addi	s0,sp,48
    4858:	89aa                	mv	s3,a0
  oldbrk = sbrk(0);
    485a:	4501                	li	a0,0
    485c:	00001097          	auipc	ra,0x1
    4860:	04c080e7          	jalr	76(ra) # 58a8 <sbrk>
    4864:	892a                	mv	s2,a0
  a = sbrk(0);
    4866:	4501                	li	a0,0
    4868:	00001097          	auipc	ra,0x1
    486c:	040080e7          	jalr	64(ra) # 58a8 <sbrk>
    4870:	84aa                	mv	s1,a0
  p = sbrk(amt);
    4872:	06400537          	lui	a0,0x6400
    4876:	9d05                	subw	a0,a0,s1
    4878:	00001097          	auipc	ra,0x1
    487c:	030080e7          	jalr	48(ra) # 58a8 <sbrk>
  if (p != a) {
    4880:	0ca49863          	bne	s1,a0,4950 <sbrkmuch+0x108>
  char *eee = sbrk(0);
    4884:	4501                	li	a0,0
    4886:	00001097          	auipc	ra,0x1
    488a:	022080e7          	jalr	34(ra) # 58a8 <sbrk>
    488e:	87aa                	mv	a5,a0
  for(char *pp = a; pp < eee; pp += 4096)
    4890:	00a4f963          	bgeu	s1,a0,48a2 <sbrkmuch+0x5a>
    *pp = 1;
    4894:	4685                	li	a3,1
  for(char *pp = a; pp < eee; pp += 4096)
    4896:	6705                	lui	a4,0x1
    *pp = 1;
    4898:	00d48023          	sb	a3,0(s1)
  for(char *pp = a; pp < eee; pp += 4096)
    489c:	94ba                	add	s1,s1,a4
    489e:	fef4ede3          	bltu	s1,a5,4898 <sbrkmuch+0x50>
  *lastaddr = 99;
    48a2:	064007b7          	lui	a5,0x6400
    48a6:	06300713          	li	a4,99
    48aa:	fee78fa3          	sb	a4,-1(a5) # 63fffff <__BSS_END__+0x63f143f>
  a = sbrk(0);
    48ae:	4501                	li	a0,0
    48b0:	00001097          	auipc	ra,0x1
    48b4:	ff8080e7          	jalr	-8(ra) # 58a8 <sbrk>
    48b8:	84aa                	mv	s1,a0
  c = sbrk(-PGSIZE);
    48ba:	757d                	lui	a0,0xfffff
    48bc:	00001097          	auipc	ra,0x1
    48c0:	fec080e7          	jalr	-20(ra) # 58a8 <sbrk>
  if(c == (char*)0xffffffffffffffffL){
    48c4:	57fd                	li	a5,-1
    48c6:	0af50363          	beq	a0,a5,496c <sbrkmuch+0x124>
  c = sbrk(0);
    48ca:	4501                	li	a0,0
    48cc:	00001097          	auipc	ra,0x1
    48d0:	fdc080e7          	jalr	-36(ra) # 58a8 <sbrk>
  if(c != a - PGSIZE){
    48d4:	77fd                	lui	a5,0xfffff
    48d6:	97a6                	add	a5,a5,s1
    48d8:	0af51863          	bne	a0,a5,4988 <sbrkmuch+0x140>
  a = sbrk(0);
    48dc:	4501                	li	a0,0
    48de:	00001097          	auipc	ra,0x1
    48e2:	fca080e7          	jalr	-54(ra) # 58a8 <sbrk>
    48e6:	84aa                	mv	s1,a0
  c = sbrk(PGSIZE);
    48e8:	6505                	lui	a0,0x1
    48ea:	00001097          	auipc	ra,0x1
    48ee:	fbe080e7          	jalr	-66(ra) # 58a8 <sbrk>
    48f2:	8a2a                	mv	s4,a0
  if(c != a || sbrk(0) != a + PGSIZE){
    48f4:	0aa49a63          	bne	s1,a0,49a8 <sbrkmuch+0x160>
    48f8:	4501                	li	a0,0
    48fa:	00001097          	auipc	ra,0x1
    48fe:	fae080e7          	jalr	-82(ra) # 58a8 <sbrk>
    4902:	6785                	lui	a5,0x1
    4904:	97a6                	add	a5,a5,s1
    4906:	0af51163          	bne	a0,a5,49a8 <sbrkmuch+0x160>
  if(*lastaddr == 99){
    490a:	064007b7          	lui	a5,0x6400
    490e:	fff7c703          	lbu	a4,-1(a5) # 63fffff <__BSS_END__+0x63f143f>
    4912:	06300793          	li	a5,99
    4916:	0af70963          	beq	a4,a5,49c8 <sbrkmuch+0x180>
  a = sbrk(0);
    491a:	4501                	li	a0,0
    491c:	00001097          	auipc	ra,0x1
    4920:	f8c080e7          	jalr	-116(ra) # 58a8 <sbrk>
    4924:	84aa                	mv	s1,a0
  c = sbrk(-(sbrk(0) - oldbrk));
    4926:	4501                	li	a0,0
    4928:	00001097          	auipc	ra,0x1
    492c:	f80080e7          	jalr	-128(ra) # 58a8 <sbrk>
    4930:	40a9053b          	subw	a0,s2,a0
    4934:	00001097          	auipc	ra,0x1
    4938:	f74080e7          	jalr	-140(ra) # 58a8 <sbrk>
  if(c != a){
    493c:	0aa49463          	bne	s1,a0,49e4 <sbrkmuch+0x19c>
}
    4940:	70a2                	ld	ra,40(sp)
    4942:	7402                	ld	s0,32(sp)
    4944:	64e2                	ld	s1,24(sp)
    4946:	6942                	ld	s2,16(sp)
    4948:	69a2                	ld	s3,8(sp)
    494a:	6a02                	ld	s4,0(sp)
    494c:	6145                	addi	sp,sp,48
    494e:	8082                	ret
    printf("%s: sbrk test failed to grow big address space; enough phys mem?\n", s);
    4950:	85ce                	mv	a1,s3
    4952:	00003517          	auipc	a0,0x3
    4956:	35650513          	addi	a0,a0,854 # 7ca8 <malloc+0x1ff8>
    495a:	00001097          	auipc	ra,0x1
    495e:	298080e7          	jalr	664(ra) # 5bf2 <printf>
    exit(1);
    4962:	4505                	li	a0,1
    4964:	00001097          	auipc	ra,0x1
    4968:	ebc080e7          	jalr	-324(ra) # 5820 <exit>
    printf("%s: sbrk could not deallocate\n", s);
    496c:	85ce                	mv	a1,s3
    496e:	00003517          	auipc	a0,0x3
    4972:	38250513          	addi	a0,a0,898 # 7cf0 <malloc+0x2040>
    4976:	00001097          	auipc	ra,0x1
    497a:	27c080e7          	jalr	636(ra) # 5bf2 <printf>
    exit(1);
    497e:	4505                	li	a0,1
    4980:	00001097          	auipc	ra,0x1
    4984:	ea0080e7          	jalr	-352(ra) # 5820 <exit>
    printf("%s: sbrk deallocation produced wrong address, a %x c %x\n", s, a, c);
    4988:	86aa                	mv	a3,a0
    498a:	8626                	mv	a2,s1
    498c:	85ce                	mv	a1,s3
    498e:	00003517          	auipc	a0,0x3
    4992:	38250513          	addi	a0,a0,898 # 7d10 <malloc+0x2060>
    4996:	00001097          	auipc	ra,0x1
    499a:	25c080e7          	jalr	604(ra) # 5bf2 <printf>
    exit(1);
    499e:	4505                	li	a0,1
    49a0:	00001097          	auipc	ra,0x1
    49a4:	e80080e7          	jalr	-384(ra) # 5820 <exit>
    printf("%s: sbrk re-allocation failed, a %x c %x\n", s, a, c);
    49a8:	86d2                	mv	a3,s4
    49aa:	8626                	mv	a2,s1
    49ac:	85ce                	mv	a1,s3
    49ae:	00003517          	auipc	a0,0x3
    49b2:	3a250513          	addi	a0,a0,930 # 7d50 <malloc+0x20a0>
    49b6:	00001097          	auipc	ra,0x1
    49ba:	23c080e7          	jalr	572(ra) # 5bf2 <printf>
    exit(1);
    49be:	4505                	li	a0,1
    49c0:	00001097          	auipc	ra,0x1
    49c4:	e60080e7          	jalr	-416(ra) # 5820 <exit>
    printf("%s: sbrk de-allocation didn't really deallocate\n", s);
    49c8:	85ce                	mv	a1,s3
    49ca:	00003517          	auipc	a0,0x3
    49ce:	3b650513          	addi	a0,a0,950 # 7d80 <malloc+0x20d0>
    49d2:	00001097          	auipc	ra,0x1
    49d6:	220080e7          	jalr	544(ra) # 5bf2 <printf>
    exit(1);
    49da:	4505                	li	a0,1
    49dc:	00001097          	auipc	ra,0x1
    49e0:	e44080e7          	jalr	-444(ra) # 5820 <exit>
    printf("%s: sbrk downsize failed, a %x c %x\n", s, a, c);
    49e4:	86aa                	mv	a3,a0
    49e6:	8626                	mv	a2,s1
    49e8:	85ce                	mv	a1,s3
    49ea:	00003517          	auipc	a0,0x3
    49ee:	3ce50513          	addi	a0,a0,974 # 7db8 <malloc+0x2108>
    49f2:	00001097          	auipc	ra,0x1
    49f6:	200080e7          	jalr	512(ra) # 5bf2 <printf>
    exit(1);
    49fa:	4505                	li	a0,1
    49fc:	00001097          	auipc	ra,0x1
    4a00:	e24080e7          	jalr	-476(ra) # 5820 <exit>

0000000000004a04 <kernmem>:
{
    4a04:	715d                	addi	sp,sp,-80
    4a06:	e486                	sd	ra,72(sp)
    4a08:	e0a2                	sd	s0,64(sp)
    4a0a:	fc26                	sd	s1,56(sp)
    4a0c:	f84a                	sd	s2,48(sp)
    4a0e:	f44e                	sd	s3,40(sp)
    4a10:	f052                	sd	s4,32(sp)
    4a12:	ec56                	sd	s5,24(sp)
    4a14:	0880                	addi	s0,sp,80
    4a16:	8a2a                	mv	s4,a0
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    4a18:	4485                	li	s1,1
    4a1a:	04fe                	slli	s1,s1,0x1f
    if(xstatus != -1)  // did kernel kill child?
    4a1c:	5afd                	li	s5,-1
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    4a1e:	69b1                	lui	s3,0xc
    4a20:	35098993          	addi	s3,s3,848 # c350 <buf+0x7a0>
    4a24:	1003d937          	lui	s2,0x1003d
    4a28:	090e                	slli	s2,s2,0x3
    4a2a:	48090913          	addi	s2,s2,1152 # 1003d480 <__BSS_END__+0x1002e8c0>
    pid = fork();
    4a2e:	00001097          	auipc	ra,0x1
    4a32:	dea080e7          	jalr	-534(ra) # 5818 <fork>
    if(pid < 0){
    4a36:	02054963          	bltz	a0,4a68 <kernmem+0x64>
    if(pid == 0){
    4a3a:	c529                	beqz	a0,4a84 <kernmem+0x80>
    wait(&xstatus);
    4a3c:	fbc40513          	addi	a0,s0,-68
    4a40:	00001097          	auipc	ra,0x1
    4a44:	de8080e7          	jalr	-536(ra) # 5828 <wait>
    if(xstatus != -1)  // did kernel kill child?
    4a48:	fbc42783          	lw	a5,-68(s0)
    4a4c:	05579d63          	bne	a5,s5,4aa6 <kernmem+0xa2>
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    4a50:	94ce                	add	s1,s1,s3
    4a52:	fd249ee3          	bne	s1,s2,4a2e <kernmem+0x2a>
}
    4a56:	60a6                	ld	ra,72(sp)
    4a58:	6406                	ld	s0,64(sp)
    4a5a:	74e2                	ld	s1,56(sp)
    4a5c:	7942                	ld	s2,48(sp)
    4a5e:	79a2                	ld	s3,40(sp)
    4a60:	7a02                	ld	s4,32(sp)
    4a62:	6ae2                	ld	s5,24(sp)
    4a64:	6161                	addi	sp,sp,80
    4a66:	8082                	ret
      printf("%s: fork failed\n", s);
    4a68:	85d2                	mv	a1,s4
    4a6a:	00001517          	auipc	a0,0x1
    4a6e:	5be50513          	addi	a0,a0,1470 # 6028 <malloc+0x378>
    4a72:	00001097          	auipc	ra,0x1
    4a76:	180080e7          	jalr	384(ra) # 5bf2 <printf>
      exit(1);
    4a7a:	4505                	li	a0,1
    4a7c:	00001097          	auipc	ra,0x1
    4a80:	da4080e7          	jalr	-604(ra) # 5820 <exit>
      printf("%s: oops could read %x = %x\n", s, a, *a);
    4a84:	0004c683          	lbu	a3,0(s1)
    4a88:	8626                	mv	a2,s1
    4a8a:	85d2                	mv	a1,s4
    4a8c:	00003517          	auipc	a0,0x3
    4a90:	35450513          	addi	a0,a0,852 # 7de0 <malloc+0x2130>
    4a94:	00001097          	auipc	ra,0x1
    4a98:	15e080e7          	jalr	350(ra) # 5bf2 <printf>
      exit(1);
    4a9c:	4505                	li	a0,1
    4a9e:	00001097          	auipc	ra,0x1
    4aa2:	d82080e7          	jalr	-638(ra) # 5820 <exit>
      exit(1);
    4aa6:	4505                	li	a0,1
    4aa8:	00001097          	auipc	ra,0x1
    4aac:	d78080e7          	jalr	-648(ra) # 5820 <exit>

0000000000004ab0 <sbrkfail>:
{
    4ab0:	7119                	addi	sp,sp,-128
    4ab2:	fc86                	sd	ra,120(sp)
    4ab4:	f8a2                	sd	s0,112(sp)
    4ab6:	f4a6                	sd	s1,104(sp)
    4ab8:	f0ca                	sd	s2,96(sp)
    4aba:	ecce                	sd	s3,88(sp)
    4abc:	e8d2                	sd	s4,80(sp)
    4abe:	e4d6                	sd	s5,72(sp)
    4ac0:	0100                	addi	s0,sp,128
    4ac2:	8aaa                	mv	s5,a0
  if(pipe(fds) != 0){
    4ac4:	fb040513          	addi	a0,s0,-80
    4ac8:	00001097          	auipc	ra,0x1
    4acc:	d68080e7          	jalr	-664(ra) # 5830 <pipe>
    4ad0:	e901                	bnez	a0,4ae0 <sbrkfail+0x30>
    4ad2:	f8040493          	addi	s1,s0,-128
    4ad6:	fa840993          	addi	s3,s0,-88
    4ada:	8926                	mv	s2,s1
    if(pids[i] != -1)
    4adc:	5a7d                	li	s4,-1
    4ade:	a085                	j	4b3e <sbrkfail+0x8e>
    printf("%s: pipe() failed\n", s);
    4ae0:	85d6                	mv	a1,s5
    4ae2:	00002517          	auipc	a0,0x2
    4ae6:	97650513          	addi	a0,a0,-1674 # 6458 <malloc+0x7a8>
    4aea:	00001097          	auipc	ra,0x1
    4aee:	108080e7          	jalr	264(ra) # 5bf2 <printf>
    exit(1);
    4af2:	4505                	li	a0,1
    4af4:	00001097          	auipc	ra,0x1
    4af8:	d2c080e7          	jalr	-724(ra) # 5820 <exit>
      sbrk(BIG - (uint64)sbrk(0));
    4afc:	00001097          	auipc	ra,0x1
    4b00:	dac080e7          	jalr	-596(ra) # 58a8 <sbrk>
    4b04:	064007b7          	lui	a5,0x6400
    4b08:	40a7853b          	subw	a0,a5,a0
    4b0c:	00001097          	auipc	ra,0x1
    4b10:	d9c080e7          	jalr	-612(ra) # 58a8 <sbrk>
      write(fds[1], "x", 1);
    4b14:	4605                	li	a2,1
    4b16:	00001597          	auipc	a1,0x1
    4b1a:	6ca58593          	addi	a1,a1,1738 # 61e0 <malloc+0x530>
    4b1e:	fb442503          	lw	a0,-76(s0)
    4b22:	00001097          	auipc	ra,0x1
    4b26:	d1e080e7          	jalr	-738(ra) # 5840 <write>
      for(;;) sleep(1000);
    4b2a:	3e800513          	li	a0,1000
    4b2e:	00001097          	auipc	ra,0x1
    4b32:	d82080e7          	jalr	-638(ra) # 58b0 <sleep>
    4b36:	bfd5                	j	4b2a <sbrkfail+0x7a>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    4b38:	0911                	addi	s2,s2,4
    4b3a:	03390563          	beq	s2,s3,4b64 <sbrkfail+0xb4>
    if((pids[i] = fork()) == 0){
    4b3e:	00001097          	auipc	ra,0x1
    4b42:	cda080e7          	jalr	-806(ra) # 5818 <fork>
    4b46:	00a92023          	sw	a0,0(s2)
    4b4a:	d94d                	beqz	a0,4afc <sbrkfail+0x4c>
    if(pids[i] != -1)
    4b4c:	ff4506e3          	beq	a0,s4,4b38 <sbrkfail+0x88>
      read(fds[0], &scratch, 1);
    4b50:	4605                	li	a2,1
    4b52:	faf40593          	addi	a1,s0,-81
    4b56:	fb042503          	lw	a0,-80(s0)
    4b5a:	00001097          	auipc	ra,0x1
    4b5e:	cde080e7          	jalr	-802(ra) # 5838 <read>
    4b62:	bfd9                	j	4b38 <sbrkfail+0x88>
  c = sbrk(PGSIZE);
    4b64:	6505                	lui	a0,0x1
    4b66:	00001097          	auipc	ra,0x1
    4b6a:	d42080e7          	jalr	-702(ra) # 58a8 <sbrk>
    4b6e:	8a2a                	mv	s4,a0
    if(pids[i] == -1)
    4b70:	597d                	li	s2,-1
    4b72:	a021                	j	4b7a <sbrkfail+0xca>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    4b74:	0491                	addi	s1,s1,4
    4b76:	03348063          	beq	s1,s3,4b96 <sbrkfail+0xe6>
    if(pids[i] == -1)
    4b7a:	4088                	lw	a0,0(s1)
    4b7c:	ff250ce3          	beq	a0,s2,4b74 <sbrkfail+0xc4>
    kill(pids[i], SIGKILL);
    4b80:	45a5                	li	a1,9
    4b82:	00001097          	auipc	ra,0x1
    4b86:	cce080e7          	jalr	-818(ra) # 5850 <kill>
    wait(0);
    4b8a:	4501                	li	a0,0
    4b8c:	00001097          	auipc	ra,0x1
    4b90:	c9c080e7          	jalr	-868(ra) # 5828 <wait>
    4b94:	b7c5                	j	4b74 <sbrkfail+0xc4>
  if(c == (char*)0xffffffffffffffffL){
    4b96:	57fd                	li	a5,-1
    4b98:	04fa0163          	beq	s4,a5,4bda <sbrkfail+0x12a>
  pid = fork();
    4b9c:	00001097          	auipc	ra,0x1
    4ba0:	c7c080e7          	jalr	-900(ra) # 5818 <fork>
    4ba4:	84aa                	mv	s1,a0
  if(pid < 0){
    4ba6:	04054863          	bltz	a0,4bf6 <sbrkfail+0x146>
  if(pid == 0){
    4baa:	c525                	beqz	a0,4c12 <sbrkfail+0x162>
  wait(&xstatus);
    4bac:	fbc40513          	addi	a0,s0,-68
    4bb0:	00001097          	auipc	ra,0x1
    4bb4:	c78080e7          	jalr	-904(ra) # 5828 <wait>
  if(xstatus != -1 && xstatus != 2)
    4bb8:	fbc42783          	lw	a5,-68(s0)
    4bbc:	577d                	li	a4,-1
    4bbe:	00e78563          	beq	a5,a4,4bc8 <sbrkfail+0x118>
    4bc2:	4709                	li	a4,2
    4bc4:	08e79d63          	bne	a5,a4,4c5e <sbrkfail+0x1ae>
}
    4bc8:	70e6                	ld	ra,120(sp)
    4bca:	7446                	ld	s0,112(sp)
    4bcc:	74a6                	ld	s1,104(sp)
    4bce:	7906                	ld	s2,96(sp)
    4bd0:	69e6                	ld	s3,88(sp)
    4bd2:	6a46                	ld	s4,80(sp)
    4bd4:	6aa6                	ld	s5,72(sp)
    4bd6:	6109                	addi	sp,sp,128
    4bd8:	8082                	ret
    printf("%s: failed sbrk leaked memory\n", s);
    4bda:	85d6                	mv	a1,s5
    4bdc:	00003517          	auipc	a0,0x3
    4be0:	22450513          	addi	a0,a0,548 # 7e00 <malloc+0x2150>
    4be4:	00001097          	auipc	ra,0x1
    4be8:	00e080e7          	jalr	14(ra) # 5bf2 <printf>
    exit(1);
    4bec:	4505                	li	a0,1
    4bee:	00001097          	auipc	ra,0x1
    4bf2:	c32080e7          	jalr	-974(ra) # 5820 <exit>
    printf("%s: fork failed\n", s);
    4bf6:	85d6                	mv	a1,s5
    4bf8:	00001517          	auipc	a0,0x1
    4bfc:	43050513          	addi	a0,a0,1072 # 6028 <malloc+0x378>
    4c00:	00001097          	auipc	ra,0x1
    4c04:	ff2080e7          	jalr	-14(ra) # 5bf2 <printf>
    exit(1);
    4c08:	4505                	li	a0,1
    4c0a:	00001097          	auipc	ra,0x1
    4c0e:	c16080e7          	jalr	-1002(ra) # 5820 <exit>
    a = sbrk(0);
    4c12:	4501                	li	a0,0
    4c14:	00001097          	auipc	ra,0x1
    4c18:	c94080e7          	jalr	-876(ra) # 58a8 <sbrk>
    4c1c:	892a                	mv	s2,a0
    sbrk(10*BIG);
    4c1e:	3e800537          	lui	a0,0x3e800
    4c22:	00001097          	auipc	ra,0x1
    4c26:	c86080e7          	jalr	-890(ra) # 58a8 <sbrk>
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    4c2a:	87ca                	mv	a5,s2
    4c2c:	3e800737          	lui	a4,0x3e800
    4c30:	993a                	add	s2,s2,a4
    4c32:	6705                	lui	a4,0x1
      n += *(a+i);
    4c34:	0007c683          	lbu	a3,0(a5) # 6400000 <__BSS_END__+0x63f1440>
    4c38:	9cb5                	addw	s1,s1,a3
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    4c3a:	97ba                	add	a5,a5,a4
    4c3c:	ff279ce3          	bne	a5,s2,4c34 <sbrkfail+0x184>
    printf("%s: allocate a lot of memory succeeded %d\n", s, n);
    4c40:	8626                	mv	a2,s1
    4c42:	85d6                	mv	a1,s5
    4c44:	00003517          	auipc	a0,0x3
    4c48:	1dc50513          	addi	a0,a0,476 # 7e20 <malloc+0x2170>
    4c4c:	00001097          	auipc	ra,0x1
    4c50:	fa6080e7          	jalr	-90(ra) # 5bf2 <printf>
    exit(1);
    4c54:	4505                	li	a0,1
    4c56:	00001097          	auipc	ra,0x1
    4c5a:	bca080e7          	jalr	-1078(ra) # 5820 <exit>
    exit(1);
    4c5e:	4505                	li	a0,1
    4c60:	00001097          	auipc	ra,0x1
    4c64:	bc0080e7          	jalr	-1088(ra) # 5820 <exit>

0000000000004c68 <fsfull>:
{
    4c68:	7171                	addi	sp,sp,-176
    4c6a:	f506                	sd	ra,168(sp)
    4c6c:	f122                	sd	s0,160(sp)
    4c6e:	ed26                	sd	s1,152(sp)
    4c70:	e94a                	sd	s2,144(sp)
    4c72:	e54e                	sd	s3,136(sp)
    4c74:	e152                	sd	s4,128(sp)
    4c76:	fcd6                	sd	s5,120(sp)
    4c78:	f8da                	sd	s6,112(sp)
    4c7a:	f4de                	sd	s7,104(sp)
    4c7c:	f0e2                	sd	s8,96(sp)
    4c7e:	ece6                	sd	s9,88(sp)
    4c80:	e8ea                	sd	s10,80(sp)
    4c82:	e4ee                	sd	s11,72(sp)
    4c84:	1900                	addi	s0,sp,176
  printf("fsfull test\n");
    4c86:	00003517          	auipc	a0,0x3
    4c8a:	1ca50513          	addi	a0,a0,458 # 7e50 <malloc+0x21a0>
    4c8e:	00001097          	auipc	ra,0x1
    4c92:	f64080e7          	jalr	-156(ra) # 5bf2 <printf>
  for(nfiles = 0; ; nfiles++){
    4c96:	4481                	li	s1,0
    name[0] = 'f';
    4c98:	06600d13          	li	s10,102
    name[1] = '0' + nfiles / 1000;
    4c9c:	3e800c13          	li	s8,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    4ca0:	06400b93          	li	s7,100
    name[3] = '0' + (nfiles % 100) / 10;
    4ca4:	4b29                	li	s6,10
    printf("writing %s\n", name);
    4ca6:	00003c97          	auipc	s9,0x3
    4caa:	1bac8c93          	addi	s9,s9,442 # 7e60 <malloc+0x21b0>
    int total = 0;
    4cae:	4d81                	li	s11,0
      int cc = write(fd, buf, BSIZE);
    4cb0:	00007a17          	auipc	s4,0x7
    4cb4:	f00a0a13          	addi	s4,s4,-256 # bbb0 <buf>
    name[0] = 'f';
    4cb8:	f5a40823          	sb	s10,-176(s0)
    name[1] = '0' + nfiles / 1000;
    4cbc:	0384c7bb          	divw	a5,s1,s8
    4cc0:	0307879b          	addiw	a5,a5,48
    4cc4:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    4cc8:	0384e7bb          	remw	a5,s1,s8
    4ccc:	0377c7bb          	divw	a5,a5,s7
    4cd0:	0307879b          	addiw	a5,a5,48
    4cd4:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    4cd8:	0374e7bb          	remw	a5,s1,s7
    4cdc:	0367c7bb          	divw	a5,a5,s6
    4ce0:	0307879b          	addiw	a5,a5,48
    4ce4:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    4ce8:	0364e7bb          	remw	a5,s1,s6
    4cec:	0307879b          	addiw	a5,a5,48
    4cf0:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    4cf4:	f4040aa3          	sb	zero,-171(s0)
    printf("writing %s\n", name);
    4cf8:	f5040593          	addi	a1,s0,-176
    4cfc:	8566                	mv	a0,s9
    4cfe:	00001097          	auipc	ra,0x1
    4d02:	ef4080e7          	jalr	-268(ra) # 5bf2 <printf>
    int fd = open(name, O_CREATE|O_RDWR);
    4d06:	20200593          	li	a1,514
    4d0a:	f5040513          	addi	a0,s0,-176
    4d0e:	00001097          	auipc	ra,0x1
    4d12:	b52080e7          	jalr	-1198(ra) # 5860 <open>
    4d16:	892a                	mv	s2,a0
    if(fd < 0){
    4d18:	0a055663          	bgez	a0,4dc4 <fsfull+0x15c>
      printf("open %s failed\n", name);
    4d1c:	f5040593          	addi	a1,s0,-176
    4d20:	00003517          	auipc	a0,0x3
    4d24:	15050513          	addi	a0,a0,336 # 7e70 <malloc+0x21c0>
    4d28:	00001097          	auipc	ra,0x1
    4d2c:	eca080e7          	jalr	-310(ra) # 5bf2 <printf>
  while(nfiles >= 0){
    4d30:	0604c363          	bltz	s1,4d96 <fsfull+0x12e>
    name[0] = 'f';
    4d34:	06600b13          	li	s6,102
    name[1] = '0' + nfiles / 1000;
    4d38:	3e800a13          	li	s4,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    4d3c:	06400993          	li	s3,100
    name[3] = '0' + (nfiles % 100) / 10;
    4d40:	4929                	li	s2,10
  while(nfiles >= 0){
    4d42:	5afd                	li	s5,-1
    name[0] = 'f';
    4d44:	f5640823          	sb	s6,-176(s0)
    name[1] = '0' + nfiles / 1000;
    4d48:	0344c7bb          	divw	a5,s1,s4
    4d4c:	0307879b          	addiw	a5,a5,48
    4d50:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    4d54:	0344e7bb          	remw	a5,s1,s4
    4d58:	0337c7bb          	divw	a5,a5,s3
    4d5c:	0307879b          	addiw	a5,a5,48
    4d60:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    4d64:	0334e7bb          	remw	a5,s1,s3
    4d68:	0327c7bb          	divw	a5,a5,s2
    4d6c:	0307879b          	addiw	a5,a5,48
    4d70:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    4d74:	0324e7bb          	remw	a5,s1,s2
    4d78:	0307879b          	addiw	a5,a5,48
    4d7c:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    4d80:	f4040aa3          	sb	zero,-171(s0)
    unlink(name);
    4d84:	f5040513          	addi	a0,s0,-176
    4d88:	00001097          	auipc	ra,0x1
    4d8c:	ae8080e7          	jalr	-1304(ra) # 5870 <unlink>
    nfiles--;
    4d90:	34fd                	addiw	s1,s1,-1
  while(nfiles >= 0){
    4d92:	fb5499e3          	bne	s1,s5,4d44 <fsfull+0xdc>
  printf("fsfull test finished\n");
    4d96:	00003517          	auipc	a0,0x3
    4d9a:	0fa50513          	addi	a0,a0,250 # 7e90 <malloc+0x21e0>
    4d9e:	00001097          	auipc	ra,0x1
    4da2:	e54080e7          	jalr	-428(ra) # 5bf2 <printf>
}
    4da6:	70aa                	ld	ra,168(sp)
    4da8:	740a                	ld	s0,160(sp)
    4daa:	64ea                	ld	s1,152(sp)
    4dac:	694a                	ld	s2,144(sp)
    4dae:	69aa                	ld	s3,136(sp)
    4db0:	6a0a                	ld	s4,128(sp)
    4db2:	7ae6                	ld	s5,120(sp)
    4db4:	7b46                	ld	s6,112(sp)
    4db6:	7ba6                	ld	s7,104(sp)
    4db8:	7c06                	ld	s8,96(sp)
    4dba:	6ce6                	ld	s9,88(sp)
    4dbc:	6d46                	ld	s10,80(sp)
    4dbe:	6da6                	ld	s11,72(sp)
    4dc0:	614d                	addi	sp,sp,176
    4dc2:	8082                	ret
    int total = 0;
    4dc4:	89ee                	mv	s3,s11
      if(cc < BSIZE)
    4dc6:	3ff00a93          	li	s5,1023
      int cc = write(fd, buf, BSIZE);
    4dca:	40000613          	li	a2,1024
    4dce:	85d2                	mv	a1,s4
    4dd0:	854a                	mv	a0,s2
    4dd2:	00001097          	auipc	ra,0x1
    4dd6:	a6e080e7          	jalr	-1426(ra) # 5840 <write>
      if(cc < BSIZE)
    4dda:	00aad563          	bge	s5,a0,4de4 <fsfull+0x17c>
      total += cc;
    4dde:	00a989bb          	addw	s3,s3,a0
    while(1){
    4de2:	b7e5                	j	4dca <fsfull+0x162>
    printf("wrote %d bytes\n", total);
    4de4:	85ce                	mv	a1,s3
    4de6:	00003517          	auipc	a0,0x3
    4dea:	09a50513          	addi	a0,a0,154 # 7e80 <malloc+0x21d0>
    4dee:	00001097          	auipc	ra,0x1
    4df2:	e04080e7          	jalr	-508(ra) # 5bf2 <printf>
    close(fd);
    4df6:	854a                	mv	a0,s2
    4df8:	00001097          	auipc	ra,0x1
    4dfc:	a50080e7          	jalr	-1456(ra) # 5848 <close>
    if(total == 0)
    4e00:	f20988e3          	beqz	s3,4d30 <fsfull+0xc8>
  for(nfiles = 0; ; nfiles++){
    4e04:	2485                	addiw	s1,s1,1
    4e06:	bd4d                	j	4cb8 <fsfull+0x50>

0000000000004e08 <rand>:
{
    4e08:	1141                	addi	sp,sp,-16
    4e0a:	e422                	sd	s0,8(sp)
    4e0c:	0800                	addi	s0,sp,16
  randstate = randstate * 1664525 + 1013904223;
    4e0e:	00003717          	auipc	a4,0x3
    4e12:	57270713          	addi	a4,a4,1394 # 8380 <randstate>
    4e16:	6308                	ld	a0,0(a4)
    4e18:	001967b7          	lui	a5,0x196
    4e1c:	60d78793          	addi	a5,a5,1549 # 19660d <__BSS_END__+0x187a4d>
    4e20:	02f50533          	mul	a0,a0,a5
    4e24:	3c6ef7b7          	lui	a5,0x3c6ef
    4e28:	35f78793          	addi	a5,a5,863 # 3c6ef35f <__BSS_END__+0x3c6e079f>
    4e2c:	953e                	add	a0,a0,a5
    4e2e:	e308                	sd	a0,0(a4)
}
    4e30:	2501                	sext.w	a0,a0
    4e32:	6422                	ld	s0,8(sp)
    4e34:	0141                	addi	sp,sp,16
    4e36:	8082                	ret

0000000000004e38 <stacktest>:
{
    4e38:	7179                	addi	sp,sp,-48
    4e3a:	f406                	sd	ra,40(sp)
    4e3c:	f022                	sd	s0,32(sp)
    4e3e:	ec26                	sd	s1,24(sp)
    4e40:	1800                	addi	s0,sp,48
    4e42:	84aa                	mv	s1,a0
  pid = fork();
    4e44:	00001097          	auipc	ra,0x1
    4e48:	9d4080e7          	jalr	-1580(ra) # 5818 <fork>
  if(pid == 0) {
    4e4c:	c115                	beqz	a0,4e70 <stacktest+0x38>
  } else if(pid < 0){
    4e4e:	04054463          	bltz	a0,4e96 <stacktest+0x5e>
  wait(&xstatus);
    4e52:	fdc40513          	addi	a0,s0,-36
    4e56:	00001097          	auipc	ra,0x1
    4e5a:	9d2080e7          	jalr	-1582(ra) # 5828 <wait>
  if(xstatus == -1)  // kernel killed child?
    4e5e:	fdc42503          	lw	a0,-36(s0)
    4e62:	57fd                	li	a5,-1
    4e64:	04f50763          	beq	a0,a5,4eb2 <stacktest+0x7a>
    exit(xstatus);
    4e68:	00001097          	auipc	ra,0x1
    4e6c:	9b8080e7          	jalr	-1608(ra) # 5820 <exit>

static inline uint64
r_sp()
{
  uint64 x;
  asm volatile("mv %0, sp" : "=r" (x) );
    4e70:	870a                	mv	a4,sp
    printf("%s: stacktest: read below stack %p\n", s, *sp);
    4e72:	77fd                	lui	a5,0xfffff
    4e74:	97ba                	add	a5,a5,a4
    4e76:	0007c603          	lbu	a2,0(a5) # fffffffffffff000 <__BSS_END__+0xffffffffffff0440>
    4e7a:	85a6                	mv	a1,s1
    4e7c:	00003517          	auipc	a0,0x3
    4e80:	02c50513          	addi	a0,a0,44 # 7ea8 <malloc+0x21f8>
    4e84:	00001097          	auipc	ra,0x1
    4e88:	d6e080e7          	jalr	-658(ra) # 5bf2 <printf>
    exit(1);
    4e8c:	4505                	li	a0,1
    4e8e:	00001097          	auipc	ra,0x1
    4e92:	992080e7          	jalr	-1646(ra) # 5820 <exit>
    printf("%s: fork failed\n", s);
    4e96:	85a6                	mv	a1,s1
    4e98:	00001517          	auipc	a0,0x1
    4e9c:	19050513          	addi	a0,a0,400 # 6028 <malloc+0x378>
    4ea0:	00001097          	auipc	ra,0x1
    4ea4:	d52080e7          	jalr	-686(ra) # 5bf2 <printf>
    exit(1);
    4ea8:	4505                	li	a0,1
    4eaa:	00001097          	auipc	ra,0x1
    4eae:	976080e7          	jalr	-1674(ra) # 5820 <exit>
    exit(0);
    4eb2:	4501                	li	a0,0
    4eb4:	00001097          	auipc	ra,0x1
    4eb8:	96c080e7          	jalr	-1684(ra) # 5820 <exit>

0000000000004ebc <sbrkbugs>:
{
    4ebc:	1141                	addi	sp,sp,-16
    4ebe:	e406                	sd	ra,8(sp)
    4ec0:	e022                	sd	s0,0(sp)
    4ec2:	0800                	addi	s0,sp,16
  int pid = fork();
    4ec4:	00001097          	auipc	ra,0x1
    4ec8:	954080e7          	jalr	-1708(ra) # 5818 <fork>
  if(pid < 0){
    4ecc:	02054263          	bltz	a0,4ef0 <sbrkbugs+0x34>
  if(pid == 0){
    4ed0:	ed0d                	bnez	a0,4f0a <sbrkbugs+0x4e>
    int sz = (uint64) sbrk(0);
    4ed2:	00001097          	auipc	ra,0x1
    4ed6:	9d6080e7          	jalr	-1578(ra) # 58a8 <sbrk>
    sbrk(-sz);
    4eda:	40a0053b          	negw	a0,a0
    4ede:	00001097          	auipc	ra,0x1
    4ee2:	9ca080e7          	jalr	-1590(ra) # 58a8 <sbrk>
    exit(0);
    4ee6:	4501                	li	a0,0
    4ee8:	00001097          	auipc	ra,0x1
    4eec:	938080e7          	jalr	-1736(ra) # 5820 <exit>
    printf("fork failed\n");
    4ef0:	00002517          	auipc	a0,0x2
    4ef4:	b0050513          	addi	a0,a0,-1280 # 69f0 <malloc+0xd40>
    4ef8:	00001097          	auipc	ra,0x1
    4efc:	cfa080e7          	jalr	-774(ra) # 5bf2 <printf>
    exit(1);
    4f00:	4505                	li	a0,1
    4f02:	00001097          	auipc	ra,0x1
    4f06:	91e080e7          	jalr	-1762(ra) # 5820 <exit>
  wait(0);
    4f0a:	4501                	li	a0,0
    4f0c:	00001097          	auipc	ra,0x1
    4f10:	91c080e7          	jalr	-1764(ra) # 5828 <wait>
  pid = fork();
    4f14:	00001097          	auipc	ra,0x1
    4f18:	904080e7          	jalr	-1788(ra) # 5818 <fork>
  if(pid < 0){
    4f1c:	02054563          	bltz	a0,4f46 <sbrkbugs+0x8a>
  if(pid == 0){
    4f20:	e121                	bnez	a0,4f60 <sbrkbugs+0xa4>
    int sz = (uint64) sbrk(0);
    4f22:	00001097          	auipc	ra,0x1
    4f26:	986080e7          	jalr	-1658(ra) # 58a8 <sbrk>
    sbrk(-(sz - 3500));
    4f2a:	6785                	lui	a5,0x1
    4f2c:	dac7879b          	addiw	a5,a5,-596
    4f30:	40a7853b          	subw	a0,a5,a0
    4f34:	00001097          	auipc	ra,0x1
    4f38:	974080e7          	jalr	-1676(ra) # 58a8 <sbrk>
    exit(0);
    4f3c:	4501                	li	a0,0
    4f3e:	00001097          	auipc	ra,0x1
    4f42:	8e2080e7          	jalr	-1822(ra) # 5820 <exit>
    printf("fork failed\n");
    4f46:	00002517          	auipc	a0,0x2
    4f4a:	aaa50513          	addi	a0,a0,-1366 # 69f0 <malloc+0xd40>
    4f4e:	00001097          	auipc	ra,0x1
    4f52:	ca4080e7          	jalr	-860(ra) # 5bf2 <printf>
    exit(1);
    4f56:	4505                	li	a0,1
    4f58:	00001097          	auipc	ra,0x1
    4f5c:	8c8080e7          	jalr	-1848(ra) # 5820 <exit>
  wait(0);
    4f60:	4501                	li	a0,0
    4f62:	00001097          	auipc	ra,0x1
    4f66:	8c6080e7          	jalr	-1850(ra) # 5828 <wait>
  pid = fork();
    4f6a:	00001097          	auipc	ra,0x1
    4f6e:	8ae080e7          	jalr	-1874(ra) # 5818 <fork>
  if(pid < 0){
    4f72:	02054a63          	bltz	a0,4fa6 <sbrkbugs+0xea>
  if(pid == 0){
    4f76:	e529                	bnez	a0,4fc0 <sbrkbugs+0x104>
    sbrk((10*4096 + 2048) - (uint64)sbrk(0));
    4f78:	00001097          	auipc	ra,0x1
    4f7c:	930080e7          	jalr	-1744(ra) # 58a8 <sbrk>
    4f80:	67ad                	lui	a5,0xb
    4f82:	8007879b          	addiw	a5,a5,-2048
    4f86:	40a7853b          	subw	a0,a5,a0
    4f8a:	00001097          	auipc	ra,0x1
    4f8e:	91e080e7          	jalr	-1762(ra) # 58a8 <sbrk>
    sbrk(-10);
    4f92:	5559                	li	a0,-10
    4f94:	00001097          	auipc	ra,0x1
    4f98:	914080e7          	jalr	-1772(ra) # 58a8 <sbrk>
    exit(0);
    4f9c:	4501                	li	a0,0
    4f9e:	00001097          	auipc	ra,0x1
    4fa2:	882080e7          	jalr	-1918(ra) # 5820 <exit>
    printf("fork failed\n");
    4fa6:	00002517          	auipc	a0,0x2
    4faa:	a4a50513          	addi	a0,a0,-1462 # 69f0 <malloc+0xd40>
    4fae:	00001097          	auipc	ra,0x1
    4fb2:	c44080e7          	jalr	-956(ra) # 5bf2 <printf>
    exit(1);
    4fb6:	4505                	li	a0,1
    4fb8:	00001097          	auipc	ra,0x1
    4fbc:	868080e7          	jalr	-1944(ra) # 5820 <exit>
  wait(0);
    4fc0:	4501                	li	a0,0
    4fc2:	00001097          	auipc	ra,0x1
    4fc6:	866080e7          	jalr	-1946(ra) # 5828 <wait>
  exit(0);
    4fca:	4501                	li	a0,0
    4fcc:	00001097          	auipc	ra,0x1
    4fd0:	854080e7          	jalr	-1964(ra) # 5820 <exit>

0000000000004fd4 <badwrite>:
{
    4fd4:	7179                	addi	sp,sp,-48
    4fd6:	f406                	sd	ra,40(sp)
    4fd8:	f022                	sd	s0,32(sp)
    4fda:	ec26                	sd	s1,24(sp)
    4fdc:	e84a                	sd	s2,16(sp)
    4fde:	e44e                	sd	s3,8(sp)
    4fe0:	e052                	sd	s4,0(sp)
    4fe2:	1800                	addi	s0,sp,48
  unlink("junk");
    4fe4:	00003517          	auipc	a0,0x3
    4fe8:	eec50513          	addi	a0,a0,-276 # 7ed0 <malloc+0x2220>
    4fec:	00001097          	auipc	ra,0x1
    4ff0:	884080e7          	jalr	-1916(ra) # 5870 <unlink>
    4ff4:	25800913          	li	s2,600
    int fd = open("junk", O_CREATE|O_WRONLY);
    4ff8:	00003997          	auipc	s3,0x3
    4ffc:	ed898993          	addi	s3,s3,-296 # 7ed0 <malloc+0x2220>
    write(fd, (char*)0xffffffffffL, 1);
    5000:	5a7d                	li	s4,-1
    5002:	018a5a13          	srli	s4,s4,0x18
    int fd = open("junk", O_CREATE|O_WRONLY);
    5006:	20100593          	li	a1,513
    500a:	854e                	mv	a0,s3
    500c:	00001097          	auipc	ra,0x1
    5010:	854080e7          	jalr	-1964(ra) # 5860 <open>
    5014:	84aa                	mv	s1,a0
    if(fd < 0){
    5016:	06054b63          	bltz	a0,508c <badwrite+0xb8>
    write(fd, (char*)0xffffffffffL, 1);
    501a:	4605                	li	a2,1
    501c:	85d2                	mv	a1,s4
    501e:	00001097          	auipc	ra,0x1
    5022:	822080e7          	jalr	-2014(ra) # 5840 <write>
    close(fd);
    5026:	8526                	mv	a0,s1
    5028:	00001097          	auipc	ra,0x1
    502c:	820080e7          	jalr	-2016(ra) # 5848 <close>
    unlink("junk");
    5030:	854e                	mv	a0,s3
    5032:	00001097          	auipc	ra,0x1
    5036:	83e080e7          	jalr	-1986(ra) # 5870 <unlink>
  for(int i = 0; i < assumed_free; i++){
    503a:	397d                	addiw	s2,s2,-1
    503c:	fc0915e3          	bnez	s2,5006 <badwrite+0x32>
  int fd = open("junk", O_CREATE|O_WRONLY);
    5040:	20100593          	li	a1,513
    5044:	00003517          	auipc	a0,0x3
    5048:	e8c50513          	addi	a0,a0,-372 # 7ed0 <malloc+0x2220>
    504c:	00001097          	auipc	ra,0x1
    5050:	814080e7          	jalr	-2028(ra) # 5860 <open>
    5054:	84aa                	mv	s1,a0
  if(fd < 0){
    5056:	04054863          	bltz	a0,50a6 <badwrite+0xd2>
  if(write(fd, "x", 1) != 1){
    505a:	4605                	li	a2,1
    505c:	00001597          	auipc	a1,0x1
    5060:	18458593          	addi	a1,a1,388 # 61e0 <malloc+0x530>
    5064:	00000097          	auipc	ra,0x0
    5068:	7dc080e7          	jalr	2012(ra) # 5840 <write>
    506c:	4785                	li	a5,1
    506e:	04f50963          	beq	a0,a5,50c0 <badwrite+0xec>
    printf("write failed\n");
    5072:	00003517          	auipc	a0,0x3
    5076:	e7e50513          	addi	a0,a0,-386 # 7ef0 <malloc+0x2240>
    507a:	00001097          	auipc	ra,0x1
    507e:	b78080e7          	jalr	-1160(ra) # 5bf2 <printf>
    exit(1);
    5082:	4505                	li	a0,1
    5084:	00000097          	auipc	ra,0x0
    5088:	79c080e7          	jalr	1948(ra) # 5820 <exit>
      printf("open junk failed\n");
    508c:	00003517          	auipc	a0,0x3
    5090:	e4c50513          	addi	a0,a0,-436 # 7ed8 <malloc+0x2228>
    5094:	00001097          	auipc	ra,0x1
    5098:	b5e080e7          	jalr	-1186(ra) # 5bf2 <printf>
      exit(1);
    509c:	4505                	li	a0,1
    509e:	00000097          	auipc	ra,0x0
    50a2:	782080e7          	jalr	1922(ra) # 5820 <exit>
    printf("open junk failed\n");
    50a6:	00003517          	auipc	a0,0x3
    50aa:	e3250513          	addi	a0,a0,-462 # 7ed8 <malloc+0x2228>
    50ae:	00001097          	auipc	ra,0x1
    50b2:	b44080e7          	jalr	-1212(ra) # 5bf2 <printf>
    exit(1);
    50b6:	4505                	li	a0,1
    50b8:	00000097          	auipc	ra,0x0
    50bc:	768080e7          	jalr	1896(ra) # 5820 <exit>
  close(fd);
    50c0:	8526                	mv	a0,s1
    50c2:	00000097          	auipc	ra,0x0
    50c6:	786080e7          	jalr	1926(ra) # 5848 <close>
  unlink("junk");
    50ca:	00003517          	auipc	a0,0x3
    50ce:	e0650513          	addi	a0,a0,-506 # 7ed0 <malloc+0x2220>
    50d2:	00000097          	auipc	ra,0x0
    50d6:	79e080e7          	jalr	1950(ra) # 5870 <unlink>
  exit(0);
    50da:	4501                	li	a0,0
    50dc:	00000097          	auipc	ra,0x0
    50e0:	744080e7          	jalr	1860(ra) # 5820 <exit>

00000000000050e4 <execout>:
// test the exec() code that cleans up if it runs out
// of memory. it's really a test that such a condition
// doesn't cause a panic.
void
execout(char *s)
{
    50e4:	715d                	addi	sp,sp,-80
    50e6:	e486                	sd	ra,72(sp)
    50e8:	e0a2                	sd	s0,64(sp)
    50ea:	fc26                	sd	s1,56(sp)
    50ec:	f84a                	sd	s2,48(sp)
    50ee:	f44e                	sd	s3,40(sp)
    50f0:	f052                	sd	s4,32(sp)
    50f2:	0880                	addi	s0,sp,80
  for(int avail = 0; avail < 15; avail++){
    50f4:	4901                	li	s2,0
    50f6:	49bd                	li	s3,15
    int pid = fork();
    50f8:	00000097          	auipc	ra,0x0
    50fc:	720080e7          	jalr	1824(ra) # 5818 <fork>
    5100:	84aa                	mv	s1,a0
    if(pid < 0){
    5102:	02054063          	bltz	a0,5122 <execout+0x3e>
      printf("fork failed\n");
      exit(1);
    } else if(pid == 0){
    5106:	c91d                	beqz	a0,513c <execout+0x58>
      close(1);
      char *args[] = { "echo", "x", 0 };
      exec("echo", args);
      exit(0);
    } else {
      wait((int*)0);
    5108:	4501                	li	a0,0
    510a:	00000097          	auipc	ra,0x0
    510e:	71e080e7          	jalr	1822(ra) # 5828 <wait>
  for(int avail = 0; avail < 15; avail++){
    5112:	2905                	addiw	s2,s2,1
    5114:	ff3912e3          	bne	s2,s3,50f8 <execout+0x14>
    }
  }

  exit(0);
    5118:	4501                	li	a0,0
    511a:	00000097          	auipc	ra,0x0
    511e:	706080e7          	jalr	1798(ra) # 5820 <exit>
      printf("fork failed\n");
    5122:	00002517          	auipc	a0,0x2
    5126:	8ce50513          	addi	a0,a0,-1842 # 69f0 <malloc+0xd40>
    512a:	00001097          	auipc	ra,0x1
    512e:	ac8080e7          	jalr	-1336(ra) # 5bf2 <printf>
      exit(1);
    5132:	4505                	li	a0,1
    5134:	00000097          	auipc	ra,0x0
    5138:	6ec080e7          	jalr	1772(ra) # 5820 <exit>
        if(a == 0xffffffffffffffffLL)
    513c:	59fd                	li	s3,-1
        *(char*)(a + 4096 - 1) = 1;
    513e:	4a05                	li	s4,1
        uint64 a = (uint64) sbrk(4096);
    5140:	6505                	lui	a0,0x1
    5142:	00000097          	auipc	ra,0x0
    5146:	766080e7          	jalr	1894(ra) # 58a8 <sbrk>
        if(a == 0xffffffffffffffffLL)
    514a:	01350763          	beq	a0,s3,5158 <execout+0x74>
        *(char*)(a + 4096 - 1) = 1;
    514e:	6785                	lui	a5,0x1
    5150:	953e                	add	a0,a0,a5
    5152:	ff450fa3          	sb	s4,-1(a0) # fff <preempt+0x16b>
      while(1){
    5156:	b7ed                	j	5140 <execout+0x5c>
      for(int i = 0; i < avail; i++)
    5158:	01205a63          	blez	s2,516c <execout+0x88>
        sbrk(-4096);
    515c:	757d                	lui	a0,0xfffff
    515e:	00000097          	auipc	ra,0x0
    5162:	74a080e7          	jalr	1866(ra) # 58a8 <sbrk>
      for(int i = 0; i < avail; i++)
    5166:	2485                	addiw	s1,s1,1
    5168:	ff249ae3          	bne	s1,s2,515c <execout+0x78>
      close(1);
    516c:	4505                	li	a0,1
    516e:	00000097          	auipc	ra,0x0
    5172:	6da080e7          	jalr	1754(ra) # 5848 <close>
      char *args[] = { "echo", "x", 0 };
    5176:	00001517          	auipc	a0,0x1
    517a:	ffa50513          	addi	a0,a0,-6 # 6170 <malloc+0x4c0>
    517e:	faa43c23          	sd	a0,-72(s0)
    5182:	00001797          	auipc	a5,0x1
    5186:	05e78793          	addi	a5,a5,94 # 61e0 <malloc+0x530>
    518a:	fcf43023          	sd	a5,-64(s0)
    518e:	fc043423          	sd	zero,-56(s0)
      exec("echo", args);
    5192:	fb840593          	addi	a1,s0,-72
    5196:	00000097          	auipc	ra,0x0
    519a:	6c2080e7          	jalr	1730(ra) # 5858 <exec>
      exit(0);
    519e:	4501                	li	a0,0
    51a0:	00000097          	auipc	ra,0x0
    51a4:	680080e7          	jalr	1664(ra) # 5820 <exit>

00000000000051a8 <countfree>:
// because out of memory with lazy allocation results in the process
// taking a fault and being killed, fork and report back.
//
int
countfree()
{
    51a8:	7139                	addi	sp,sp,-64
    51aa:	fc06                	sd	ra,56(sp)
    51ac:	f822                	sd	s0,48(sp)
    51ae:	f426                	sd	s1,40(sp)
    51b0:	f04a                	sd	s2,32(sp)
    51b2:	ec4e                	sd	s3,24(sp)
    51b4:	0080                	addi	s0,sp,64
  int fds[2];

  if(pipe(fds) < 0){
    51b6:	fc840513          	addi	a0,s0,-56
    51ba:	00000097          	auipc	ra,0x0
    51be:	676080e7          	jalr	1654(ra) # 5830 <pipe>
    51c2:	06054763          	bltz	a0,5230 <countfree+0x88>
    printf("pipe() failed in countfree()\n");
    exit(1);
  }
  
  int pid = fork();
    51c6:	00000097          	auipc	ra,0x0
    51ca:	652080e7          	jalr	1618(ra) # 5818 <fork>

  if(pid < 0){
    51ce:	06054e63          	bltz	a0,524a <countfree+0xa2>
    printf("fork failed in countfree()\n");
    exit(1);
  }

  if(pid == 0){
    51d2:	ed51                	bnez	a0,526e <countfree+0xc6>
    close(fds[0]);
    51d4:	fc842503          	lw	a0,-56(s0)
    51d8:	00000097          	auipc	ra,0x0
    51dc:	670080e7          	jalr	1648(ra) # 5848 <close>
    
    while(1){
      uint64 a = (uint64) sbrk(4096);
      if(a == 0xffffffffffffffff){
    51e0:	597d                	li	s2,-1
        break;
      }

      // modify the memory to make sure it's really allocated.
      *(char *)(a + 4096 - 1) = 1;
    51e2:	4485                	li	s1,1

      // report back one more page.
      if(write(fds[1], "x", 1) != 1){
    51e4:	00001997          	auipc	s3,0x1
    51e8:	ffc98993          	addi	s3,s3,-4 # 61e0 <malloc+0x530>
      uint64 a = (uint64) sbrk(4096);
    51ec:	6505                	lui	a0,0x1
    51ee:	00000097          	auipc	ra,0x0
    51f2:	6ba080e7          	jalr	1722(ra) # 58a8 <sbrk>
      if(a == 0xffffffffffffffff){
    51f6:	07250763          	beq	a0,s2,5264 <countfree+0xbc>
      *(char *)(a + 4096 - 1) = 1;
    51fa:	6785                	lui	a5,0x1
    51fc:	953e                	add	a0,a0,a5
    51fe:	fe950fa3          	sb	s1,-1(a0) # fff <preempt+0x16b>
      if(write(fds[1], "x", 1) != 1){
    5202:	8626                	mv	a2,s1
    5204:	85ce                	mv	a1,s3
    5206:	fcc42503          	lw	a0,-52(s0)
    520a:	00000097          	auipc	ra,0x0
    520e:	636080e7          	jalr	1590(ra) # 5840 <write>
    5212:	fc950de3          	beq	a0,s1,51ec <countfree+0x44>
        printf("write() failed in countfree()\n");
    5216:	00003517          	auipc	a0,0x3
    521a:	d2a50513          	addi	a0,a0,-726 # 7f40 <malloc+0x2290>
    521e:	00001097          	auipc	ra,0x1
    5222:	9d4080e7          	jalr	-1580(ra) # 5bf2 <printf>
        exit(1);
    5226:	4505                	li	a0,1
    5228:	00000097          	auipc	ra,0x0
    522c:	5f8080e7          	jalr	1528(ra) # 5820 <exit>
    printf("pipe() failed in countfree()\n");
    5230:	00003517          	auipc	a0,0x3
    5234:	cd050513          	addi	a0,a0,-816 # 7f00 <malloc+0x2250>
    5238:	00001097          	auipc	ra,0x1
    523c:	9ba080e7          	jalr	-1606(ra) # 5bf2 <printf>
    exit(1);
    5240:	4505                	li	a0,1
    5242:	00000097          	auipc	ra,0x0
    5246:	5de080e7          	jalr	1502(ra) # 5820 <exit>
    printf("fork failed in countfree()\n");
    524a:	00003517          	auipc	a0,0x3
    524e:	cd650513          	addi	a0,a0,-810 # 7f20 <malloc+0x2270>
    5252:	00001097          	auipc	ra,0x1
    5256:	9a0080e7          	jalr	-1632(ra) # 5bf2 <printf>
    exit(1);
    525a:	4505                	li	a0,1
    525c:	00000097          	auipc	ra,0x0
    5260:	5c4080e7          	jalr	1476(ra) # 5820 <exit>
      }
    }

    exit(0);
    5264:	4501                	li	a0,0
    5266:	00000097          	auipc	ra,0x0
    526a:	5ba080e7          	jalr	1466(ra) # 5820 <exit>
  }

  close(fds[1]);
    526e:	fcc42503          	lw	a0,-52(s0)
    5272:	00000097          	auipc	ra,0x0
    5276:	5d6080e7          	jalr	1494(ra) # 5848 <close>

  int n = 0;
    527a:	4481                	li	s1,0
  while(1){
    char c;
    int cc = read(fds[0], &c, 1);
    527c:	4605                	li	a2,1
    527e:	fc740593          	addi	a1,s0,-57
    5282:	fc842503          	lw	a0,-56(s0)
    5286:	00000097          	auipc	ra,0x0
    528a:	5b2080e7          	jalr	1458(ra) # 5838 <read>
    if(cc < 0){
    528e:	00054563          	bltz	a0,5298 <countfree+0xf0>
      printf("read() failed in countfree()\n");
      exit(1);
    }
    if(cc == 0)
    5292:	c105                	beqz	a0,52b2 <countfree+0x10a>
      break;
    n += 1;
    5294:	2485                	addiw	s1,s1,1
  while(1){
    5296:	b7dd                	j	527c <countfree+0xd4>
      printf("read() failed in countfree()\n");
    5298:	00003517          	auipc	a0,0x3
    529c:	cc850513          	addi	a0,a0,-824 # 7f60 <malloc+0x22b0>
    52a0:	00001097          	auipc	ra,0x1
    52a4:	952080e7          	jalr	-1710(ra) # 5bf2 <printf>
      exit(1);
    52a8:	4505                	li	a0,1
    52aa:	00000097          	auipc	ra,0x0
    52ae:	576080e7          	jalr	1398(ra) # 5820 <exit>
  }

  close(fds[0]);
    52b2:	fc842503          	lw	a0,-56(s0)
    52b6:	00000097          	auipc	ra,0x0
    52ba:	592080e7          	jalr	1426(ra) # 5848 <close>
  wait((int*)0);
    52be:	4501                	li	a0,0
    52c0:	00000097          	auipc	ra,0x0
    52c4:	568080e7          	jalr	1384(ra) # 5828 <wait>
  
  return n;
}
    52c8:	8526                	mv	a0,s1
    52ca:	70e2                	ld	ra,56(sp)
    52cc:	7442                	ld	s0,48(sp)
    52ce:	74a2                	ld	s1,40(sp)
    52d0:	7902                	ld	s2,32(sp)
    52d2:	69e2                	ld	s3,24(sp)
    52d4:	6121                	addi	sp,sp,64
    52d6:	8082                	ret

00000000000052d8 <run>:

// run each test in its own process. run returns 1 if child's exit()
// indicates success.
int
run(void f(char *), char *s) {
    52d8:	7179                	addi	sp,sp,-48
    52da:	f406                	sd	ra,40(sp)
    52dc:	f022                	sd	s0,32(sp)
    52de:	ec26                	sd	s1,24(sp)
    52e0:	e84a                	sd	s2,16(sp)
    52e2:	1800                	addi	s0,sp,48
    52e4:	84aa                	mv	s1,a0
    52e6:	892e                	mv	s2,a1
  int pid;
  int xstatus;

  printf("test %s: ", s);
    52e8:	00003517          	auipc	a0,0x3
    52ec:	c9850513          	addi	a0,a0,-872 # 7f80 <malloc+0x22d0>
    52f0:	00001097          	auipc	ra,0x1
    52f4:	902080e7          	jalr	-1790(ra) # 5bf2 <printf>
  if((pid = fork()) < 0) {
    52f8:	00000097          	auipc	ra,0x0
    52fc:	520080e7          	jalr	1312(ra) # 5818 <fork>
    5300:	02054e63          	bltz	a0,533c <run+0x64>
    printf("runtest: fork error\n");
    exit(1);
  }
  if(pid == 0) {
    5304:	c929                	beqz	a0,5356 <run+0x7e>
    f(s);
    exit(0);
  } else {
    wait(&xstatus);
    5306:	fdc40513          	addi	a0,s0,-36
    530a:	00000097          	auipc	ra,0x0
    530e:	51e080e7          	jalr	1310(ra) # 5828 <wait>
    if(xstatus != 0) 
    5312:	fdc42783          	lw	a5,-36(s0)
    5316:	c7b9                	beqz	a5,5364 <run+0x8c>
      printf("FAILED\n");
    5318:	00003517          	auipc	a0,0x3
    531c:	c9050513          	addi	a0,a0,-880 # 7fa8 <malloc+0x22f8>
    5320:	00001097          	auipc	ra,0x1
    5324:	8d2080e7          	jalr	-1838(ra) # 5bf2 <printf>
    else
      printf("OK\n");
    return xstatus == 0;
    5328:	fdc42503          	lw	a0,-36(s0)
  }
}
    532c:	00153513          	seqz	a0,a0
    5330:	70a2                	ld	ra,40(sp)
    5332:	7402                	ld	s0,32(sp)
    5334:	64e2                	ld	s1,24(sp)
    5336:	6942                	ld	s2,16(sp)
    5338:	6145                	addi	sp,sp,48
    533a:	8082                	ret
    printf("runtest: fork error\n");
    533c:	00003517          	auipc	a0,0x3
    5340:	c5450513          	addi	a0,a0,-940 # 7f90 <malloc+0x22e0>
    5344:	00001097          	auipc	ra,0x1
    5348:	8ae080e7          	jalr	-1874(ra) # 5bf2 <printf>
    exit(1);
    534c:	4505                	li	a0,1
    534e:	00000097          	auipc	ra,0x0
    5352:	4d2080e7          	jalr	1234(ra) # 5820 <exit>
    f(s);
    5356:	854a                	mv	a0,s2
    5358:	9482                	jalr	s1
    exit(0);
    535a:	4501                	li	a0,0
    535c:	00000097          	auipc	ra,0x0
    5360:	4c4080e7          	jalr	1220(ra) # 5820 <exit>
      printf("OK\n");
    5364:	00003517          	auipc	a0,0x3
    5368:	c4c50513          	addi	a0,a0,-948 # 7fb0 <malloc+0x2300>
    536c:	00001097          	auipc	ra,0x1
    5370:	886080e7          	jalr	-1914(ra) # 5bf2 <printf>
    5374:	bf55                	j	5328 <run+0x50>

0000000000005376 <main>:

int
main(int argc, char *argv[])
{
    5376:	d3010113          	addi	sp,sp,-720
    537a:	2c113423          	sd	ra,712(sp)
    537e:	2c813023          	sd	s0,704(sp)
    5382:	2a913c23          	sd	s1,696(sp)
    5386:	2b213823          	sd	s2,688(sp)
    538a:	2b313423          	sd	s3,680(sp)
    538e:	2b413023          	sd	s4,672(sp)
    5392:	29513c23          	sd	s5,664(sp)
    5396:	29613823          	sd	s6,656(sp)
    539a:	0d80                	addi	s0,sp,720
    539c:	89aa                	mv	s3,a0
  int continuous = 0;
  char *justone = 0;

  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    539e:	4789                	li	a5,2
    53a0:	08f50b63          	beq	a0,a5,5436 <main+0xc0>
    continuous = 1;
  } else if(argc == 2 && strcmp(argv[1], "-C") == 0){
    continuous = 2;
  } else if(argc == 2 && argv[1][0] != '-'){
    justone = argv[1];
  } else if(argc > 1){
    53a4:	4785                	li	a5,1
  char *justone = 0;
    53a6:	4901                	li	s2,0
  } else if(argc > 1){
    53a8:	0ca7c563          	blt	a5,a0,5472 <main+0xfc>
  }
  
  struct test {
    void (*f)(char *);
    char *s;
  } tests[] = {
    53ac:	00003797          	auipc	a5,0x3
    53b0:	d1c78793          	addi	a5,a5,-740 # 80c8 <malloc+0x2418>
    53b4:	d3040713          	addi	a4,s0,-720
    53b8:	00003817          	auipc	a6,0x3
    53bc:	f9080813          	addi	a6,a6,-112 # 8348 <malloc+0x2698>
    53c0:	6388                	ld	a0,0(a5)
    53c2:	678c                	ld	a1,8(a5)
    53c4:	6b90                	ld	a2,16(a5)
    53c6:	6f94                	ld	a3,24(a5)
    53c8:	e308                	sd	a0,0(a4)
    53ca:	e70c                	sd	a1,8(a4)
    53cc:	eb10                	sd	a2,16(a4)
    53ce:	ef14                	sd	a3,24(a4)
    53d0:	02078793          	addi	a5,a5,32
    53d4:	02070713          	addi	a4,a4,32
    53d8:	ff0794e3          	bne	a5,a6,53c0 <main+0x4a>
    53dc:	6394                	ld	a3,0(a5)
    53de:	679c                	ld	a5,8(a5)
    53e0:	e314                	sd	a3,0(a4)
    53e2:	e71c                	sd	a5,8(a4)
          exit(1);
      }
    }
  }

  printf("usertests2 starting\n");
    53e4:	00003517          	auipc	a0,0x3
    53e8:	c8450513          	addi	a0,a0,-892 # 8068 <malloc+0x23b8>
    53ec:	00001097          	auipc	ra,0x1
    53f0:	806080e7          	jalr	-2042(ra) # 5bf2 <printf>
  int free0 = countfree();
    53f4:	00000097          	auipc	ra,0x0
    53f8:	db4080e7          	jalr	-588(ra) # 51a8 <countfree>
    53fc:	8a2a                	mv	s4,a0
  int free1 = 0;
  int fail = 0;
  for (struct test *t = tests; t->s != 0; t++) {
    53fe:	d3843503          	ld	a0,-712(s0)
    5402:	d3040493          	addi	s1,s0,-720
  int fail = 0;
    5406:	4981                	li	s3,0
    if((justone == 0) || strcmp(t->s, justone) == 0) {
      if(!run(t->f, t->s))
        fail = 1;
    5408:	4a85                	li	s5,1
  for (struct test *t = tests; t->s != 0; t++) {
    540a:	e55d                	bnez	a0,54b8 <main+0x142>
  }

  if(fail){
    printf("SOME TESTS FAILED\n");
    exit(1);
  } else if((free1 = countfree()) < free0){
    540c:	00000097          	auipc	ra,0x0
    5410:	d9c080e7          	jalr	-612(ra) # 51a8 <countfree>
    5414:	85aa                	mv	a1,a0
    5416:	0f455163          	bge	a0,s4,54f8 <main+0x182>
    printf("FAILED -- lost some free pages %d (out of %d)\n", free1, free0);
    541a:	8652                	mv	a2,s4
    541c:	00003517          	auipc	a0,0x3
    5420:	c0450513          	addi	a0,a0,-1020 # 8020 <malloc+0x2370>
    5424:	00000097          	auipc	ra,0x0
    5428:	7ce080e7          	jalr	1998(ra) # 5bf2 <printf>
    exit(1);
    542c:	4505                	li	a0,1
    542e:	00000097          	auipc	ra,0x0
    5432:	3f2080e7          	jalr	1010(ra) # 5820 <exit>
    5436:	84ae                	mv	s1,a1
  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    5438:	00003597          	auipc	a1,0x3
    543c:	b8058593          	addi	a1,a1,-1152 # 7fb8 <malloc+0x2308>
    5440:	6488                	ld	a0,8(s1)
    5442:	00000097          	auipc	ra,0x0
    5446:	18c080e7          	jalr	396(ra) # 55ce <strcmp>
    544a:	10050563          	beqz	a0,5554 <main+0x1de>
  } else if(argc == 2 && strcmp(argv[1], "-C") == 0){
    544e:	00003597          	auipc	a1,0x3
    5452:	c5258593          	addi	a1,a1,-942 # 80a0 <malloc+0x23f0>
    5456:	6488                	ld	a0,8(s1)
    5458:	00000097          	auipc	ra,0x0
    545c:	176080e7          	jalr	374(ra) # 55ce <strcmp>
    5460:	c97d                	beqz	a0,5556 <main+0x1e0>
  } else if(argc == 2 && argv[1][0] != '-'){
    5462:	0084b903          	ld	s2,8(s1)
    5466:	00094703          	lbu	a4,0(s2)
    546a:	02d00793          	li	a5,45
    546e:	f2f71fe3          	bne	a4,a5,53ac <main+0x36>
    printf("Usage: usertests [-c] [testname]\n");
    5472:	00003517          	auipc	a0,0x3
    5476:	b4e50513          	addi	a0,a0,-1202 # 7fc0 <malloc+0x2310>
    547a:	00000097          	auipc	ra,0x0
    547e:	778080e7          	jalr	1912(ra) # 5bf2 <printf>
    exit(1);
    5482:	4505                	li	a0,1
    5484:	00000097          	auipc	ra,0x0
    5488:	39c080e7          	jalr	924(ra) # 5820 <exit>
          exit(1);
    548c:	4505                	li	a0,1
    548e:	00000097          	auipc	ra,0x0
    5492:	392080e7          	jalr	914(ra) # 5820 <exit>
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    5496:	40a905bb          	subw	a1,s2,a0
    549a:	855a                	mv	a0,s6
    549c:	00000097          	auipc	ra,0x0
    54a0:	756080e7          	jalr	1878(ra) # 5bf2 <printf>
        if(continuous != 2)
    54a4:	09498463          	beq	s3,s4,552c <main+0x1b6>
          exit(1);
    54a8:	4505                	li	a0,1
    54aa:	00000097          	auipc	ra,0x0
    54ae:	376080e7          	jalr	886(ra) # 5820 <exit>
  for (struct test *t = tests; t->s != 0; t++) {
    54b2:	04c1                	addi	s1,s1,16
    54b4:	6488                	ld	a0,8(s1)
    54b6:	c115                	beqz	a0,54da <main+0x164>
    if((justone == 0) || strcmp(t->s, justone) == 0) {
    54b8:	00090863          	beqz	s2,54c8 <main+0x152>
    54bc:	85ca                	mv	a1,s2
    54be:	00000097          	auipc	ra,0x0
    54c2:	110080e7          	jalr	272(ra) # 55ce <strcmp>
    54c6:	f575                	bnez	a0,54b2 <main+0x13c>
      if(!run(t->f, t->s))
    54c8:	648c                	ld	a1,8(s1)
    54ca:	6088                	ld	a0,0(s1)
    54cc:	00000097          	auipc	ra,0x0
    54d0:	e0c080e7          	jalr	-500(ra) # 52d8 <run>
    54d4:	fd79                	bnez	a0,54b2 <main+0x13c>
        fail = 1;
    54d6:	89d6                	mv	s3,s5
    54d8:	bfe9                	j	54b2 <main+0x13c>
  if(fail){
    54da:	f20989e3          	beqz	s3,540c <main+0x96>
    printf("SOME TESTS FAILED\n");
    54de:	00003517          	auipc	a0,0x3
    54e2:	b2a50513          	addi	a0,a0,-1238 # 8008 <malloc+0x2358>
    54e6:	00000097          	auipc	ra,0x0
    54ea:	70c080e7          	jalr	1804(ra) # 5bf2 <printf>
    exit(1);
    54ee:	4505                	li	a0,1
    54f0:	00000097          	auipc	ra,0x0
    54f4:	330080e7          	jalr	816(ra) # 5820 <exit>
  } else {
    printf("ALL TESTS PASSED\n");
    54f8:	00003517          	auipc	a0,0x3
    54fc:	b5850513          	addi	a0,a0,-1192 # 8050 <malloc+0x23a0>
    5500:	00000097          	auipc	ra,0x0
    5504:	6f2080e7          	jalr	1778(ra) # 5bf2 <printf>
    exit(0);
    5508:	4501                	li	a0,0
    550a:	00000097          	auipc	ra,0x0
    550e:	316080e7          	jalr	790(ra) # 5820 <exit>
        printf("SOME TESTS FAILED\n");
    5512:	8556                	mv	a0,s5
    5514:	00000097          	auipc	ra,0x0
    5518:	6de080e7          	jalr	1758(ra) # 5bf2 <printf>
        if(continuous != 2)
    551c:	f74998e3          	bne	s3,s4,548c <main+0x116>
      int free1 = countfree();
    5520:	00000097          	auipc	ra,0x0
    5524:	c88080e7          	jalr	-888(ra) # 51a8 <countfree>
      if(free1 < free0){
    5528:	f72547e3          	blt	a0,s2,5496 <main+0x120>
      int free0 = countfree();
    552c:	00000097          	auipc	ra,0x0
    5530:	c7c080e7          	jalr	-900(ra) # 51a8 <countfree>
    5534:	892a                	mv	s2,a0
      for (struct test *t = tests; t->s != 0; t++) {
    5536:	d3843583          	ld	a1,-712(s0)
    553a:	d1fd                	beqz	a1,5520 <main+0x1aa>
    553c:	d3040493          	addi	s1,s0,-720
        if(!run(t->f, t->s)){
    5540:	6088                	ld	a0,0(s1)
    5542:	00000097          	auipc	ra,0x0
    5546:	d96080e7          	jalr	-618(ra) # 52d8 <run>
    554a:	d561                	beqz	a0,5512 <main+0x19c>
      for (struct test *t = tests; t->s != 0; t++) {
    554c:	04c1                	addi	s1,s1,16
    554e:	648c                	ld	a1,8(s1)
    5550:	f9e5                	bnez	a1,5540 <main+0x1ca>
    5552:	b7f9                	j	5520 <main+0x1aa>
    continuous = 1;
    5554:	4985                	li	s3,1
  } tests[] = {
    5556:	00003797          	auipc	a5,0x3
    555a:	b7278793          	addi	a5,a5,-1166 # 80c8 <malloc+0x2418>
    555e:	d3040713          	addi	a4,s0,-720
    5562:	00003817          	auipc	a6,0x3
    5566:	de680813          	addi	a6,a6,-538 # 8348 <malloc+0x2698>
    556a:	6388                	ld	a0,0(a5)
    556c:	678c                	ld	a1,8(a5)
    556e:	6b90                	ld	a2,16(a5)
    5570:	6f94                	ld	a3,24(a5)
    5572:	e308                	sd	a0,0(a4)
    5574:	e70c                	sd	a1,8(a4)
    5576:	eb10                	sd	a2,16(a4)
    5578:	ef14                	sd	a3,24(a4)
    557a:	02078793          	addi	a5,a5,32
    557e:	02070713          	addi	a4,a4,32
    5582:	ff0794e3          	bne	a5,a6,556a <main+0x1f4>
    5586:	6394                	ld	a3,0(a5)
    5588:	679c                	ld	a5,8(a5)
    558a:	e314                	sd	a3,0(a4)
    558c:	e71c                	sd	a5,8(a4)
    printf("continuous usertests starting\n");
    558e:	00003517          	auipc	a0,0x3
    5592:	af250513          	addi	a0,a0,-1294 # 8080 <malloc+0x23d0>
    5596:	00000097          	auipc	ra,0x0
    559a:	65c080e7          	jalr	1628(ra) # 5bf2 <printf>
        printf("SOME TESTS FAILED\n");
    559e:	00003a97          	auipc	s5,0x3
    55a2:	a6aa8a93          	addi	s5,s5,-1430 # 8008 <malloc+0x2358>
        if(continuous != 2)
    55a6:	4a09                	li	s4,2
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    55a8:	00003b17          	auipc	s6,0x3
    55ac:	a40b0b13          	addi	s6,s6,-1472 # 7fe8 <malloc+0x2338>
    55b0:	bfb5                	j	552c <main+0x1b6>

00000000000055b2 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
    55b2:	1141                	addi	sp,sp,-16
    55b4:	e422                	sd	s0,8(sp)
    55b6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
    55b8:	87aa                	mv	a5,a0
    55ba:	0585                	addi	a1,a1,1
    55bc:	0785                	addi	a5,a5,1
    55be:	fff5c703          	lbu	a4,-1(a1)
    55c2:	fee78fa3          	sb	a4,-1(a5)
    55c6:	fb75                	bnez	a4,55ba <strcpy+0x8>
    ;
  return os;
}
    55c8:	6422                	ld	s0,8(sp)
    55ca:	0141                	addi	sp,sp,16
    55cc:	8082                	ret

00000000000055ce <strcmp>:

int
strcmp(const char *p, const char *q)
{
    55ce:	1141                	addi	sp,sp,-16
    55d0:	e422                	sd	s0,8(sp)
    55d2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
    55d4:	00054783          	lbu	a5,0(a0)
    55d8:	cb91                	beqz	a5,55ec <strcmp+0x1e>
    55da:	0005c703          	lbu	a4,0(a1)
    55de:	00f71763          	bne	a4,a5,55ec <strcmp+0x1e>
    p++, q++;
    55e2:	0505                	addi	a0,a0,1
    55e4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
    55e6:	00054783          	lbu	a5,0(a0)
    55ea:	fbe5                	bnez	a5,55da <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
    55ec:	0005c503          	lbu	a0,0(a1)
}
    55f0:	40a7853b          	subw	a0,a5,a0
    55f4:	6422                	ld	s0,8(sp)
    55f6:	0141                	addi	sp,sp,16
    55f8:	8082                	ret

00000000000055fa <strlen>:

uint
strlen(const char *s)
{
    55fa:	1141                	addi	sp,sp,-16
    55fc:	e422                	sd	s0,8(sp)
    55fe:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    5600:	00054783          	lbu	a5,0(a0)
    5604:	cf91                	beqz	a5,5620 <strlen+0x26>
    5606:	0505                	addi	a0,a0,1
    5608:	87aa                	mv	a5,a0
    560a:	4685                	li	a3,1
    560c:	9e89                	subw	a3,a3,a0
    560e:	00f6853b          	addw	a0,a3,a5
    5612:	0785                	addi	a5,a5,1
    5614:	fff7c703          	lbu	a4,-1(a5)
    5618:	fb7d                	bnez	a4,560e <strlen+0x14>
    ;
  return n;
}
    561a:	6422                	ld	s0,8(sp)
    561c:	0141                	addi	sp,sp,16
    561e:	8082                	ret
  for(n = 0; s[n]; n++)
    5620:	4501                	li	a0,0
    5622:	bfe5                	j	561a <strlen+0x20>

0000000000005624 <memset>:

void*
memset(void *dst, int c, uint n)
{
    5624:	1141                	addi	sp,sp,-16
    5626:	e422                	sd	s0,8(sp)
    5628:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    562a:	ca19                	beqz	a2,5640 <memset+0x1c>
    562c:	87aa                	mv	a5,a0
    562e:	1602                	slli	a2,a2,0x20
    5630:	9201                	srli	a2,a2,0x20
    5632:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    5636:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    563a:	0785                	addi	a5,a5,1
    563c:	fee79de3          	bne	a5,a4,5636 <memset+0x12>
  }
  return dst;
}
    5640:	6422                	ld	s0,8(sp)
    5642:	0141                	addi	sp,sp,16
    5644:	8082                	ret

0000000000005646 <strchr>:

char*
strchr(const char *s, char c)
{
    5646:	1141                	addi	sp,sp,-16
    5648:	e422                	sd	s0,8(sp)
    564a:	0800                	addi	s0,sp,16
  for(; *s; s++)
    564c:	00054783          	lbu	a5,0(a0)
    5650:	cb99                	beqz	a5,5666 <strchr+0x20>
    if(*s == c)
    5652:	00f58763          	beq	a1,a5,5660 <strchr+0x1a>
  for(; *s; s++)
    5656:	0505                	addi	a0,a0,1
    5658:	00054783          	lbu	a5,0(a0)
    565c:	fbfd                	bnez	a5,5652 <strchr+0xc>
      return (char*)s;
  return 0;
    565e:	4501                	li	a0,0
}
    5660:	6422                	ld	s0,8(sp)
    5662:	0141                	addi	sp,sp,16
    5664:	8082                	ret
  return 0;
    5666:	4501                	li	a0,0
    5668:	bfe5                	j	5660 <strchr+0x1a>

000000000000566a <gets>:

char*
gets(char *buf, int max)
{
    566a:	711d                	addi	sp,sp,-96
    566c:	ec86                	sd	ra,88(sp)
    566e:	e8a2                	sd	s0,80(sp)
    5670:	e4a6                	sd	s1,72(sp)
    5672:	e0ca                	sd	s2,64(sp)
    5674:	fc4e                	sd	s3,56(sp)
    5676:	f852                	sd	s4,48(sp)
    5678:	f456                	sd	s5,40(sp)
    567a:	f05a                	sd	s6,32(sp)
    567c:	ec5e                	sd	s7,24(sp)
    567e:	1080                	addi	s0,sp,96
    5680:	8baa                	mv	s7,a0
    5682:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    5684:	892a                	mv	s2,a0
    5686:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
    5688:	4aa9                	li	s5,10
    568a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
    568c:	89a6                	mv	s3,s1
    568e:	2485                	addiw	s1,s1,1
    5690:	0344d863          	bge	s1,s4,56c0 <gets+0x56>
    cc = read(0, &c, 1);
    5694:	4605                	li	a2,1
    5696:	faf40593          	addi	a1,s0,-81
    569a:	4501                	li	a0,0
    569c:	00000097          	auipc	ra,0x0
    56a0:	19c080e7          	jalr	412(ra) # 5838 <read>
    if(cc < 1)
    56a4:	00a05e63          	blez	a0,56c0 <gets+0x56>
    buf[i++] = c;
    56a8:	faf44783          	lbu	a5,-81(s0)
    56ac:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
    56b0:	01578763          	beq	a5,s5,56be <gets+0x54>
    56b4:	0905                	addi	s2,s2,1
    56b6:	fd679be3          	bne	a5,s6,568c <gets+0x22>
  for(i=0; i+1 < max; ){
    56ba:	89a6                	mv	s3,s1
    56bc:	a011                	j	56c0 <gets+0x56>
    56be:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
    56c0:	99de                	add	s3,s3,s7
    56c2:	00098023          	sb	zero,0(s3)
  return buf;
}
    56c6:	855e                	mv	a0,s7
    56c8:	60e6                	ld	ra,88(sp)
    56ca:	6446                	ld	s0,80(sp)
    56cc:	64a6                	ld	s1,72(sp)
    56ce:	6906                	ld	s2,64(sp)
    56d0:	79e2                	ld	s3,56(sp)
    56d2:	7a42                	ld	s4,48(sp)
    56d4:	7aa2                	ld	s5,40(sp)
    56d6:	7b02                	ld	s6,32(sp)
    56d8:	6be2                	ld	s7,24(sp)
    56da:	6125                	addi	sp,sp,96
    56dc:	8082                	ret

00000000000056de <stat>:

int
stat(const char *n, struct stat *st)
{
    56de:	1101                	addi	sp,sp,-32
    56e0:	ec06                	sd	ra,24(sp)
    56e2:	e822                	sd	s0,16(sp)
    56e4:	e426                	sd	s1,8(sp)
    56e6:	e04a                	sd	s2,0(sp)
    56e8:	1000                	addi	s0,sp,32
    56ea:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
    56ec:	4581                	li	a1,0
    56ee:	00000097          	auipc	ra,0x0
    56f2:	172080e7          	jalr	370(ra) # 5860 <open>
  if(fd < 0)
    56f6:	02054563          	bltz	a0,5720 <stat+0x42>
    56fa:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
    56fc:	85ca                	mv	a1,s2
    56fe:	00000097          	auipc	ra,0x0
    5702:	17a080e7          	jalr	378(ra) # 5878 <fstat>
    5706:	892a                	mv	s2,a0
  close(fd);
    5708:	8526                	mv	a0,s1
    570a:	00000097          	auipc	ra,0x0
    570e:	13e080e7          	jalr	318(ra) # 5848 <close>
  return r;
}
    5712:	854a                	mv	a0,s2
    5714:	60e2                	ld	ra,24(sp)
    5716:	6442                	ld	s0,16(sp)
    5718:	64a2                	ld	s1,8(sp)
    571a:	6902                	ld	s2,0(sp)
    571c:	6105                	addi	sp,sp,32
    571e:	8082                	ret
    return -1;
    5720:	597d                	li	s2,-1
    5722:	bfc5                	j	5712 <stat+0x34>

0000000000005724 <atoi>:

int
atoi(const char *s)
{
    5724:	1141                	addi	sp,sp,-16
    5726:	e422                	sd	s0,8(sp)
    5728:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    572a:	00054603          	lbu	a2,0(a0)
    572e:	fd06079b          	addiw	a5,a2,-48
    5732:	0ff7f793          	andi	a5,a5,255
    5736:	4725                	li	a4,9
    5738:	02f76963          	bltu	a4,a5,576a <atoi+0x46>
    573c:	86aa                	mv	a3,a0
  n = 0;
    573e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
    5740:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
    5742:	0685                	addi	a3,a3,1
    5744:	0025179b          	slliw	a5,a0,0x2
    5748:	9fa9                	addw	a5,a5,a0
    574a:	0017979b          	slliw	a5,a5,0x1
    574e:	9fb1                	addw	a5,a5,a2
    5750:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
    5754:	0006c603          	lbu	a2,0(a3)
    5758:	fd06071b          	addiw	a4,a2,-48
    575c:	0ff77713          	andi	a4,a4,255
    5760:	fee5f1e3          	bgeu	a1,a4,5742 <atoi+0x1e>
  return n;
}
    5764:	6422                	ld	s0,8(sp)
    5766:	0141                	addi	sp,sp,16
    5768:	8082                	ret
  n = 0;
    576a:	4501                	li	a0,0
    576c:	bfe5                	j	5764 <atoi+0x40>

000000000000576e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
    576e:	1141                	addi	sp,sp,-16
    5770:	e422                	sd	s0,8(sp)
    5772:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
    5774:	02b57463          	bgeu	a0,a1,579c <memmove+0x2e>
    while(n-- > 0)
    5778:	00c05f63          	blez	a2,5796 <memmove+0x28>
    577c:	1602                	slli	a2,a2,0x20
    577e:	9201                	srli	a2,a2,0x20
    5780:	00c507b3          	add	a5,a0,a2
  dst = vdst;
    5784:	872a                	mv	a4,a0
      *dst++ = *src++;
    5786:	0585                	addi	a1,a1,1
    5788:	0705                	addi	a4,a4,1
    578a:	fff5c683          	lbu	a3,-1(a1)
    578e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    5792:	fee79ae3          	bne	a5,a4,5786 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
    5796:	6422                	ld	s0,8(sp)
    5798:	0141                	addi	sp,sp,16
    579a:	8082                	ret
    dst += n;
    579c:	00c50733          	add	a4,a0,a2
    src += n;
    57a0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
    57a2:	fec05ae3          	blez	a2,5796 <memmove+0x28>
    57a6:	fff6079b          	addiw	a5,a2,-1
    57aa:	1782                	slli	a5,a5,0x20
    57ac:	9381                	srli	a5,a5,0x20
    57ae:	fff7c793          	not	a5,a5
    57b2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
    57b4:	15fd                	addi	a1,a1,-1
    57b6:	177d                	addi	a4,a4,-1
    57b8:	0005c683          	lbu	a3,0(a1)
    57bc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    57c0:	fee79ae3          	bne	a5,a4,57b4 <memmove+0x46>
    57c4:	bfc9                	j	5796 <memmove+0x28>

00000000000057c6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
    57c6:	1141                	addi	sp,sp,-16
    57c8:	e422                	sd	s0,8(sp)
    57ca:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
    57cc:	ca05                	beqz	a2,57fc <memcmp+0x36>
    57ce:	fff6069b          	addiw	a3,a2,-1
    57d2:	1682                	slli	a3,a3,0x20
    57d4:	9281                	srli	a3,a3,0x20
    57d6:	0685                	addi	a3,a3,1
    57d8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
    57da:	00054783          	lbu	a5,0(a0)
    57de:	0005c703          	lbu	a4,0(a1)
    57e2:	00e79863          	bne	a5,a4,57f2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
    57e6:	0505                	addi	a0,a0,1
    p2++;
    57e8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
    57ea:	fed518e3          	bne	a0,a3,57da <memcmp+0x14>
  }
  return 0;
    57ee:	4501                	li	a0,0
    57f0:	a019                	j	57f6 <memcmp+0x30>
      return *p1 - *p2;
    57f2:	40e7853b          	subw	a0,a5,a4
}
    57f6:	6422                	ld	s0,8(sp)
    57f8:	0141                	addi	sp,sp,16
    57fa:	8082                	ret
  return 0;
    57fc:	4501                	li	a0,0
    57fe:	bfe5                	j	57f6 <memcmp+0x30>

0000000000005800 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
    5800:	1141                	addi	sp,sp,-16
    5802:	e406                	sd	ra,8(sp)
    5804:	e022                	sd	s0,0(sp)
    5806:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    5808:	00000097          	auipc	ra,0x0
    580c:	f66080e7          	jalr	-154(ra) # 576e <memmove>
}
    5810:	60a2                	ld	ra,8(sp)
    5812:	6402                	ld	s0,0(sp)
    5814:	0141                	addi	sp,sp,16
    5816:	8082                	ret

0000000000005818 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
    5818:	4885                	li	a7,1
 ecall
    581a:	00000073          	ecall
 ret
    581e:	8082                	ret

0000000000005820 <exit>:
.global exit
exit:
 li a7, SYS_exit
    5820:	4889                	li	a7,2
 ecall
    5822:	00000073          	ecall
 ret
    5826:	8082                	ret

0000000000005828 <wait>:
.global wait
wait:
 li a7, SYS_wait
    5828:	488d                	li	a7,3
 ecall
    582a:	00000073          	ecall
 ret
    582e:	8082                	ret

0000000000005830 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
    5830:	4891                	li	a7,4
 ecall
    5832:	00000073          	ecall
 ret
    5836:	8082                	ret

0000000000005838 <read>:
.global read
read:
 li a7, SYS_read
    5838:	4895                	li	a7,5
 ecall
    583a:	00000073          	ecall
 ret
    583e:	8082                	ret

0000000000005840 <write>:
.global write
write:
 li a7, SYS_write
    5840:	48c1                	li	a7,16
 ecall
    5842:	00000073          	ecall
 ret
    5846:	8082                	ret

0000000000005848 <close>:
.global close
close:
 li a7, SYS_close
    5848:	48d5                	li	a7,21
 ecall
    584a:	00000073          	ecall
 ret
    584e:	8082                	ret

0000000000005850 <kill>:
.global kill
kill:
 li a7, SYS_kill
    5850:	4899                	li	a7,6
 ecall
    5852:	00000073          	ecall
 ret
    5856:	8082                	ret

0000000000005858 <exec>:
.global exec
exec:
 li a7, SYS_exec
    5858:	489d                	li	a7,7
 ecall
    585a:	00000073          	ecall
 ret
    585e:	8082                	ret

0000000000005860 <open>:
.global open
open:
 li a7, SYS_open
    5860:	48bd                	li	a7,15
 ecall
    5862:	00000073          	ecall
 ret
    5866:	8082                	ret

0000000000005868 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
    5868:	48c5                	li	a7,17
 ecall
    586a:	00000073          	ecall
 ret
    586e:	8082                	ret

0000000000005870 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
    5870:	48c9                	li	a7,18
 ecall
    5872:	00000073          	ecall
 ret
    5876:	8082                	ret

0000000000005878 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
    5878:	48a1                	li	a7,8
 ecall
    587a:	00000073          	ecall
 ret
    587e:	8082                	ret

0000000000005880 <link>:
.global link
link:
 li a7, SYS_link
    5880:	48cd                	li	a7,19
 ecall
    5882:	00000073          	ecall
 ret
    5886:	8082                	ret

0000000000005888 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
    5888:	48d1                	li	a7,20
 ecall
    588a:	00000073          	ecall
 ret
    588e:	8082                	ret

0000000000005890 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
    5890:	48a5                	li	a7,9
 ecall
    5892:	00000073          	ecall
 ret
    5896:	8082                	ret

0000000000005898 <dup>:
.global dup
dup:
 li a7, SYS_dup
    5898:	48a9                	li	a7,10
 ecall
    589a:	00000073          	ecall
 ret
    589e:	8082                	ret

00000000000058a0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
    58a0:	48ad                	li	a7,11
 ecall
    58a2:	00000073          	ecall
 ret
    58a6:	8082                	ret

00000000000058a8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
    58a8:	48b1                	li	a7,12
 ecall
    58aa:	00000073          	ecall
 ret
    58ae:	8082                	ret

00000000000058b0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
    58b0:	48b5                	li	a7,13
 ecall
    58b2:	00000073          	ecall
 ret
    58b6:	8082                	ret

00000000000058b8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
    58b8:	48b9                	li	a7,14
 ecall
    58ba:	00000073          	ecall
 ret
    58be:	8082                	ret

00000000000058c0 <sigprocmask>:
.global sigprocmask
sigprocmask:
 li a7, SYS_sigprocmask
    58c0:	48d9                	li	a7,22
 ecall
    58c2:	00000073          	ecall
 ret
    58c6:	8082                	ret

00000000000058c8 <sigaction>:
.global sigaction
sigaction:
 li a7, SYS_sigaction
    58c8:	48dd                	li	a7,23
 ecall
    58ca:	00000073          	ecall
 ret
    58ce:	8082                	ret

00000000000058d0 <sigret>:
.global sigret
sigret:
 li a7, SYS_sigret
    58d0:	48e1                	li	a7,24
 ecall
    58d2:	00000073          	ecall
 ret
    58d6:	8082                	ret

00000000000058d8 <kthread_create>:
.global kthread_create
kthread_create:
 li a7, SYS_kthread_create
    58d8:	48e5                	li	a7,25
 ecall
    58da:	00000073          	ecall
 ret
    58de:	8082                	ret

00000000000058e0 <kthread_id>:
.global kthread_id
kthread_id:
 li a7, SYS_kthread_id
    58e0:	48e9                	li	a7,26
 ecall
    58e2:	00000073          	ecall
 ret
    58e6:	8082                	ret

00000000000058e8 <kthread_exit>:
.global kthread_exit
kthread_exit:
 li a7, SYS_kthread_exit
    58e8:	48ed                	li	a7,27
 ecall
    58ea:	00000073          	ecall
 ret
    58ee:	8082                	ret

00000000000058f0 <kthread_join>:
.global kthread_join
kthread_join:
 li a7, SYS_kthread_join
    58f0:	48f1                	li	a7,28
 ecall
    58f2:	00000073          	ecall
 ret
    58f6:	8082                	ret

00000000000058f8 <bsem_alloc>:
.global bsem_alloc
bsem_alloc:
 li a7, SYS_bsem_alloc
    58f8:	48f5                	li	a7,29
 ecall
    58fa:	00000073          	ecall
 ret
    58fe:	8082                	ret

0000000000005900 <bsem_free>:
.global bsem_free
bsem_free:
 li a7, SYS_bsem_free
    5900:	48f9                	li	a7,30
 ecall
    5902:	00000073          	ecall
 ret
    5906:	8082                	ret

0000000000005908 <bsem_down>:
.global bsem_down
bsem_down:
 li a7, SYS_bsem_down
    5908:	48fd                	li	a7,31
 ecall
    590a:	00000073          	ecall
 ret
    590e:	8082                	ret

0000000000005910 <bsem_up>:
.global bsem_up
bsem_up:
 li a7, SYS_bsem_up
    5910:	02000893          	li	a7,32
 ecall
    5914:	00000073          	ecall
 ret
    5918:	8082                	ret

000000000000591a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
    591a:	1101                	addi	sp,sp,-32
    591c:	ec06                	sd	ra,24(sp)
    591e:	e822                	sd	s0,16(sp)
    5920:	1000                	addi	s0,sp,32
    5922:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
    5926:	4605                	li	a2,1
    5928:	fef40593          	addi	a1,s0,-17
    592c:	00000097          	auipc	ra,0x0
    5930:	f14080e7          	jalr	-236(ra) # 5840 <write>
}
    5934:	60e2                	ld	ra,24(sp)
    5936:	6442                	ld	s0,16(sp)
    5938:	6105                	addi	sp,sp,32
    593a:	8082                	ret

000000000000593c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    593c:	7139                	addi	sp,sp,-64
    593e:	fc06                	sd	ra,56(sp)
    5940:	f822                	sd	s0,48(sp)
    5942:	f426                	sd	s1,40(sp)
    5944:	f04a                	sd	s2,32(sp)
    5946:	ec4e                	sd	s3,24(sp)
    5948:	0080                	addi	s0,sp,64
    594a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
    594c:	c299                	beqz	a3,5952 <printint+0x16>
    594e:	0805c863          	bltz	a1,59de <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
    5952:	2581                	sext.w	a1,a1
  neg = 0;
    5954:	4881                	li	a7,0
    5956:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
    595a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
    595c:	2601                	sext.w	a2,a2
    595e:	00003517          	auipc	a0,0x3
    5962:	a0250513          	addi	a0,a0,-1534 # 8360 <digits>
    5966:	883a                	mv	a6,a4
    5968:	2705                	addiw	a4,a4,1
    596a:	02c5f7bb          	remuw	a5,a1,a2
    596e:	1782                	slli	a5,a5,0x20
    5970:	9381                	srli	a5,a5,0x20
    5972:	97aa                	add	a5,a5,a0
    5974:	0007c783          	lbu	a5,0(a5)
    5978:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
    597c:	0005879b          	sext.w	a5,a1
    5980:	02c5d5bb          	divuw	a1,a1,a2
    5984:	0685                	addi	a3,a3,1
    5986:	fec7f0e3          	bgeu	a5,a2,5966 <printint+0x2a>
  if(neg)
    598a:	00088b63          	beqz	a7,59a0 <printint+0x64>
    buf[i++] = '-';
    598e:	fd040793          	addi	a5,s0,-48
    5992:	973e                	add	a4,a4,a5
    5994:	02d00793          	li	a5,45
    5998:	fef70823          	sb	a5,-16(a4)
    599c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    59a0:	02e05863          	blez	a4,59d0 <printint+0x94>
    59a4:	fc040793          	addi	a5,s0,-64
    59a8:	00e78933          	add	s2,a5,a4
    59ac:	fff78993          	addi	s3,a5,-1
    59b0:	99ba                	add	s3,s3,a4
    59b2:	377d                	addiw	a4,a4,-1
    59b4:	1702                	slli	a4,a4,0x20
    59b6:	9301                	srli	a4,a4,0x20
    59b8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
    59bc:	fff94583          	lbu	a1,-1(s2)
    59c0:	8526                	mv	a0,s1
    59c2:	00000097          	auipc	ra,0x0
    59c6:	f58080e7          	jalr	-168(ra) # 591a <putc>
  while(--i >= 0)
    59ca:	197d                	addi	s2,s2,-1
    59cc:	ff3918e3          	bne	s2,s3,59bc <printint+0x80>
}
    59d0:	70e2                	ld	ra,56(sp)
    59d2:	7442                	ld	s0,48(sp)
    59d4:	74a2                	ld	s1,40(sp)
    59d6:	7902                	ld	s2,32(sp)
    59d8:	69e2                	ld	s3,24(sp)
    59da:	6121                	addi	sp,sp,64
    59dc:	8082                	ret
    x = -xx;
    59de:	40b005bb          	negw	a1,a1
    neg = 1;
    59e2:	4885                	li	a7,1
    x = -xx;
    59e4:	bf8d                	j	5956 <printint+0x1a>

00000000000059e6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    59e6:	7119                	addi	sp,sp,-128
    59e8:	fc86                	sd	ra,120(sp)
    59ea:	f8a2                	sd	s0,112(sp)
    59ec:	f4a6                	sd	s1,104(sp)
    59ee:	f0ca                	sd	s2,96(sp)
    59f0:	ecce                	sd	s3,88(sp)
    59f2:	e8d2                	sd	s4,80(sp)
    59f4:	e4d6                	sd	s5,72(sp)
    59f6:	e0da                	sd	s6,64(sp)
    59f8:	fc5e                	sd	s7,56(sp)
    59fa:	f862                	sd	s8,48(sp)
    59fc:	f466                	sd	s9,40(sp)
    59fe:	f06a                	sd	s10,32(sp)
    5a00:	ec6e                	sd	s11,24(sp)
    5a02:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    5a04:	0005c903          	lbu	s2,0(a1)
    5a08:	18090f63          	beqz	s2,5ba6 <vprintf+0x1c0>
    5a0c:	8aaa                	mv	s5,a0
    5a0e:	8b32                	mv	s6,a2
    5a10:	00158493          	addi	s1,a1,1
  state = 0;
    5a14:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    5a16:	02500a13          	li	s4,37
      if(c == 'd'){
    5a1a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    5a1e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    5a22:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    5a26:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5a2a:	00003b97          	auipc	s7,0x3
    5a2e:	936b8b93          	addi	s7,s7,-1738 # 8360 <digits>
    5a32:	a839                	j	5a50 <vprintf+0x6a>
        putc(fd, c);
    5a34:	85ca                	mv	a1,s2
    5a36:	8556                	mv	a0,s5
    5a38:	00000097          	auipc	ra,0x0
    5a3c:	ee2080e7          	jalr	-286(ra) # 591a <putc>
    5a40:	a019                	j	5a46 <vprintf+0x60>
    } else if(state == '%'){
    5a42:	01498f63          	beq	s3,s4,5a60 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    5a46:	0485                	addi	s1,s1,1
    5a48:	fff4c903          	lbu	s2,-1(s1)
    5a4c:	14090d63          	beqz	s2,5ba6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    5a50:	0009079b          	sext.w	a5,s2
    if(state == 0){
    5a54:	fe0997e3          	bnez	s3,5a42 <vprintf+0x5c>
      if(c == '%'){
    5a58:	fd479ee3          	bne	a5,s4,5a34 <vprintf+0x4e>
        state = '%';
    5a5c:	89be                	mv	s3,a5
    5a5e:	b7e5                	j	5a46 <vprintf+0x60>
      if(c == 'd'){
    5a60:	05878063          	beq	a5,s8,5aa0 <vprintf+0xba>
      } else if(c == 'l') {
    5a64:	05978c63          	beq	a5,s9,5abc <vprintf+0xd6>
      } else if(c == 'x') {
    5a68:	07a78863          	beq	a5,s10,5ad8 <vprintf+0xf2>
      } else if(c == 'p') {
    5a6c:	09b78463          	beq	a5,s11,5af4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    5a70:	07300713          	li	a4,115
    5a74:	0ce78663          	beq	a5,a4,5b40 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    5a78:	06300713          	li	a4,99
    5a7c:	0ee78e63          	beq	a5,a4,5b78 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    5a80:	11478863          	beq	a5,s4,5b90 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    5a84:	85d2                	mv	a1,s4
    5a86:	8556                	mv	a0,s5
    5a88:	00000097          	auipc	ra,0x0
    5a8c:	e92080e7          	jalr	-366(ra) # 591a <putc>
        putc(fd, c);
    5a90:	85ca                	mv	a1,s2
    5a92:	8556                	mv	a0,s5
    5a94:	00000097          	auipc	ra,0x0
    5a98:	e86080e7          	jalr	-378(ra) # 591a <putc>
      }
      state = 0;
    5a9c:	4981                	li	s3,0
    5a9e:	b765                	j	5a46 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    5aa0:	008b0913          	addi	s2,s6,8
    5aa4:	4685                	li	a3,1
    5aa6:	4629                	li	a2,10
    5aa8:	000b2583          	lw	a1,0(s6)
    5aac:	8556                	mv	a0,s5
    5aae:	00000097          	auipc	ra,0x0
    5ab2:	e8e080e7          	jalr	-370(ra) # 593c <printint>
    5ab6:	8b4a                	mv	s6,s2
      state = 0;
    5ab8:	4981                	li	s3,0
    5aba:	b771                	j	5a46 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    5abc:	008b0913          	addi	s2,s6,8
    5ac0:	4681                	li	a3,0
    5ac2:	4629                	li	a2,10
    5ac4:	000b2583          	lw	a1,0(s6)
    5ac8:	8556                	mv	a0,s5
    5aca:	00000097          	auipc	ra,0x0
    5ace:	e72080e7          	jalr	-398(ra) # 593c <printint>
    5ad2:	8b4a                	mv	s6,s2
      state = 0;
    5ad4:	4981                	li	s3,0
    5ad6:	bf85                	j	5a46 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    5ad8:	008b0913          	addi	s2,s6,8
    5adc:	4681                	li	a3,0
    5ade:	4641                	li	a2,16
    5ae0:	000b2583          	lw	a1,0(s6)
    5ae4:	8556                	mv	a0,s5
    5ae6:	00000097          	auipc	ra,0x0
    5aea:	e56080e7          	jalr	-426(ra) # 593c <printint>
    5aee:	8b4a                	mv	s6,s2
      state = 0;
    5af0:	4981                	li	s3,0
    5af2:	bf91                	j	5a46 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    5af4:	008b0793          	addi	a5,s6,8
    5af8:	f8f43423          	sd	a5,-120(s0)
    5afc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    5b00:	03000593          	li	a1,48
    5b04:	8556                	mv	a0,s5
    5b06:	00000097          	auipc	ra,0x0
    5b0a:	e14080e7          	jalr	-492(ra) # 591a <putc>
  putc(fd, 'x');
    5b0e:	85ea                	mv	a1,s10
    5b10:	8556                	mv	a0,s5
    5b12:	00000097          	auipc	ra,0x0
    5b16:	e08080e7          	jalr	-504(ra) # 591a <putc>
    5b1a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5b1c:	03c9d793          	srli	a5,s3,0x3c
    5b20:	97de                	add	a5,a5,s7
    5b22:	0007c583          	lbu	a1,0(a5)
    5b26:	8556                	mv	a0,s5
    5b28:	00000097          	auipc	ra,0x0
    5b2c:	df2080e7          	jalr	-526(ra) # 591a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    5b30:	0992                	slli	s3,s3,0x4
    5b32:	397d                	addiw	s2,s2,-1
    5b34:	fe0914e3          	bnez	s2,5b1c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    5b38:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    5b3c:	4981                	li	s3,0
    5b3e:	b721                	j	5a46 <vprintf+0x60>
        s = va_arg(ap, char*);
    5b40:	008b0993          	addi	s3,s6,8
    5b44:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    5b48:	02090163          	beqz	s2,5b6a <vprintf+0x184>
        while(*s != 0){
    5b4c:	00094583          	lbu	a1,0(s2)
    5b50:	c9a1                	beqz	a1,5ba0 <vprintf+0x1ba>
          putc(fd, *s);
    5b52:	8556                	mv	a0,s5
    5b54:	00000097          	auipc	ra,0x0
    5b58:	dc6080e7          	jalr	-570(ra) # 591a <putc>
          s++;
    5b5c:	0905                	addi	s2,s2,1
        while(*s != 0){
    5b5e:	00094583          	lbu	a1,0(s2)
    5b62:	f9e5                	bnez	a1,5b52 <vprintf+0x16c>
        s = va_arg(ap, char*);
    5b64:	8b4e                	mv	s6,s3
      state = 0;
    5b66:	4981                	li	s3,0
    5b68:	bdf9                	j	5a46 <vprintf+0x60>
          s = "(null)";
    5b6a:	00002917          	auipc	s2,0x2
    5b6e:	7ee90913          	addi	s2,s2,2030 # 8358 <malloc+0x26a8>
        while(*s != 0){
    5b72:	02800593          	li	a1,40
    5b76:	bff1                	j	5b52 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    5b78:	008b0913          	addi	s2,s6,8
    5b7c:	000b4583          	lbu	a1,0(s6)
    5b80:	8556                	mv	a0,s5
    5b82:	00000097          	auipc	ra,0x0
    5b86:	d98080e7          	jalr	-616(ra) # 591a <putc>
    5b8a:	8b4a                	mv	s6,s2
      state = 0;
    5b8c:	4981                	li	s3,0
    5b8e:	bd65                	j	5a46 <vprintf+0x60>
        putc(fd, c);
    5b90:	85d2                	mv	a1,s4
    5b92:	8556                	mv	a0,s5
    5b94:	00000097          	auipc	ra,0x0
    5b98:	d86080e7          	jalr	-634(ra) # 591a <putc>
      state = 0;
    5b9c:	4981                	li	s3,0
    5b9e:	b565                	j	5a46 <vprintf+0x60>
        s = va_arg(ap, char*);
    5ba0:	8b4e                	mv	s6,s3
      state = 0;
    5ba2:	4981                	li	s3,0
    5ba4:	b54d                	j	5a46 <vprintf+0x60>
    }
  }
}
    5ba6:	70e6                	ld	ra,120(sp)
    5ba8:	7446                	ld	s0,112(sp)
    5baa:	74a6                	ld	s1,104(sp)
    5bac:	7906                	ld	s2,96(sp)
    5bae:	69e6                	ld	s3,88(sp)
    5bb0:	6a46                	ld	s4,80(sp)
    5bb2:	6aa6                	ld	s5,72(sp)
    5bb4:	6b06                	ld	s6,64(sp)
    5bb6:	7be2                	ld	s7,56(sp)
    5bb8:	7c42                	ld	s8,48(sp)
    5bba:	7ca2                	ld	s9,40(sp)
    5bbc:	7d02                	ld	s10,32(sp)
    5bbe:	6de2                	ld	s11,24(sp)
    5bc0:	6109                	addi	sp,sp,128
    5bc2:	8082                	ret

0000000000005bc4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    5bc4:	715d                	addi	sp,sp,-80
    5bc6:	ec06                	sd	ra,24(sp)
    5bc8:	e822                	sd	s0,16(sp)
    5bca:	1000                	addi	s0,sp,32
    5bcc:	e010                	sd	a2,0(s0)
    5bce:	e414                	sd	a3,8(s0)
    5bd0:	e818                	sd	a4,16(s0)
    5bd2:	ec1c                	sd	a5,24(s0)
    5bd4:	03043023          	sd	a6,32(s0)
    5bd8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    5bdc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    5be0:	8622                	mv	a2,s0
    5be2:	00000097          	auipc	ra,0x0
    5be6:	e04080e7          	jalr	-508(ra) # 59e6 <vprintf>
}
    5bea:	60e2                	ld	ra,24(sp)
    5bec:	6442                	ld	s0,16(sp)
    5bee:	6161                	addi	sp,sp,80
    5bf0:	8082                	ret

0000000000005bf2 <printf>:

void
printf(const char *fmt, ...)
{
    5bf2:	711d                	addi	sp,sp,-96
    5bf4:	ec06                	sd	ra,24(sp)
    5bf6:	e822                	sd	s0,16(sp)
    5bf8:	1000                	addi	s0,sp,32
    5bfa:	e40c                	sd	a1,8(s0)
    5bfc:	e810                	sd	a2,16(s0)
    5bfe:	ec14                	sd	a3,24(s0)
    5c00:	f018                	sd	a4,32(s0)
    5c02:	f41c                	sd	a5,40(s0)
    5c04:	03043823          	sd	a6,48(s0)
    5c08:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    5c0c:	00840613          	addi	a2,s0,8
    5c10:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    5c14:	85aa                	mv	a1,a0
    5c16:	4505                	li	a0,1
    5c18:	00000097          	auipc	ra,0x0
    5c1c:	dce080e7          	jalr	-562(ra) # 59e6 <vprintf>
}
    5c20:	60e2                	ld	ra,24(sp)
    5c22:	6442                	ld	s0,16(sp)
    5c24:	6125                	addi	sp,sp,96
    5c26:	8082                	ret

0000000000005c28 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    5c28:	1141                	addi	sp,sp,-16
    5c2a:	e422                	sd	s0,8(sp)
    5c2c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    5c2e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c32:	00002797          	auipc	a5,0x2
    5c36:	75e7b783          	ld	a5,1886(a5) # 8390 <freep>
    5c3a:	a805                	j	5c6a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    5c3c:	4618                	lw	a4,8(a2)
    5c3e:	9db9                	addw	a1,a1,a4
    5c40:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    5c44:	6398                	ld	a4,0(a5)
    5c46:	6318                	ld	a4,0(a4)
    5c48:	fee53823          	sd	a4,-16(a0)
    5c4c:	a091                	j	5c90 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    5c4e:	ff852703          	lw	a4,-8(a0)
    5c52:	9e39                	addw	a2,a2,a4
    5c54:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    5c56:	ff053703          	ld	a4,-16(a0)
    5c5a:	e398                	sd	a4,0(a5)
    5c5c:	a099                	j	5ca2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c5e:	6398                	ld	a4,0(a5)
    5c60:	00e7e463          	bltu	a5,a4,5c68 <free+0x40>
    5c64:	00e6ea63          	bltu	a3,a4,5c78 <free+0x50>
{
    5c68:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c6a:	fed7fae3          	bgeu	a5,a3,5c5e <free+0x36>
    5c6e:	6398                	ld	a4,0(a5)
    5c70:	00e6e463          	bltu	a3,a4,5c78 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c74:	fee7eae3          	bltu	a5,a4,5c68 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    5c78:	ff852583          	lw	a1,-8(a0)
    5c7c:	6390                	ld	a2,0(a5)
    5c7e:	02059813          	slli	a6,a1,0x20
    5c82:	01c85713          	srli	a4,a6,0x1c
    5c86:	9736                	add	a4,a4,a3
    5c88:	fae60ae3          	beq	a2,a4,5c3c <free+0x14>
    bp->s.ptr = p->s.ptr;
    5c8c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    5c90:	4790                	lw	a2,8(a5)
    5c92:	02061593          	slli	a1,a2,0x20
    5c96:	01c5d713          	srli	a4,a1,0x1c
    5c9a:	973e                	add	a4,a4,a5
    5c9c:	fae689e3          	beq	a3,a4,5c4e <free+0x26>
  } else
    p->s.ptr = bp;
    5ca0:	e394                	sd	a3,0(a5)
  freep = p;
    5ca2:	00002717          	auipc	a4,0x2
    5ca6:	6ef73723          	sd	a5,1774(a4) # 8390 <freep>
}
    5caa:	6422                	ld	s0,8(sp)
    5cac:	0141                	addi	sp,sp,16
    5cae:	8082                	ret

0000000000005cb0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    5cb0:	7139                	addi	sp,sp,-64
    5cb2:	fc06                	sd	ra,56(sp)
    5cb4:	f822                	sd	s0,48(sp)
    5cb6:	f426                	sd	s1,40(sp)
    5cb8:	f04a                	sd	s2,32(sp)
    5cba:	ec4e                	sd	s3,24(sp)
    5cbc:	e852                	sd	s4,16(sp)
    5cbe:	e456                	sd	s5,8(sp)
    5cc0:	e05a                	sd	s6,0(sp)
    5cc2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    5cc4:	02051493          	slli	s1,a0,0x20
    5cc8:	9081                	srli	s1,s1,0x20
    5cca:	04bd                	addi	s1,s1,15
    5ccc:	8091                	srli	s1,s1,0x4
    5cce:	0014899b          	addiw	s3,s1,1
    5cd2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    5cd4:	00002517          	auipc	a0,0x2
    5cd8:	6bc53503          	ld	a0,1724(a0) # 8390 <freep>
    5cdc:	c515                	beqz	a0,5d08 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5cde:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5ce0:	4798                	lw	a4,8(a5)
    5ce2:	02977f63          	bgeu	a4,s1,5d20 <malloc+0x70>
    5ce6:	8a4e                	mv	s4,s3
    5ce8:	0009871b          	sext.w	a4,s3
    5cec:	6685                	lui	a3,0x1
    5cee:	00d77363          	bgeu	a4,a3,5cf4 <malloc+0x44>
    5cf2:	6a05                	lui	s4,0x1
    5cf4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    5cf8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    5cfc:	00002917          	auipc	s2,0x2
    5d00:	69490913          	addi	s2,s2,1684 # 8390 <freep>
  if(p == (char*)-1)
    5d04:	5afd                	li	s5,-1
    5d06:	a895                	j	5d7a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    5d08:	00009797          	auipc	a5,0x9
    5d0c:	ea878793          	addi	a5,a5,-344 # ebb0 <base>
    5d10:	00002717          	auipc	a4,0x2
    5d14:	68f73023          	sd	a5,1664(a4) # 8390 <freep>
    5d18:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    5d1a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    5d1e:	b7e1                	j	5ce6 <malloc+0x36>
      if(p->s.size == nunits)
    5d20:	02e48c63          	beq	s1,a4,5d58 <malloc+0xa8>
        p->s.size -= nunits;
    5d24:	4137073b          	subw	a4,a4,s3
    5d28:	c798                	sw	a4,8(a5)
        p += p->s.size;
    5d2a:	02071693          	slli	a3,a4,0x20
    5d2e:	01c6d713          	srli	a4,a3,0x1c
    5d32:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    5d34:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    5d38:	00002717          	auipc	a4,0x2
    5d3c:	64a73c23          	sd	a0,1624(a4) # 8390 <freep>
      return (void*)(p + 1);
    5d40:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    5d44:	70e2                	ld	ra,56(sp)
    5d46:	7442                	ld	s0,48(sp)
    5d48:	74a2                	ld	s1,40(sp)
    5d4a:	7902                	ld	s2,32(sp)
    5d4c:	69e2                	ld	s3,24(sp)
    5d4e:	6a42                	ld	s4,16(sp)
    5d50:	6aa2                	ld	s5,8(sp)
    5d52:	6b02                	ld	s6,0(sp)
    5d54:	6121                	addi	sp,sp,64
    5d56:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    5d58:	6398                	ld	a4,0(a5)
    5d5a:	e118                	sd	a4,0(a0)
    5d5c:	bff1                	j	5d38 <malloc+0x88>
  hp->s.size = nu;
    5d5e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    5d62:	0541                	addi	a0,a0,16
    5d64:	00000097          	auipc	ra,0x0
    5d68:	ec4080e7          	jalr	-316(ra) # 5c28 <free>
  return freep;
    5d6c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    5d70:	d971                	beqz	a0,5d44 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5d72:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5d74:	4798                	lw	a4,8(a5)
    5d76:	fa9775e3          	bgeu	a4,s1,5d20 <malloc+0x70>
    if(p == freep)
    5d7a:	00093703          	ld	a4,0(s2)
    5d7e:	853e                	mv	a0,a5
    5d80:	fef719e3          	bne	a4,a5,5d72 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    5d84:	8552                	mv	a0,s4
    5d86:	00000097          	auipc	ra,0x0
    5d8a:	b22080e7          	jalr	-1246(ra) # 58a8 <sbrk>
  if(p == (char*)-1)
    5d8e:	fd5518e3          	bne	a0,s5,5d5e <malloc+0xae>
        return 0;
    5d92:	4501                	li	a0,0
    5d94:	bf45                	j	5d44 <malloc+0x94>
