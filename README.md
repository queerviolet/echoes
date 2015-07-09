Echoes is an art project.

It consists of an iOS app which records audio and a stream of timestamped location data, and a small backend written in Go for AppEngine.

The idea is to record the sounds of a place breathing, eventually to visualize it and turn it into a musical instrument.

# TODO #

1. Data uploading
  * the client's FileBucket module needs to have a syncer which opportunistically saves data
  to the server.
  * it should request an id and signed policy document for each FileBucket object and
  write each file when the object is closed
  * the server needs to support a new method which create a new echo object in the database
  and returns a signed policy document allowing uploads to it
2. Data processing pipeline
  * the server needs to respond to Google Cloud Storage change events
  * it should use a work queue and push work items into the queue in response to events
  * and then support an /ingest call which updates a given object