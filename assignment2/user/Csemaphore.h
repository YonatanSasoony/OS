struct counting_semaphore{
    int permits;
    int bs1;
    int bs2;
};

int  csem_alloc(struct counting_semaphore*, int);
void csem_free(struct counting_semaphore*);
void csem_down(struct counting_semaphore*);
void csem_up(struct counting_semaphore*);

// #include "kernel/types.h"
// // #include "kernel/stat.h"
// #include "user/user.h"



// int 
// csem_alloc(struct counting_semaphore* sem  , int initial_value)
// {
//     if(sem == 0 || initial_value < 0)
//         return -2;

//     if((sem->bs1 = bsem_alloc()) == -1){
//         return -1;
//     }

//     if((sem->bs2 = bsem_alloc()) == -1){
//         return -1;
//     }

//     // S2 = min(1, initial_value);
//     if(initial_value == 0) {
//         bsem_down(sem->bs2);
//     }

//     sem->permits = initial_value;
//     return 0;
// }

// void 
// csem_free(struct counting_semaphore* sem)
// {
//     bsem_free(sem->bs1);
//     bsem_free(sem->bs2);
//     sem->permits = 0;
// }

// void 
// csem_down(struct counting_semaphore* sem)
// {
//     bsem_down(sem->bs2);
//     bsem_down(sem->bs1);
//     sem->permits--;
//     if(sem->permits > 0){
//        bsem_up(sem->bs2); 
//     }
//     bsem_up(sem->bs1);
// }

// void 
// csem_up(struct counting_semaphore* sem)
// {
//     bsem_down(sem->bs1);
//     sem->permits++;
//     if(sem->permits == 1){
//         bsem_up(sem->bs2); 
//     }
//     bsem_up(sem->bs1);
// }
