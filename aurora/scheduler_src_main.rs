use sysinfo::{System, SystemExt, ProcessExt};
use tokio::time::{interval, Duration};
use std::collections::BinaryHeap;
use std::cmp::Reverse;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Clone, Serialize, Deserialize)]
struct Task {
    id: Uuid,
    priority: u8, // 0=low, 255=critical
    goal: String,
    resources: ResourceReq,
    created: DateTime<Utc>,
}

#[derive(Clone, Serialize, Deserialize)]
struct ResourceReq {
    ram_mb: u64,
    cpu_cores: u64,
    timeout_sec: u64,
}

struct TaskPriority(Reverse<u8>, Uuid); // Max-heap

impl PartialEq for TaskPriority {
    fn eq(&self, other: &Self) -> bool { self.0 == other.0 }
}
impl Eq for TaskPriority {}
impl PartialOrd for TaskPriority {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.0.cmp(&other.0))
    }
}
impl Ord for TaskPriority {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering { self.0.cmp(&other.0) }
}

struct AuroraScheduler {
    tasks: BinaryHeap<TaskPriority>,
    sys: System,
}

impl AuroraScheduler {
    fn new() -> Self {
        Self {
            tasks: BinaryHeap::new(),
            sys: System::new_all(),
        }
    }

    fn predict_cost(&mut self, goal: &str) -> f64 {
        self.sys.refresh_all();
        let free_ram_gb = (self.sys.total_memory() - self.sys.used_memory()) as f64 / 1e9;
        (goal.len() as f64 / 1000.0) * (4.0 / free_ram_gb.max(1.0))
    }

    async fn can_schedule(&mut self, req: &ResourceReq) -> bool {
        self.sys.refresh_all();
        let free_ram_gb = (self.sys.total_memory() - self.sys.used_memory()) as f64 / 1e9;
        let cpu_usage = self.sys.global_cpu_info().cpu_usage();
        
        free_ram_gb > req.ram_mb as f64 / 1024.0 && cpu_usage < 80.0
    }
}

#[tokio::main]
async fn main() {
    let mut scheduler = AuroraScheduler::new();
    
    let monitor = tokio::spawn(async move {
        let mut interval = interval(Duration::from_secs(1));
        loop {
            interval.tick().await;
            scheduler.sys.refresh_all();
        }
    });
    
    monitor.await.unwrap();
}
