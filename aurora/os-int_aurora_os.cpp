#include "aurora_os.h"
#include <sys/resource.h>
#include <sys/prctl.h>
#include <unistd.h>
#include <signal.h>
#include <cstdio>
#include <cstdlib>

void set_process_limits(int max_ram_mb, int max_cpu_sec) {
    struct rlimit rl;
    
    // RAM limit
    rl.rlim_cur = (rlim_t)max_ram_mb * 1024 * 1024;
    rl.rlim_max = (rlim_t)max_ram_mb * 1024 * 1024;
    setrlimit(RLIMIT_AS, &rl);
    
    // CPU limit
    rl.rlim_cur = (rlim_t)max_cpu_sec;
    rl.rlim_max = (rlim_t)max_cpu_sec;
    setrlimit(RLIMIT_CPU, &rl);
}

int get_battery_percentage() {
    FILE *fp = fopen("/sys/class/power_supply/battery/capacity", "r");
    if (!fp) return 100;
    int level;
    fscanf(fp, "%d", &level);
    fclose(fp);
    return level;
}

int get_cpu_temperature() {
    FILE *fp = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    if (!fp) return 0;
    int temp;
    fscanf(fp, "%d", &temp);
    fclose(fp);
    return temp / 1000;
}

void adjust_oom_score(int score) {
    prctl(PR_SET_OOM_SCORE_ADJ, score);
}

void graceful_self_terminate() {
    kill(getpid(), SIGTERM);
}
