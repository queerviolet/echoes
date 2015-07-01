package echoes

import (
  "bytes"
  "time"
  "reflect"
  "fmt"
)

type UnixTimeSecondsFloat64 float64

type Location struct {
    Time UnixTimeSecondsFloat64
    AudioTime float64
    Latitude float64
    Longitude float64
    Altitude float64
    Floor int64
    HorizontalAccuracy float64
    VerticalAccuracy float64
    Speed float64
    Course float64
}

type Heading struct {
    Time UnixTimeSecondsFloat64
    AudioTime float64
    /*
    
    The value in this property represents the heading relative to the
    magnetic North Pole, which is different from the geographic North Pole.
    The value 0 means the device is pointed toward magnetic north,
    90 means it is pointed east, 180 means it is pointed south,
    and so on.
    
    -- [https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLHeading_Class/#//apple_ref/occ/instp/CLHeading/magneticHeading]
    */
    MagneticHeading float64
    // magneticHeading is accurate to +/- headingAccuracy in degrees.
    HeadingAccuracy float64
    
    // Raw heading data measured in microteslas.
    X float64
    Y float64
    Z float64
}

func (self UnixTimeSecondsFloat64) String() string {
    return self.Time().Format("2006-01-02T15:04:05.999999-07:00")
}

func (self UnixTimeSecondsFloat64) Time() time.Time {
    sec := int64(self)
    nsec := int64(float64(self) - float64(sec))
    return time.Unix(sec, nsec)
}

func inspectStruct(obj interface{}) string {
  var buffer bytes.Buffer
  s := reflect.ValueOf(obj)
  typeOfT := s.Type()
  for i := 0; i < s.NumField(); i++ {
    f := s.Field(i)
    buffer.WriteString(
      fmt.Sprintf("%d: %s %s = %v\n", i,
        typeOfT.Field(i).Name, f.Type(), f.Interface()))

  }
  return buffer.String()
}

func (loc *Location) String() string {
  return inspectStruct(*loc)
}

func (hdg *Heading) String() string {
  return inspectStruct(*hdg)
}