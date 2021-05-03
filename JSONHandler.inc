
  include('JSONObject.inc'),ONCE

StackQJ             Queue,type,pre(SQJ)
PropertyStarted         BYTE
PropertyNameStarted     BYTE
PropertyValueStarted    BYTE
ColonExpected           BYTE
NextOrEOFExpected       BYTE
StringStarted           BYTE
NumericStarted          BYTE
Next                    BYTE
JustPopped              BYTE
Buffer                  &BufferClass
NameBuffer              &BufferClass
                    end!queue

JSONHandler          CLASS,TYPE,module('JSONHandler.CLW'),LINK('JSONHandler.CLW',1),DLL(0)
IsFirst                 BYTE
EOF                     BYTE
Error                   String(250)
StackRecordCount        LONG

Stack                   &StackQJ

jObject                 &JSONObject
Current                 &JSONObject

Construct                   procedure() !added to eliminate the use of init and kill
Destruct                    procedure()
init                    procedure()
kill                    procedure()
CreatejObject           procedure()
ReleasejObject          procedure()
Reset                   procedure()
ResetStack              procedure()
Parse                   procedure(STRING toParse),*JSONObject

HandleStringDelimiter   procedure()
HandleChar              procedure(STRING s)
HandleNumeric           procedure(string s)

SetError                procedure(STRING s)

Push                    procedure()
Pop                     procedure()
EndString               procedure()
StartString             procedure()
EndProperty             procedure()
EndArrayLiteral         procedure()
UnEscapeString          procedure()

                      end!class


