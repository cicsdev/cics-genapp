//GENACSD JOB 241901,'CSD GENERATE',NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H
//*
//* (C) Copyright IBM Corp. 2011, 2020
//*
//*****
//***** CSD definitions for stand-alone GENAPP
//*****
//CSDDEFS  EXEC PGM=DFHCSDUP,REGION=1M
//STEPLIB  DD DISP=SHR,DSN=<CICSHLQ>.SDFHLOAD
//DFHCSD   DD DSN=<CSDNAME>,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(1024,(100,100))
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
**********************************************************
*Remove Group(GENASAT)     List(GENALIST)
*Remove Group(GENASAP)     List(GENALIST)
*Remove Group(GENASAD)     List(GENALIST)
*Remove Group(GENASAF)     List(GENALIST)
*Remove Group(GENA)        List(GENALIST)
*Delete Group(GENASAT)  All
*Delete Group(GENASAP)  All
*Delete Group(GENASAD)  All
*Delete Group(GENASAF)  All
*Delete Group(GENA)     All
*
Add    Group(GENASAT)     List(GENALIST)
Add    Group(GENASAP)     List(GENALIST)
Add    Group(GENASAD)     List(GENALIST)
Add    Group(GENASAF)     List(GENALIST)
Add    Group(GENA)        List(GENALIST)
*******

***** Transactions
Define Transaction(SSC1) Group(GENASAT)
       Program(LGTESTC1) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(SSP1) Group(GENASAT)
       Program(LGTESTP1) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(SSP2) Group(GENASAT)
       Program(LGTESTP2) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(SSP3) Group(GENASAT)
       Program(LGTESTP3) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(SSP4) Group(GENASAT)
       Program(LGTESTP4) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(LGSE) Group(GENASAT)
       Program(LGSETUP)  TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(LGCF) Group(GENASAT)
       Program(LGICVS01) TaskDataLoc(Any)   TaskDataKey(User)
Define Transaction(LGPF) Group(GENASAT)
       Program(LGIPVS01) TaskDataLoc(Any)   TaskDataKey(User)

***** Programs
Define Program(LGTESTC1) Group(GENASAP)
       Description(Solution Customer Menu)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGTESTP1) Group(GENASAP)
       Description(Solution Motor Policy Menu)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGTESTP2) Group(GENASAP)
       Description(Solution Life Policy Menu)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGTESTP3) Group(GENASAP)
       Description(Solution House Policy Menu)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGTESTP4) Group(GENASAP)
       Description(Solution Commercial Policy Menu)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(SSMAP)    Group(GENASAP)
       Description(BMS Map)
       Language(Cobol)   DataLocation(Any)   Execkey(User)

Define Program(LGACUS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGAPBR01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGAPOL01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGDPOL01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGICUS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGIPOL01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUCUS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUPOL01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGACDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGACDB02) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGAPDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGDPDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGICDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGIPDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUCDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUPDB01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGACVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGAPVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGDPVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGICVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGIPVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUCVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGUPVS01) Group(GENASAP)
       Language(Cobol)   DataLocation(Any)   Execkey(User)

Define Program(LGSETUP)  Group(GENASAP)
       Description(Initial setup of TSQueue)
       Language(Cobol)   DataLocation(Any)   Execkey(User)
Define Program(LGSTSQ)   Group(GENASAP)
       Description(Message output to TSQueues)
       Language(Cobol)   DataLocation(Any)   Execkey(User)

***** DB2 Attachment
Define DB2Conn(<DB2SSID>)     Group(GENASAD)  DB2ID(<DB2SSID>)
       NONtermrel(No)    ResyncMember(No)
       MSGqueue1(CSMT)   StatsQueue(CSMT)
       TCBlimit(400)     ThreadError(Abend)
       AccountRec(Txid)  AuthType(Userid)
       Drollback(Yes)    ThreadLimit(250)
Define DB2Entry(<DB2SSID>LU2) Group(GENASAD)  Transid(SS*)
       AccountRec(Txid)
       Plan(GENAONE)     ThreadLimit(250)

***** File Definitions
  Define File(KSDSCUST)    Group(GENASAF)
         DSname(<USRHLQ>.GENAPP.KSDSCUST)
         Recordsize(82)    Keylength(10)
         Status(Enabled)   Opentime(Firstref)
         Add(Yes)          Browse(Yes)        Read(Yes)
         Delete(No)        Update(Yes)
  Define File(KSDSPOLY)    Group(GENASAF)
         DSname(<USRHLQ>.GENAPP.KSDSPOLY)
         Recordsize(64)    Keylength(21)
         Status(Enabled)   Opentime(Firstref)
         Add(Yes)          Browse(Yes)        Read(Yes)
         Delete(Yes)       Update(Yes)
*
  Define Enqmodel(GENAMOD) Group(GENA)
         Description(GRS for GENAPP)
         ENQscope(GENA)    ENQname(GENACNTL)
*
* Define TSmodel(GENASTSQ) Group(GENA)
*        Poolname(GENA)
*        Prefix(GENA++++)
/*
//