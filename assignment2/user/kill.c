#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// ADDED Q2.2.2 
int
main(int argc, char **argv)
{
  int i;

  if(argc < 3 || argc % 2 == 0){ // must have even parameters, including the 'kill' - odd
    fprintf(2, "usage: kill pid1 signal1 pid2 signal2 ... pidN signalN \n");
    exit(1);
  }
  for(i=1; i<argc - 1 ; i+=2)
    kill(atoi(argv[i]), atoi(argv[i+1])); 
  exit(0);
}
