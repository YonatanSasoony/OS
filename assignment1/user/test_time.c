#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/proc.h"


int main(int argc, char** argv){
    int pid = getpid();

    int cpid = fork();
    if(cpid == 0){
        sleep(5);
        exit(0);
    }
    else {
        int status;
        struct perf preformance;
        int pid2 = wait_stat(&status, &preformance);
        
        
        fprintf(2, "child pid: %d\n", cpid);
        fprintf(2, "returned pid: %d\n", pid2);
        fprintf(2, "status: %d\n", status);
        
        
        fprintf(2, "performance of pid:%d\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nruime:%d\n",
        pid2,preformance.ctime,preformance.ttime,preformance.stime,preformance.retime,
        preformance.rutime);
        
    }

    exit(0);
}

