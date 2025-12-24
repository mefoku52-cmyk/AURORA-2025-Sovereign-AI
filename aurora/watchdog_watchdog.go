package main

import (
\t"log"
\t"os/exec"
\t"time"
)

func main() {
\tfor i := 0; i < 10; i++ {
\t\tcmd := exec.Command("uvicorn", "api.main:app", "--port", "8080")
\t\terr := cmd.Start()
\t\tif err != nil {
\t\t\tlog.Printf("Restart %d failed: %v", i, err)
\t\t\ttime.Sleep(5 * time.Second)
\t\t\tcontinue
\t\t}
\t\t
\t\tcmd.Wait()
\t\tlog.Printf("Process %d died, restarting...", i)
\t\ttime.Sleep(2 * time.Second)
\t}
}
