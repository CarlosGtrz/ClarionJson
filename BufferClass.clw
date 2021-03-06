  MEMBER

CP_ACP                          EQUATE(0)
CP_UTF8                         EQUATE(65001)

MB_PRECOMPOSED      EQUATE(1)
MB_COMPOSITE        EQUATE(2)

crlf EQUATE('<13,10>')

SaveFileName   STRING(FILE:MaxFilePath),THREAD
SaveFile            FILE,DRIVER('DOS'),NAME(SaveFileName),CREATE,PRE(SF),THREAD
rec                     record
Buf                         STRING(1024)
                        end!
                    end!

  Map
    module('winapi')
      MultiByteToWideChar(LONG CodePage, ULONG dwFlags, LONG lpMultiByteString, |
              LONG cbMultiByte, LONG lpWideCharString, LONG ccWideChar),LONG,PASCAL,RAW
      WideCharToMultiByte(LONG CodePage, ULONG dwFlags, LONG lpWideCharStr, |
              LONG cchWideChar, LONG lpMultiByteStr, LONG cbMultiByte, LONG lpDefaultChar, LONG lpUsedDefaultChar),LONG,PASCAL,RAW
    end!m
  end!map

  include('BufferClass.inc'),ONCE

BufferClass.Construct       procedure()  !added to eliminate use of init and kill
    CODE
        SELF.SetSize(100)
        
BufferClass.Destruct            procedure()
    CODE
        SELF.kill()
        
BufferClass.init    procedure(LONG initialSize = 0)
  CODE
    If initialSize = 0
      InitialSize = 1000
    end!if
    SELF.Position = 0
    
    SELF.SetSize(InitialSize)
    
BufferClass.kill    procedure()
  CODE
    if SELF.BufferSize > 0
      DISPOSE(SELF.Buffer)
      SELF.BufferSize = 0
      SELF.Position = 0
    end!if    
    
BufferClass.SetSize procedure(LONG pSize)
NewBuffer &STRING
  CODE
  if SELF.BufferSize > 0
    IF pSize > 1000000000 !1 gb -> Goto 2GB and thats the limit
      self.BufferSize = ((2^31) -1) * 2   
    else
      SELF.BufferSize = 10 ^ (INT(Log10(pSize))+1) !goes from 1000 to 10000, 100000 etc      
    end!if
    NewBuffer &= NEW STRING(SELF.BufferSize)   
    NewBuffer = SELF.Buffer
    DISPOSE(SELF.Buffer)
  ELSE
    SELF.BufferSize = pSize
    NewBuffer &= NEW String(SELF.BufferSize)
  end!If
  SELF.Buffer &= NewBuffer

BufferClass.Add     procedure(STRING s)
len LONG
  CODE
  len = len(s)
  if SELF.Position + len > SELF.BufferSize
    SELF.SetSize(SELF.Position + len )
  end!if
  if len > 0
    SELF.Buffer[self.Position+1 : SELF.Position + LEN] = s
    SELF.Position += LEN
  end!if

BufferClass.AddLine     procedure(STRING s)
  CODE
  SELF.Add(s & crlf)

BufferClass.Set     procedure(STRING s)
len   long
  CODE
    len = len(s)
    if SELF.BufferSize < len
      SELF.SetSize(len)
    end!if
    SELF.Position = len
    SELF.Buffer = s
 
BufferClass.Reset   procedure()
  CODE
    SELF.Position = 0
    SELF.Buffer = ''
    
BufferClass.GetBufferLength procedure()
  CODE
    return SELF.Position
    
BufferClass.GetBuffer       procedure(LONG fromPos=1)
  CODE
    if fromPos < 1
      return ''
    end
    if SELF.Position = 0
      return ''
    end!If
    if fromPos > Self.Position
      return ''
    end!if
    return SELF.Buffer[fromPos : SELF.Position]

BufferClass.GetPartialBuffer    procedure(LONG fromPos, LONG toPos)
  CODE
    if fromPos < 1 or toPos < 1
      return ''
    end
    if toPos < fromPos
      return ''
    .
    if SELF.Position = 0
      return ''
    end!If
    if fromPos > Self.Position 
      return ''
    end!if
    if toPOS > SELF.Position
      toPos = SELF.Position
    end!if
    return SELF.Buffer[fromPos : toPos]

BufferClass.SetPartialBuffer procedure(LONG fromPos, LONG toPos, STRING str)
  CODE
    if SELF.Position = 0
      return 
    end!If
    if fromPos > Self.Position 
      return 
    end!if
    if toPOS > SELF.Position
      toPos = SELF.Position
    end!if
    SELF.Buffer[fromPos : toPos] = str 

BufferClass.GetBufferAddress    procedure()
  CODE
    return ADDRESS(SELF.Buffer)
    
BufferClass.ConvertToUtf8   procedure()
widestringlen                 LONG
multibytestringlen            LONG
widestring                    &CSTRING
multibuytestring              &CSTRING
ANSIString                    &CSTRING 
bRetVal                       BYTE

  CODE
    !convert current buffer contents to utf-8 from ANSI - current codepage    
    !first get the necessary width. The +1 due to the zero byte
    !the conversion to cstring is not strictly necessary, but I have read posts that it is advisable.
    ANSIString &= NEW CSTRING(SELF.GetBufferLength()+1 )
    ANSIString = SELF.GetBuffer()
    widestringlen = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, ADDRESS(ANSIString),-1,0,0)
    if widestringlen > 0
      widestring &= new cstring(widestringlen*2)  !mind you, a wide string has 2 bytes for each char!
      if MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, address(ANSIString),-1,address(widestring),widestringlen) > 0 
        !convert this widecharstring to utf8
        multibytestringlen = WideCharToMultiByte(CP_UTF8,0,ADDRESS(widestring),-1,0,0,0,0) 
        if multibytestringlen > 0
          multibuytestring &= NEW CSTRING(multibytestringlen)
          if WideCharToMultiByte(CP_UTF8,0,ADDRESS(Widestring),-1,Address(multibuytestring),multibytestringlen,0,0) > 0
            SELF.Set(multibuytestring)
            bRetVal = true
          end!if  
        end!if
        DISPOSE(multibuytestring)
      end!if
      DISPOSE(widestring)
    end!if
    DISPOSE(ANSIString)
    
    return bRetVal
 
BufferClass.ConvertFromUtf8 procedure()
widestringlen                 LONG
multibytestringlen            LONG
widestring                    &CSTRING
multibytestring               &CSTRING
UTF8String                    &CSTRING 
bRetVal                       BYTE

  CODE
    !convert current buffer contents from utf 8 to ANSI - current codepage    
    !first get the necessary width. The +1 due to the zero byte
    !the conversion to cstring is not strictly necessary, but I have read posts that it is advisable.
    UTF8String &= NEW CSTRING(SELF.GetBufferLength()+1 )
    UTF8String = SELF.GetBuffer()
    widestringlen = MultiByteToWideChar(CP_UTF8, 0, ADDRESS(UTF8String),-1,0,0)
    if widestringlen > 0
      widestring &= new cstring(widestringlen*2)   !mind you, a wide string has 2 bytes for each char!
      if MultiByteToWideChar(CP_UTF8, 0, address(UTF8String),-1,address(widestring),widestringlen) > 0 
        !convert this widecharstring to ANSI
        multibytestringlen = WideCharToMultiByte(CP_ACP,0,ADDRESS(widestring),-1,0,0,0,0) 
        if multibytestringlen > 0
          multibytestring &= NEW CSTRING(multibytestringlen)
          if WideCharToMultiByte(CP_ACP,0,ADDRESS(Widestring),-1,Address(multibytestring),multibytestringlen,0,0) > 0
            SELF.Set(multibytestring)
            bRetVal = true
          end!if  
        end!if
        DISPOSE(multibytestring)
      end!if
      DISPOSE(widestring)
    end!if
    DISPOSE(UTF8String)
    
    return bRetVal

BufferClass.ToFile  procedure(STRING fileName)
bResult                 byte
b                       LONG
lines                   LONG
startPos                LONG

    CODE
        saveFileName = fileName
        CREATE(SaveFile)
        If ~errorcode()
            OPEN(SaveFile)
            if ~errorcode()
                lines = SELF.GetBufferLength()/1024
                LOOP b = 1 to lines
                    startpos = (b-1)*1024
                    SaveFile.Buf = SELF.Buffer[startPos + 1: startPos + 1024]
                    ADD(SaveFile)
                end!loop
                if SELF.GetBufferLength() % 1024 > 0
                    SaveFile.Buf = SELF.Buffer[lines *1024+1 : self.GetBufferLength()]
                    Add(SaveFile,SELF.GetBufferLength() % 1024)
                end!if
                CLOSE(SaveFile)
                bResult = true                
            end!if
        end!if    
        return bResult
        
BufferClass.FromFile  procedure(STRING fileName)
bResult                 byte
b                       LONG
lines                   LONG
startPos                LONG

    CODE
    saveFileName = fileName
    SHARE(SaveFile)
    If ~errorcode()
        SET(SaveFile)
        LOOP 
            NEXT(SaveFile)
            if errorcode()
                BREAK
            end!if                
            SELF.Add(SaveFile.Buf[1 : BYTES(SaveFile) ])
        end!loop
        CLOSE(SaveFile)
        bResult = true                
    end!if    
    CLOSE(SaveFile)
    return bResult
        
BufferClass.IndexOf procedure(STRING substr, LONG nStep = 1, LONG nStart = 1,LONG caseInsensitive = 0)!,LONG
    CODE
    if caseInsensitive
      return INSTRING(UPPER(substr),UPPER(SELF.GetBuffer()),nStep,nStart)
    end    
    return INSTRING(substr,SELF.GetBuffer(),nStep,nStart) 
    
BufferClass.Replace                     procedure(STRING toReplace, STRING strReplace)
r                                         LONG
nStart                                    LONG
nPos                                      LONG
nLen                                      LONG
    CODE
    nStart = 1
    nLen = LEN(toReplace)
    if nLen = 0
      RETURN
    end!
    nPos = SELF.IndexOf(toReplace,1,nStart)
    LOOP WHILE nPos > 0
      if nPos = 1
        SELF.Set(strReplace & SELF.GetBuffer(nLen+1))
      else
        SELF.Set(SELF.GetPartialBuffer(1,nPos-1) & strReplace & SELF.GetBuffer(nPos+nLen))
      end!if
      nStart = nPos + len(strReplace)
      nPos = SELF.IndexOf(toReplace,1,nStart)
    END!loop

BufferClass.Insert          procedure(LONG atPos, STRING str)
    CODE
    SELF.Set(SELF.GetPartialBuffer(1,atPos-1) & str & SELF.GetBuffer(atPos))

BufferClass.Fold            procedure(LONG width)
original    &STRING
idx         LONG
linePos     LONG
c           STRING(1)
    CODE
    if width < 1
      RETURN
    end
    original &= NEW STRING(SELF.GetBufferLength())
    original = SELF.GetBuffer()
    SELF.Reset()
    linePos = 0
    LOOP idx = 1 TO SIZE(original)
      c = original[ idx ]
      if ~INSTRING(c,crlf)
        if linePos = width
          SELF.Add(crlf)
          linePos = 0
        end
        linePos += 1
      end
      SELF.Add(c)
      if SELF.GetBuffer(SELF.Position-1) = crlf
        linePos = 0
      end
    end
    DISPOSE(original)

BufferClass.GetLines        procedure(LONG fromLine,LONG toLine)!,STRING
idx LONG
lineNumber LONG
fromPos LONG
toPos LONG
    CODE
    if fromLine > toLine
      return ''
    end
    lineNumber = 1
    fromPos = 0
    toPos = 0
    LOOP idx = 1 TO SELF.GetBufferLength()
      if NOT fromPos AND lineNumber = fromLine
        fromPos = idx 
      end
      if SELF.GetPartialBuffer(idx-1,idx) = crlf
        if lineNumber = toLine
          toPos = idx - 2
          break
        end
        lineNumber += 1
      end
      toPos = idx
    end
    RETURN SELF.GetPartialBuffer(fromPos,toPos)

BufferClass.ConvertToValidFileName  procedure(<STRING replaceWith>, LONG replaceSpaces, LONG replacePathSeparators, LONG replaceListSeparators)
repl STRING(1)
  CODE
  repl = ' '
  IF NOT OMITTED(replaceWith)
    repl = replaceWith
  .
  IF replaceSpaces 
    IF NOT repl 
      repl = '-'
    .    
    SELF.Replace(' ',repl)
  .  
  SELF.Replace('<',repl)
  SELF.Replace('>',repl)
  SELF.Replace('"',repl)
  SELF.Replace('|',repl)
  SELF.Replace('?',repl)
  SELF.Replace('*',repl)
  IF replacePathSeparators
    SELF.Replace(':',repl)
    SELF.Replace('/',repl)
    SELF.Replace('\',repl)
  .  
  IF replaceListSeparators
    SELF.Replace(',',repl)
    SELF.Replace(';',repl)
  .
  
  
  
  
  

    