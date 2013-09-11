  include('BufferClass.inc'),ONCE

JSONObjectQueue     Queue,TYPE,PRE(JQ)
ObjectValue                 &JSONObject
                    end!queue

                    itemize(0),PRE(ObjectType)
None                  EQUATE()
Literal               EQUATE()
Object                EQUATE()
Array                 EQUATE()
ObjectProperty        EQUATE()
                    end!itemize

                    itemize(0),pre(LiteralType)
String                EQUATE()
Numeric               EQUATE()
Boolean               EQUATE()
Binary                EQUATE()
DateTime              EQUATE()
Nil                   EQUATE()
                    end!itemize

JSONObject          CLASS,TYPE,module('JSONObject.CLW'),LINK('JSONObject.CLW',1),DLL(0)
ObjectType            BYTE,PROTECTED
LiteralType           BYTE,PROTECTED
Children              &JSONObjectQueue,PROTECTED
ParentObject          &JSONObject,PROTECTED     
ObjectValue           &BufferClass,PROTECTED
ObjectName            &BufferClass,PROTECTED
ToStringBuffer        &BufferClass,PROTECTED

Construct               procedure() !added to eliminate the use of init and kill
Destruct              procedure()
ClearChildren         procedure()
init                  procedure()
kill                  procedure()
GetParentObject       procedure(),*JSONObject
SetParentObject       procedure(*JSONObject parentobject)

Add                     procedure(),*JSONObject
Add                     procedure(*JSONObject o)
Add                   procedure(STRING pName, STRING pValue, BYTE pType = LiteralType:String),*JSONObject,PROC
Add                     procedure(STRING pName),*JSONObject,PROC
Add                     procedure(*Group g, BYTE omitEmpty = 0),*JSONObject,PROC
Add                     procedure(*Queue q),*JSONObject,PROC

AddItem                 procedure(*JSONObject pItem),*JSONObject
AddItem                 procedure(),*JSONObject

SetObjectType         procedure(BYTE objectType)
GetObjectType         procedure(),BYTE
SetValue              procedure(STRING s, BYTE pLiteralType = LiteralType:String)
SetDateValue          procedure(LONG date)
SetTimeValue          procedure(LONG time)
SetValue              procedure(*JSONObject o)
Nullify               procedure(),*JSONObject,PROC 
GetValue              procedure(),STRING
DeleteProperty        procedure(STRING propName),BYTE,PROC

SetName               procedure(STRING s)
GetName               procedure(),STRING
SetLiteralType        procedure(BYTE lt)
GetLiteralType        procedure(),BYTE
GetLength             procedure(),LONG
Get                   procedure(LONG index,BYTE clearReference = false),*JSONObject  !Mind you: clearReference breaks the object! Only do this when you know what you're doing
GetIndexOf            procedure(STRING propName),LONG
GetPropertyValue      procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),STRING
GetPropertyBooleanValue procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),LONG
GetPropertyBinaryValue procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),STRING
GetPropertyDateValue  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),LONG
GetPropertyTimeValue  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),LONG
GetPropertyUtf8Value  procedure(STRING propname, LONG nDeeperLevelsAllowed = 99999),STRING

GetObjectByName       procedure(STRING  propertyName, LONG nDeeperLevelsAllowed = 99999 ),*JSONObject !0 = no deeper levels
Stringify             procedure(*BufferClass buf, BYTE format = false, LONG level = 0)
StringifyToFile       procedure(STRING fileName, BYTE format = false)
AddEscapedString      procedure(*BufferClass buf, STRING toEscape)
AddBase64String       procedure(*BufferClass buf, STRING toEscape)

FillStructure         procedure(*GROUP g)
FillStructure         procedure(*QUEUE q)

                    end!class