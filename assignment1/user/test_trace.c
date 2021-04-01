#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"


// TODO - remove


int main(int argc, char** argv){
    int pid = getpid();

    fprintf(2, "Father - Hello world!, my pid- %d\n", pid);

    int mask=(1<< 1);
    mask=(1<< SYS_fork) | ( 1<< SYS_kill) | ( 1<< SYS_sbrk) | ( 1<< SYS_write);

    sleep(1); //doesn't print this sleep
    trace(mask, pid);
    int cpid=fork();// father prints fork
    if (cpid==0){ //son
        mask= (1<< SYS_sleep) | ( 1<< SYS_kill); //to turn on only the sleep and kill bits
        trace(mask, getpid());

        fprintf(2, "Son- Hello world!, my pid- %d\n", getpid());

        int gpid = fork(); // son not prints fork 
        if (gpid==0){ //grandson
            fprintf(2, "Grandson- Hello world!, my pid- %d\n", getpid());
            sleep(10); // should print and fail
        } else { //son
            sleep(5); // son should print
            kill(gpid);// should print that son killed grandson
            kill(200);// should print that son killed 200 and failed

        }

        exit(0);//should print nothing
    } else {
        sleep(10);// the father doesnt pring it - has original mask
        sbrk(4096); // father should print
        fprintf(2, "BYE"); // father should print
    }
    exit(0);
}

/* example for right printing:

Father - Hello world!, my pid- 3
3: syscall fork NULL -> 4
Son- Hello world!, my pid- 4

Grandson- Hello world!, my pid- 5
4: syscall sleep -> 0
5: syscall sleep -> 0
4: syscall kill 5 -> 0
4: syscall kill 200 -> -1
3: syscall sbrk 4096 -> 12288
B
Y
E ?
 */