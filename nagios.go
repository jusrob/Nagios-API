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

func buildHostConfigFile(host string) string{
  content := `define host{
              use linux-server
              host_name ` + host + `
              }`
  return content
}

func main() {
  c := buildHostConfigFile("cl2570.appl.ge.com")
  createConfigFile("/Users/justinroberts/Documents/scripts/GO/test.txt",c)
}

