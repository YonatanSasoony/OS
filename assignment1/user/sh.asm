
user/_sh:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <getcmd>:
  exit(0);
}

int
getcmd(char *buf, int nbuf)
{
       0:	1101                	addi	sp,sp,-32
       2:	ec06                	sd	ra,24(sp)
       4:	e822                	sd	s0,16(sp)
       6:	e426                	sd	s1,8(sp)
       8:	e04a                	sd	s2,0(sp)
       a:	1000                	addi	s0,sp,32
       c:	84aa                	mv	s1,a0
       e:	892e                	mv	s2,a1
  fprintf(2, "$ ");
      10:	00001597          	auipc	a1,0x1
      14:	36058593          	addi	a1,a1,864 # 1370 <malloc+0xec>
      18:	4509                	li	a0,2
      1a:	00001097          	auipc	ra,0x1
      1e:	17e080e7          	jalr	382(ra) # 1198 <fprintf>
  memset(buf, 0, nbuf);
      22:	864a                	mv	a2,s2
      24:	4581                	li	a1,0
      26:	8526                	mv	a0,s1
      28:	00001097          	auipc	ra,0x1
      2c:	c22080e7          	jalr	-990(ra) # c4a <memset>
  gets(buf, nbuf);
      30:	85ca                	mv	a1,s2
      32:	8526                	mv	a0,s1
      34:	00001097          	auipc	ra,0x1
      38:	c5c080e7          	jalr	-932(ra) # c90 <gets>
  if(buf[0] == 0) // EOF
      3c:	0004c503          	lbu	a0,0(s1)
      40:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
      44:	40a00533          	neg	a0,a0
      48:	60e2                	ld	ra,24(sp)
      4a:	6442                	ld	s0,16(sp)
      4c:	64a2                	ld	s1,8(sp)
      4e:	6902                	ld	s2,0(sp)
      50:	6105                	addi	sp,sp,32
      52:	8082                	ret

0000000000000054 <panic>:
  exit(0);
}

void
panic(char *s)
{
      54:	1141                	addi	sp,sp,-16
      56:	e406                	sd	ra,8(sp)
      58:	e022                	sd	s0,0(sp)
      5a:	0800                	addi	s0,sp,16
      5c:	862a                	mv	a2,a0
  fprintf(2, "%s\n", s);
      5e:	00001597          	auipc	a1,0x1
      62:	31a58593          	addi	a1,a1,794 # 1378 <malloc+0xf4>
      66:	4509                	li	a0,2
      68:	00001097          	auipc	ra,0x1
      6c:	130080e7          	jalr	304(ra) # 1198 <fprintf>
  exit(1);
      70:	4505                	li	a0,1
      72:	00001097          	auipc	ra,0x1
      76:	dd4080e7          	jalr	-556(ra) # e46 <exit>

000000000000007a <fork1>:
}

int
fork1(void)
{
      7a:	1141                	addi	sp,sp,-16
      7c:	e406                	sd	ra,8(sp)
      7e:	e022                	sd	s0,0(sp)
      80:	0800                	addi	s0,sp,16
  int pid;

  pid = fork();
      82:	00001097          	auipc	ra,0x1
      86:	dbc080e7          	jalr	-580(ra) # e3e <fork>
  if(pid == -1)
      8a:	57fd                	li	a5,-1
      8c:	00f50663          	beq	a0,a5,98 <fork1+0x1e>
    panic("fork");
  return pid;
}
      90:	60a2                	ld	ra,8(sp)
      92:	6402                	ld	s0,0(sp)
      94:	0141                	addi	sp,sp,16
      96:	8082                	ret
    panic("fork");
      98:	00001517          	auipc	a0,0x1
      9c:	2e850513          	addi	a0,a0,744 # 1380 <malloc+0xfc>
      a0:	00000097          	auipc	ra,0x0
      a4:	fb4080e7          	jalr	-76(ra) # 54 <panic>

00000000000000a8 <runcmd>:
{
      a8:	da010113          	addi	sp,sp,-608
      ac:	24113c23          	sd	ra,600(sp)
      b0:	24813823          	sd	s0,592(sp)
      b4:	24913423          	sd	s1,584(sp)
      b8:	25213023          	sd	s2,576(sp)
      bc:	23313c23          	sd	s3,568(sp)
      c0:	23413823          	sd	s4,560(sp)
      c4:	23513423          	sd	s5,552(sp)
      c8:	23613023          	sd	s6,544(sp)
      cc:	21713c23          	sd	s7,536(sp)
      d0:	1480                	addi	s0,sp,608
  if(cmd == 0)
      d2:	c10d                	beqz	a0,f4 <runcmd+0x4c>
      d4:	84aa                	mv	s1,a0
  switch(cmd->type){
      d6:	4118                	lw	a4,0(a0)
      d8:	4795                	li	a5,5
      da:	02e7e263          	bltu	a5,a4,fe <runcmd+0x56>
      de:	00056783          	lwu	a5,0(a0)
      e2:	078a                	slli	a5,a5,0x2
      e4:	00001717          	auipc	a4,0x1
      e8:	3a470713          	addi	a4,a4,932 # 1488 <malloc+0x204>
      ec:	97ba                	add	a5,a5,a4
      ee:	439c                	lw	a5,0(a5)
      f0:	97ba                	add	a5,a5,a4
      f2:	8782                	jr	a5
    exit(1);
      f4:	4505                	li	a0,1
      f6:	00001097          	auipc	ra,0x1
      fa:	d50080e7          	jalr	-688(ra) # e46 <exit>
    panic("runcmd");
      fe:	00001517          	auipc	a0,0x1
     102:	28a50513          	addi	a0,a0,650 # 1388 <malloc+0x104>
     106:	00000097          	auipc	ra,0x0
     10a:	f4e080e7          	jalr	-178(ra) # 54 <panic>
    if(ecmd->argv[0] == 0)
     10e:	6508                	ld	a0,8(a0)
     110:	c90d                	beqz	a0,142 <runcmd+0x9a>
    exec(ecmd->argv[0], ecmd->argv);
     112:	00848b13          	addi	s6,s1,8
     116:	85da                	mv	a1,s6
     118:	00001097          	auipc	ra,0x1
     11c:	d66080e7          	jalr	-666(ra) # e7e <exec>
    if((fd = open(PATH, O_RDONLY)) >= 0){
     120:	4581                	li	a1,0
     122:	00001517          	auipc	a0,0x1
     126:	26e50513          	addi	a0,a0,622 # 1390 <malloc+0x10c>
     12a:	00001097          	auipc	ra,0x1
     12e:	d5c080e7          	jalr	-676(ra) # e86 <open>
     132:	8a2a                	mv	s4,a0
      int buf_cnt = 0;
     134:	4981                	li	s3,0
    if((fd = open(PATH, O_RDONLY)) >= 0){
     136:	04054b63          	bltz	a0,18c <runcmd+0xe4>
        else if( (char)(*(buf+buf_cnt)) == ':' ){
     13a:	03a00a93          	li	s5,58
          buf_cnt = 0;
     13e:	4b81                	li	s7,0
     140:	a039                	j	14e <runcmd+0xa6>
      exit(1);
     142:	4505                	li	a0,1
     144:	00001097          	auipc	ra,0x1
     148:	d02080e7          	jalr	-766(ra) # e46 <exit>
          buf_cnt++;
     14c:	2985                	addiw	s3,s3,1
        read_cnt = read(fd, buf+buf_cnt, 1);
     14e:	da840793          	addi	a5,s0,-600
     152:	01378933          	add	s2,a5,s3
     156:	4605                	li	a2,1
     158:	85ca                	mv	a1,s2
     15a:	8552                	mv	a0,s4
     15c:	00001097          	auipc	ra,0x1
     160:	d02080e7          	jalr	-766(ra) # e5e <read>
        if (read_cnt == 0){
     164:	c505                	beqz	a0,18c <runcmd+0xe4>
        else if( (char)(*(buf+buf_cnt)) == ':' ){
     166:	00094783          	lbu	a5,0(s2)
     16a:	ff5791e3          	bne	a5,s5,14c <runcmd+0xa4>
          strcpy(buf+buf_cnt, ecmd->argv[0]);
     16e:	648c                	ld	a1,8(s1)
     170:	854a                	mv	a0,s2
     172:	00001097          	auipc	ra,0x1
     176:	a66080e7          	jalr	-1434(ra) # bd8 <strcpy>
          exec(buf, ecmd->argv);
     17a:	85da                	mv	a1,s6
     17c:	da840513          	addi	a0,s0,-600
     180:	00001097          	auipc	ra,0x1
     184:	cfe080e7          	jalr	-770(ra) # e7e <exec>
          buf_cnt = 0;
     188:	89de                	mv	s3,s7
     18a:	b7d1                	j	14e <runcmd+0xa6>
    fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     18c:	6490                	ld	a2,8(s1)
     18e:	00001597          	auipc	a1,0x1
     192:	20a58593          	addi	a1,a1,522 # 1398 <malloc+0x114>
     196:	4509                	li	a0,2
     198:	00001097          	auipc	ra,0x1
     19c:	000080e7          	jalr	ra # 1198 <fprintf>
  exit(0);
     1a0:	4501                	li	a0,0
     1a2:	00001097          	auipc	ra,0x1
     1a6:	ca4080e7          	jalr	-860(ra) # e46 <exit>
    close(rcmd->fd);
     1aa:	5148                	lw	a0,36(a0)
     1ac:	00001097          	auipc	ra,0x1
     1b0:	cc2080e7          	jalr	-830(ra) # e6e <close>
    if(open(rcmd->file, rcmd->mode) < 0){
     1b4:	508c                	lw	a1,32(s1)
     1b6:	6888                	ld	a0,16(s1)
     1b8:	00001097          	auipc	ra,0x1
     1bc:	cce080e7          	jalr	-818(ra) # e86 <open>
     1c0:	00054763          	bltz	a0,1ce <runcmd+0x126>
    runcmd(rcmd->cmd);
     1c4:	6488                	ld	a0,8(s1)
     1c6:	00000097          	auipc	ra,0x0
     1ca:	ee2080e7          	jalr	-286(ra) # a8 <runcmd>
      fprintf(2, "open %s failed\n", rcmd->file);
     1ce:	6890                	ld	a2,16(s1)
     1d0:	00001597          	auipc	a1,0x1
     1d4:	1d858593          	addi	a1,a1,472 # 13a8 <malloc+0x124>
     1d8:	4509                	li	a0,2
     1da:	00001097          	auipc	ra,0x1
     1de:	fbe080e7          	jalr	-66(ra) # 1198 <fprintf>
      exit(1);
     1e2:	4505                	li	a0,1
     1e4:	00001097          	auipc	ra,0x1
     1e8:	c62080e7          	jalr	-926(ra) # e46 <exit>
    if(fork1() == 0)
     1ec:	00000097          	auipc	ra,0x0
     1f0:	e8e080e7          	jalr	-370(ra) # 7a <fork1>
     1f4:	c919                	beqz	a0,20a <runcmd+0x162>
    wait(0);
     1f6:	4501                	li	a0,0
     1f8:	00001097          	auipc	ra,0x1
     1fc:	c56080e7          	jalr	-938(ra) # e4e <wait>
    runcmd(lcmd->right);
     200:	6888                	ld	a0,16(s1)
     202:	00000097          	auipc	ra,0x0
     206:	ea6080e7          	jalr	-346(ra) # a8 <runcmd>
      runcmd(lcmd->left);
     20a:	6488                	ld	a0,8(s1)
     20c:	00000097          	auipc	ra,0x0
     210:	e9c080e7          	jalr	-356(ra) # a8 <runcmd>
    if(pipe(p) < 0)
     214:	fa840513          	addi	a0,s0,-88
     218:	00001097          	auipc	ra,0x1
     21c:	c3e080e7          	jalr	-962(ra) # e56 <pipe>
     220:	04054363          	bltz	a0,266 <runcmd+0x1be>
    if(fork1() == 0){
     224:	00000097          	auipc	ra,0x0
     228:	e56080e7          	jalr	-426(ra) # 7a <fork1>
     22c:	c529                	beqz	a0,276 <runcmd+0x1ce>
    if(fork1() == 0){
     22e:	00000097          	auipc	ra,0x0
     232:	e4c080e7          	jalr	-436(ra) # 7a <fork1>
     236:	cd25                	beqz	a0,2ae <runcmd+0x206>
    close(p[0]);
     238:	fa842503          	lw	a0,-88(s0)
     23c:	00001097          	auipc	ra,0x1
     240:	c32080e7          	jalr	-974(ra) # e6e <close>
    close(p[1]);
     244:	fac42503          	lw	a0,-84(s0)
     248:	00001097          	auipc	ra,0x1
     24c:	c26080e7          	jalr	-986(ra) # e6e <close>
    wait(0);
     250:	4501                	li	a0,0
     252:	00001097          	auipc	ra,0x1
     256:	bfc080e7          	jalr	-1028(ra) # e4e <wait>
    wait(0);
     25a:	4501                	li	a0,0
     25c:	00001097          	auipc	ra,0x1
     260:	bf2080e7          	jalr	-1038(ra) # e4e <wait>
    break;
     264:	bf35                	j	1a0 <runcmd+0xf8>
      panic("pipe");
     266:	00001517          	auipc	a0,0x1
     26a:	15250513          	addi	a0,a0,338 # 13b8 <malloc+0x134>
     26e:	00000097          	auipc	ra,0x0
     272:	de6080e7          	jalr	-538(ra) # 54 <panic>
      close(1);
     276:	4505                	li	a0,1
     278:	00001097          	auipc	ra,0x1
     27c:	bf6080e7          	jalr	-1034(ra) # e6e <close>
      dup(p[1]);
     280:	fac42503          	lw	a0,-84(s0)
     284:	00001097          	auipc	ra,0x1
     288:	c3a080e7          	jalr	-966(ra) # ebe <dup>
      close(p[0]);
     28c:	fa842503          	lw	a0,-88(s0)
     290:	00001097          	auipc	ra,0x1
     294:	bde080e7          	jalr	-1058(ra) # e6e <close>
      close(p[1]);
     298:	fac42503          	lw	a0,-84(s0)
     29c:	00001097          	auipc	ra,0x1
     2a0:	bd2080e7          	jalr	-1070(ra) # e6e <close>
      runcmd(pcmd->left);
     2a4:	6488                	ld	a0,8(s1)
     2a6:	00000097          	auipc	ra,0x0
     2aa:	e02080e7          	jalr	-510(ra) # a8 <runcmd>
      close(0);
     2ae:	00001097          	auipc	ra,0x1
     2b2:	bc0080e7          	jalr	-1088(ra) # e6e <close>
      dup(p[0]);
     2b6:	fa842503          	lw	a0,-88(s0)
     2ba:	00001097          	auipc	ra,0x1
     2be:	c04080e7          	jalr	-1020(ra) # ebe <dup>
      close(p[0]);
     2c2:	fa842503          	lw	a0,-88(s0)
     2c6:	00001097          	auipc	ra,0x1
     2ca:	ba8080e7          	jalr	-1112(ra) # e6e <close>
      close(p[1]);
     2ce:	fac42503          	lw	a0,-84(s0)
     2d2:	00001097          	auipc	ra,0x1
     2d6:	b9c080e7          	jalr	-1124(ra) # e6e <close>
      runcmd(pcmd->right);
     2da:	6888                	ld	a0,16(s1)
     2dc:	00000097          	auipc	ra,0x0
     2e0:	dcc080e7          	jalr	-564(ra) # a8 <runcmd>
    if(fork1() == 0)
     2e4:	00000097          	auipc	ra,0x0
     2e8:	d96080e7          	jalr	-618(ra) # 7a <fork1>
     2ec:	ea051ae3          	bnez	a0,1a0 <runcmd+0xf8>
      runcmd(bcmd->cmd);
     2f0:	6488                	ld	a0,8(s1)
     2f2:	00000097          	auipc	ra,0x0
     2f6:	db6080e7          	jalr	-586(ra) # a8 <runcmd>

00000000000002fa <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     2fa:	1101                	addi	sp,sp,-32
     2fc:	ec06                	sd	ra,24(sp)
     2fe:	e822                	sd	s0,16(sp)
     300:	e426                	sd	s1,8(sp)
     302:	1000                	addi	s0,sp,32
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     304:	0a800513          	li	a0,168
     308:	00001097          	auipc	ra,0x1
     30c:	f7c080e7          	jalr	-132(ra) # 1284 <malloc>
     310:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     312:	0a800613          	li	a2,168
     316:	4581                	li	a1,0
     318:	00001097          	auipc	ra,0x1
     31c:	932080e7          	jalr	-1742(ra) # c4a <memset>
  cmd->type = EXEC;
     320:	4785                	li	a5,1
     322:	c09c                	sw	a5,0(s1)
  return (struct cmd*)cmd;
}
     324:	8526                	mv	a0,s1
     326:	60e2                	ld	ra,24(sp)
     328:	6442                	ld	s0,16(sp)
     32a:	64a2                	ld	s1,8(sp)
     32c:	6105                	addi	sp,sp,32
     32e:	8082                	ret

0000000000000330 <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     330:	7139                	addi	sp,sp,-64
     332:	fc06                	sd	ra,56(sp)
     334:	f822                	sd	s0,48(sp)
     336:	f426                	sd	s1,40(sp)
     338:	f04a                	sd	s2,32(sp)
     33a:	ec4e                	sd	s3,24(sp)
     33c:	e852                	sd	s4,16(sp)
     33e:	e456                	sd	s5,8(sp)
     340:	e05a                	sd	s6,0(sp)
     342:	0080                	addi	s0,sp,64
     344:	8b2a                	mv	s6,a0
     346:	8aae                	mv	s5,a1
     348:	8a32                	mv	s4,a2
     34a:	89b6                	mv	s3,a3
     34c:	893a                	mv	s2,a4
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     34e:	02800513          	li	a0,40
     352:	00001097          	auipc	ra,0x1
     356:	f32080e7          	jalr	-206(ra) # 1284 <malloc>
     35a:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     35c:	02800613          	li	a2,40
     360:	4581                	li	a1,0
     362:	00001097          	auipc	ra,0x1
     366:	8e8080e7          	jalr	-1816(ra) # c4a <memset>
  cmd->type = REDIR;
     36a:	4789                	li	a5,2
     36c:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     36e:	0164b423          	sd	s6,8(s1)
  cmd->file = file;
     372:	0154b823          	sd	s5,16(s1)
  cmd->efile = efile;
     376:	0144bc23          	sd	s4,24(s1)
  cmd->mode = mode;
     37a:	0334a023          	sw	s3,32(s1)
  cmd->fd = fd;
     37e:	0324a223          	sw	s2,36(s1)
  return (struct cmd*)cmd;
}
     382:	8526                	mv	a0,s1
     384:	70e2                	ld	ra,56(sp)
     386:	7442                	ld	s0,48(sp)
     388:	74a2                	ld	s1,40(sp)
     38a:	7902                	ld	s2,32(sp)
     38c:	69e2                	ld	s3,24(sp)
     38e:	6a42                	ld	s4,16(sp)
     390:	6aa2                	ld	s5,8(sp)
     392:	6b02                	ld	s6,0(sp)
     394:	6121                	addi	sp,sp,64
     396:	8082                	ret

0000000000000398 <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     398:	7179                	addi	sp,sp,-48
     39a:	f406                	sd	ra,40(sp)
     39c:	f022                	sd	s0,32(sp)
     39e:	ec26                	sd	s1,24(sp)
     3a0:	e84a                	sd	s2,16(sp)
     3a2:	e44e                	sd	s3,8(sp)
     3a4:	1800                	addi	s0,sp,48
     3a6:	89aa                	mv	s3,a0
     3a8:	892e                	mv	s2,a1
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3aa:	4561                	li	a0,24
     3ac:	00001097          	auipc	ra,0x1
     3b0:	ed8080e7          	jalr	-296(ra) # 1284 <malloc>
     3b4:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3b6:	4661                	li	a2,24
     3b8:	4581                	li	a1,0
     3ba:	00001097          	auipc	ra,0x1
     3be:	890080e7          	jalr	-1904(ra) # c4a <memset>
  cmd->type = PIPE;
     3c2:	478d                	li	a5,3
     3c4:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     3c6:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     3ca:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     3ce:	8526                	mv	a0,s1
     3d0:	70a2                	ld	ra,40(sp)
     3d2:	7402                	ld	s0,32(sp)
     3d4:	64e2                	ld	s1,24(sp)
     3d6:	6942                	ld	s2,16(sp)
     3d8:	69a2                	ld	s3,8(sp)
     3da:	6145                	addi	sp,sp,48
     3dc:	8082                	ret

00000000000003de <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     3de:	7179                	addi	sp,sp,-48
     3e0:	f406                	sd	ra,40(sp)
     3e2:	f022                	sd	s0,32(sp)
     3e4:	ec26                	sd	s1,24(sp)
     3e6:	e84a                	sd	s2,16(sp)
     3e8:	e44e                	sd	s3,8(sp)
     3ea:	1800                	addi	s0,sp,48
     3ec:	89aa                	mv	s3,a0
     3ee:	892e                	mv	s2,a1
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3f0:	4561                	li	a0,24
     3f2:	00001097          	auipc	ra,0x1
     3f6:	e92080e7          	jalr	-366(ra) # 1284 <malloc>
     3fa:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3fc:	4661                	li	a2,24
     3fe:	4581                	li	a1,0
     400:	00001097          	auipc	ra,0x1
     404:	84a080e7          	jalr	-1974(ra) # c4a <memset>
  cmd->type = LIST;
     408:	4791                	li	a5,4
     40a:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     40c:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     410:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     414:	8526                	mv	a0,s1
     416:	70a2                	ld	ra,40(sp)
     418:	7402                	ld	s0,32(sp)
     41a:	64e2                	ld	s1,24(sp)
     41c:	6942                	ld	s2,16(sp)
     41e:	69a2                	ld	s3,8(sp)
     420:	6145                	addi	sp,sp,48
     422:	8082                	ret

0000000000000424 <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     424:	1101                	addi	sp,sp,-32
     426:	ec06                	sd	ra,24(sp)
     428:	e822                	sd	s0,16(sp)
     42a:	e426                	sd	s1,8(sp)
     42c:	e04a                	sd	s2,0(sp)
     42e:	1000                	addi	s0,sp,32
     430:	892a                	mv	s2,a0
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     432:	4541                	li	a0,16
     434:	00001097          	auipc	ra,0x1
     438:	e50080e7          	jalr	-432(ra) # 1284 <malloc>
     43c:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     43e:	4641                	li	a2,16
     440:	4581                	li	a1,0
     442:	00001097          	auipc	ra,0x1
     446:	808080e7          	jalr	-2040(ra) # c4a <memset>
  cmd->type = BACK;
     44a:	4795                	li	a5,5
     44c:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     44e:	0124b423          	sd	s2,8(s1)
  return (struct cmd*)cmd;
}
     452:	8526                	mv	a0,s1
     454:	60e2                	ld	ra,24(sp)
     456:	6442                	ld	s0,16(sp)
     458:	64a2                	ld	s1,8(sp)
     45a:	6902                	ld	s2,0(sp)
     45c:	6105                	addi	sp,sp,32
     45e:	8082                	ret

0000000000000460 <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     460:	7139                	addi	sp,sp,-64
     462:	fc06                	sd	ra,56(sp)
     464:	f822                	sd	s0,48(sp)
     466:	f426                	sd	s1,40(sp)
     468:	f04a                	sd	s2,32(sp)
     46a:	ec4e                	sd	s3,24(sp)
     46c:	e852                	sd	s4,16(sp)
     46e:	e456                	sd	s5,8(sp)
     470:	e05a                	sd	s6,0(sp)
     472:	0080                	addi	s0,sp,64
     474:	8a2a                	mv	s4,a0
     476:	892e                	mv	s2,a1
     478:	8ab2                	mv	s5,a2
     47a:	8b36                	mv	s6,a3
  char *s;
  int ret;

  s = *ps;
     47c:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     47e:	00001997          	auipc	s3,0x1
     482:	06298993          	addi	s3,s3,98 # 14e0 <whitespace>
     486:	00b4fd63          	bgeu	s1,a1,4a0 <gettoken+0x40>
     48a:	0004c583          	lbu	a1,0(s1)
     48e:	854e                	mv	a0,s3
     490:	00000097          	auipc	ra,0x0
     494:	7dc080e7          	jalr	2012(ra) # c6c <strchr>
     498:	c501                	beqz	a0,4a0 <gettoken+0x40>
    s++;
     49a:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     49c:	fe9917e3          	bne	s2,s1,48a <gettoken+0x2a>
  if(q)
     4a0:	000a8463          	beqz	s5,4a8 <gettoken+0x48>
    *q = s;
     4a4:	009ab023          	sd	s1,0(s5)
  ret = *s;
     4a8:	0004c783          	lbu	a5,0(s1)
     4ac:	00078a9b          	sext.w	s5,a5
  switch(*s){
     4b0:	03c00713          	li	a4,60
     4b4:	06f76563          	bltu	a4,a5,51e <gettoken+0xbe>
     4b8:	03a00713          	li	a4,58
     4bc:	00f76e63          	bltu	a4,a5,4d8 <gettoken+0x78>
     4c0:	cf89                	beqz	a5,4da <gettoken+0x7a>
     4c2:	02600713          	li	a4,38
     4c6:	00e78963          	beq	a5,a4,4d8 <gettoken+0x78>
     4ca:	fd87879b          	addiw	a5,a5,-40
     4ce:	0ff7f793          	andi	a5,a5,255
     4d2:	4705                	li	a4,1
     4d4:	06f76c63          	bltu	a4,a5,54c <gettoken+0xec>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     4d8:	0485                	addi	s1,s1,1
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     4da:	000b0463          	beqz	s6,4e2 <gettoken+0x82>
    *eq = s;
     4de:	009b3023          	sd	s1,0(s6)

  while(s < es && strchr(whitespace, *s))
     4e2:	00001997          	auipc	s3,0x1
     4e6:	ffe98993          	addi	s3,s3,-2 # 14e0 <whitespace>
     4ea:	0124fd63          	bgeu	s1,s2,504 <gettoken+0xa4>
     4ee:	0004c583          	lbu	a1,0(s1)
     4f2:	854e                	mv	a0,s3
     4f4:	00000097          	auipc	ra,0x0
     4f8:	778080e7          	jalr	1912(ra) # c6c <strchr>
     4fc:	c501                	beqz	a0,504 <gettoken+0xa4>
    s++;
     4fe:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     500:	fe9917e3          	bne	s2,s1,4ee <gettoken+0x8e>
  *ps = s;
     504:	009a3023          	sd	s1,0(s4)
  return ret;
}
     508:	8556                	mv	a0,s5
     50a:	70e2                	ld	ra,56(sp)
     50c:	7442                	ld	s0,48(sp)
     50e:	74a2                	ld	s1,40(sp)
     510:	7902                	ld	s2,32(sp)
     512:	69e2                	ld	s3,24(sp)
     514:	6a42                	ld	s4,16(sp)
     516:	6aa2                	ld	s5,8(sp)
     518:	6b02                	ld	s6,0(sp)
     51a:	6121                	addi	sp,sp,64
     51c:	8082                	ret
  switch(*s){
     51e:	03e00713          	li	a4,62
     522:	02e79163          	bne	a5,a4,544 <gettoken+0xe4>
    s++;
     526:	00148693          	addi	a3,s1,1
    if(*s == '>'){
     52a:	0014c703          	lbu	a4,1(s1)
     52e:	03e00793          	li	a5,62
      s++;
     532:	0489                	addi	s1,s1,2
      ret = '+';
     534:	02b00a93          	li	s5,43
    if(*s == '>'){
     538:	faf701e3          	beq	a4,a5,4da <gettoken+0x7a>
    s++;
     53c:	84b6                	mv	s1,a3
  ret = *s;
     53e:	03e00a93          	li	s5,62
     542:	bf61                	j	4da <gettoken+0x7a>
  switch(*s){
     544:	07c00713          	li	a4,124
     548:	f8e788e3          	beq	a5,a4,4d8 <gettoken+0x78>
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     54c:	00001997          	auipc	s3,0x1
     550:	f9498993          	addi	s3,s3,-108 # 14e0 <whitespace>
     554:	00001a97          	auipc	s5,0x1
     558:	f84a8a93          	addi	s5,s5,-124 # 14d8 <symbols>
     55c:	0324f563          	bgeu	s1,s2,586 <gettoken+0x126>
     560:	0004c583          	lbu	a1,0(s1)
     564:	854e                	mv	a0,s3
     566:	00000097          	auipc	ra,0x0
     56a:	706080e7          	jalr	1798(ra) # c6c <strchr>
     56e:	e505                	bnez	a0,596 <gettoken+0x136>
     570:	0004c583          	lbu	a1,0(s1)
     574:	8556                	mv	a0,s5
     576:	00000097          	auipc	ra,0x0
     57a:	6f6080e7          	jalr	1782(ra) # c6c <strchr>
     57e:	e909                	bnez	a0,590 <gettoken+0x130>
      s++;
     580:	0485                	addi	s1,s1,1
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     582:	fc991fe3          	bne	s2,s1,560 <gettoken+0x100>
  if(eq)
     586:	06100a93          	li	s5,97
     58a:	f40b1ae3          	bnez	s6,4de <gettoken+0x7e>
     58e:	bf9d                	j	504 <gettoken+0xa4>
    ret = 'a';
     590:	06100a93          	li	s5,97
     594:	b799                	j	4da <gettoken+0x7a>
     596:	06100a93          	li	s5,97
     59a:	b781                	j	4da <gettoken+0x7a>

000000000000059c <peek>:

int
peek(char **ps, char *es, char *toks)
{
     59c:	7139                	addi	sp,sp,-64
     59e:	fc06                	sd	ra,56(sp)
     5a0:	f822                	sd	s0,48(sp)
     5a2:	f426                	sd	s1,40(sp)
     5a4:	f04a                	sd	s2,32(sp)
     5a6:	ec4e                	sd	s3,24(sp)
     5a8:	e852                	sd	s4,16(sp)
     5aa:	e456                	sd	s5,8(sp)
     5ac:	0080                	addi	s0,sp,64
     5ae:	8a2a                	mv	s4,a0
     5b0:	892e                	mv	s2,a1
     5b2:	8ab2                	mv	s5,a2
  char *s;

  s = *ps;
     5b4:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     5b6:	00001997          	auipc	s3,0x1
     5ba:	f2a98993          	addi	s3,s3,-214 # 14e0 <whitespace>
     5be:	00b4fd63          	bgeu	s1,a1,5d8 <peek+0x3c>
     5c2:	0004c583          	lbu	a1,0(s1)
     5c6:	854e                	mv	a0,s3
     5c8:	00000097          	auipc	ra,0x0
     5cc:	6a4080e7          	jalr	1700(ra) # c6c <strchr>
     5d0:	c501                	beqz	a0,5d8 <peek+0x3c>
    s++;
     5d2:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     5d4:	fe9917e3          	bne	s2,s1,5c2 <peek+0x26>
  *ps = s;
     5d8:	009a3023          	sd	s1,0(s4)
  return *s && strchr(toks, *s);
     5dc:	0004c583          	lbu	a1,0(s1)
     5e0:	4501                	li	a0,0
     5e2:	e991                	bnez	a1,5f6 <peek+0x5a>
}
     5e4:	70e2                	ld	ra,56(sp)
     5e6:	7442                	ld	s0,48(sp)
     5e8:	74a2                	ld	s1,40(sp)
     5ea:	7902                	ld	s2,32(sp)
     5ec:	69e2                	ld	s3,24(sp)
     5ee:	6a42                	ld	s4,16(sp)
     5f0:	6aa2                	ld	s5,8(sp)
     5f2:	6121                	addi	sp,sp,64
     5f4:	8082                	ret
  return *s && strchr(toks, *s);
     5f6:	8556                	mv	a0,s5
     5f8:	00000097          	auipc	ra,0x0
     5fc:	674080e7          	jalr	1652(ra) # c6c <strchr>
     600:	00a03533          	snez	a0,a0
     604:	b7c5                	j	5e4 <peek+0x48>

0000000000000606 <parseredirs>:
  return cmd;
}

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     606:	7159                	addi	sp,sp,-112
     608:	f486                	sd	ra,104(sp)
     60a:	f0a2                	sd	s0,96(sp)
     60c:	eca6                	sd	s1,88(sp)
     60e:	e8ca                	sd	s2,80(sp)
     610:	e4ce                	sd	s3,72(sp)
     612:	e0d2                	sd	s4,64(sp)
     614:	fc56                	sd	s5,56(sp)
     616:	f85a                	sd	s6,48(sp)
     618:	f45e                	sd	s7,40(sp)
     61a:	f062                	sd	s8,32(sp)
     61c:	ec66                	sd	s9,24(sp)
     61e:	1880                	addi	s0,sp,112
     620:	8a2a                	mv	s4,a0
     622:	89ae                	mv	s3,a1
     624:	8932                	mv	s2,a2
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     626:	00001b97          	auipc	s7,0x1
     62a:	dbab8b93          	addi	s7,s7,-582 # 13e0 <malloc+0x15c>
    tok = gettoken(ps, es, 0, 0);
    if(gettoken(ps, es, &q, &eq) != 'a')
     62e:	06100c13          	li	s8,97
      panic("missing file for redirection");
    switch(tok){
     632:	03c00c93          	li	s9,60
  while(peek(ps, es, "<>")){
     636:	a02d                	j	660 <parseredirs+0x5a>
      panic("missing file for redirection");
     638:	00001517          	auipc	a0,0x1
     63c:	d8850513          	addi	a0,a0,-632 # 13c0 <malloc+0x13c>
     640:	00000097          	auipc	ra,0x0
     644:	a14080e7          	jalr	-1516(ra) # 54 <panic>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     648:	4701                	li	a4,0
     64a:	4681                	li	a3,0
     64c:	f9043603          	ld	a2,-112(s0)
     650:	f9843583          	ld	a1,-104(s0)
     654:	8552                	mv	a0,s4
     656:	00000097          	auipc	ra,0x0
     65a:	cda080e7          	jalr	-806(ra) # 330 <redircmd>
     65e:	8a2a                	mv	s4,a0
    switch(tok){
     660:	03e00b13          	li	s6,62
     664:	02b00a93          	li	s5,43
  while(peek(ps, es, "<>")){
     668:	865e                	mv	a2,s7
     66a:	85ca                	mv	a1,s2
     66c:	854e                	mv	a0,s3
     66e:	00000097          	auipc	ra,0x0
     672:	f2e080e7          	jalr	-210(ra) # 59c <peek>
     676:	c925                	beqz	a0,6e6 <parseredirs+0xe0>
    tok = gettoken(ps, es, 0, 0);
     678:	4681                	li	a3,0
     67a:	4601                	li	a2,0
     67c:	85ca                	mv	a1,s2
     67e:	854e                	mv	a0,s3
     680:	00000097          	auipc	ra,0x0
     684:	de0080e7          	jalr	-544(ra) # 460 <gettoken>
     688:	84aa                	mv	s1,a0
    if(gettoken(ps, es, &q, &eq) != 'a')
     68a:	f9040693          	addi	a3,s0,-112
     68e:	f9840613          	addi	a2,s0,-104
     692:	85ca                	mv	a1,s2
     694:	854e                	mv	a0,s3
     696:	00000097          	auipc	ra,0x0
     69a:	dca080e7          	jalr	-566(ra) # 460 <gettoken>
     69e:	f9851de3          	bne	a0,s8,638 <parseredirs+0x32>
    switch(tok){
     6a2:	fb9483e3          	beq	s1,s9,648 <parseredirs+0x42>
     6a6:	03648263          	beq	s1,s6,6ca <parseredirs+0xc4>
     6aa:	fb549fe3          	bne	s1,s5,668 <parseredirs+0x62>
      break;
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
      break;
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     6ae:	4705                	li	a4,1
     6b0:	20100693          	li	a3,513
     6b4:	f9043603          	ld	a2,-112(s0)
     6b8:	f9843583          	ld	a1,-104(s0)
     6bc:	8552                	mv	a0,s4
     6be:	00000097          	auipc	ra,0x0
     6c2:	c72080e7          	jalr	-910(ra) # 330 <redircmd>
     6c6:	8a2a                	mv	s4,a0
      break;
     6c8:	bf61                	j	660 <parseredirs+0x5a>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
     6ca:	4705                	li	a4,1
     6cc:	60100693          	li	a3,1537
     6d0:	f9043603          	ld	a2,-112(s0)
     6d4:	f9843583          	ld	a1,-104(s0)
     6d8:	8552                	mv	a0,s4
     6da:	00000097          	auipc	ra,0x0
     6de:	c56080e7          	jalr	-938(ra) # 330 <redircmd>
     6e2:	8a2a                	mv	s4,a0
      break;
     6e4:	bfb5                	j	660 <parseredirs+0x5a>
    }
  }
  return cmd;
}
     6e6:	8552                	mv	a0,s4
     6e8:	70a6                	ld	ra,104(sp)
     6ea:	7406                	ld	s0,96(sp)
     6ec:	64e6                	ld	s1,88(sp)
     6ee:	6946                	ld	s2,80(sp)
     6f0:	69a6                	ld	s3,72(sp)
     6f2:	6a06                	ld	s4,64(sp)
     6f4:	7ae2                	ld	s5,56(sp)
     6f6:	7b42                	ld	s6,48(sp)
     6f8:	7ba2                	ld	s7,40(sp)
     6fa:	7c02                	ld	s8,32(sp)
     6fc:	6ce2                	ld	s9,24(sp)
     6fe:	6165                	addi	sp,sp,112
     700:	8082                	ret

0000000000000702 <parseexec>:
  return cmd;
}

struct cmd*
parseexec(char **ps, char *es)
{
     702:	7159                	addi	sp,sp,-112
     704:	f486                	sd	ra,104(sp)
     706:	f0a2                	sd	s0,96(sp)
     708:	eca6                	sd	s1,88(sp)
     70a:	e8ca                	sd	s2,80(sp)
     70c:	e4ce                	sd	s3,72(sp)
     70e:	e0d2                	sd	s4,64(sp)
     710:	fc56                	sd	s5,56(sp)
     712:	f85a                	sd	s6,48(sp)
     714:	f45e                	sd	s7,40(sp)
     716:	f062                	sd	s8,32(sp)
     718:	ec66                	sd	s9,24(sp)
     71a:	1880                	addi	s0,sp,112
     71c:	8a2a                	mv	s4,a0
     71e:	8aae                	mv	s5,a1
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;

  if(peek(ps, es, "("))
     720:	00001617          	auipc	a2,0x1
     724:	cc860613          	addi	a2,a2,-824 # 13e8 <malloc+0x164>
     728:	00000097          	auipc	ra,0x0
     72c:	e74080e7          	jalr	-396(ra) # 59c <peek>
     730:	e905                	bnez	a0,760 <parseexec+0x5e>
     732:	89aa                	mv	s3,a0
    return parseblock(ps, es);

  ret = execcmd();
     734:	00000097          	auipc	ra,0x0
     738:	bc6080e7          	jalr	-1082(ra) # 2fa <execcmd>
     73c:	8c2a                	mv	s8,a0
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
     73e:	8656                	mv	a2,s5
     740:	85d2                	mv	a1,s4
     742:	00000097          	auipc	ra,0x0
     746:	ec4080e7          	jalr	-316(ra) # 606 <parseredirs>
     74a:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     74c:	008c0913          	addi	s2,s8,8
     750:	00001b17          	auipc	s6,0x1
     754:	cb8b0b13          	addi	s6,s6,-840 # 1408 <malloc+0x184>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
      break;
    if(tok != 'a')
     758:	06100c93          	li	s9,97
      panic("syntax");
    cmd->argv[argc] = q;
    cmd->eargv[argc] = eq;
    argc++;
    if(argc >= MAXARGS)
     75c:	4ba9                	li	s7,10
  while(!peek(ps, es, "|)&;")){
     75e:	a0b1                	j	7aa <parseexec+0xa8>
    return parseblock(ps, es);
     760:	85d6                	mv	a1,s5
     762:	8552                	mv	a0,s4
     764:	00000097          	auipc	ra,0x0
     768:	1bc080e7          	jalr	444(ra) # 920 <parseblock>
     76c:	84aa                	mv	s1,a0
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
  cmd->eargv[argc] = 0;
  return ret;
}
     76e:	8526                	mv	a0,s1
     770:	70a6                	ld	ra,104(sp)
     772:	7406                	ld	s0,96(sp)
     774:	64e6                	ld	s1,88(sp)
     776:	6946                	ld	s2,80(sp)
     778:	69a6                	ld	s3,72(sp)
     77a:	6a06                	ld	s4,64(sp)
     77c:	7ae2                	ld	s5,56(sp)
     77e:	7b42                	ld	s6,48(sp)
     780:	7ba2                	ld	s7,40(sp)
     782:	7c02                	ld	s8,32(sp)
     784:	6ce2                	ld	s9,24(sp)
     786:	6165                	addi	sp,sp,112
     788:	8082                	ret
      panic("syntax");
     78a:	00001517          	auipc	a0,0x1
     78e:	c6650513          	addi	a0,a0,-922 # 13f0 <malloc+0x16c>
     792:	00000097          	auipc	ra,0x0
     796:	8c2080e7          	jalr	-1854(ra) # 54 <panic>
    ret = parseredirs(ret, ps, es);
     79a:	8656                	mv	a2,s5
     79c:	85d2                	mv	a1,s4
     79e:	8526                	mv	a0,s1
     7a0:	00000097          	auipc	ra,0x0
     7a4:	e66080e7          	jalr	-410(ra) # 606 <parseredirs>
     7a8:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     7aa:	865a                	mv	a2,s6
     7ac:	85d6                	mv	a1,s5
     7ae:	8552                	mv	a0,s4
     7b0:	00000097          	auipc	ra,0x0
     7b4:	dec080e7          	jalr	-532(ra) # 59c <peek>
     7b8:	e131                	bnez	a0,7fc <parseexec+0xfa>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     7ba:	f9040693          	addi	a3,s0,-112
     7be:	f9840613          	addi	a2,s0,-104
     7c2:	85d6                	mv	a1,s5
     7c4:	8552                	mv	a0,s4
     7c6:	00000097          	auipc	ra,0x0
     7ca:	c9a080e7          	jalr	-870(ra) # 460 <gettoken>
     7ce:	c51d                	beqz	a0,7fc <parseexec+0xfa>
    if(tok != 'a')
     7d0:	fb951de3          	bne	a0,s9,78a <parseexec+0x88>
    cmd->argv[argc] = q;
     7d4:	f9843783          	ld	a5,-104(s0)
     7d8:	00f93023          	sd	a5,0(s2)
    cmd->eargv[argc] = eq;
     7dc:	f9043783          	ld	a5,-112(s0)
     7e0:	04f93823          	sd	a5,80(s2)
    argc++;
     7e4:	2985                	addiw	s3,s3,1
    if(argc >= MAXARGS)
     7e6:	0921                	addi	s2,s2,8
     7e8:	fb7999e3          	bne	s3,s7,79a <parseexec+0x98>
      panic("too many args");
     7ec:	00001517          	auipc	a0,0x1
     7f0:	c0c50513          	addi	a0,a0,-1012 # 13f8 <malloc+0x174>
     7f4:	00000097          	auipc	ra,0x0
     7f8:	860080e7          	jalr	-1952(ra) # 54 <panic>
  cmd->argv[argc] = 0;
     7fc:	098e                	slli	s3,s3,0x3
     7fe:	99e2                	add	s3,s3,s8
     800:	0009b423          	sd	zero,8(s3)
  cmd->eargv[argc] = 0;
     804:	0409bc23          	sd	zero,88(s3)
  return ret;
     808:	b79d                	j	76e <parseexec+0x6c>

000000000000080a <parsepipe>:
{
     80a:	7179                	addi	sp,sp,-48
     80c:	f406                	sd	ra,40(sp)
     80e:	f022                	sd	s0,32(sp)
     810:	ec26                	sd	s1,24(sp)
     812:	e84a                	sd	s2,16(sp)
     814:	e44e                	sd	s3,8(sp)
     816:	1800                	addi	s0,sp,48
     818:	892a                	mv	s2,a0
     81a:	89ae                	mv	s3,a1
  cmd = parseexec(ps, es);
     81c:	00000097          	auipc	ra,0x0
     820:	ee6080e7          	jalr	-282(ra) # 702 <parseexec>
     824:	84aa                	mv	s1,a0
  if(peek(ps, es, "|")){
     826:	00001617          	auipc	a2,0x1
     82a:	bea60613          	addi	a2,a2,-1046 # 1410 <malloc+0x18c>
     82e:	85ce                	mv	a1,s3
     830:	854a                	mv	a0,s2
     832:	00000097          	auipc	ra,0x0
     836:	d6a080e7          	jalr	-662(ra) # 59c <peek>
     83a:	e909                	bnez	a0,84c <parsepipe+0x42>
}
     83c:	8526                	mv	a0,s1
     83e:	70a2                	ld	ra,40(sp)
     840:	7402                	ld	s0,32(sp)
     842:	64e2                	ld	s1,24(sp)
     844:	6942                	ld	s2,16(sp)
     846:	69a2                	ld	s3,8(sp)
     848:	6145                	addi	sp,sp,48
     84a:	8082                	ret
    gettoken(ps, es, 0, 0);
     84c:	4681                	li	a3,0
     84e:	4601                	li	a2,0
     850:	85ce                	mv	a1,s3
     852:	854a                	mv	a0,s2
     854:	00000097          	auipc	ra,0x0
     858:	c0c080e7          	jalr	-1012(ra) # 460 <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     85c:	85ce                	mv	a1,s3
     85e:	854a                	mv	a0,s2
     860:	00000097          	auipc	ra,0x0
     864:	faa080e7          	jalr	-86(ra) # 80a <parsepipe>
     868:	85aa                	mv	a1,a0
     86a:	8526                	mv	a0,s1
     86c:	00000097          	auipc	ra,0x0
     870:	b2c080e7          	jalr	-1236(ra) # 398 <pipecmd>
     874:	84aa                	mv	s1,a0
  return cmd;
     876:	b7d9                	j	83c <parsepipe+0x32>

0000000000000878 <parseline>:
{
     878:	7179                	addi	sp,sp,-48
     87a:	f406                	sd	ra,40(sp)
     87c:	f022                	sd	s0,32(sp)
     87e:	ec26                	sd	s1,24(sp)
     880:	e84a                	sd	s2,16(sp)
     882:	e44e                	sd	s3,8(sp)
     884:	e052                	sd	s4,0(sp)
     886:	1800                	addi	s0,sp,48
     888:	892a                	mv	s2,a0
     88a:	89ae                	mv	s3,a1
  cmd = parsepipe(ps, es);
     88c:	00000097          	auipc	ra,0x0
     890:	f7e080e7          	jalr	-130(ra) # 80a <parsepipe>
     894:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     896:	00001a17          	auipc	s4,0x1
     89a:	b82a0a13          	addi	s4,s4,-1150 # 1418 <malloc+0x194>
     89e:	a839                	j	8bc <parseline+0x44>
    gettoken(ps, es, 0, 0);
     8a0:	4681                	li	a3,0
     8a2:	4601                	li	a2,0
     8a4:	85ce                	mv	a1,s3
     8a6:	854a                	mv	a0,s2
     8a8:	00000097          	auipc	ra,0x0
     8ac:	bb8080e7          	jalr	-1096(ra) # 460 <gettoken>
    cmd = backcmd(cmd);
     8b0:	8526                	mv	a0,s1
     8b2:	00000097          	auipc	ra,0x0
     8b6:	b72080e7          	jalr	-1166(ra) # 424 <backcmd>
     8ba:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     8bc:	8652                	mv	a2,s4
     8be:	85ce                	mv	a1,s3
     8c0:	854a                	mv	a0,s2
     8c2:	00000097          	auipc	ra,0x0
     8c6:	cda080e7          	jalr	-806(ra) # 59c <peek>
     8ca:	f979                	bnez	a0,8a0 <parseline+0x28>
  if(peek(ps, es, ";")){
     8cc:	00001617          	auipc	a2,0x1
     8d0:	b5460613          	addi	a2,a2,-1196 # 1420 <malloc+0x19c>
     8d4:	85ce                	mv	a1,s3
     8d6:	854a                	mv	a0,s2
     8d8:	00000097          	auipc	ra,0x0
     8dc:	cc4080e7          	jalr	-828(ra) # 59c <peek>
     8e0:	e911                	bnez	a0,8f4 <parseline+0x7c>
}
     8e2:	8526                	mv	a0,s1
     8e4:	70a2                	ld	ra,40(sp)
     8e6:	7402                	ld	s0,32(sp)
     8e8:	64e2                	ld	s1,24(sp)
     8ea:	6942                	ld	s2,16(sp)
     8ec:	69a2                	ld	s3,8(sp)
     8ee:	6a02                	ld	s4,0(sp)
     8f0:	6145                	addi	sp,sp,48
     8f2:	8082                	ret
    gettoken(ps, es, 0, 0);
     8f4:	4681                	li	a3,0
     8f6:	4601                	li	a2,0
     8f8:	85ce                	mv	a1,s3
     8fa:	854a                	mv	a0,s2
     8fc:	00000097          	auipc	ra,0x0
     900:	b64080e7          	jalr	-1180(ra) # 460 <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     904:	85ce                	mv	a1,s3
     906:	854a                	mv	a0,s2
     908:	00000097          	auipc	ra,0x0
     90c:	f70080e7          	jalr	-144(ra) # 878 <parseline>
     910:	85aa                	mv	a1,a0
     912:	8526                	mv	a0,s1
     914:	00000097          	auipc	ra,0x0
     918:	aca080e7          	jalr	-1334(ra) # 3de <listcmd>
     91c:	84aa                	mv	s1,a0
  return cmd;
     91e:	b7d1                	j	8e2 <parseline+0x6a>

0000000000000920 <parseblock>:
{
     920:	7179                	addi	sp,sp,-48
     922:	f406                	sd	ra,40(sp)
     924:	f022                	sd	s0,32(sp)
     926:	ec26                	sd	s1,24(sp)
     928:	e84a                	sd	s2,16(sp)
     92a:	e44e                	sd	s3,8(sp)
     92c:	1800                	addi	s0,sp,48
     92e:	84aa                	mv	s1,a0
     930:	892e                	mv	s2,a1
  if(!peek(ps, es, "("))
     932:	00001617          	auipc	a2,0x1
     936:	ab660613          	addi	a2,a2,-1354 # 13e8 <malloc+0x164>
     93a:	00000097          	auipc	ra,0x0
     93e:	c62080e7          	jalr	-926(ra) # 59c <peek>
     942:	c12d                	beqz	a0,9a4 <parseblock+0x84>
  gettoken(ps, es, 0, 0);
     944:	4681                	li	a3,0
     946:	4601                	li	a2,0
     948:	85ca                	mv	a1,s2
     94a:	8526                	mv	a0,s1
     94c:	00000097          	auipc	ra,0x0
     950:	b14080e7          	jalr	-1260(ra) # 460 <gettoken>
  cmd = parseline(ps, es);
     954:	85ca                	mv	a1,s2
     956:	8526                	mv	a0,s1
     958:	00000097          	auipc	ra,0x0
     95c:	f20080e7          	jalr	-224(ra) # 878 <parseline>
     960:	89aa                	mv	s3,a0
  if(!peek(ps, es, ")"))
     962:	00001617          	auipc	a2,0x1
     966:	ad660613          	addi	a2,a2,-1322 # 1438 <malloc+0x1b4>
     96a:	85ca                	mv	a1,s2
     96c:	8526                	mv	a0,s1
     96e:	00000097          	auipc	ra,0x0
     972:	c2e080e7          	jalr	-978(ra) # 59c <peek>
     976:	cd1d                	beqz	a0,9b4 <parseblock+0x94>
  gettoken(ps, es, 0, 0);
     978:	4681                	li	a3,0
     97a:	4601                	li	a2,0
     97c:	85ca                	mv	a1,s2
     97e:	8526                	mv	a0,s1
     980:	00000097          	auipc	ra,0x0
     984:	ae0080e7          	jalr	-1312(ra) # 460 <gettoken>
  cmd = parseredirs(cmd, ps, es);
     988:	864a                	mv	a2,s2
     98a:	85a6                	mv	a1,s1
     98c:	854e                	mv	a0,s3
     98e:	00000097          	auipc	ra,0x0
     992:	c78080e7          	jalr	-904(ra) # 606 <parseredirs>
}
     996:	70a2                	ld	ra,40(sp)
     998:	7402                	ld	s0,32(sp)
     99a:	64e2                	ld	s1,24(sp)
     99c:	6942                	ld	s2,16(sp)
     99e:	69a2                	ld	s3,8(sp)
     9a0:	6145                	addi	sp,sp,48
     9a2:	8082                	ret
    panic("parseblock");
     9a4:	00001517          	auipc	a0,0x1
     9a8:	a8450513          	addi	a0,a0,-1404 # 1428 <malloc+0x1a4>
     9ac:	fffff097          	auipc	ra,0xfffff
     9b0:	6a8080e7          	jalr	1704(ra) # 54 <panic>
    panic("syntax - missing )");
     9b4:	00001517          	auipc	a0,0x1
     9b8:	a8c50513          	addi	a0,a0,-1396 # 1440 <malloc+0x1bc>
     9bc:	fffff097          	auipc	ra,0xfffff
     9c0:	698080e7          	jalr	1688(ra) # 54 <panic>

00000000000009c4 <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     9c4:	1101                	addi	sp,sp,-32
     9c6:	ec06                	sd	ra,24(sp)
     9c8:	e822                	sd	s0,16(sp)
     9ca:	e426                	sd	s1,8(sp)
     9cc:	1000                	addi	s0,sp,32
     9ce:	84aa                	mv	s1,a0
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     9d0:	c521                	beqz	a0,a18 <nulterminate+0x54>
    return 0;

  switch(cmd->type){
     9d2:	4118                	lw	a4,0(a0)
     9d4:	4795                	li	a5,5
     9d6:	04e7e163          	bltu	a5,a4,a18 <nulterminate+0x54>
     9da:	00056783          	lwu	a5,0(a0)
     9de:	078a                	slli	a5,a5,0x2
     9e0:	00001717          	auipc	a4,0x1
     9e4:	ac070713          	addi	a4,a4,-1344 # 14a0 <malloc+0x21c>
     9e8:	97ba                	add	a5,a5,a4
     9ea:	439c                	lw	a5,0(a5)
     9ec:	97ba                	add	a5,a5,a4
     9ee:	8782                	jr	a5
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     9f0:	651c                	ld	a5,8(a0)
     9f2:	c39d                	beqz	a5,a18 <nulterminate+0x54>
     9f4:	01050793          	addi	a5,a0,16
      *ecmd->eargv[i] = 0;
     9f8:	67b8                	ld	a4,72(a5)
     9fa:	00070023          	sb	zero,0(a4)
    for(i=0; ecmd->argv[i]; i++)
     9fe:	07a1                	addi	a5,a5,8
     a00:	ff87b703          	ld	a4,-8(a5)
     a04:	fb75                	bnez	a4,9f8 <nulterminate+0x34>
     a06:	a809                	j	a18 <nulterminate+0x54>
    break;

  case REDIR:
    rcmd = (struct redircmd*)cmd;
    nulterminate(rcmd->cmd);
     a08:	6508                	ld	a0,8(a0)
     a0a:	00000097          	auipc	ra,0x0
     a0e:	fba080e7          	jalr	-70(ra) # 9c4 <nulterminate>
    *rcmd->efile = 0;
     a12:	6c9c                	ld	a5,24(s1)
     a14:	00078023          	sb	zero,0(a5)
    bcmd = (struct backcmd*)cmd;
    nulterminate(bcmd->cmd);
    break;
  }
  return cmd;
}
     a18:	8526                	mv	a0,s1
     a1a:	60e2                	ld	ra,24(sp)
     a1c:	6442                	ld	s0,16(sp)
     a1e:	64a2                	ld	s1,8(sp)
     a20:	6105                	addi	sp,sp,32
     a22:	8082                	ret
    nulterminate(pcmd->left);
     a24:	6508                	ld	a0,8(a0)
     a26:	00000097          	auipc	ra,0x0
     a2a:	f9e080e7          	jalr	-98(ra) # 9c4 <nulterminate>
    nulterminate(pcmd->right);
     a2e:	6888                	ld	a0,16(s1)
     a30:	00000097          	auipc	ra,0x0
     a34:	f94080e7          	jalr	-108(ra) # 9c4 <nulterminate>
    break;
     a38:	b7c5                	j	a18 <nulterminate+0x54>
    nulterminate(lcmd->left);
     a3a:	6508                	ld	a0,8(a0)
     a3c:	00000097          	auipc	ra,0x0
     a40:	f88080e7          	jalr	-120(ra) # 9c4 <nulterminate>
    nulterminate(lcmd->right);
     a44:	6888                	ld	a0,16(s1)
     a46:	00000097          	auipc	ra,0x0
     a4a:	f7e080e7          	jalr	-130(ra) # 9c4 <nulterminate>
    break;
     a4e:	b7e9                	j	a18 <nulterminate+0x54>
    nulterminate(bcmd->cmd);
     a50:	6508                	ld	a0,8(a0)
     a52:	00000097          	auipc	ra,0x0
     a56:	f72080e7          	jalr	-142(ra) # 9c4 <nulterminate>
    break;
     a5a:	bf7d                	j	a18 <nulterminate+0x54>

0000000000000a5c <parsecmd>:
{
     a5c:	7179                	addi	sp,sp,-48
     a5e:	f406                	sd	ra,40(sp)
     a60:	f022                	sd	s0,32(sp)
     a62:	ec26                	sd	s1,24(sp)
     a64:	e84a                	sd	s2,16(sp)
     a66:	1800                	addi	s0,sp,48
     a68:	fca43c23          	sd	a0,-40(s0)
  es = s + strlen(s);
     a6c:	84aa                	mv	s1,a0
     a6e:	00000097          	auipc	ra,0x0
     a72:	1b2080e7          	jalr	434(ra) # c20 <strlen>
     a76:	1502                	slli	a0,a0,0x20
     a78:	9101                	srli	a0,a0,0x20
     a7a:	94aa                	add	s1,s1,a0
  cmd = parseline(&s, es);
     a7c:	85a6                	mv	a1,s1
     a7e:	fd840513          	addi	a0,s0,-40
     a82:	00000097          	auipc	ra,0x0
     a86:	df6080e7          	jalr	-522(ra) # 878 <parseline>
     a8a:	892a                	mv	s2,a0
  peek(&s, es, "");
     a8c:	00001617          	auipc	a2,0x1
     a90:	9cc60613          	addi	a2,a2,-1588 # 1458 <malloc+0x1d4>
     a94:	85a6                	mv	a1,s1
     a96:	fd840513          	addi	a0,s0,-40
     a9a:	00000097          	auipc	ra,0x0
     a9e:	b02080e7          	jalr	-1278(ra) # 59c <peek>
  if(s != es){
     aa2:	fd843603          	ld	a2,-40(s0)
     aa6:	00961e63          	bne	a2,s1,ac2 <parsecmd+0x66>
  nulterminate(cmd);
     aaa:	854a                	mv	a0,s2
     aac:	00000097          	auipc	ra,0x0
     ab0:	f18080e7          	jalr	-232(ra) # 9c4 <nulterminate>
}
     ab4:	854a                	mv	a0,s2
     ab6:	70a2                	ld	ra,40(sp)
     ab8:	7402                	ld	s0,32(sp)
     aba:	64e2                	ld	s1,24(sp)
     abc:	6942                	ld	s2,16(sp)
     abe:	6145                	addi	sp,sp,48
     ac0:	8082                	ret
    fprintf(2, "leftovers: %s\n", s);
     ac2:	00001597          	auipc	a1,0x1
     ac6:	99e58593          	addi	a1,a1,-1634 # 1460 <malloc+0x1dc>
     aca:	4509                	li	a0,2
     acc:	00000097          	auipc	ra,0x0
     ad0:	6cc080e7          	jalr	1740(ra) # 1198 <fprintf>
    panic("syntax");
     ad4:	00001517          	auipc	a0,0x1
     ad8:	91c50513          	addi	a0,a0,-1764 # 13f0 <malloc+0x16c>
     adc:	fffff097          	auipc	ra,0xfffff
     ae0:	578080e7          	jalr	1400(ra) # 54 <panic>

0000000000000ae4 <main>:
{
     ae4:	7139                	addi	sp,sp,-64
     ae6:	fc06                	sd	ra,56(sp)
     ae8:	f822                	sd	s0,48(sp)
     aea:	f426                	sd	s1,40(sp)
     aec:	f04a                	sd	s2,32(sp)
     aee:	ec4e                	sd	s3,24(sp)
     af0:	e852                	sd	s4,16(sp)
     af2:	e456                	sd	s5,8(sp)
     af4:	0080                	addi	s0,sp,64
  while((fd = open("console", O_RDWR)) >= 0){
     af6:	00001497          	auipc	s1,0x1
     afa:	97a48493          	addi	s1,s1,-1670 # 1470 <malloc+0x1ec>
     afe:	4589                	li	a1,2
     b00:	8526                	mv	a0,s1
     b02:	00000097          	auipc	ra,0x0
     b06:	384080e7          	jalr	900(ra) # e86 <open>
     b0a:	00054963          	bltz	a0,b1c <main+0x38>
    if(fd >= 3){
     b0e:	4789                	li	a5,2
     b10:	fea7d7e3          	bge	a5,a0,afe <main+0x1a>
      close(fd);
     b14:	00000097          	auipc	ra,0x0
     b18:	35a080e7          	jalr	858(ra) # e6e <close>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b1c:	00001497          	auipc	s1,0x1
     b20:	9d448493          	addi	s1,s1,-1580 # 14f0 <buf.0>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     b24:	06300913          	li	s2,99
     b28:	02000993          	li	s3,32
      if(chdir(buf+3) < 0)
     b2c:	00001a17          	auipc	s4,0x1
     b30:	9c7a0a13          	addi	s4,s4,-1593 # 14f3 <buf.0+0x3>
        fprintf(2, "cannot cd %s\n", buf+3);
     b34:	00001a97          	auipc	s5,0x1
     b38:	944a8a93          	addi	s5,s5,-1724 # 1478 <malloc+0x1f4>
     b3c:	a819                	j	b52 <main+0x6e>
    if(fork1() == 0)
     b3e:	fffff097          	auipc	ra,0xfffff
     b42:	53c080e7          	jalr	1340(ra) # 7a <fork1>
     b46:	c925                	beqz	a0,bb6 <main+0xd2>
    wait(0);
     b48:	4501                	li	a0,0
     b4a:	00000097          	auipc	ra,0x0
     b4e:	304080e7          	jalr	772(ra) # e4e <wait>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b52:	06400593          	li	a1,100
     b56:	8526                	mv	a0,s1
     b58:	fffff097          	auipc	ra,0xfffff
     b5c:	4a8080e7          	jalr	1192(ra) # 0 <getcmd>
     b60:	06054763          	bltz	a0,bce <main+0xea>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     b64:	0004c783          	lbu	a5,0(s1)
     b68:	fd279be3          	bne	a5,s2,b3e <main+0x5a>
     b6c:	0014c703          	lbu	a4,1(s1)
     b70:	06400793          	li	a5,100
     b74:	fcf715e3          	bne	a4,a5,b3e <main+0x5a>
     b78:	0024c783          	lbu	a5,2(s1)
     b7c:	fd3791e3          	bne	a5,s3,b3e <main+0x5a>
      buf[strlen(buf)-1] = 0;  // chop \n
     b80:	8526                	mv	a0,s1
     b82:	00000097          	auipc	ra,0x0
     b86:	09e080e7          	jalr	158(ra) # c20 <strlen>
     b8a:	fff5079b          	addiw	a5,a0,-1
     b8e:	1782                	slli	a5,a5,0x20
     b90:	9381                	srli	a5,a5,0x20
     b92:	97a6                	add	a5,a5,s1
     b94:	00078023          	sb	zero,0(a5)
      if(chdir(buf+3) < 0)
     b98:	8552                	mv	a0,s4
     b9a:	00000097          	auipc	ra,0x0
     b9e:	31c080e7          	jalr	796(ra) # eb6 <chdir>
     ba2:	fa0558e3          	bgez	a0,b52 <main+0x6e>
        fprintf(2, "cannot cd %s\n", buf+3);
     ba6:	8652                	mv	a2,s4
     ba8:	85d6                	mv	a1,s5
     baa:	4509                	li	a0,2
     bac:	00000097          	auipc	ra,0x0
     bb0:	5ec080e7          	jalr	1516(ra) # 1198 <fprintf>
     bb4:	bf79                	j	b52 <main+0x6e>
      runcmd(parsecmd(buf));
     bb6:	00001517          	auipc	a0,0x1
     bba:	93a50513          	addi	a0,a0,-1734 # 14f0 <buf.0>
     bbe:	00000097          	auipc	ra,0x0
     bc2:	e9e080e7          	jalr	-354(ra) # a5c <parsecmd>
     bc6:	fffff097          	auipc	ra,0xfffff
     bca:	4e2080e7          	jalr	1250(ra) # a8 <runcmd>
  exit(0);
     bce:	4501                	li	a0,0
     bd0:	00000097          	auipc	ra,0x0
     bd4:	276080e7          	jalr	630(ra) # e46 <exit>

0000000000000bd8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     bd8:	1141                	addi	sp,sp,-16
     bda:	e422                	sd	s0,8(sp)
     bdc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     bde:	87aa                	mv	a5,a0
     be0:	0585                	addi	a1,a1,1
     be2:	0785                	addi	a5,a5,1
     be4:	fff5c703          	lbu	a4,-1(a1)
     be8:	fee78fa3          	sb	a4,-1(a5)
     bec:	fb75                	bnez	a4,be0 <strcpy+0x8>
    ;
  return os;
}
     bee:	6422                	ld	s0,8(sp)
     bf0:	0141                	addi	sp,sp,16
     bf2:	8082                	ret

0000000000000bf4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     bf4:	1141                	addi	sp,sp,-16
     bf6:	e422                	sd	s0,8(sp)
     bf8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     bfa:	00054783          	lbu	a5,0(a0)
     bfe:	cb91                	beqz	a5,c12 <strcmp+0x1e>
     c00:	0005c703          	lbu	a4,0(a1)
     c04:	00f71763          	bne	a4,a5,c12 <strcmp+0x1e>
    p++, q++;
     c08:	0505                	addi	a0,a0,1
     c0a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c0c:	00054783          	lbu	a5,0(a0)
     c10:	fbe5                	bnez	a5,c00 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c12:	0005c503          	lbu	a0,0(a1)
}
     c16:	40a7853b          	subw	a0,a5,a0
     c1a:	6422                	ld	s0,8(sp)
     c1c:	0141                	addi	sp,sp,16
     c1e:	8082                	ret

0000000000000c20 <strlen>:

uint
strlen(const char *s)
{
     c20:	1141                	addi	sp,sp,-16
     c22:	e422                	sd	s0,8(sp)
     c24:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c26:	00054783          	lbu	a5,0(a0)
     c2a:	cf91                	beqz	a5,c46 <strlen+0x26>
     c2c:	0505                	addi	a0,a0,1
     c2e:	87aa                	mv	a5,a0
     c30:	4685                	li	a3,1
     c32:	9e89                	subw	a3,a3,a0
     c34:	00f6853b          	addw	a0,a3,a5
     c38:	0785                	addi	a5,a5,1
     c3a:	fff7c703          	lbu	a4,-1(a5)
     c3e:	fb7d                	bnez	a4,c34 <strlen+0x14>
    ;
  return n;
}
     c40:	6422                	ld	s0,8(sp)
     c42:	0141                	addi	sp,sp,16
     c44:	8082                	ret
  for(n = 0; s[n]; n++)
     c46:	4501                	li	a0,0
     c48:	bfe5                	j	c40 <strlen+0x20>

0000000000000c4a <memset>:

void*
memset(void *dst, int c, uint n)
{
     c4a:	1141                	addi	sp,sp,-16
     c4c:	e422                	sd	s0,8(sp)
     c4e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c50:	ca19                	beqz	a2,c66 <memset+0x1c>
     c52:	87aa                	mv	a5,a0
     c54:	1602                	slli	a2,a2,0x20
     c56:	9201                	srli	a2,a2,0x20
     c58:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     c5c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     c60:	0785                	addi	a5,a5,1
     c62:	fee79de3          	bne	a5,a4,c5c <memset+0x12>
  }
  return dst;
}
     c66:	6422                	ld	s0,8(sp)
     c68:	0141                	addi	sp,sp,16
     c6a:	8082                	ret

0000000000000c6c <strchr>:

char*
strchr(const char *s, char c)
{
     c6c:	1141                	addi	sp,sp,-16
     c6e:	e422                	sd	s0,8(sp)
     c70:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c72:	00054783          	lbu	a5,0(a0)
     c76:	cb99                	beqz	a5,c8c <strchr+0x20>
    if(*s == c)
     c78:	00f58763          	beq	a1,a5,c86 <strchr+0x1a>
  for(; *s; s++)
     c7c:	0505                	addi	a0,a0,1
     c7e:	00054783          	lbu	a5,0(a0)
     c82:	fbfd                	bnez	a5,c78 <strchr+0xc>
      return (char*)s;
  return 0;
     c84:	4501                	li	a0,0
}
     c86:	6422                	ld	s0,8(sp)
     c88:	0141                	addi	sp,sp,16
     c8a:	8082                	ret
  return 0;
     c8c:	4501                	li	a0,0
     c8e:	bfe5                	j	c86 <strchr+0x1a>

0000000000000c90 <gets>:

char*
gets(char *buf, int max)
{
     c90:	711d                	addi	sp,sp,-96
     c92:	ec86                	sd	ra,88(sp)
     c94:	e8a2                	sd	s0,80(sp)
     c96:	e4a6                	sd	s1,72(sp)
     c98:	e0ca                	sd	s2,64(sp)
     c9a:	fc4e                	sd	s3,56(sp)
     c9c:	f852                	sd	s4,48(sp)
     c9e:	f456                	sd	s5,40(sp)
     ca0:	f05a                	sd	s6,32(sp)
     ca2:	ec5e                	sd	s7,24(sp)
     ca4:	1080                	addi	s0,sp,96
     ca6:	8baa                	mv	s7,a0
     ca8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     caa:	892a                	mv	s2,a0
     cac:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     cae:	4aa9                	li	s5,10
     cb0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     cb2:	89a6                	mv	s3,s1
     cb4:	2485                	addiw	s1,s1,1
     cb6:	0344d863          	bge	s1,s4,ce6 <gets+0x56>
    cc = read(0, &c, 1);
     cba:	4605                	li	a2,1
     cbc:	faf40593          	addi	a1,s0,-81
     cc0:	4501                	li	a0,0
     cc2:	00000097          	auipc	ra,0x0
     cc6:	19c080e7          	jalr	412(ra) # e5e <read>
    if(cc < 1)
     cca:	00a05e63          	blez	a0,ce6 <gets+0x56>
    buf[i++] = c;
     cce:	faf44783          	lbu	a5,-81(s0)
     cd2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     cd6:	01578763          	beq	a5,s5,ce4 <gets+0x54>
     cda:	0905                	addi	s2,s2,1
     cdc:	fd679be3          	bne	a5,s6,cb2 <gets+0x22>
  for(i=0; i+1 < max; ){
     ce0:	89a6                	mv	s3,s1
     ce2:	a011                	j	ce6 <gets+0x56>
     ce4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     ce6:	99de                	add	s3,s3,s7
     ce8:	00098023          	sb	zero,0(s3)
  return buf;
}
     cec:	855e                	mv	a0,s7
     cee:	60e6                	ld	ra,88(sp)
     cf0:	6446                	ld	s0,80(sp)
     cf2:	64a6                	ld	s1,72(sp)
     cf4:	6906                	ld	s2,64(sp)
     cf6:	79e2                	ld	s3,56(sp)
     cf8:	7a42                	ld	s4,48(sp)
     cfa:	7aa2                	ld	s5,40(sp)
     cfc:	7b02                	ld	s6,32(sp)
     cfe:	6be2                	ld	s7,24(sp)
     d00:	6125                	addi	sp,sp,96
     d02:	8082                	ret

0000000000000d04 <stat>:

int
stat(const char *n, struct stat *st)
{
     d04:	1101                	addi	sp,sp,-32
     d06:	ec06                	sd	ra,24(sp)
     d08:	e822                	sd	s0,16(sp)
     d0a:	e426                	sd	s1,8(sp)
     d0c:	e04a                	sd	s2,0(sp)
     d0e:	1000                	addi	s0,sp,32
     d10:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d12:	4581                	li	a1,0
     d14:	00000097          	auipc	ra,0x0
     d18:	172080e7          	jalr	370(ra) # e86 <open>
  if(fd < 0)
     d1c:	02054563          	bltz	a0,d46 <stat+0x42>
     d20:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d22:	85ca                	mv	a1,s2
     d24:	00000097          	auipc	ra,0x0
     d28:	17a080e7          	jalr	378(ra) # e9e <fstat>
     d2c:	892a                	mv	s2,a0
  close(fd);
     d2e:	8526                	mv	a0,s1
     d30:	00000097          	auipc	ra,0x0
     d34:	13e080e7          	jalr	318(ra) # e6e <close>
  return r;
}
     d38:	854a                	mv	a0,s2
     d3a:	60e2                	ld	ra,24(sp)
     d3c:	6442                	ld	s0,16(sp)
     d3e:	64a2                	ld	s1,8(sp)
     d40:	6902                	ld	s2,0(sp)
     d42:	6105                	addi	sp,sp,32
     d44:	8082                	ret
    return -1;
     d46:	597d                	li	s2,-1
     d48:	bfc5                	j	d38 <stat+0x34>

0000000000000d4a <atoi>:

int
atoi(const char *s)
{
     d4a:	1141                	addi	sp,sp,-16
     d4c:	e422                	sd	s0,8(sp)
     d4e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d50:	00054603          	lbu	a2,0(a0)
     d54:	fd06079b          	addiw	a5,a2,-48
     d58:	0ff7f793          	andi	a5,a5,255
     d5c:	4725                	li	a4,9
     d5e:	02f76963          	bltu	a4,a5,d90 <atoi+0x46>
     d62:	86aa                	mv	a3,a0
  n = 0;
     d64:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     d66:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     d68:	0685                	addi	a3,a3,1
     d6a:	0025179b          	slliw	a5,a0,0x2
     d6e:	9fa9                	addw	a5,a5,a0
     d70:	0017979b          	slliw	a5,a5,0x1
     d74:	9fb1                	addw	a5,a5,a2
     d76:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d7a:	0006c603          	lbu	a2,0(a3)
     d7e:	fd06071b          	addiw	a4,a2,-48
     d82:	0ff77713          	andi	a4,a4,255
     d86:	fee5f1e3          	bgeu	a1,a4,d68 <atoi+0x1e>
  return n;
}
     d8a:	6422                	ld	s0,8(sp)
     d8c:	0141                	addi	sp,sp,16
     d8e:	8082                	ret
  n = 0;
     d90:	4501                	li	a0,0
     d92:	bfe5                	j	d8a <atoi+0x40>

0000000000000d94 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     d94:	1141                	addi	sp,sp,-16
     d96:	e422                	sd	s0,8(sp)
     d98:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     d9a:	02b57463          	bgeu	a0,a1,dc2 <memmove+0x2e>
    while(n-- > 0)
     d9e:	00c05f63          	blez	a2,dbc <memmove+0x28>
     da2:	1602                	slli	a2,a2,0x20
     da4:	9201                	srli	a2,a2,0x20
     da6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     daa:	872a                	mv	a4,a0
      *dst++ = *src++;
     dac:	0585                	addi	a1,a1,1
     dae:	0705                	addi	a4,a4,1
     db0:	fff5c683          	lbu	a3,-1(a1)
     db4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     db8:	fee79ae3          	bne	a5,a4,dac <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     dbc:	6422                	ld	s0,8(sp)
     dbe:	0141                	addi	sp,sp,16
     dc0:	8082                	ret
    dst += n;
     dc2:	00c50733          	add	a4,a0,a2
    src += n;
     dc6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     dc8:	fec05ae3          	blez	a2,dbc <memmove+0x28>
     dcc:	fff6079b          	addiw	a5,a2,-1
     dd0:	1782                	slli	a5,a5,0x20
     dd2:	9381                	srli	a5,a5,0x20
     dd4:	fff7c793          	not	a5,a5
     dd8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     dda:	15fd                	addi	a1,a1,-1
     ddc:	177d                	addi	a4,a4,-1
     dde:	0005c683          	lbu	a3,0(a1)
     de2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     de6:	fee79ae3          	bne	a5,a4,dda <memmove+0x46>
     dea:	bfc9                	j	dbc <memmove+0x28>

0000000000000dec <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     dec:	1141                	addi	sp,sp,-16
     dee:	e422                	sd	s0,8(sp)
     df0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     df2:	ca05                	beqz	a2,e22 <memcmp+0x36>
     df4:	fff6069b          	addiw	a3,a2,-1
     df8:	1682                	slli	a3,a3,0x20
     dfa:	9281                	srli	a3,a3,0x20
     dfc:	0685                	addi	a3,a3,1
     dfe:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e00:	00054783          	lbu	a5,0(a0)
     e04:	0005c703          	lbu	a4,0(a1)
     e08:	00e79863          	bne	a5,a4,e18 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e0c:	0505                	addi	a0,a0,1
    p2++;
     e0e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e10:	fed518e3          	bne	a0,a3,e00 <memcmp+0x14>
  }
  return 0;
     e14:	4501                	li	a0,0
     e16:	a019                	j	e1c <memcmp+0x30>
      return *p1 - *p2;
     e18:	40e7853b          	subw	a0,a5,a4
}
     e1c:	6422                	ld	s0,8(sp)
     e1e:	0141                	addi	sp,sp,16
     e20:	8082                	ret
  return 0;
     e22:	4501                	li	a0,0
     e24:	bfe5                	j	e1c <memcmp+0x30>

0000000000000e26 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e26:	1141                	addi	sp,sp,-16
     e28:	e406                	sd	ra,8(sp)
     e2a:	e022                	sd	s0,0(sp)
     e2c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e2e:	00000097          	auipc	ra,0x0
     e32:	f66080e7          	jalr	-154(ra) # d94 <memmove>
}
     e36:	60a2                	ld	ra,8(sp)
     e38:	6402                	ld	s0,0(sp)
     e3a:	0141                	addi	sp,sp,16
     e3c:	8082                	ret

0000000000000e3e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e3e:	4885                	li	a7,1
 ecall
     e40:	00000073          	ecall
 ret
     e44:	8082                	ret

0000000000000e46 <exit>:
.global exit
exit:
 li a7, SYS_exit
     e46:	4889                	li	a7,2
 ecall
     e48:	00000073          	ecall
 ret
     e4c:	8082                	ret

0000000000000e4e <wait>:
.global wait
wait:
 li a7, SYS_wait
     e4e:	488d                	li	a7,3
 ecall
     e50:	00000073          	ecall
 ret
     e54:	8082                	ret

0000000000000e56 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     e56:	4891                	li	a7,4
 ecall
     e58:	00000073          	ecall
 ret
     e5c:	8082                	ret

0000000000000e5e <read>:
.global read
read:
 li a7, SYS_read
     e5e:	4895                	li	a7,5
 ecall
     e60:	00000073          	ecall
 ret
     e64:	8082                	ret

0000000000000e66 <write>:
.global write
write:
 li a7, SYS_write
     e66:	48c1                	li	a7,16
 ecall
     e68:	00000073          	ecall
 ret
     e6c:	8082                	ret

0000000000000e6e <close>:
.global close
close:
 li a7, SYS_close
     e6e:	48d5                	li	a7,21
 ecall
     e70:	00000073          	ecall
 ret
     e74:	8082                	ret

0000000000000e76 <kill>:
.global kill
kill:
 li a7, SYS_kill
     e76:	4899                	li	a7,6
 ecall
     e78:	00000073          	ecall
 ret
     e7c:	8082                	ret

0000000000000e7e <exec>:
.global exec
exec:
 li a7, SYS_exec
     e7e:	489d                	li	a7,7
 ecall
     e80:	00000073          	ecall
 ret
     e84:	8082                	ret

0000000000000e86 <open>:
.global open
open:
 li a7, SYS_open
     e86:	48bd                	li	a7,15
 ecall
     e88:	00000073          	ecall
 ret
     e8c:	8082                	ret

0000000000000e8e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     e8e:	48c5                	li	a7,17
 ecall
     e90:	00000073          	ecall
 ret
     e94:	8082                	ret

0000000000000e96 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     e96:	48c9                	li	a7,18
 ecall
     e98:	00000073          	ecall
 ret
     e9c:	8082                	ret

0000000000000e9e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     e9e:	48a1                	li	a7,8
 ecall
     ea0:	00000073          	ecall
 ret
     ea4:	8082                	ret

0000000000000ea6 <link>:
.global link
link:
 li a7, SYS_link
     ea6:	48cd                	li	a7,19
 ecall
     ea8:	00000073          	ecall
 ret
     eac:	8082                	ret

0000000000000eae <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     eae:	48d1                	li	a7,20
 ecall
     eb0:	00000073          	ecall
 ret
     eb4:	8082                	ret

0000000000000eb6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     eb6:	48a5                	li	a7,9
 ecall
     eb8:	00000073          	ecall
 ret
     ebc:	8082                	ret

0000000000000ebe <dup>:
.global dup
dup:
 li a7, SYS_dup
     ebe:	48a9                	li	a7,10
 ecall
     ec0:	00000073          	ecall
 ret
     ec4:	8082                	ret

0000000000000ec6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     ec6:	48ad                	li	a7,11
 ecall
     ec8:	00000073          	ecall
 ret
     ecc:	8082                	ret

0000000000000ece <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     ece:	48b1                	li	a7,12
 ecall
     ed0:	00000073          	ecall
 ret
     ed4:	8082                	ret

0000000000000ed6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     ed6:	48b5                	li	a7,13
 ecall
     ed8:	00000073          	ecall
 ret
     edc:	8082                	ret

0000000000000ede <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     ede:	48b9                	li	a7,14
 ecall
     ee0:	00000073          	ecall
 ret
     ee4:	8082                	ret

0000000000000ee6 <trace>:
.global trace
trace:
 li a7, SYS_trace
     ee6:	48d9                	li	a7,22
 ecall
     ee8:	00000073          	ecall
 ret
     eec:	8082                	ret

0000000000000eee <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     eee:	1101                	addi	sp,sp,-32
     ef0:	ec06                	sd	ra,24(sp)
     ef2:	e822                	sd	s0,16(sp)
     ef4:	1000                	addi	s0,sp,32
     ef6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     efa:	4605                	li	a2,1
     efc:	fef40593          	addi	a1,s0,-17
     f00:	00000097          	auipc	ra,0x0
     f04:	f66080e7          	jalr	-154(ra) # e66 <write>
}
     f08:	60e2                	ld	ra,24(sp)
     f0a:	6442                	ld	s0,16(sp)
     f0c:	6105                	addi	sp,sp,32
     f0e:	8082                	ret

0000000000000f10 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f10:	7139                	addi	sp,sp,-64
     f12:	fc06                	sd	ra,56(sp)
     f14:	f822                	sd	s0,48(sp)
     f16:	f426                	sd	s1,40(sp)
     f18:	f04a                	sd	s2,32(sp)
     f1a:	ec4e                	sd	s3,24(sp)
     f1c:	0080                	addi	s0,sp,64
     f1e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f20:	c299                	beqz	a3,f26 <printint+0x16>
     f22:	0805c863          	bltz	a1,fb2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f26:	2581                	sext.w	a1,a1
  neg = 0;
     f28:	4881                	li	a7,0
     f2a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f2e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f30:	2601                	sext.w	a2,a2
     f32:	00000517          	auipc	a0,0x0
     f36:	58e50513          	addi	a0,a0,1422 # 14c0 <digits>
     f3a:	883a                	mv	a6,a4
     f3c:	2705                	addiw	a4,a4,1
     f3e:	02c5f7bb          	remuw	a5,a1,a2
     f42:	1782                	slli	a5,a5,0x20
     f44:	9381                	srli	a5,a5,0x20
     f46:	97aa                	add	a5,a5,a0
     f48:	0007c783          	lbu	a5,0(a5)
     f4c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     f50:	0005879b          	sext.w	a5,a1
     f54:	02c5d5bb          	divuw	a1,a1,a2
     f58:	0685                	addi	a3,a3,1
     f5a:	fec7f0e3          	bgeu	a5,a2,f3a <printint+0x2a>
  if(neg)
     f5e:	00088b63          	beqz	a7,f74 <printint+0x64>
    buf[i++] = '-';
     f62:	fd040793          	addi	a5,s0,-48
     f66:	973e                	add	a4,a4,a5
     f68:	02d00793          	li	a5,45
     f6c:	fef70823          	sb	a5,-16(a4)
     f70:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     f74:	02e05863          	blez	a4,fa4 <printint+0x94>
     f78:	fc040793          	addi	a5,s0,-64
     f7c:	00e78933          	add	s2,a5,a4
     f80:	fff78993          	addi	s3,a5,-1
     f84:	99ba                	add	s3,s3,a4
     f86:	377d                	addiw	a4,a4,-1
     f88:	1702                	slli	a4,a4,0x20
     f8a:	9301                	srli	a4,a4,0x20
     f8c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     f90:	fff94583          	lbu	a1,-1(s2)
     f94:	8526                	mv	a0,s1
     f96:	00000097          	auipc	ra,0x0
     f9a:	f58080e7          	jalr	-168(ra) # eee <putc>
  while(--i >= 0)
     f9e:	197d                	addi	s2,s2,-1
     fa0:	ff3918e3          	bne	s2,s3,f90 <printint+0x80>
}
     fa4:	70e2                	ld	ra,56(sp)
     fa6:	7442                	ld	s0,48(sp)
     fa8:	74a2                	ld	s1,40(sp)
     faa:	7902                	ld	s2,32(sp)
     fac:	69e2                	ld	s3,24(sp)
     fae:	6121                	addi	sp,sp,64
     fb0:	8082                	ret
    x = -xx;
     fb2:	40b005bb          	negw	a1,a1
    neg = 1;
     fb6:	4885                	li	a7,1
    x = -xx;
     fb8:	bf8d                	j	f2a <printint+0x1a>

0000000000000fba <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     fba:	7119                	addi	sp,sp,-128
     fbc:	fc86                	sd	ra,120(sp)
     fbe:	f8a2                	sd	s0,112(sp)
     fc0:	f4a6                	sd	s1,104(sp)
     fc2:	f0ca                	sd	s2,96(sp)
     fc4:	ecce                	sd	s3,88(sp)
     fc6:	e8d2                	sd	s4,80(sp)
     fc8:	e4d6                	sd	s5,72(sp)
     fca:	e0da                	sd	s6,64(sp)
     fcc:	fc5e                	sd	s7,56(sp)
     fce:	f862                	sd	s8,48(sp)
     fd0:	f466                	sd	s9,40(sp)
     fd2:	f06a                	sd	s10,32(sp)
     fd4:	ec6e                	sd	s11,24(sp)
     fd6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     fd8:	0005c903          	lbu	s2,0(a1)
     fdc:	18090f63          	beqz	s2,117a <vprintf+0x1c0>
     fe0:	8aaa                	mv	s5,a0
     fe2:	8b32                	mv	s6,a2
     fe4:	00158493          	addi	s1,a1,1
  state = 0;
     fe8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
     fea:	02500a13          	li	s4,37
      if(c == 'd'){
     fee:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
     ff2:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
     ff6:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
     ffa:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
     ffe:	00000b97          	auipc	s7,0x0
    1002:	4c2b8b93          	addi	s7,s7,1218 # 14c0 <digits>
    1006:	a839                	j	1024 <vprintf+0x6a>
        putc(fd, c);
    1008:	85ca                	mv	a1,s2
    100a:	8556                	mv	a0,s5
    100c:	00000097          	auipc	ra,0x0
    1010:	ee2080e7          	jalr	-286(ra) # eee <putc>
    1014:	a019                	j	101a <vprintf+0x60>
    } else if(state == '%'){
    1016:	01498f63          	beq	s3,s4,1034 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    101a:	0485                	addi	s1,s1,1
    101c:	fff4c903          	lbu	s2,-1(s1)
    1020:	14090d63          	beqz	s2,117a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1024:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1028:	fe0997e3          	bnez	s3,1016 <vprintf+0x5c>
      if(c == '%'){
    102c:	fd479ee3          	bne	a5,s4,1008 <vprintf+0x4e>
        state = '%';
    1030:	89be                	mv	s3,a5
    1032:	b7e5                	j	101a <vprintf+0x60>
      if(c == 'd'){
    1034:	05878063          	beq	a5,s8,1074 <vprintf+0xba>
      } else if(c == 'l') {
    1038:	05978c63          	beq	a5,s9,1090 <vprintf+0xd6>
      } else if(c == 'x') {
    103c:	07a78863          	beq	a5,s10,10ac <vprintf+0xf2>
      } else if(c == 'p') {
    1040:	09b78463          	beq	a5,s11,10c8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1044:	07300713          	li	a4,115
    1048:	0ce78663          	beq	a5,a4,1114 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    104c:	06300713          	li	a4,99
    1050:	0ee78e63          	beq	a5,a4,114c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    1054:	11478863          	beq	a5,s4,1164 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    1058:	85d2                	mv	a1,s4
    105a:	8556                	mv	a0,s5
    105c:	00000097          	auipc	ra,0x0
    1060:	e92080e7          	jalr	-366(ra) # eee <putc>
        putc(fd, c);
    1064:	85ca                	mv	a1,s2
    1066:	8556                	mv	a0,s5
    1068:	00000097          	auipc	ra,0x0
    106c:	e86080e7          	jalr	-378(ra) # eee <putc>
      }
      state = 0;
    1070:	4981                	li	s3,0
    1072:	b765                	j	101a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    1074:	008b0913          	addi	s2,s6,8
    1078:	4685                	li	a3,1
    107a:	4629                	li	a2,10
    107c:	000b2583          	lw	a1,0(s6)
    1080:	8556                	mv	a0,s5
    1082:	00000097          	auipc	ra,0x0
    1086:	e8e080e7          	jalr	-370(ra) # f10 <printint>
    108a:	8b4a                	mv	s6,s2
      state = 0;
    108c:	4981                	li	s3,0
    108e:	b771                	j	101a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    1090:	008b0913          	addi	s2,s6,8
    1094:	4681                	li	a3,0
    1096:	4629                	li	a2,10
    1098:	000b2583          	lw	a1,0(s6)
    109c:	8556                	mv	a0,s5
    109e:	00000097          	auipc	ra,0x0
    10a2:	e72080e7          	jalr	-398(ra) # f10 <printint>
    10a6:	8b4a                	mv	s6,s2
      state = 0;
    10a8:	4981                	li	s3,0
    10aa:	bf85                	j	101a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    10ac:	008b0913          	addi	s2,s6,8
    10b0:	4681                	li	a3,0
    10b2:	4641                	li	a2,16
    10b4:	000b2583          	lw	a1,0(s6)
    10b8:	8556                	mv	a0,s5
    10ba:	00000097          	auipc	ra,0x0
    10be:	e56080e7          	jalr	-426(ra) # f10 <printint>
    10c2:	8b4a                	mv	s6,s2
      state = 0;
    10c4:	4981                	li	s3,0
    10c6:	bf91                	j	101a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    10c8:	008b0793          	addi	a5,s6,8
    10cc:	f8f43423          	sd	a5,-120(s0)
    10d0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    10d4:	03000593          	li	a1,48
    10d8:	8556                	mv	a0,s5
    10da:	00000097          	auipc	ra,0x0
    10de:	e14080e7          	jalr	-492(ra) # eee <putc>
  putc(fd, 'x');
    10e2:	85ea                	mv	a1,s10
    10e4:	8556                	mv	a0,s5
    10e6:	00000097          	auipc	ra,0x0
    10ea:	e08080e7          	jalr	-504(ra) # eee <putc>
    10ee:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    10f0:	03c9d793          	srli	a5,s3,0x3c
    10f4:	97de                	add	a5,a5,s7
    10f6:	0007c583          	lbu	a1,0(a5)
    10fa:	8556                	mv	a0,s5
    10fc:	00000097          	auipc	ra,0x0
    1100:	df2080e7          	jalr	-526(ra) # eee <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1104:	0992                	slli	s3,s3,0x4
    1106:	397d                	addiw	s2,s2,-1
    1108:	fe0914e3          	bnez	s2,10f0 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    110c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    1110:	4981                	li	s3,0
    1112:	b721                	j	101a <vprintf+0x60>
        s = va_arg(ap, char*);
    1114:	008b0993          	addi	s3,s6,8
    1118:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    111c:	02090163          	beqz	s2,113e <vprintf+0x184>
        while(*s != 0){
    1120:	00094583          	lbu	a1,0(s2)
    1124:	c9a1                	beqz	a1,1174 <vprintf+0x1ba>
          putc(fd, *s);
    1126:	8556                	mv	a0,s5
    1128:	00000097          	auipc	ra,0x0
    112c:	dc6080e7          	jalr	-570(ra) # eee <putc>
          s++;
    1130:	0905                	addi	s2,s2,1
        while(*s != 0){
    1132:	00094583          	lbu	a1,0(s2)
    1136:	f9e5                	bnez	a1,1126 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1138:	8b4e                	mv	s6,s3
      state = 0;
    113a:	4981                	li	s3,0
    113c:	bdf9                	j	101a <vprintf+0x60>
          s = "(null)";
    113e:	00000917          	auipc	s2,0x0
    1142:	37a90913          	addi	s2,s2,890 # 14b8 <malloc+0x234>
        while(*s != 0){
    1146:	02800593          	li	a1,40
    114a:	bff1                	j	1126 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    114c:	008b0913          	addi	s2,s6,8
    1150:	000b4583          	lbu	a1,0(s6)
    1154:	8556                	mv	a0,s5
    1156:	00000097          	auipc	ra,0x0
    115a:	d98080e7          	jalr	-616(ra) # eee <putc>
    115e:	8b4a                	mv	s6,s2
      state = 0;
    1160:	4981                	li	s3,0
    1162:	bd65                	j	101a <vprintf+0x60>
        putc(fd, c);
    1164:	85d2                	mv	a1,s4
    1166:	8556                	mv	a0,s5
    1168:	00000097          	auipc	ra,0x0
    116c:	d86080e7          	jalr	-634(ra) # eee <putc>
      state = 0;
    1170:	4981                	li	s3,0
    1172:	b565                	j	101a <vprintf+0x60>
        s = va_arg(ap, char*);
    1174:	8b4e                	mv	s6,s3
      state = 0;
    1176:	4981                	li	s3,0
    1178:	b54d                	j	101a <vprintf+0x60>
    }
  }
}
    117a:	70e6                	ld	ra,120(sp)
    117c:	7446                	ld	s0,112(sp)
    117e:	74a6                	ld	s1,104(sp)
    1180:	7906                	ld	s2,96(sp)
    1182:	69e6                	ld	s3,88(sp)
    1184:	6a46                	ld	s4,80(sp)
    1186:	6aa6                	ld	s5,72(sp)
    1188:	6b06                	ld	s6,64(sp)
    118a:	7be2                	ld	s7,56(sp)
    118c:	7c42                	ld	s8,48(sp)
    118e:	7ca2                	ld	s9,40(sp)
    1190:	7d02                	ld	s10,32(sp)
    1192:	6de2                	ld	s11,24(sp)
    1194:	6109                	addi	sp,sp,128
    1196:	8082                	ret

0000000000001198 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    1198:	715d                	addi	sp,sp,-80
    119a:	ec06                	sd	ra,24(sp)
    119c:	e822                	sd	s0,16(sp)
    119e:	1000                	addi	s0,sp,32
    11a0:	e010                	sd	a2,0(s0)
    11a2:	e414                	sd	a3,8(s0)
    11a4:	e818                	sd	a4,16(s0)
    11a6:	ec1c                	sd	a5,24(s0)
    11a8:	03043023          	sd	a6,32(s0)
    11ac:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    11b0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    11b4:	8622                	mv	a2,s0
    11b6:	00000097          	auipc	ra,0x0
    11ba:	e04080e7          	jalr	-508(ra) # fba <vprintf>
}
    11be:	60e2                	ld	ra,24(sp)
    11c0:	6442                	ld	s0,16(sp)
    11c2:	6161                	addi	sp,sp,80
    11c4:	8082                	ret

00000000000011c6 <printf>:

void
printf(const char *fmt, ...)
{
    11c6:	711d                	addi	sp,sp,-96
    11c8:	ec06                	sd	ra,24(sp)
    11ca:	e822                	sd	s0,16(sp)
    11cc:	1000                	addi	s0,sp,32
    11ce:	e40c                	sd	a1,8(s0)
    11d0:	e810                	sd	a2,16(s0)
    11d2:	ec14                	sd	a3,24(s0)
    11d4:	f018                	sd	a4,32(s0)
    11d6:	f41c                	sd	a5,40(s0)
    11d8:	03043823          	sd	a6,48(s0)
    11dc:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    11e0:	00840613          	addi	a2,s0,8
    11e4:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    11e8:	85aa                	mv	a1,a0
    11ea:	4505                	li	a0,1
    11ec:	00000097          	auipc	ra,0x0
    11f0:	dce080e7          	jalr	-562(ra) # fba <vprintf>
}
    11f4:	60e2                	ld	ra,24(sp)
    11f6:	6442                	ld	s0,16(sp)
    11f8:	6125                	addi	sp,sp,96
    11fa:	8082                	ret

00000000000011fc <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    11fc:	1141                	addi	sp,sp,-16
    11fe:	e422                	sd	s0,8(sp)
    1200:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1202:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1206:	00000797          	auipc	a5,0x0
    120a:	2e27b783          	ld	a5,738(a5) # 14e8 <freep>
    120e:	a805                	j	123e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    1210:	4618                	lw	a4,8(a2)
    1212:	9db9                	addw	a1,a1,a4
    1214:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1218:	6398                	ld	a4,0(a5)
    121a:	6318                	ld	a4,0(a4)
    121c:	fee53823          	sd	a4,-16(a0)
    1220:	a091                	j	1264 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1222:	ff852703          	lw	a4,-8(a0)
    1226:	9e39                	addw	a2,a2,a4
    1228:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    122a:	ff053703          	ld	a4,-16(a0)
    122e:	e398                	sd	a4,0(a5)
    1230:	a099                	j	1276 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1232:	6398                	ld	a4,0(a5)
    1234:	00e7e463          	bltu	a5,a4,123c <free+0x40>
    1238:	00e6ea63          	bltu	a3,a4,124c <free+0x50>
{
    123c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    123e:	fed7fae3          	bgeu	a5,a3,1232 <free+0x36>
    1242:	6398                	ld	a4,0(a5)
    1244:	00e6e463          	bltu	a3,a4,124c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1248:	fee7eae3          	bltu	a5,a4,123c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    124c:	ff852583          	lw	a1,-8(a0)
    1250:	6390                	ld	a2,0(a5)
    1252:	02059813          	slli	a6,a1,0x20
    1256:	01c85713          	srli	a4,a6,0x1c
    125a:	9736                	add	a4,a4,a3
    125c:	fae60ae3          	beq	a2,a4,1210 <free+0x14>
    bp->s.ptr = p->s.ptr;
    1260:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    1264:	4790                	lw	a2,8(a5)
    1266:	02061593          	slli	a1,a2,0x20
    126a:	01c5d713          	srli	a4,a1,0x1c
    126e:	973e                	add	a4,a4,a5
    1270:	fae689e3          	beq	a3,a4,1222 <free+0x26>
  } else
    p->s.ptr = bp;
    1274:	e394                	sd	a3,0(a5)
  freep = p;
    1276:	00000717          	auipc	a4,0x0
    127a:	26f73923          	sd	a5,626(a4) # 14e8 <freep>
}
    127e:	6422                	ld	s0,8(sp)
    1280:	0141                	addi	sp,sp,16
    1282:	8082                	ret

0000000000001284 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    1284:	7139                	addi	sp,sp,-64
    1286:	fc06                	sd	ra,56(sp)
    1288:	f822                	sd	s0,48(sp)
    128a:	f426                	sd	s1,40(sp)
    128c:	f04a                	sd	s2,32(sp)
    128e:	ec4e                	sd	s3,24(sp)
    1290:	e852                	sd	s4,16(sp)
    1292:	e456                	sd	s5,8(sp)
    1294:	e05a                	sd	s6,0(sp)
    1296:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    1298:	02051493          	slli	s1,a0,0x20
    129c:	9081                	srli	s1,s1,0x20
    129e:	04bd                	addi	s1,s1,15
    12a0:	8091                	srli	s1,s1,0x4
    12a2:	0014899b          	addiw	s3,s1,1
    12a6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12a8:	00000517          	auipc	a0,0x0
    12ac:	24053503          	ld	a0,576(a0) # 14e8 <freep>
    12b0:	c515                	beqz	a0,12dc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12b2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12b4:	4798                	lw	a4,8(a5)
    12b6:	02977f63          	bgeu	a4,s1,12f4 <malloc+0x70>
    12ba:	8a4e                	mv	s4,s3
    12bc:	0009871b          	sext.w	a4,s3
    12c0:	6685                	lui	a3,0x1
    12c2:	00d77363          	bgeu	a4,a3,12c8 <malloc+0x44>
    12c6:	6a05                	lui	s4,0x1
    12c8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    12cc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    12d0:	00000917          	auipc	s2,0x0
    12d4:	21890913          	addi	s2,s2,536 # 14e8 <freep>
  if(p == (char*)-1)
    12d8:	5afd                	li	s5,-1
    12da:	a895                	j	134e <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    12dc:	00000797          	auipc	a5,0x0
    12e0:	27c78793          	addi	a5,a5,636 # 1558 <base>
    12e4:	00000717          	auipc	a4,0x0
    12e8:	20f73223          	sd	a5,516(a4) # 14e8 <freep>
    12ec:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    12ee:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    12f2:	b7e1                	j	12ba <malloc+0x36>
      if(p->s.size == nunits)
    12f4:	02e48c63          	beq	s1,a4,132c <malloc+0xa8>
        p->s.size -= nunits;
    12f8:	4137073b          	subw	a4,a4,s3
    12fc:	c798                	sw	a4,8(a5)
        p += p->s.size;
    12fe:	02071693          	slli	a3,a4,0x20
    1302:	01c6d713          	srli	a4,a3,0x1c
    1306:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    1308:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    130c:	00000717          	auipc	a4,0x0
    1310:	1ca73e23          	sd	a0,476(a4) # 14e8 <freep>
      return (void*)(p + 1);
    1314:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1318:	70e2                	ld	ra,56(sp)
    131a:	7442                	ld	s0,48(sp)
    131c:	74a2                	ld	s1,40(sp)
    131e:	7902                	ld	s2,32(sp)
    1320:	69e2                	ld	s3,24(sp)
    1322:	6a42                	ld	s4,16(sp)
    1324:	6aa2                	ld	s5,8(sp)
    1326:	6b02                	ld	s6,0(sp)
    1328:	6121                	addi	sp,sp,64
    132a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    132c:	6398                	ld	a4,0(a5)
    132e:	e118                	sd	a4,0(a0)
    1330:	bff1                	j	130c <malloc+0x88>
  hp->s.size = nu;
    1332:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1336:	0541                	addi	a0,a0,16
    1338:	00000097          	auipc	ra,0x0
    133c:	ec4080e7          	jalr	-316(ra) # 11fc <free>
  return freep;
    1340:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1344:	d971                	beqz	a0,1318 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1346:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1348:	4798                	lw	a4,8(a5)
    134a:	fa9775e3          	bgeu	a4,s1,12f4 <malloc+0x70>
    if(p == freep)
    134e:	00093703          	ld	a4,0(s2)
    1352:	853e                	mv	a0,a5
    1354:	fef719e3          	bne	a4,a5,1346 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    1358:	8552                	mv	a0,s4
    135a:	00000097          	auipc	ra,0x0
    135e:	b74080e7          	jalr	-1164(ra) # ece <sbrk>
  if(p == (char*)-1)
    1362:	fd5518e3          	bne	a0,s5,1332 <malloc+0xae>
        return 0;
    1366:	4501                	li	a0,0
    1368:	bf45                	j	1318 <malloc+0x94>
