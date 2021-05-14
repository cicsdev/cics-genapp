# Building the application environment

Run the customized jobs to create the Db2® database, application files, and CICS® resources.

## About this task

To set up the general insurance application, run each of the customized jobs in the *hlq*.GENAPP.CNTL data set.
Some jobs are optional and depend on whether you want to use a coupling facility to share application data across
CICS regions. If you want to run the application in a single CICS region, you do not have to run the jobs related
to the coupling facility.

## Procedure

1. Submit the job `@ADEF121` to create the VSAM application files for customer details and policy details. This job
also populates the KSDSCUST and KSDSPOLY files with data.
1. Submit the job `@ASMMAP` to build the BMS maps for the 3270 interface.

   This job has a return code of 4.
1. Submit the job `@CDEF121` to add all of the required resource definitions to the existing CSD. The group list is
called GENALIST.
1. Submit the job `@COBOL` to compile the COBOL application programs. The compiled programs are put in the
*userid*.GENAPP.LOAD library.
1. Submit the job `@DB2CRE` to create the Db2 database for the application. It creates a storage group, database,
tables, and indexes. This job also populates the database with data.
1. Submit the job `@DB2BIND` to bind the application to the Db2 objects.
1. Optional: If you want to use a named counter server with the application, create a structure in the coupling
facility. The pool name is GENA and the structure name is DFHNCLS_GENA.

   For details on how to define a list structure for a named counter server, see
   [Setting up and running a named counter server](https://www.ibm.com/docs/en/cics-ts/5.6?topic=servers-setting-up-running-named-counter-server).

1. Optional: If you want to use a shared temporary storage queue, create a structure in the coupling facility. The
shared temporary storage queue is also called GENA and the structure name is DFHXQLS_GENA.

   For details on how to define a list structure for a temporary storage server, see
   [Setting up and running a temporary storage server](https://www.ibm.com/docs/en/cics-ts/5.6?topic=servers-setting-up-running-temporary-storage-server).

1. Optional: Submit the job `@SAMPNCS` to create a named counter server called GENA.

   You can customize this sample to change the pool name if appropriate.

   The job is long-running. You can check that the job started successfully by looking in the system log for the
   CICS message **DFHNC0102I Named counter server for pool GENA is now active**.

1. Optional: Submit the job `@SAMPTSQ` to create a temporary storage queue server called GENA.

   You can customize this sample to change the pool name if appropriate.

   This job is long-running. You can check that the job started successfully by looking in the system log for the
   CICS message **DFHXQ0102I Shared TS queue server for pool GENA is now active**.

1. Edit the startup JCL for the CICS region:

   Update the system initialization parameters to provide the following non-default values:

      ```
      GRPLIST=(DFHLIST,GENALIST)
      DB2CONN=YES
      NCPLDFT=GENA
      ```

   Add the load library *userid*.GENAPP.LOAD to the DFHRPL concatenation.

1. Ensure the CICS region has the necessary entries in the STEPLIB and DFHRPL concatenations to access Db2.

1. Submit the job to start the CICS region.

## Results

The CICS region starts up successfully. If you want to rebuild the environment, submit the job `@DB2DEL` to delete
the Db2 database.

## What to do next

[Validate that the general insurance application works](Testing.md) and can connect to Db2.
