package main

import (
  "os"
)

func check(e error) {
    if e != nil {
        panic(e)
    }
}

func createConfigFile(filepath string, content string) {
  file, err := os.Create(filepath)
  check(err)
  defer file.Close()
  file.WriteString(content)
  file.Sync()
}

func buildConfigFile(host string, fileType string, config map[string]string) string{
  content := "define " + fileType + "{\n"
  for key, value := range config {
    content += "\t" + key + ": " + value + "\n"
  }
  content += "}"

  return content
}

func createLinuxHost(host string) {
  hostConfig := map[string]string{
    "use": "linux-server",
    "host_name": host,
  }
  totalProcessesConfig := map[string]string {
    "use": "generic-service",
    "host_name": host,
    "service_description": "Total Processes",
    "check_command": "check_nrpe!check_total_procs",
  }

  hostFile := buildConfigFile(host, "host", hostConfig)
  totalProcessesFile := buildConfigFile(host, "service", totalProcessesConfig)

  createConfigFile("/Users/justinroberts/tmp/host.cfg", hostFile)
  createConfigFile("/Users/justinroberts/tmp/totalProcesses.cfg", totalProcessesFile)
}

func main() {
  createLinuxHost("cl2750.appl.ge.com")
}
