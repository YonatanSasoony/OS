// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"

// #define print(s) printf("%s\n", s);
// #define STACK_SIZE 4000

// void func_for_compiler() {
//     print("bla")
// }

// void func() {
//     int tid = kthread_id();
//     printf("thread %d start\n", tid);
//     sleep(1);
//     printf("thread %d end\n", tid);
//     kthread_exit(tid);
// }

// int main(int argc, char *argv[])
// {
//     void* stack;

//     printf("HELLO TEST THREAD\n");
//     printf("address of func: %p\n", func);
//     printf("address of func_for_compiler: %p\n", func_for_compiler);
    
//     for(int i=0; i<4; i++){
//         stack = malloc(STACK_SIZE);
//         kthread_create(func, stack);
//     }

//     sleep(10);

//     exit(0);
// }

// ***************************************************************************************************************************

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000
#define NTHREADS 2
int shared = 0;
void func()
{
    sleep(1);
    // printf("woke up\n");
    shared++;
    // printf("!!!!!!!!!!!!!!!!!!!!!!1\n");
    kthread_exit(7);
}

int main(int argc, char *argv[])
{
    int tids[NTHREADS];
    void *stacks[NTHREADS];
    for (int i = 0; i < NTHREADS; i++)
    {
        void *stack = malloc(STACK_SIZE);
        tids[i] = kthread_create(func, stack);
        stacks[i] = stack;
    }

    for (int i = 0; i < NTHREADS; i++)
    {
        int status;
        kthread_join(tids[i], &status);
        free(stacks[i]);
        printf("the status is: %d\n", status);
    }
    printf("%d\n", shared);
    exit(0);
}