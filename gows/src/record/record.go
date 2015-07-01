package record

import (
  "bytes"
  "io"
  "encoding/binary"
  "log"
)

func Read(reader io.Reader, record interface{}) error {
  // Read record size in big endian.
  var szRecord uint64
  if err := binary.Read(reader, binary.BigEndian, &szRecord); err != nil {
    return err
  }

  // Read record size in record byte order
  var szCheck uint64
  if err := binary.Read(reader, binary.BigEndian, &szCheck); err != nil {
    return err
  }

  // From this, we can determine the record byte order.
  var byteOrder binary.ByteOrder
  if szRecord == szCheck {
    byteOrder = binary.BigEndian
  } else {
    byteOrder = binary.LittleEndian
  }

  szStruct := uint64(binary.Size(record))

  src := reader
  if szRecord != szStruct {
    log.Printf("szRecord=%d; szStruct=%d", szRecord, szStruct)
    // If the size of the record on disk doesn't agree with the size
    // of the struct, use a buffered reader initialized to zero.
    // szBuf = max(szStruct, szRecord)
    var szBuf = szStruct
    if szRecord > szBuf { szBuf = szRecord }
    buf := make([]byte, szBuf)
    reader.Read(buf[:szRecord])
    src = bytes.NewReader(buf)
  }

  // Read record
  if err := binary.Read(src, byteOrder, record); err != nil {
    return err
  }

  return nil
}

func ReadMany(reader io.Reader,
              constructor func() interface{}) (records chan interface{},
                                               errors chan error) {
  records = make(chan interface{}, 16)
  errors = make(chan error, 1)

  go func() {
    defer close(records)
    defer close(errors)

    var err error = nil
    for err == nil {
      data := constructor()
      err = Read(reader, data)
      if (err == nil) {
        records <- data
      }
    }

    if (err != nil && err != io.EOF) {
      errors <- err
    }
  }()

  return records, errors
}