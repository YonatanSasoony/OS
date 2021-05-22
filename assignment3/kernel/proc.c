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

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

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
      p->kstack = KSTACK((int) (p - proc));
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
  struct proc *p = c->proc;
  pop_off();
  return p;
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

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
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
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
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
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
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
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
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
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// ADDED Q1
int fill_swapFile(struct proc *p)
{
  char *page = kalloc();
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    if (writeToSwapFile(p, page, disk_pg->offset, PGSIZE) < 0) {
      return -1;
    }
  }
  kfree(page);
  return 0;
}

// ADDED Q1
int copy_swapFile(struct proc *src, struct proc *dst) {
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    return -1;
  }

  char *buffer = (char *)kalloc();
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    if(disk_pg->used) {
      if (readFromSwapFile(src, buffer, disk_pg->offset, PGSIZE) < 0) {
        return -1;
      }
      if (writeToSwapFile(dst, buffer, disk_pg->offset, PGSIZE) < 0) {
        return -1;
      }
    }
  }
  kfree((void *)buffer);
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

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

  // ADDED Q1
  if (relevant_metadata_proc(np)) {
    if (init_metadata(np) < 0) {
      freeproc(np);
      return -1;
    }
    if (fill_swapFile(np) < 0) {
      freeproc(np);
      return -1;
    }
  }

  if (relevant_metadata_proc(p)) {
    if (copy_swapFile(p, np) < 0) {
      freeproc(np);
      free_metadata(np);
      return -1;
    }
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    np->scfifo_index = p->scfifo_index; // ADDED Q2
  }

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);
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

  // ADDED Q1
  if (relevant_metadata_proc(p)) {
    free_metadata(p);
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
         if (relevant_metadata_proc(p)) {
           free_metadata(np);
         }

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

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // ADDED Q2
        #if defined(NFUA) || defined(LAPA)
          maintain_age(p);
        #endif
        
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
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
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
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
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
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

// ADDED Q1 - p->lock must not be held because of createSwapFile!
int init_metadata(struct proc *p)
{
  if (!p->swapFile && createSwapFile(p) < 0) {
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    p->ram_pages[i].va = 0;
    p->ram_pages[i].age = 0; // ADDED Q2
    p->ram_pages[i].used = 0;
  }
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    p->disk_pages[i].va = 0;
    p->disk_pages[i].offset = i * PGSIZE;
    p->disk_pages[i].used = 0;
  }
  p->scfifo_index = 0; // ADDED Q2
  return 0;
}

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    if (p->swapFile && removeSwapFile(p) < 0) {
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
      p->ram_pages[i].va = 0;
      p->ram_pages[i].age = 0; // ADDED Q2
      p->ram_pages[i].used = 0;
    }
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
      p->disk_pages[i].va = 0;
      p->disk_pages[i].offset = 0;
      p->disk_pages[i].used = 0;
    }
    p->scfifo_index = 0; // ADDED Q2
}
// ADDED Q1
int get_free_page_in_disk()
{
  struct proc *p = myproc();
  int i = 0;
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    if (!disk_pg->used) {
      return i;
    }
  }
  return -1;
}

void swapout(int ram_pg_index)
{
  struct proc *p = myproc();
  if (ram_pg_index < 0 || ram_pg_index >= MAX_PSYC_PAGES) {
    panic("swapout: ram page index out of bounds");
  }
  struct ram_page *ram_pg_to_swap = &p->ram_pages[ram_pg_index];

  if (!ram_pg_to_swap->used) {
    panic("swapout: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    panic("swapout: walk failed");
  }

  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    panic("swapout: page is not in ram");
  }

  int unused_disk_pg_index;
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    panic("swapout: disk overflow");
  }

  struct disk_page *disk_pg_to_store = &p->disk_pages[unused_disk_pg_index];
  uint64 pa = PTE2PA(*pte);
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    panic("swapout: failed to write to swapFile");
  }
  disk_pg_to_store->used = 1;
  disk_pg_to_store->va = ram_pg_to_swap->va;
  kfree((void *)pa);

  ram_pg_to_swap->va = 0;
  ram_pg_to_swap->used = 0;

  *pte = *pte & ~PTE_V;
  *pte = *pte | PTE_PG; // Paged out to secondary storage
  sfence_vma();   // clear TLB
}

void swapin(int disk_index, int ram_index)
{
  if (disk_index < 0 || disk_index >= MAX_DISK_PAGES) {
    panic("swapin: disk index out of bounds");
  }

  if (ram_index < 0 || ram_index >= MAX_PSYC_PAGES) {
    panic("swapin: ram index out of bounds");
  }
  struct proc *p = myproc();
  struct disk_page *disk_pg = &p->disk_pages[disk_index]; 

  if (!disk_pg->used) {
    panic("swapin: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    panic("swapin: unallocated pte");
  }

  if ((*pte & PTE_V) || !(*pte & PTE_PG))
      panic("swapin: page is not in disk");

  struct ram_page *ram_pg = &p->ram_pages[ram_index];
  if (ram_pg->used) {
    panic("swapin: ram page used");
  }

  uint64 npa;
  if ( (npa = (uint64)kalloc()) == 0 ) {
    panic("swapin: failed alocate physical address");
  }

  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    panic("swapin: read from disk failed");
  }

  ram_pg->used = 1;
  ram_pg->va = disk_pg->va;
  // ADDED Q2
  #ifdef LAPA
    ram_pg->age = 0xFFFFFFFF;
  #endif
  #ifndef LAPA 
    ram_pg->age = 0;
  #endif

  disk_pg->va = 0;
  disk_pg->used = 0;

  *pte = *pte | PTE_V;                           
  *pte = *pte & ~PTE_PG;                         
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
  sfence_vma(); // clear TLB
}

int get_unused_ram_index(struct proc* p)
{
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    if (!p->ram_pages[i].used) {
      return i;
    }
  }
  return -1;
}

int get_disk_page_index(struct proc *p, uint64 va)
{
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    if (p->disk_pages[i].va == va) {
      return i;
    }
  }
  return -1;
}

void handle_page_fault(uint64 va)
{
  struct proc *p = myproc();
  pte_t *pte;
  if (!(pte = walk(p->pagetable, va, 0))) {
    panic("handle_page_fault: walk failed");
  }

  if(*pte & PTE_V){
    panic("handle_page_fault: invalid pte");
  }
  
  if(!(*pte & PTE_PG)) {
    panic("handle_page_fault: PTE_PG off");
  }
  
  int unused_ram_pg_index;
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
      int ram_pg_index_to_swap =  index_page_to_swap();
      swapout(ram_pg_index_to_swap); 
      unused_ram_pg_index = ram_pg_index_to_swap;
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
  }
  int target_idx;
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    panic("handle_page_fault: get_disk_page_index failed");
  }
  swapin(target_idx, unused_ram_pg_index);
}

void insert_page_to_ram(uint64 va)
{
  struct proc *p = myproc();
  if (!relevant_metadata_proc(p)) {
    return;
  }
  struct ram_page *ram_pg;
  int unused_ram_pg_index;
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
  {
    int ram_pg_index_to_swap = index_page_to_swap();
    swapout(ram_pg_index_to_swap);
    unused_ram_pg_index = ram_pg_index_to_swap;
  }
  ram_pg = &p->ram_pages[unused_ram_pg_index];
  ram_pg->va = va;
  ram_pg->used = 1;
  // ADDED Q2
  #ifdef LAPA
    ram_pg->age = 0xFFFFFFFF;
  #endif
  #ifndef LAPA 
    ram_pg->age = 0;
  #endif
}

void remove_page_from_ram(uint64 va)
{
  struct proc *p = myproc();
  if (!relevant_metadata_proc(p)) {
    return;
  }
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
      p->ram_pages[i].va = 0;
      p->ram_pages[i].used = 0;
      p->ram_pages[i].age = 0; // ADDED Q2
      return;
    }
  }
  panic("remove_page_from_ram failed");
}

int nfua()
{
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    if(ram_pg->age <= min_age){
      min_index = i;
      min_age = ram_pg->age;
    }
  }
  return min_index;
}

int count_ones(uint num) 
{
  int count = 0;
  while(num > 0){
    int cur_lsb = num % 2;
    count += cur_lsb;
    num = num / 2; 
  }
  return count;
}

int lapa()
{
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    int ram_pg_age_ones = count_ones(ram_pg->age);
    int min_age_ones = count_ones(min_age);
    if (ram_pg_age_ones < min_age_ones) {
      min_index = i;
      min_age = ram_pg->age;
    }
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
      min_index = i;
      min_age = ram_pg->age;
    }
  }
  return min_index;
}

int scfifo()
{
  struct ram_page *cur_ram_pg;
  struct proc *p = myproc();
  int index = p->scfifo_index;
  while(1){
    cur_ram_pg = &p->ram_pages[index];

    pte_t *pte;
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
      panic("scfifo: walk failed");
    }
    
    if(*pte & PTE_A){
      *pte = *pte & ~PTE_A;
      index = (index + 1) % MAX_PSYC_PAGES;
    }
    else{
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
      return index;
    }
  }
}

int index_page_to_swap()
{
  #ifdef NFUA
    return nfua();
  #endif

  #ifdef LAPA
    return lapa();
  #endif

  #ifdef SCFIFO
    return scfifo();
  #endif

  #ifdef NONE
    return -1;
  #endif
  return -1;
}

void maintain_age(struct proc *p){
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    pte_t *pte;
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
      panic("maintain_age: walk failed");
    }
    ram_pg->age = (ram_pg->age >> 1);
    if (*pte & PTE_A){
      ram_pg->age = ram_pg->age | (1 << 31);
      *pte = *pte & ~PTE_A;
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  #ifdef NONE
    return 0;
  #endif
  return p->pid != INIT_PID && p->pid != SHELL_PID;
}