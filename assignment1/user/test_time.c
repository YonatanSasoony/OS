#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/param.h"
#include "kernel/spinlock.h"
#include "kernel/riscv.h"
#include "kernel/proc.h"

int main(int argc, char** argv){

    int cpid = fork();
    if(cpid == 0){
        sleep(5);
        int k = 0; 
        for (int i = 0; i < 1000000000; i++) {
             k++; 
        } 
        fprintf(2, "k:%d\n",k); 
        sleep(5);

        exit(0);
    }
    else {
        int status;
        struct perf performance;
        int pid2 = wait_stat(&status, &performance);
        
        fprintf(2, "child pid: %d\n", cpid);
        fprintf(2, "returned pid: %d\n", pid2);
        fprintf(2, "status: %d\n", status);
        
        fprintf(2, "performance of pid:%d\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nruime:%d\n",
        pid2,performance.ctime,performance.ttime,performance.stime,performance.retime,
        performance.rutime);
        
    }

    exit(0);
}

