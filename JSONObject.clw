  MEMBER

  MAP
  end!map

  include('BufferClass.inc'),ONCE
  include('JSONObject.inc'),ONCE
 
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
  
JSONObject.Add                procedure(*Group g)
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
addr                            LONG
addr2                           LONG
rl                              &LONG

d                               string(20)

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
  addr = address(g)
  PropertyName &= NEW BufferClass
  LOOP !c = 1 to fields
    c += 1
    f &= WHAT(g,c)
    if f &= NULL
      BREAK
    end!If
    addr = what(g,c)
    addr2 = address(WHAT(g,c))
    if ~ISSTRING(f)
      lt = LiteralType:Numeric
    ELSE
      lt = LiteralType:String
    end!if
    o &= BaseObject.Add()
    PropertyName.Set(WHO(g,c))
    nPos = instring(':',PropertyName.GetBuffer(),1,1)
    if npos > 0
      o.SetName(PropertyName.GetBuffer(nPos+1))
    else
      o.SetName(PropertyName.GetBuffer())
    end!if    

    if ISGROUP(g,c)
      gr &= GETGROUP(g,c)
      o.Add(gr)
    else
      if lt = LiteralType:String
        o.SetValue(CLIP(f),lt)
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

JSONObject.Stringify procedure(*BufferClass buf, BYTE format = false, LONG level = 0 )
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
            if o.GetLiteralType() = LiteralType:String
              buf.Add('"')
            end!If
            case o.GetLiteralType() 
            of LiteralType:Boolean                
                buf.Add( CHOOSE( o.GetValue(),'true','false'))
            of LiteralType:Nil
                buf.Add('null')
            of LiteralType:String
                SELF.AddEscapedString(buf,o.GetValue()) 
            else
                buf.Add(CLIP(o.GetValue()))
            end!case
            if o.GetLiteralType() = LiteralType:String
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
  