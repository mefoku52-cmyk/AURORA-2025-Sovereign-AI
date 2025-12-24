#ifndef AURORA_OS_H
#define AURORA_OS_H

#ifdef __cplusplus
extern "C" {
#endif

void set_process_limits(int max_ram_mb, int max_cpu_sec);
int get_battery_percentage();
int get_cpu_temperature();
void adjust_oom_score(int score);
void graceful_self_terminate();

#ifdef __cplusplus
}
#endif

#endif
