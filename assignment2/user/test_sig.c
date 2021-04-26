#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"

struct sigaction {
    void (*sa_handler) (int);
    uint sigmask;
};
// The test should include spawning of multiple processes, modifying the handlers using
// sigaction, restoring previous handlers using the sigaction oldact, blocking signals.
// All possible actions should be tested, as well as user space signals.
// You should update the existing kill user program to support signal sending, as in Linux kill
// shell command.

int test = 0;

void test_kill_handler(int x){
    printf("kill handler invoked\n");
}

void test2_handler(int x){
    printf("created in order to make test_handler`s address not 0\n");
}


void test1_handler(int signum){
    printf("created also in order to make test_handler`s address not 0\n");
}


void t_handler(int signum){
    test = 1;
}

void test_handler(int signum){
    test = 1;
}

int main(int argc, char **argv)
{
    printf("HELLO TEST SIG\n");
    printf("test2 handler pointer: %p\n", test2_handler);
    printf("test handler pointer: %p\n", t_handler);
    printf("t handler pointer: %p\n", t_handler);
    printf("test1 handler pointer: %p\n", test1_handler);

    test2_handler(1);

    test = 0;
    
    struct sigaction act;
    act.sa_handler = (void(*)(int)) test_handler;
    act.sigmask = 0;

    if(sigaction(SIGSTOP, &act, 0) != -1){
        printf("test1 failed - SIGSTOP cannot be modified\n");
    }else{
        printf("test1 passed\n");
    }

    if(sigaction(SIGKILL, &act, 0) != -1){
        printf("test2 failed - SIGKILL cannot be modified\n");
    }else{
        printf("test2 passed\n");
    }

    act.sigmask = (1 << SIGKILL) | (1 << SIGSTOP);
    if(sigaction(SIGSTOP, &act, 0) != -1){
        printf("test3 failed - SIGSTOP and SIGKILL cannot be ignored\n");
    }else{
        printf("test3 passed\n");
    }

    uint mask = (1 << SIGKILL) | (1 << SIGSTOP);
    if (sigprocmask(mask) != -1){
        printf("test4 failed - SIGSTOP and SIGKILL cannot be blocked\n");
    }else{
        printf("test4 passed\n");
    }

    mask = (1 << 7);
    if (sigprocmask(mask) != 0){
        printf("test5 failed - init mask should be 0\n");
    }else{
        printf("test5 passed\n");
    }
    
    if (sigprocmask((1 << 14)) != mask){
        printf("test6 failed - old mask should be 7\n");
    }else{
        printf("test6 passed\n");
    }
    
    act.sigmask = 0;
    if (sigaction(7, &act, 0) == 0){
        kill(getpid(), 7);
        sleep(2);
        if(test != 1){
            printf("test7 failed - test_handler did not invoke\n");
        }else{
            printf("test7 passed\n");
        }
    }else{
        printf("test7 failed - sigaction failed\n");
    }

    test = 0;
    sigprocmask((1 << 14));
    if (sigaction(14, &act, 0) == 0){
        kill(getpid(), 14);
        sleep(2);
        if(test == 1){
            printf("test8 failed - test_handler did not blocked by the mask\n");
        } else{
            printf("test8 passed\n");
        }   
    }else{
        printf("test8 failed - sigaction failed\n");
    }

    printf("in order to pass tests 9-12 you should get a passed messages\n");

    // check sleep and wakeup child
    int pid = fork();
    if (pid == 0) {
        sleep(1);
        printf("test9 - passed\n");
        exit(0);
    } else {
        kill(pid, SIGSTOP);
        sleep(2);
        kill(pid, SIGCONT);
        wait(0);
    }

    // check kill child 
    pid = fork();
    if (pid == 0) {
        while(1){
            sleep(1);
        }
    } else {
        kill(pid, SIGKILL);
        wait(0);
        printf("test 10 - passed\n");
    }

    //check kill child with SIG_DFL
    pid = fork();
    if (pid == 0) {
        while(1){
            sleep(1);
        }
    } else {
        kill(pid, 24);
        wait(0);
        printf("test 11 - passed\n");
    }

    // check if child inherit parnet's mask and handlers
    act.sa_handler = (void(*)(int)) test_handler;
    act.sigmask = 0;
    sigaction(27, &act, 0);
    sigprocmask((1<<26));
    pid = fork();
    if(pid == 0){
        if(sigprocmask(0) != (1<<26)){
            printf("test12A faild - child didn't inherit parent's mask\n");
        }else{
            printf("test12A passed\n");
        }
        kill(pid, 27);
        printf("test12B passed\n");
    }else{
        wait(0);
    }
    
    exit(0);
}



