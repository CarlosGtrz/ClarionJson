  MEMBER

  MAP
  end!map

  include('JSONHandler.inc'),once
  include('JSONObject.inc'),once
  include('BufferClass.inc'),once

!-----
JSONHandler.Construct       procedure()
    CODE
    SELF.jObject &= NULL
    SELF.Current &= NULL
    SELF.Stack &= NEW StackQJ
         
JSONHandler.Destruct        procedure()
    CODE
    if ~SElF.jObject &= NULL !when not released-> dispose to prevent memory leaks
      DISPOSE(SELF.jObject)
    end!If

    SELF.ResetStack()
    FREE(SELF.Stack)
    DISPOSE(SELF.Stack)
        
JSONHandler.init     procedure()
    CODE
    
JSONHandler.kill     procedure()
    CODE
        
JSONHandler.Reset   procedure()
    CODE
    SELF.CreatejObject()
    SELF.IsFirst = TRUE
    SELF.EOF = FALSE
    SELF.ResetStack()
    
JSONHandler.ResetStack        procedure()
s                               LONG
  CODE
  LOOP s = records(SELF.Stack) to 1 by -1
    SELF.Pop()
  end!If

JSONHandler.CreatejObject  procedure()
  CODE
    if ~SElF.jObject &= NULL !when not released-> dispose to prevent memory leaks
      DISPOSE(SELF.jObject)
    end!If
    SELF.jObject &= NEW JSONObject
    SELF.Current &= SELF.jObject

JSONHandler.ReleasejObject  procedure()  ! use this to prevent this handler class from killing and disposing the jsonobject. It is a returnvalue, so it can be released by the caller to persist the class.
  CODE  !The class that calls release should not forget to kill and dispose the jsonobject
    SELF.jObject &= NULL
    SELF.Current &= NULL
    
JSONHandler.Parse     procedure(STRING toParse)
pos                   LONG
Length                LONG
c                     LONG
endPos                  LONG
  CODE
   
    SELF.Reset()
    
    !if it begins with [ => array
    !if it begin with { => object
    !else: => properties
    
    Length = len(toparse)
    LOOP c = 1 to length
      if SELF.EOF
        BREAK
      end!if

      case toParse[c]
      of '"' 
        SELF.Stack.Next = false
        if c = 1 or (c > 1 and toParse[c-1] <> '\')
          SELF.HandleStringDelimiter()
        end!if
      of '['
        if SELF.Stack.StringStarted
          SELF.HandleChar('[')
        ELSE
          SELF.Stack.NextOrEOFExpected = false
          SELF.Stack.Next = false
          SELF.push()
          SELF.Current.SetObjectType( ObjectType:Array )
        end
      of ']' 
        if SELF.Stack.StringStarted
          SELF.HandleChar(']')
        ELSE
          if ~SELF.Stack.JustPopped AND SELF.Stack.Buffer.GetBufferLength() > 0
            SELF.EndArrayLiteral()
          end!if
          SELF.Pop()
        end!If
      of ':'
        if SELF.Stack.StringStarted
          SELF.HandleChar(':')
        elsif SELF.Stack.Next
          SELF.SetError('Unexpected colon (next expected) at pos ' & c)
        else
          if SELF.Stack.ColonExpected 
            SELF.Stack.PropertyValueStarted = TRUE
          ELSE
            SELF.SetError('Unexpected colon at pos ' & c)
            break
          end!If
        end!if
      of ','
        IF SELF.Stack.StringStarted
          SELF.HandleChar(',')
        ELSE
          if SELF.Stack.NextOrEOFExpected
            SELF.Stack.Next = TRUE
          ELSIF SELF.Stack.PropertyValueStarted
            SELF.EndProperty()
          ELSIF SELF.Current.GetObjectType() = ObjectType:Array
            if ~SELF.Stack.JustPopped
              SELF.EndArrayLiteral()
            end!if
          ELSE
            SELF.SetError('Unexpected comma at pos ' & c)
            break
          end!if
        end!if
      of '}'
        if SELF.Stack.StringStarted
          SELF.HandleChar('}')
        ELSE
          if SELF.Stack.PropertyValueStarted
            SELF.EndProperty()
          end!if
          if SELF.Stack.NextOrEOFExpected
            SELF.Pop()
          ELSE
            SELF.SetError('Unexpected } at pos ' & c)
            break
          end!if
        end!If
      of '{{'
        if c > 1 and SELF.Stack.StringStarted
          SELF.HandleChar(toParse[c])
        ELSE
          SELF.Stack.NextOrEOFExpected = false
          SELF.Stack.Next = false
          SELF.Push()
        end!If
      of ' ' orof chr(9)  !tab
        if SELF.Stack.StringStarted
          SELF.HandleChar(toParse[c])
        end!if
      of '0' to '9' orof '.' orof '-' 
        if SELF.Stack.StringStarted
          SELF.HandleChar(toParse[c])
        ELSE
          SELF.Stack.Next  = false
          SELF.HandleNumeric(toParse[c])
        end!If
      of 't' orof 'r' orof 'u' orof 'e' orof 'f' orof 'a' orof 'l' orof 's' !true/false
        if SELF.Stack.PropertyValueStarted AND not SELF.Stack.StringStarted
          SELF.Stack.Next  = false
          SELF.HandleNumeric(toParse[c])
        ELSE
          SELF.HandleChar(toParse[c])
        end!if
      else
        SELF.Stack.Next = false
        SELF.HandleChar(toParse[c])
      end!case
    end!loop
  return SELF.jObject

JSONHandler.EndArrayLiteral procedure()
o  &JSONObject
  CODE
    o &= SELF.Current.Add()
    o.SetValue(SELF.Stack.Buffer.GetBuffer())
    o.SetObjectType(ObjectType:Literal)
    if SELF.Stack.NumericStarted
      o.SetLiteralType( LiteralType:Numeric)
    ELSE
      o.SetLiteralType( LiteralType:String)
    end!if
    SELF.Stack.NumericStarted = false
    SELF.Stack.Buffer.Reset()
    SELF.Stack.NextOrEOFExpected = true
    
JSONHandler.HandleNumeric   procedure(string s)
  CODE
    if SELF.Stack.PropertyValueStarted
      if ~SELF.Stack.NumericStarted
        SELF.Stack.Buffer.reset()
        SELF.Stack.NumericStarted = true
        SELF.Stack.Next = false
        SELF.Stack.NextOrEOFExpected = false
      end!If
      SELF.HandleChar(s)
    ELSIF SELF.Current.GetObjectType() = ObjectType:Array
      if ~SELF.Stack.NumericStarted
        SELF.Stack.Buffer.reset()
        SELF.Stack.NumericStarted = true
        SELF.Stack.Next = false
        SELF.Stack.NextOrEOFExpected = false
      end!If
      SELF.HandleChar(s)
    else
      SELF.SetError('Unexpected literal (' & s & ')')
    end!If
    
JSONHandler.HandleStringDelimiter   PROCEDURE()
  CODE
    if SELF.Stack.StringStarted 
      SELF.EndString()
    ELSE
      SELF.StartString()
    end!if

JSONHandler.StartString procedure()
  CODE
    SELF.Stack.Buffer.Reset()
    SELF.Stack.StringStarted = TRUE
    SELF.Stack.Next = false
    SELF.Stack.NextOrEOFExpected = false
    if ~SELF.Stack.PropertyNameStarted
      SELF.Stack.PropertyNameStarted = TRUE
    ELSE
      SELF.Stack.PropertyValueStarted = TRUE
    end!If

JSONHandler.EndString   procedure()
  CODE
  SELF.Stack.StringStarted = FALSE
  if SELF.Stack.PropertyValueStarted
    !deserialize
    SELF.UnEscapeString()    
    SELF.EndProperty()
  ELSif SELF.Stack.PropertyNameStarted
    SELF.Stack.ColonExpected = true
    SELF.Stack.NameBuffer.Set(SELF.Stack.Buffer.GetBuffer())
  end!if
  SELF.Stack.Buffer.reset()
    
JSONHandler.UnEscapeString              procedure()
  CODE
  SELF.stack.Buffer.Replace('\\', '\')
  SELF.Stack.Buffer.Replace('\"','"')
  
JSONHandler.HandleChar                  procedure(STRING c)
  CODE
    if SELF.Stack.StringStarted OR SELF.Stack.NumericStarted
      SELF.Stack.Buffer.Add(c)
    end!If
    
JSONHandler.EndProperty procedure()
o  &JSONObject
  CODE
    SELF.Stack.PropertyStarted = FALSE
    SELF.Stack.PropertyValueStarted = false
    SELF.Stack.PropertyNameStarted = false
    SELF.Stack.NumericStarted = false
    if ~SELF.Stack.JustPopped
      o &= SELF.Current.Add()
      o.SetValue(SELF.Stack.Buffer.GetBuffer())
      o.SetName(SELF.Stack.NameBuffer.GetBuffer())
    end!if
    SELF.Stack.Buffer.Reset()
    SELF.Stack.NameBuffer.Reset()
    SELF.Stack.NextOrEOFExpected = true
    SELF.Stack.JustPopped = false
    
JSONHandler.Push    procedure()
  CODE
    if ~SELF.IsFirst
      SELF.Current &= SELF.Current.Add()
      if SELF.Stack.PropertyNameStarted
        SELF.Current.SetName(SELF.Stack.NameBuffer.GetBuffer())
      end!if
    end!if
    SELF.IsFirst = FALSE

    if SELF.StackRecordCount
      PUT(SELF.Stack)
    end!if
    
    CLEAR(SELF.Stack)
    SELF.Stack.PropertyStarted         = false
    SELF.Stack.PropertyNameStarted     = false
    SELF.Stack.PropertyValueStarted    = false
    SELF.Stack.ColonExpected           = false
    SELF.Stack.NextOrEOFExpected       = FALSE
    SELF.Stack.StringStarted           = false
    SELF.Stack.NumericStarted          = FALSE
    SELF.Stack.Next                    = false
    SELF.Stack.Buffer &= New BufferClass()
    SELF.Stack.NameBuffer &= NEW BufferClass()

    ADD(SELF.Stack)
  SELF.StackRecordCount     = records(SELF.Stack)
  
JSONHandler.Pop procedure()
  CODE
  if ~SELF.Current &= NULL
    SELF.Current &= SELF.Current.GetParentObject() 
  end!If
  DISPOSE(SELF.Stack.Buffer)
  SELF.Stack.Buffer &= NULL  
  DISPOSE(SELF.Stack.NameBuffer)
  SELF.Stack.NameBuffer &= NULL
  DELETE(SELF.Stack)
  SELF.StackRecordCount     = records(SELF.Stack)  
  GET(SELF.Stack, records(SELF.Stack))
  if errorcode()
    SELF.Eof = TRUE
  end!if
  SELF.Stack.JustPopped = true
    
JSONHandler.SetError    procedure(STRING s)
  CODE
    SELF.Error = s
    SELF.EOF = true
    