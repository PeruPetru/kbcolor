#include <stdio.h>
#include <stdlib.h>
#include <sys/syslog.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <syslog.h>
#include <time.h>
#include <curl/curl.h>

static void kbcolor_daemon() {
    pid_t pid;

    pid = fork();

    if (pid < 0) 
        exit(EXIT_FAILURE);

    if (pid > 0)
        exit(EXIT_SUCCESS);

    if (setsid() < 0)
        exit(EXIT_FAILURE);

    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP, SIG_IGN);

    pid = fork();

    if (pid < 0)
        exit(EXIT_FAILURE);

    if (pid > 0)
        exit(EXIT_SUCCESS);

    umask(0);

    chdir("/");

    int x;
    for (x = sysconf(_SC_OPEN_MAX); x>=0; x--) {
        close(x);
    }

    openlog("kbcolordaemon", LOG_PID, LOG_DAEMON);
}

int main() {
    kbcolor_daemon();
    
    time_t seconds;
    char buffer[1024];
    
    syslog(LOG_NOTICE, "KBCOLOR Daemon started.");

    while (1) {
        usleep(1e6);
        time(&seconds);
        sprintf(buffer, "kbcolor hue %i", ((int)seconds%360));
        system(buffer);
    }

    syslog(LOG_NOTICE, "KBCOLOR Daemon terminated.");
    closelog();

    return EXIT_SUCCESS;
}

