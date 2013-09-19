# ClarionJson

Json serializer and parser for Clarion. Fork of code created by Dries Driessen for his [RavenDB client](http://www.indirection.nl/#!RavenDB).

## Changes in this fork:

###BufferClass

- New methods: .AddLine, .SetPartialBuffer(fromPos,toPos,str), .Insert(atPos,str), .Fold(width), .GetLines(fromLine,toLine)
- Some fixes

###JSONObject

- New literal types for DateTime and Binary
- Set literal type using EXTERNAL('') suffixes
- Encode binary data to base64
- New methods: SetDateValue(date), .SetTimeValue(time), .GetPropertyBooleanValue, .GetPropertyBinaryValue, .GetPropertyDateValue, .GetPropertyTimeValue, .GetPropertyUtf8Value, .AddBase64String
- Optional parameter omitEmpty to .Add(*GROUP)
- Fix for fields in inner groups added twice

###JSONHandler

- Fix for handling '[' and '{'

Check [commits](https://github.com/CarlosGtrz/ClarionJson/commits/master) for details.

