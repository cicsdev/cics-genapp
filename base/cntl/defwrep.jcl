//EYUWREP JOB 241901,'CPSM GENERATE',NOTIFY=&SYSUID,
//             CLASS=A,MSGCLASS=H
//*
//* (C) Copyright IBM Corp. 2011, 2020
//*
//*----------------------------------------------------------
//* DELETE EXISTING WUI SERVER REPOSITORY
//*----------------------------------------------------------
//DELWREP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *

   DELETE <USRHLQ>.<WUIAPPL>.EYUWREP
   SET MAXCC=0
/*
//*----------------------------------------------------------
//* DEFINE NEW WUI SERVER REPOSITORY
//*----------------------------------------------------------
//DEFWREP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DEFINE CLUSTER (                                -
                    NAME( <USRHLQ>.<WUIAPPL>.EYUWREP ) -
                    VOLUMES(SYSDAV)                -
                    STORCLAS( STANDARD )           -
                    RECORDS( 5000 5000 )           -
                    CONTROLINTERVALSIZE( 8192 )    -
                    SPANNED                        -
                    INDEXED                        -
                    SHAREOPTIONS( 2 )              -
                  )                                -
          DATA    (                                -
                    NAME( <USRHLQ>.<WUIAPPL>.EYUWREP.DATA ) -
                    KEYS( 20 20 )                  -
                    RECORDSIZE( 8192 32000 )       -
                  )                                -
          INDEX   (                                -
                    NAME( <USRHLQ>.<WUIAPPL>.EYUWREP.INDEX ) -
                  )
/*
//