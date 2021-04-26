#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"

// ADDED Q2.2.2 
int
main(int argc, char **argv)
{
  int i;

  if(argc < 3){ //TODO: check usage - currently assuming- kill <pid> <signal1> ... <signalN>
    //waiting for forum Q-  https://moodle2.bgu.ac.il/moodle/mod/forum/discuss.php?d=494713
    fprintf(2, "usage: kill pid signal1... sginalN\n");
    exit(1);
  }
  for(i=2; i<argc; i++)
    kill(atoi(argv[1]), atoi(argv[i])); 
  exit(0);
}
