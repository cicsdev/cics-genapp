//GENABIND JOB 241901,'Bind programs',NOTIFY=&SYSUID,
//          CLASS=A,MSGCLASS=H
//*
//* (C) Copyright IBM Corp. 2011, 2021
//*
//BIND    EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD  DSN=<DB2HLQ>.SDSNLOAD,DISP=SHR
//DBRMLIB  DD  DSN=<DBRMLIX>,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSTSIN DD *
DSN SYSTEM(<DB2SSID>)
BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGICDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGIPDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGDPDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGAPDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGACDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGACDB02)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGUCDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PACKAGE (GENASA1)                                    -
     ISO(CS)                                              -
     CURRENTDATA(NO)                                      -
     MEMBER(LGUPDB01)                                     -
     DEGREE(1)                                            -
     DYNAMICRULES(BIND)                                   -
     ACTION (REPLACE)                                     -
     EXPLAIN(NO)                                          -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     ENABLE(BATCH,CICS)                                   -
     REL(DEALLOCATE)                                      -
     VALIDATE(BIND)

BIND PLAN (GENAONE)                                       -
     PKLIST(NULLID.*, *.GENASA1.*)                        -
     CURRENTDATA(NO)                                      -
     ISO(CS)                                              -
     ACTION (REP)                                         -
     OWNER(<SQLID>)                                       -
     QUALIFIER(<DB2DBID>)                                 -
     REL(DEALLOCATE)                                      -
     ACQUIRE(USE)                                         -
     RETAIN                                               -
     NOREOPT(VARS)                                        -
     VALIDATE(BIND)

RUN PROGRAM(DSNTIAD) PLAN(<DB2PLAN>) -
    LIB('<DB2RUN>.RUNLIB.LOAD')

END
/*
//SYSIN  DD *
  SET CURRENT SQLID='<SQLID>' ;
  GRANT EXECUTE ON PLAN GENAONE TO PUBLIC;
/*
//