#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"


struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

int nexttid = 1;
struct spinlock tid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);
static void freethread(struct thread *t);

extern char trampoline[]; // trampoline.S
extern void* start_inject_sigret; // ADDED Q2.4
extern void* end_inject_sigret; // ADDED Q2.4

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

struct spinlock join_lock; // ADDED Q3.2

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
    initlock(&p->lock, "proc");
    //p->kstack = KSTACK((int) (p - proc)); ADDED Q3
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      initlock(&t->lock, "thread");
    }
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->thread->proc; //ADDED Q3
  pop_off();
  return p;
}

// ADDED Q3
// Return the current struct thread *, or zero if none.
struct thread*
mythread(void) {
  push_off();
  struct cpu *c = mycpu();
  struct thread *t = c->thread;
  pop_off();
  return t;
}

int
allocpid() {
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// ADDED Q3
int
alloctid() {
  int tid;
  
  acquire(&tid_lock);
  tid = nexttid;
  nexttid = nexttid + 1;
  release(&tid_lock);

  return tid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // ADDED Q2
  p->pending_signals = 0;
  p->signal_mask = 0;
  for(int signum = 0; signum < SIG_NUM; signum++){
    p->signal_handlers[signum] = SIG_DFL;
  }

  struct thread *t = &p->threads[0]; // ADDED Q3

  // Allocate a trapframe page.
  // ADDED Q3
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // ADDED Q3
  t->tid = alloctid();
  t->index = 0;
  t->state = USED_T;
  t->trapframe = &p->trapframes[t->index];
  t->proc = p;

  // ADDED Q2 
  // Allocate a trapframe_backup page.
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&t->context, 0, sizeof(t->context));
  t->context.ra = (uint64)forkret;

//TODO: ?
  //if ((t->kstack = (uint64)kalloc()) == 0) 
  //  {
 //       freeproc(p);
  //      release(&p->lock);
  //      return 0;
  //  }

  t->context.sp = t->kstack + PGSIZE;
  return p;
}

// ADDED Q3
static void
freethread(struct thread *t)
{
    if (t->kstack)
        kfree((void *)t->kstack);
    t->kstack = 0;
    if(t->trapframe)
      kfree((void*)t->trapframe);
    t->trapframe = 0;
    t->tid = 0;
    t->proc = 0;
    t->chan = 0;
    t->terminated = 0;
    t->state = UNUSED_T;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  //ADDED Q3
 // if(p->trapframe)
  //  kfree((void*)p->trapframe);
 // p->trapframe = 0;

  // ADDED Q2.1.2
  if(p->trapframe_backup)
    kfree((void*)p->trapframe_backup);
  p->trapframe_backup = 0;

  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
 // p->chan = 0; ADDED Q3
  p->killed = 0;
  p->stopped = 0;
  p->xstate = 0;
  p->state = UNUSED;

  // ADDED Q3
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    freethread(t);
  }
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
              (uint64)(p->threads[0].trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
  // TODO: add trapframe_backup?
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  p = allocproc();
  initproc = p;
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->threads[0].trapframe->epc = 0;      // user program counter
  p->threads[0].trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->threads[0].state = RUNNABLE;
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
 // ADDED Q3 - sync over p
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();
  acquire(&p->lock);
  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      release(&p->lock);
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  release(&p->lock);
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct thread *t = mythread();
  struct thread *nt;
  struct proc *np;
  struct proc *p = myproc();
  // Allocate process.
  if((np = allocproc()) == 0) {
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
  nt = &np->threads[0]; // ADDED Q3
  // copy saved user registers.
  *(nt->trapframe) = *(t->trapframe); 

  // Cause fork to return 0 in the child.
  nt->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    np->signal_handlers[i] = p->signal_handlers[i];    
  }
  np->pending_signals = 0; // ADDED Q2.1.2
  release(&np->lock);

  acquire(&nt->lock);
  nt->state = RUNNABLE;
  release(&nt->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  // ADDED Q3
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    if (t->tid != mythread()->tid) {
      acquire(&t->lock);
      t->terminated = 1;
      if (t->state == SLEEPING) {
          t->state = RUNNABLE;
      }
      release(&t->lock);
      kthread_join(t->tid, 0);
    }
  }

  release(&p->lock);

  struct thread *t = mythread();
  acquire(&t->lock);
  t->xstate = status;
  t->state = ZOMBIE_T;

  release(&wait_lock);
  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// ADDED Q2.3.1
// ADDED Q3
void
kill_handler() //TODO: update to thread??
{
  struct proc *p = myproc();
  p->killed = 1; 
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    if (t->state == SLEEPING) {
      t->state = RUNNABLE;
    }
  }

}

// ADDED Q2.3.1
int received_continue()
{
    struct proc *p = myproc();
    acquire(&p->lock);
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    for (int signum = 0; signum < SIG_NUM; signum++) {
      if( (pending_and_not_blocked & (1 << signum)) &&
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
            release(&p->lock);
            return 1;
      }
    }
    release(&p->lock);
    return 0;
}

// ADDED Q2.3.1
void
stop_handler()
{
  struct proc *p = myproc();
  p->stopped = 1;
  release(&p->lock);
  while (p->stopped && !received_continue())
  {
      yield();
  }
  acquire(&p->lock);
}

// ADDED Q2.3.1
void
continue_handler()
{
  struct proc *p = myproc();
  p->stopped = 0;
}

// ADDED Q2.4
void 
handle_user_signals(int signum) {
  struct thread *t = mythread();
  struct proc *p = myproc();
  
  p->signal_mask_backup = p->signal_mask;
  p->signal_mask = p->signal_handlers_masks[signum];  

  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));

  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;

  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);

  t->trapframe->a0 = signum;
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
  t->trapframe->ra = t->trapframe->sp;
}

// ADDED Q2.4
void 
handle_signals()
{
  struct proc *p = myproc();
  acquire(&p->lock);
  for(int signum = 0; signum < SIG_NUM; signum++){
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    if(pending_and_not_blocked & (1 << signum)){
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
        stop_handler();
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
        continue_handler();
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
        kill_handler();
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
      } else if (p->handling_user_level_signal == 0){
        p->handling_user_level_signal = 1;
        handle_user_signals(signum);
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
      }
    }
  }
  release(&p->lock);
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
 // ADDED Q3
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
 
  c->thread = 0;

  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    // TODO: return at the end all for to- for(struct thread *t = p->threads; t< &p->threads[NTHREAD]; t++)
    for(p = proc; p < &proc[NPROC]; p++) {
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
        acquire(&t->lock);
        if(t->state == RUNNABLE) {
          // Switch to chosen process.  It is the process's job
          // to release its lock and then reacquire it
          // before jumping back to us.
          t->state = RUNNING;
          c->thread = t;
          swtch(&c->context, &t->context);

          // Process is done running for now.
          // It should have changed its p->state before coming back.
          c->thread = 0;
        }
        release(&t->lock);
      }
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.

// ADDED Q3
void
sched(void)
{
  int intena;
  struct thread *t = mythread();

  if(!holding(&t->lock))
    panic("sched t->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(t->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&t->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// ADDED Q3
// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct thread *t = mythread();
  acquire(&t->lock);
  t->state = RUNNABLE;
  sched();
  release(&t->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding t->lock from scheduler.
  release(&mythread()->lock); // ADDED Q3

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct thread *t = mythread();
  
  // Must acquire t->lock in order to
  // change t->state and then call sched.
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  t->chan = chan;
  t->state = SLEEPING;

  sched();

  // Tidy up.
  t->chan = 0;

  // Reacquire original lock.
  release(&t->lock);
  acquire(lk);
}

// Wake up all threads sleeping on chan.
// Must be called without any p->lock.
// ADDED Q3
void
wakeup(void *chan)
{
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
          t->state = RUNNABLE;
        }
        release(&t->lock);
      }
    }
  }
}

// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid) {
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  // no such pid
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
 // [SLEEPING]  "sleep ", // ADDED Q3
 // [RUNNABLE]  "runble",
 // [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
  struct proc *p = myproc();
  uint old_mask = p->signal_mask;
  acquire(&p->lock);

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
  release(&p->lock);
  return old_mask;
}

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
  struct proc *p = myproc();
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    return -1;
  }

  acquire(&p->lock);

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    release(&p->lock);
    return -1;
  }

  

  if (oldact) {
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
      release(&p->lock);
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
  }

  release(&p->lock);
  return 0;
}

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
  struct thread *t = mythread();
  struct proc *p = myproc();

  acquire(&p->lock);
  acquire(&t->lock);
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
  p->signal_mask = p->signal_mask_backup;
  p->handling_user_level_signal = 0;
  release(&t->lock);
  release(&p->lock);
}

// ADDED Q3.2
static struct thread*
allocthread(struct proc *p)
{
    int t_index = 0;
    struct thread *t;

    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
      if (t != mythread()) {
        acquire(&t->lock);
        if (t->state == UNUSED_T) {
          goto found;
        }
        release(&t->lock);
      }
    }
    return 0;

found:
  t->tid = alloctid();
  t->index = t_index;
  t->state = USED_T;
  t->trapframe = &p->trapframes[t_index];
  t->proc = p;

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&t->context, 0, sizeof(t->context));
  //t->context.ra = (uint64)forkret; // TODO: check? ra?
  if((t->kstack = (uint64) kalloc()) == 0) {
      freethread(t);
      release(&t->lock);
      return 0;
  }
  t->context.sp = t->kstack + PGSIZE;
  return t;
}

int
kthread_create(void (*start_func)(), void* stack)
{
    struct thread* t = mythread();
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    // *nt->context = *t->context; // TODO: check
    nt->trapframe->epc = (uint64)start_func;
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE);
    nt->state = RUNNABLE;

    release(&nt->lock);
    return nt->tid;
}

void
exit_single_thread(int status) {
  struct thread *t = mythread();
  struct proc *p = myproc();

  acquire(&t->lock);
  t->xstate = status;
  t->state = ZOMBIE_T;

  release(&p->lock);
  wakeup(t);
  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

void
kthread_exit(int status)
{
  struct proc *p = myproc();

  acquire(&p->lock);
  int used_threads = 0;
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    if (t->state != UNUSED_T) {
      used_threads++;
    }
  }

  if (used_threads <= 1) {
    release(&p->lock);
    exit(status);
  }

  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
  struct thread *jt  = 0;
  struct proc *p = myproc();  

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    if (thread_id == temp_t->tid) {
      jt = temp_t;
    }
  }  

  if (jt == 0) {
    return -1;
  }

  acquire(&join_lock);

  // TODO: deadlock?
  while (1) {
    acquire(&jt->lock);
    if (jt->state == ZOMBIE_T) {
      break;
    }
    release(&jt->lock);
    sleep(jt, &join_lock);
  }

  if(status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    release(&jt->lock);
    release(&join_lock);
    return -1;
  }

  freethread(jt);
  release(&jt->lock);
  release(&join_lock);
  return 0;
}
