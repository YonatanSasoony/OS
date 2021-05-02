#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000

void func() {
    print("I got 99 problems but a thread ain't one")
    kthread_exit(7);
}

int main(int argc, char *argv[])
{
    int tid;
    int status;
    void* stack = malloc(STACK_SIZE);
    printf("HELLO TEST THREAD\n");
    printf("thread id: %d\n",kthread_id());
    tid = kthread_create(func, stack);
    printf("new thread id: %d\n",kthread_id());
    kthread_join(tid,&status);
    tid = kthread_id();
    printf("thread id: %d\n",kthread_id());
    free(stack);
    printf("status: %d\n", status);
    exit(0);
}
