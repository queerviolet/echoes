package server

import (
  "fmt"
  "net/http"
  "html/template"

  "echoes"
  "record"

  "appengine"
  "appengine/datastore"  
  "appengine/user"
)

func init() {
  http.HandleFunc("/", hello)
  http.HandleFunc("/login", login)
  http.HandleFunc("/ingest_locations", ingestLocations)
}

func getDatasetRoot(c appengine.Context, dataset string) *datastore.Key {
  return datastore.NewKey(c, "Dataset", dataset, 0, nil)
}

func getSegmentKey(c appengine.Context, dataset string, url string) *datastore.Key {
  return datastore.NewKey(c, "Segment", url, 0, getDatasetRoot(c, dataset))
}

var helloTemplate = template.Must(template.New("hello").Parse(`
<!doctype html>
<html>
  <head>
    <title>Upload location or heading data</title>
  </head>
  <body>
    <form action="/ingest_locations" method="post" enctype='multipart/form-data'>
      <input type=text name=segment_url value="http://example.com/1">
      <input type=file id=upload name=location_pack value="location.pack file">
      <input type=submit>
    </form>
  </body>
</html>
`))

func hello(w http.ResponseWriter, r *http.Request) {
//  fmt.Fprint(w, "Hello, world!")
  if err := helloTemplate.Execute(w, nil); err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
  }  
}

func ingestLocations(w http.ResponseWriter, r *http.Request) {
  c := appengine.NewContext(r)

  f, _, err := r.FormFile("location_pack")
  if err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
  }

  url := r.FormValue("segment_url")
  if url == "" {
    http.Error(w, "segment_url required", http.StatusBadRequest)
  }

  records, errors := record.ReadMany(f, func() interface{} {
    return new(echoes.Location)
  })

  segmentKey := getSegmentKey(c, "global", url)

  for r := range records {
    key := datastore.NewIncompleteKey(c, "Location", segmentKey)
    _, err := datastore.Put(c, key, r)
    if err != nil {
       http.Error(w, err.Error(), http.StatusInternalServerError)
       return
    }
  }

  for err := range errors {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }

  http.Redirect(w, r, "/", http.StatusFound)
}

func login(w http.ResponseWriter, r *http.Request) {
    c := appengine.NewContext(r)
    u := user.Current(c)
    if u == nil {
        url, err := user.LoginURL(c, r.URL.String())
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        w.Header().Set("Location", url)
        w.WriteHeader(http.StatusFound)
        return
    }
    fmt.Fprintf(w, "Hello, %v!", u)
}