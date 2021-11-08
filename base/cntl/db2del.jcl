//GENADB2 JOB 241901,'Db2 delete',NOTIFY=&SYSUID,
//         CLASS=A,MSGCLASS=H
//*
//* (C) Copyright IBM Corp. 2011, 2021
//*
//JOBLIB   DD DSN=<DB2HLQ>.SDSNLOAD,DISP=SHR
//*
//********************************************************************
//*   DELETE STORAGE GROUP/DATABASE/TABLESPACES/TABLES
//********************************************************************
//DELETE  EXEC PGM=IKJEFT01,DYNAMNBR=20
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
   DSN SYSTEM(<DB2SSID>)
   RUN  PROGRAM(DSNTIAD) PLAN(<DB2PLAN>) -
        LIB('<DB2RUN>.RUNLIB.LOAD')
   FREE PACKAGE(GENASA1.*)
   FREE PLAN(GENAONE)
   END
/*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD *
    DROP     TABLE      <DB2DBID>.customer;
    DROP     TABLE      <DB2DBID>.customer_secure;
    DROP     TABLE      <DB2DBID>.policy;
    DROP     TABLE      <DB2DBID>.house;
    DROP     TABLE      <DB2DBID>.endowment;
    DROP     TABLE      <DB2DBID>.motor;
    DROP     TABLE      <DB2DBID>.commercial;
    DROP     TABLE      <DB2DBID>.claim;
    DROP     TABLESPACE <DB2DBID>.GENATS01;
    DROP     TABLESPACE <DB2DBID>.GENATS02;
    DROP     TABLESPACE <DB2DBID>.GENATS03;
    DROP     TABLESPACE <DB2DBID>.GENATS04;
    DROP     TABLESPACE <DB2DBID>.GENATS05;
    DROP     TABLESPACE <DB2DBID>.GENATS06;
    DROP     TABLESPACE <DB2DBID>.GENATS07;
    commit;
    DROP     DATABASE   <DB2DBID>;
    commit;
    DROP     STOGROUP   GENASG02;
/*
//