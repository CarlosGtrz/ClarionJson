  PROGRAM

  INCLUDE('JSONObject.inc'),ONCE
  INCLUDE('JSONHandler.inc'),ONCE

  MAP
AssertEqual PROCEDURE(? pExpected,? pActual,STRING pInfo)
  .
testResults         ANY

  CODE
  testResults = ''
  
  DO JsonFromCode 
  DO JsonFromGroup
  DO JsonToGroup
  DO JsonFromGroupAllTypes
  DO JsonToGroupAllTypes
  
  SETCLIPBOARD(testResults)
  MESSAGE(testResults)
  
  
JsonFromCode        ROUTINE
  DATA
js  JSONObject
person  &JSONObject
buf BufferClass
  CODE
  person &= js.Add('Person')
  person.Add('Name','Abc Def' )
  person.Add('Phone','123 123 123')
  person.Add('Active',0,LiteralType:Boolean)

  js.Stringify(buf)
  AssertEqual('{{"Person" : {{"Name" : "Abc Def","Phone" : "123 123 123","Active" : false}}',buf.GetBuffer(),'json from code')
  

JsonFromGroup        ROUTINE
  DATA
js  JSONObject
person  &JSONObject
buf BufferClass
PersonGroup GROUP
Name          STRING(50),NAME('Name')
Phone         STRING(50),NAME('Phone')
Active        BYTE,NAME('Active|JsonBoolean')
            END
  CODE
  
  CLEAR(PersonGroup)
  PersonGroup.Name = 'Abc Def'
  PersonGroup.Phone =  '123 123 123'
  PersonGroup.Active = 1
  
  person &= js.Add('Person')
  person.Add(PersonGroup)
  js.Stringify(buf)
  AssertEqual('{{"Person" : {{"Name" : "Abc Def","Phone" : "123 123 123","Active" : true}}',buf.GetBuffer(),'json from group')

JsonToGroup       ROUTINE
  DATA
jh  JSONHandler
js  &JSONObject
person  &JSONObject
buf BufferClass
PersonGroup GROUP
Name          STRING(50),NAME('Name')
Phone         STRING(50),NAME('Phone')
Active        BYTE,NAME('Active|JsonBoolean')
            END
jsonString  STRING('{{"Person" : {{"Name" : "Abc Def","Phone" : "123 123 123","Active" : true}}')
  CODE   
  
  js &= jh.Parse(jsonString)
  person &= js.GetObjectByName('Person')
  person.FillGroup(PersonGroup)
  AssertEqual('Abc Def 123 123 123 1',CLIP(PersonGroup.Name)&' '&CLIP(PersonGroup.Phone)&' '&PersonGroup.Active,'json to group')
  
JsonFromGroupAllTypes       ROUTINE
  DATA
js  JSONObject
person  &JSONObject
buf BufferClass
PersonGroup GROUP
Name          STRING(50),NAME('Name')
Phone         STRING(50),NAME('Phone')
Active        BYTE,NAME('Active|JsonBoolean')
Password      STRING(10),NAME('|JsonOmit')
CheckinDate   DATE,NAME('Checkin|JsonDate')
CheckInTime   TIME,NAME('Checkin|JsonTime')
CheckinTz     SHORT,NAME('Checkin|JsonTZ')
BinaryStamp   STRING(20),NAME('Stamp|JsonBinary')
            END
  CODE
  
  CLEAR(PersonGroup)
  PersonGroup.Name = 'Abc Def'
  PersonGroup.Phone =  '123 123 123'
  PersonGroup.Active = 1
  PersonGroup.Password = 'Secret'
  PersonGroup.CheckinDate = DATE(8,30,2021)
  PersonGroup.CheckInTime = 1 + 13*60*60*100 + 45*60*100 + 28*10
  PersonGroup.CheckinTz = -600
  PersonGroup.BinaryStamp = 'ABCDE12345GHIJK67890'
  person &= js.Add('Person')
  person.Add(PersonGroup)
  js.Stringify(buf)
  AssertEqual('{{"Person" : {{"Name" : "Abc Def","Phone" : "123 123 123","Active" : true,"Checkin" : "2021-08-30T13:45:02-06:00","Stamp" : "QUJDREUxMjM0NUdISUpLNjc4OTA="}}', |
    buf.GetBuffer(),'json from group all types')

JsonToGroupAllTypes         ROUTINE
  DATA
jh  JSONHandler
js  &JSONObject
person  &JSONObject
buf BufferClass
PersonGroup GROUP
Name          STRING(50),NAME('Name')
Phone         STRING(50),NAME('Phone')
Active        BYTE,NAME('Active|JsonBoolean')
Password      STRING(10),NAME('|JsonOmit')
CheckinDate   DATE,NAME('Checkin|JsonDate')
CheckInTime   TIME,NAME('Checkin|JsonTime')
CheckinTz     SHORT,NAME('Checkin|JsonTZ')
BinaryStamp   STRING(20),NAME('Stamp|JsonBinary')
            END
jsonString  STRING('{{"Person" : {{"Name" : "Abc Def","Phone" : "123 123 123","Active" : true,"Checkin" : "2021-08-30T13:45:02-06:00","Stamp" : "QUJDREUxMjM0NUdISUpLNjc4OTA="}}')
  CODE   
  
  js &= jh.Parse(jsonString)
  person &= js.GetObjectByName('Person')
  person.FillGroup(PersonGroup)
  AssertEqual('Abc Def 123 123 123 1 08/30/2021 13:45:02 -600 ABCDE12345GHIJK67890', |
    CLIP(PersonGroup.Name)&' '& |
    CLIP(PersonGroup.Phone)&' '& |
    PersonGroup.Active&' '& |
    FORMAT(PersonGroup.CheckinDate,@D02)&' '& |
    FORMAT(PersonGroup.CheckInTime,@t04)&' '& | 
    PersonGroup.CheckinTz&' '& | 
    PersonGroup.BinaryStamp |
    ,'json to group all types')
  
AssertEqual         PROCEDURE(? pExpected,? pActual,STRING pInfo)!,LONG,PROC
  CODE 
  testResults = testResults & |      
    CHOOSE(pExpected = pActual,'ok','--')&'<9>'& |
    CLIP(pInfo)&'<13,10>' & |
    'Exp: <'&CLIP(pExpected)&'>'&'<13,10>'& |
    'Act: <'&pActual&'>' & |
    '<13,10,13,10>'
  
  
  
    
  
  

  