
BufferClass                             Class,TYPE,module('BufferClass.CLW'),LINK('BufferCLass.CLW',1),DLL(0)
Buffer                                    &STRING
Position                                  LONG
BufferSize                                LONG

Construct                                 procedure()  !added to eliminate use of init and kill
Destruct                                  procedure()

init                                      procedure(LONG initialSize = 0)
kill                                      procedure()
SetSize                                   procedure(LONG pSize)
Add                                       procedure(STRING s)
AddLine                                   procedure(STRING s)
GetBufferLength                           procedure(),LONG
GetBuffer                                 procedure(LONG fromPos=1),STRING
GetBufferAddress                          procedure(),LONG
GetPartialBuffer                          procedure(LONG fromPos, LONG toPos),STRING
SetPartialBuffer                          procedure(LONG fromPos, LONG toPos, STRING str)
Set                                       procedure(STRING s)
Reset                                     procedure()

IndexOf                                   procedure(STRING substr,LONG nStep = 1, LONG nStart = 1),LONG
Replace                                   procedure(STRING toReplace, STRING strReplace)
Insert                                    procedure(LONG atPos, STRING str)
Fold                                      procedure(LONG width = 72)
GetLines                                  procedure(LONG fromLine,LONG toLine),STRING

ConvertToUtf8                             procedure(),BYTE
ConvertFromUtf8                           procedure(),BYTE

ToFile                                    procedure(STRING fileName),BYTE,PROC
FromFile                                  procedure(STRING fileName),BYTE,PROC
                                        end!class