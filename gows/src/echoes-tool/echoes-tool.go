package main

import (
  "encoding/json"
  "io"
  "os"
  "flag"
  "fmt"

  "echoes"
  "record"
)

func main() {
  dataType := flag.String( // --type=location|heading
    "type",
    "location",  // default: location
    "type of data ('location' or 'heading')")
  outputJson := flag.Bool("json", // --json
    false,  // default: not json
    "output data in json stanzas")

  flag.Parse()
  files := flag.Args()

  exitCode := 0
  defer os.Exit(exitCode)  
  for _, file := range files {
    var f io.Reader
    var err error
    if file == "-" {
      f, err = os.Stdin, error(nil)
    } else {
      f, err = os.Open(file)
    }
    if err != nil { panic(err) }


    records, errors := record.ReadMany(f, func() interface{} {
      if (*dataType == "location") {
        return new(echoes.Location)
      }
      return new(echoes.Heading)
    })

    for record := range records {
      if *outputJson {
        jsonBytes, err := json.Marshal(record)
        if err != nil {
          fmt.Printf("(json) %s: %s", file, err)
          break
        } else {
          fmt.Println(string(jsonBytes))
        }
      } else {
        fmt.Printf("%s\n", record)
      }
    }

    for err := range errors {
      fmt.Printf("error %s: %s\n", file, err)
      exitCode = 1
    }
  }
}