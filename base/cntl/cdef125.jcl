//GENACSD JOB 241901,'CSD GENERATE',NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H
//*
//* (C) Copyright IBM Corp. 2011, 2020
//*
//*****
//***** CSD definitions for Event processing - Transaction throughput
//*****
//CSDDEFS  EXEC PGM=DFHCSDUP,REGION=1M
//STEPLIB  DD DISP=SHR,DSN=<CICSHLQ>.SDFHLOAD
//DFHCSD   DD DSN=<CSDNAME>,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(1024,(100,100))
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
**********************************************************
*******
Add    Group(GENAEVNT)    List(TORLIST)
*******

******Terminal Owning Region definitions **************
***** Program
Define Program(LGASTAT1)      Group(GENAEVNT)
Define Program(LGWEBST5)      Group(GENAEVNT)

***** Transaction
Define Transaction(LGST)      Group(GENAEVNT)
       Program(LGASTAT1)
Define Transaction(SSST)      Group(GENAEVNT)
       Program(LGWEBST5)

***** Bundle for Business events
Define Bundle(GENAEV01)       Group(GENAEVNT)
       BundleDir(/u/s8smith/genapp/genapp)
/*
//