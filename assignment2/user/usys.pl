#!/usr/bin/perl -w

# Generate usys.S, the stubs for syscalls.

print "# generated by usys.pl - do not edit\n";

print "#include \"kernel/syscall.h\"\n";

sub entry {
    my $name = shift;
    print ".global $name\n";
    print "${name}:\n";
    print " li a7, SYS_${name}\n";
    print " ecall\n";
    print " ret\n";
}
	
entry("fork");
entry("exit");
entry("wait");
entry("pipe");
entry("read");
entry("write");
entry("close");
entry("kill");
entry("exec");
entry("open");
entry("mknod");
entry("unlink");
entry("fstat");
entry("link");
entry("mkdir");
entry("chdir");
entry("dup");
entry("getpid");
entry("sbrk");
entry("sleep");
entry("uptime");
entry("sigprocmask"); # ADDED Q2.1.3
entry("sigaction"); # ADDED Q2.1.4
entry("sigret"); # ADDED Q2.1.5
entry("kthread_create"); # ADDED Q3.2
entry("kthread_id"); # ADDED Q3.2
entry("kthread_exit"); # ADDED Q3.2
entry("kthread_join"); # ADDED Q3.2
entry("bsem_alloc"); # ADDED Q4.1
entry("bsem_free"); # ADDED Q4.1
entry("bsem_down"); # ADDED Q4.1
entry("bsem_up"); # ADDED Q4.1
