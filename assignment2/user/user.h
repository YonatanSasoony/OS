struct stat;
struct rtcdate;
struct sigaction; // ADDED Q2.1.4

// system calls
int fork(void);
int exit(int) __attribute__((noreturn));
int wait(int*);
int pipe(int*);
int write(int, const void*, int);
int read(int, void*, int);
int close(int);
int kill(int, int); // ADDED Q2.2.1
int exec(char*, char**);
int open(const char*, int);
int mknod(const char*, short, short);
int unlink(const char*);
int fstat(int fd, struct stat*);
int link(const char*, const char*);
int mkdir(const char*);
int chdir(const char*);
int dup(int);
int getpid(void);
char* sbrk(int);
int sleep(int);
int uptime(void);
uint sigprocmask(uint); // ADDED Q2.1.3
int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact); // ADDED Q2.1.4
void sigret(void); // ADDED Q2.1.5

// ADDED Q3.2
int kthread_create (void (*)(), void *);
int kthread_id(void);
void kthread_exit(int satus);
int kthread_join(int, int*);

// ADDED Q4.1
int bsem_alloc(void);
void bsem_free(int);
void bsem_down(int);
void bsem_up(int);

// ulib.c
int stat(const char*, struct stat*);
char* strcpy(char*, const char*);
void *memmove(void*, const void*, int);
char* strchr(const char*, char c);
int strcmp(const char*, const char*);
void fprintf(int, const char*, ...);
void printf(const char*, ...);
char* gets(char*, int max);
uint strlen(const char*);
void* memset(void*, int, uint);
void* malloc(uint);
void free(void*);
int atoi(const char*);
int memcmp(const void *, const void *, uint);
void *memcpy(void *, const void *, uint);
