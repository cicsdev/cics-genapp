//GENASOAP  JOB  ,S8SMITH,CLASS=A,NOTIFY=&SYSUID,
//         MSGCLASS=A,REGION=900M
//*
//* (C) Copyright IBM Corp. 2011, 2020
//*
//********************************************************
//* LANGUAGE STRUCTURE TO WSDL CONVERSION ROUTINE
//* Obtain POLICY number from VSAM file
//********************************************************
//*
//JOBPROC JCLLIB ORDER=<CICSHLQ>.SDFHINST
//*
//LS2WSVS   EXEC DFHLS2WS,
//    JAVADIR='java601_bit64_ga/J6.0.1_64',
//    USSDIR='cics660',
//    PATHPREF='',
//    TMPDIR='/tmp',
//    TMPFILE='LS2WS'
//INPUT.SYSUT1 DD *
 PDSLIB=<SOURCEX>
 LANG=COBOL
 PGMNAME=LGIPVS01
 REQMEM=SOAVPII
 RESPMEM=SOAVPIO
 LOGFILE=<ZFSHOME>/genapp/logs/LS2WS_LGIPVS01.LOG
 URI=GENAPP/LGIPVS01
 PGMINT=COMMAREA
 WSBIND=<ZFSHOME>/genapp/wsdir/LGIPVS01.wsbind
 WSDL=<ZFSHOME>/genapp/wsdir/LGIPVS01.wsdl
 HTTPPROXY=PROXY.HURSLEY.IBM.COM:80
/*
//