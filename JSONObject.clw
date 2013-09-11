  MEMBER

  MAP
GroupFieldsCount PROCEDURE(*GROUP),LONG
  end!map

  include('BufferClass.inc'),ONCE
  include('JSONObject.inc'),ONCE
  include('base64.inc'),ONCE

JSONObject.Construct        procedure()
    CODE
    SELF.Children &= NEW JSONObjectQueue
    SELF.ObjectType = ObjectType:None
    SELF.ObjectValue &= NEW BufferClass
    SELF.ObjectName &= NEW BufferClass
    !SELF.ToStringBuffer &= NEW BufferClass
    
JSONObject.Destruct procedure()
  CODE
  SELF.ClearChildren()
  DISPOSE(SELF.Children)
  DISPOSE(SELF.ObjectValue)
  DISPOSE(SELF.ObjectName)
  !DISPOSE(SELF.ToStringBuffer)

JSONObject.ClearChildren      procedure()
p                               LONG
  CODE
  IF SELF.Children &= NULL
    return
  .
  LOOP p = 1 to records(SELF.Children)
    GET(SELF.Children,p)
    if ~SELF.Children.ObjectValue &= NULL
      DISPOSE(SELF.Children.ObjectValue)
    end!if
  end!loop
  FREE(SELF.Children)
                                  
JSONObject.init      procedure()
  CODE
    
    
JSONObject.kill      procedure()
    CODE
        
JSONObject.GetParentObject procedure()
  CODE
    return SELF.ParentObject
    
JSONObject.SetParentObject  procedure(*JSONObject parentobject)
  CODE
    SELF.ParentObject &= parentobject

JSONObject.Add                procedure(*JSONObject o)
  CODE
  CLEAR(SELF.Children)
  IF SELF.ObjectType = ObjectType:None OR SELF.ObjectType = ObjectType:Literal
    SELF.ObjectType = ObjectType:Object
  end!if
  SELF.Children.ObjectValue &= o
  ADD(SELF.Children) !,SELF.Children.ObjectName)

JSONObject.Add                procedure()
o                               &JSONObject
  CODE
  o &= NEW JSONObject
  o.SetParentObject(SELF)
  SELF.Add(o)
  return o

JSONObject.Add                procedure(STRING pName, STRING pValue, BYTE pType = LiteralType:String)
o                               &JSONObject
  CODE
  o &= SELF.Add(pName)
  o.SetValue(pValue)
  o.SetLiteralType( pType )
  return o

JSONObject.Add                procedure(STRING pName)
o                               &JSONObject
  CODE
  o &= SELF.Add()
  o.SetName(pName)
  return o  
  
JSONObject.Add                procedure(*Group g, BYTE omitEmpty = 0)
o                               &JSONObject
c                               LONG
fields                          LONG
lt                              BYTE
gr                              &GROUP
f                               ANY
nPos                            LONG
PropertyName                    &BufferClass
BaseObject                      &JSONObject
m                               LONG
qr                              &QUEUE
b                               BYTE
rl                              &LONG
d                               string(20)
isDate                          LONG
idxDt                           LONG
  CODE
  if SELF.ObjectType = ObjectType:None OR SELF.ObjectType = ObjectType:Literal
    SELF.SetObjectType(ObjectType:Object)
  end!If
  if SELF.ObjectType = ObjectType:Array
    BaseObject &= SELF.Add()
  ELSE
    BaseObject &= SELF
  end!if
  c = 0
  PropertyName &= NEW BufferClass
  LOOP !c = 1 to fields
    c += 1
    f &= WHAT(g,c)
    if f &= NULL
      BREAK
    end!If
    if ~ISSTRING(f)
      if omitEmpty AND f = 0
        CYCLE
      .
      lt = LiteralType:Numeric
    ELSE
      if omitEmpty AND f = ''
        CYCLE
      .
      lt = LiteralType:String
    end!if
    if SELF.ObjectType = ObjectType:None OR SELF.ObjectType = ObjectType:Literal
      SELF.SetObjectType(ObjectType:Object)
    end!If
    if SELF.ObjectType = ObjectType:Array
      BaseObject &= SELF.Add()
    ELSE
      BaseObject &= SELF
    end!if
    PropertyName.Set(WHO(g,c))
    nPos = instring(':',PropertyName.GetBuffer(),1,1)
    if npos > 0
      PropertyName.Set(PropertyName.GetBuffer(nPos+1))
    else
      PropertyName.Set(PropertyName.GetBuffer())
    end!if
    nPos = instring('|JSONBINARY',UPPER(PropertyName.GetBuffer()),1,1)
    if npos > 0
      lt = LiteralType:Binary
      PropertyName.Set(PropertyName.GetPartialBuffer(1,nPos-1))
    end!if
    nPos = instring('|JSONBOOLEAN',UPPER(PropertyName.GetBuffer()),1,1)
    if npos > 0
      lt = LiteralType:Boolean
      PropertyName.Set(PropertyName.GetPartialBuffer(1,nPos-1))
    end!if
    nPos = instring('|JSONDATE',UPPER(PropertyName.GetBuffer()),1,1)
    if npos > 0
      lt = LiteralType:DateTime
      isDate = 1
      PropertyName.Set(PropertyName.GetPartialBuffer(1,nPos-1))
    end!if
    nPos = instring('|JSONTIME',UPPER(PropertyName.GetBuffer()),1,1)
    if npos > 0
      lt = LiteralType:DateTime
      isDate = 0
      PropertyName.Set(PropertyName.GetPartialBuffer(1,nPos-1))
    end!if
    if lt = LiteralType:DateTime
      idxDt = BaseObject.GetIndexOf(PropertyName.GetBuffer())
      if idxDt
        o &= BaseObject.Get(idxDt)
      else
        o &= BaseObject.Add()
      end
    else
      o &= BaseObject.Add()
    end
    o.SetName(PropertyName.GetBuffer())
    if ISGROUP(g,c)
      gr &= GETGROUP(g,c)
      o.Add(gr,omitEmpty)
      c += GroupFieldsCount(gr)
    else
      if lt = LiteralType:String
        o.SetValue(CLIP(f),lt)
      elsif lt = LiteralType:DateTime
        if isDate
          o.SetDateValue(f)
        else
          o.SetTimeValue(f)
        end
      else
        o.SetValue(f,lt)
      end!if
    end!If
  end!Loop
  DISPOSE(PropertyName)
  f &= NULL
  return SELF


    
JSONObject.Add                procedure(*Queue q)
nRecs                           LONG
r                               LONG
g                               &GROUP
o                               &JSONObject
  CODE
  SELF.SetObjectType(ObjectType:Array)
    
  nRecs = RECORDS(q)
  g &= Q
  LOOP r = 1 to nRecs
    GET(q,r)
    SELF.Add(g)
  end!Loop
  return SELF
    
JSONObject.AddItem            procedure(*JSONObject pItem)
oRet                            &JSONObject
  CODE
  oRet &= SELF.AddItem()
  oRet.SetValue(pItem)
  return oRet
    
JSONObject.AddItem            procedure()
oRet &JSONObject
  CODE
  SELF.ObjectType = ObjectType:Array
  oRet &= SELF.Add()
  return oRet
  
JSONObject.SetValue procedure(STRING pValue,BYTE pLiteralType = LiteralType:String)
  CODE
  SELF.ObjectType = ObjectType:Literal
  SELF.ObjectValue.Set(pValue)
  SELF.LiteralType = pLiteralType

JSONObject.SetDateValue       procedure(LONG date)
  CODE
  SELF.ObjectType = ObjectType:Literal
  !0001-01-01T00:00:00
  SELF.ObjectValue.Set(FORMAT(date,@D10-)&'T'&SUB(SELF.GetValue(),11,8))
  SELF.LiteralType = LiteralType:DateTime

JSONObject.SetTimeValue       procedure(LONG time)
  CODE
  SELF.ObjectType = ObjectType:Literal
  !0001-01-01T00:00:00
  SELF.ObjectValue.Set(SUB(SELF.GetValue(),1,10)&'T'&FORMAT(time,@T04))
  SELF.LiteralType = LiteralType:DateTime

JSONObject.SetValue           procedure(*JSONObject o)
  CODE
  SELF.ClearChildren()
  SELF.SetObjectType(ObjectType:ObjectProperty)
  CLEAR(SELF.Children)
  SELF.Children.ObjectValue &= o
  ADD(SELF.Children) !,SELF.Children.ObjectName)

JSONObject.Nullify procedure()
  CODE
    SELF.ObjectType = ObjectType:Literal
    SELF.LiteralType = LiteralType:Nil        
    return SELF
    
JSONOBject.GetObjectType    procedure()
  CODE
    return SELF.ObjectType

JSONObject.SetObjectType    procedure(BYTE objectType)
  CODE
    SELF.ObjectType = objectType
    
JSONObject.SetLiteralType   procedure(BYTE lt)
  CODE
    SELF.LiteralType = lt
    
JSONObject.GetLiteralType   procedure()
  CODE
    return SELF.LiteralType
    
    
JSONObject.SetName  procedure(STRING s)
  CODE
    SELF.ObjectName.Set(s)
    !return SELF

JSONObject.GetName  procedure()
  CODE
  IF SELF.ObjectName &= NULL
    return '' 
  end!if
  return SELF.ObjectName.GetBuffer()
 
JSONObject.GetLength    procedure()
  CODE
    return records(SELF.Children)
    
JSONObject.Get      procedure(LONG index,BYTE clearReference = false)
o &JSONObject
  CODE
  o &= NULL
  GET(SELF.Children,index)
  if ~errorcode()
    o &= SELF.Children.ObjectValue
    if clearReference
      SELF.Children.ObjectValue &= NULL
      PUT(SELF.Children)
    end!if
  end!if
  return o

JSONObject.GetIndexOf       procedure(STRING propname)
p                               LONG
r                               LONG(0)

  CODE
    propname = UPPER(propname)
    LOOP p = 1 to SELF.GetLength()
      GET(SELF.Children,p)
      if UPPER(SELF.Children.ObjectValue.GetName()) = propname
            r = p 
            break
      end!if
    end!loop
    return r

JSONOBject.DeleteProperty               procedure(STRING propName)
bRet                                      BYTE
i                                         LONG

  CODE
  i = SELF.GetIndexOf(propName)
  if i > 0
    GET(SELF.Children,i)
    if ~SELF.Children.ObjectValue &= NULL
      DISPOSE(SELF.Children.ObjectValue)
    end!If
    DELETE(SELF.Children)
    bRet = true
  end!if
  return bRet
  
JSONObject.GetValue procedure()
  CODE
  return SELF.ObjectValue.GetBuffer()
        
JSONObject.GetObjectByName              procedure(STRING  propertyName, LONG nDeeperLevelsAllowed = 99999 ) !0 = no deeper levels
p                                         LONG
bFound                                    BYTE
c                                         LONG
retval                                    &JSONObject

  CODE
  p = SELF.GetIndexOf(propertyName) !check own level first
  if p > 0
    bFound = TRUE
    retval &= SELF.Get(p)
  ELSIF nDeeperLevelsAllowed > 0 
    nDeeperLevelsAllowed -= 1
    LOOP c = 1 to records(SELF.Children)
      GET(SELF.Children,c)
      retval &= SELF.Children.ObjectValue.GetObjectByName(propertyName, nDeeperLevelsAllowed)
      if ~retval &= NULL
        bfound = true
        break
      end!if
    end!Loop
  end!if
            
  return retval
    
JSONObject.GetPropertyValue             procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)
o                                         &JSONObject
  CODE
  o &= SELF.GetObjectByName(propName, nDeeperLevelsAllowed)
  if ~o &= NULL
    return o.GetValue()
  end!if
        
  return ''

JSONObject.GetPropertyBooleanValue procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)!,LONG
  CODE
  return CHOOSE(LOWER(SELF.GetPropertyValue(propname,nDeeperLevelsAllowed))='true')

JSONObject.GetPropertyBinaryValue procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)!,STRING
o           &JSONObject
strbin      &STRING
lenbin      ULONG
ret         LONG
buf         BufferClass
str64       &STRING
  CODE

  o &= SELF.GetObjectByName(propName, nDeeperLevelsAllowed)
  if o &= NULL OR NOT o.ObjectValue.GetBufferLength()
    return ''
  end

  lenbin = o.ObjectValue.GetBufferLength()
  strbin &= NEW STRING(lenbin)
  str64 &= NEW STRING(o.ObjectValue.GetBufferLength())
  str64 = o.ObjectValue.GetBuffer()
  ret = base64_decode(strbin,lenbin,str64,o.ObjectValue.GetBufferLength())
  IF ret = ERR_BASE64_INVALID_CHARACTER
    DISPOSE(strbin)
    DISPOSE(str64)
    RETURN ''
  .
  IF ret = ERR_BASE64_BUFFER_TOO_SMALL
    DISPOSE(strbin)
    strbin &= NEW STRING( SIZE(lenbin))
    ret = base64_decode(strbin,lenbin,str64,o.ObjectValue.GetBufferLength())
  .
  buf.Set(strbin[1 : lenbin])
  DISPOSE(strbin)
  DISPOSE(str64)
  RETURN buf.GetBuffer()

JSONObject.GetPropertyDateValue  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)!,LONG
  CODE
  return DEFORMAT(SUB(SELF.GetPropertyValue(propname,nDeeperLevelsAllowed),1,10),@D10)

JSONObject.GetPropertyTimeValue  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)!,LONG
  CODE
  return DEFORMAT(SUB(SELF.GetPropertyValue(propname,nDeeperLevelsAllowed),12,8),@T04)

JSONObject.GetPropertyUtf8Value  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999)!,STRING
buf  BufferClass
  CODE
  buf.Set(SELF.GetPropertyValue(propname,nDeeperLevelsAllowed))
  if buf.ConvertFromUtf8() then
    buf.Replace('\n','<10>')
    buf.Replace('\r','<13>')
    buf.Replace('\t','<9>')
    return buf.GetBuffer()
  .
  return ''

JSONObject.Stringify procedure(*BufferClass buf, BYTE format = false, LONG level = 0)
index                 LONG
L                     LONG
o                     &JSONObject
  CODE

    L = SELF.GetLength()
    if SELF.ObjectType = ObjectType:Array
      buf.Add('[')
    ELSIF SELF.ObjectType = ObjectType:Object
      buf.Add('{{')
      if format
        buf.Add('<13,10>' & ALL(chr(9),level))
      end!if      
    end!if
    LOOP index = 1 to L
      o &= SELF.Get(index)
      if index > 1
        buf.Add(',')
        if format
          buf.Add('<13,10>' & ALL(chr(9),level))
        end!if
      end!if
      if ~o &= NULL
        if o.GetName() <> ''
          buf.Add('"' & o.GetName() & '" : ' )
        end!If
        if o.ObjectValue &= NULL
          !failsave
          CYCLE
        end!If
        case o.GetObjectType()
        of ObjectType:Literal
            if INLIST(o.GetLiteralType(),LiteralType:String,LiteralType:Binary,LiteralType:DateTime)
              buf.Add('"')
            end!If
            case o.GetLiteralType() 
            of LiteralType:Boolean
                if NUMERIC(o.GetValue())
                  buf.Add( CHOOSE(o.GetValue() <> 0,'true','false'))
                elsif INLIST(LOWER(o.GetValue()),'true','false')
                  buf.Add(LOWER(o.GetValue()))
                else
                  buf.Add( CHOOSE(o.GetValue() <> '','true','false'))
                .
            of LiteralType:Nil
                buf.Add('null')
            of LiteralType:String
                SELF.AddEscapedString(buf,o.GetValue()) 
            of LiteralType:Binary
                SELF.AddBase64String(buf,o.GetValue())
            else
                buf.Add(CLIP(o.GetValue()))
            end!case
            if INLIST(o.GetLiteralType(),LiteralType:String,LiteralType:Binary,LiteralType:DateTime)
              buf.Add('"')
            end!If
        of ObjectType:Array orof ObjectType:Object orof ObjectType:ObjectProperty
          o.Stringify(buf, format, level +1 )
        of ObjectType:None
          buf.Add('null')
        end!if
      else 
        buf.Add('null')
      end!if
    end!loop
    if SELF.ObjectType = ObjectType:Array
      buf.Add(']')
    ELSIF SELF.ObjectType = ObjectType:Object
      if format
        buf.Add('<13,10>' & ALL(chr(9),level-1))
      end!if
      buf.Add('}')
    end!if
      
JSONObject.StringifyToFile               procedure(STRING fileName, BYTE format = false)
Buf BufferClass
  CODE    
  SELF.Stringify(Buf,format)
  Buf.ToFile(fileName)

JSONObject.AddEscapedString             procedure(BufferClass buf, STRING toEscape)
nPos                                      LONG
cChar                                     STRING(1)
c                                         LONG
l                                         LONG
startPos                                  LONG
TmpBuffer                                 &BufferClass
  CODE
  TmpBuffer &= NEW BufferClass()
  TmpBuffer.Set(toEscape)
  LOOP c = 1 to 2
    cChar = CHOOSE(c=1, '\', '"')
            
    nPos = TmpBuffer.IndexOf(cChar,1,1)
    LOOP WHILE nPos > 0
      l = TmpBuffer.GetBufferLength()
      startPos = nPos + 1
      if c = 1 and TmpBuffer.GetPartialBuffer(nPos+1,nPos+1) <> '\'
        TmpBuffer.Set(TmpBuffer.GetPartialBuffer(1,nPos) & '\' & TmpBuffer.GetPartialBuffer(nPos+1,TmpBuffer.GetBufferLength()))
        startPos += 1
      end !if
      if c = 2 
        TmpBuffer.Set(TmpBuffer.GetPartialBuffer(1,nPos-1) & '\' & TmpBuffer.GetPartialBuffer(nPos,TmpBuffer.GetBufferLength()))
        startPos += 1
      end!if
      nPos = TmpBuffer.IndexOf(cChar,1,startPos)
    end !Loop
  end!loop
  buf.Add(TmpBuffer.GetBuffer())                   
  DISPOSE(TmpBuffer)

JSONObject.AddBase64String              procedure(BufferClass buf, STRING toEscape)
str64 &CSTRING
ret LONG
len64 ULONG
  CODE
  str64 &= NEW CSTRING( SIZE(toEscape)*1.4+1)
  len64 = SIZE(str64)
  ret = base64_encode(str64,len64,toEscape,SIZE(toEscape))
  IF ret = ERR_BASE64_BUFFER_TOO_SMALL
    DISPOSE(str64)
    str64 &= NEW CSTRING( SIZE(len64)+1)
    ret = base64_encode(str64,len64,toEscape,SIZE(toEscape))
  .
  buf.Add(str64[1 : len64])
  DISPOSE(str64)

JSONObject.FillStructure    procedure(*GROUP g)
o                     &JSONObject
c                     LONG
fields                LONG
lt                    BYTE
gr                    &GROUP
f                     ANY
nPos                  LONG
PropertyName          &BufferClass
BaseObject                      &JSONObject
nIndex                          LONG

  CODE
   
    PropertyName  &= NEW BufferClass()
    c = 0
    LOOP !c = 1 to fields
      c += 1
      f &= WHAT(g,c)
      if f &= NULL
        BREAK
      end!If
      if ~ISSTRING(f)
        lt = LiteralType:Numeric
      ELSE
        lt = LiteralType:String
      end!if
      PropertyName.Set(WHO(g,c))
      nPos = PropertyName.IndexOf(':',1,1)
      if npos > 0
        nIndex = SELF.GetIndexOf(PropertyName.GetBuffer(nPos+1))
      else
        nIndex = SELF.GetIndexOf(PropertyName.GetBuffer())
      end!if
      if nIndex > 0
        o &= SELF.Get(nindex)
        if ISGROUP(g,c)
          gr &= GETGROUP(g,c)
          o.FillStructure(gr)
        else
          f = o.GetValue() 
        end!If
      end!if
    end!Loop
    f &= NULL
  
JSONObject.FillStructure                procedure(*QUEUE q)
itemCount                                 LONG
i                                         LONG
rec                                       &GROUP
o                                         &JSONObject

  CODE
  if ~Q &= NULL
    itemCount = SELF.GetLength()
    FREE(q)
    rec &= q
    LOOP i = 1 to itemCount
      CLEAR(q)
      o &= SELF.get(i,false)
      if ~o &= NULL
        o.FillStructure(rec)
        ADD(q)
      end!if    
    end!Loop
  end!if

GroupFieldsCount procedure(*GROUP g)
n LONG
  CODE
  n = 1
  LOOP
    if not who(g,n+1)
      BREAK
    end
    n += 1
  .
  RETURN n
