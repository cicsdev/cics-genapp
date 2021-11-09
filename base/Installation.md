# Installing the general insurance application

The [general insurance application](https://github.com/cicsdev/cics-genapp) is freely available to download from the
[CICS Transaction Server for z/OS](https://github.com/cicsdev) organization on github.com. The repository contains
the jobs you need to set up the application.


## Before you begin

The general insurance application (GenApp) requires a stand-alone CICS region as a minimum, but can be extended to
run in a CICS topology and CICSplex. You must also have a supported version of Db2 and a COBOL compiler installed.

## About this task

The application is supplied as a Git repository. This repository may be cloned directly to a UNIX System Services
(USS) environment, or downloaded to your workstation.

To clone the repository to a USS environment, use a Git client at the USS command prompt. Use the supplied
installation shell script to copy files to MVS data sets.

To download the repository to your workstation, either download as a zip file or clone the repository using a Git
client. Use FTP to copy files to MVS data sets.

The files include a customization job so you can easily configure the application for your environment.

## Procedure: installation from USS

Use this procedure if you wish to clone the Git repository directly to a USS environment.

**Note:** the Git client must support the zos-working-tree-encoding attribute for files, such as
Rocket Software Git for z/OS version 2.26.2 and later.

1. Clone this repository directly into a USS environment.

1. Edit the [install.sh](bin/install.sh) script to verify the data set high level qualifier is correct.

1. Execute the [install.sh](bin/install.sh) script to allocate data sets and copy the files. For example,
issue `./install.sh` in the `base/bin` directory.

1. Follow the steps described in the "Customization" section below.

## Procedure: installation from workstation

Use this procedure if you wish to clone or download the Git repository onto your workstation and transfer
files to MVS data sets using FTP.

1. Clone this repository or download it as a zip file and extract to your workstation.

1. For each of these directories, follow the instructions in the README for guidance on transferring their
contents to the MVS data sets:
   1. [cntl/](cntl/README.md) - JCL to build the environment for the application
   1. [exec/](exec/README.md) - REXX code that customizes the JCL
   1. [data/](data/README.md) - Sample data for the application
   1. [src/](src/README.md) - Source programs for the application
   1. [wsim/](wsim/README.md) - Sample IBM Workload Simulator scripts - to avoid errors this library should be
      included, even if you are not using the IBM Workload Simulator product

1. Follow the steps described in the "Customization" section below.

## Customization

The CUST1 Rexx script allows for customization of the GenApp sample to suit your environment. To apply this
customization, use the following procedure:

1. Customize the member CUST1 in the *userid*.GENAPP.EXEC data set as described below.

1. Run the *userid*.GENAPP.EXEC(CUST1) script to customize the JCL in the CNTL data set. For example, enter the TSO
command:

   `EXEC 'userid.GENAPP.EXEC(CUST1)'`

   The script copies the members and updates them with your values. Each member name is prefixed with @ to indicate that
   it has been customized. You can run the customization step as many times as you want.

The values in the *userid*.GENAPP.EXEC(CUST1) member include settings for a CICS topology and CICSPlex SM, which you can
ignore. Replace the following values with your own:

```
PDSMEMin  = 'userid.GENAPP.CNTL'
CICSHLQ   = 'CTS540.CICS710'
CPSMHLQ   = 'CTS540.CPSM540'
CICSLIC   = 'CTS540.CICS710.LIC'
CSDNAME   = 'userid.GENAPP.DFHCSD'
USRHLQ    = 'userid'
COBOLHLQ  = 'PP.COBOL390.V610'
CEEHLQ    = 'CEE'
DB2HLQ    = 'SYS2.DB2.V12'
DB2RUN    = 'DSNV12P3'
SQLID     = 'userid'
DB2SSID   = 'DKM1'
DB2DBID   = 'GENASA1'
DB2CCSID  = '285'
DB2PLAN   = 'DSNTIA12'
WSIMHLQ   = 'PP.WSIM.V110'
ZFSHOME   = '/u/userid'
```

<dl>
<dt>PDSMEMin</dt>
    <dd>Enter the location of the CNTL library, userid.GENAPP.CNTL. Replace userid with your user ID.</dd>

<dt>CICSHLQ</dt>
    <dd>Enter the CICS high-level qualifier to customize the CICS data sets.</dd>

<dt>CPSMHLQ</dt>
    <dd>Enter the CICSPlex SM high-level qualifier to customize the CICS data sets.</dd>

<dt>CICSLIC</dt>
    <dd>Enter the high-level qualifier of the CICS licence data set, SDFHLIC.</dd>

<dt>CSDNAME</dt>
    <dd>Enter the fully qualified name of an existing CSD for the CICS regions that will run the general insurance
    application.</dd>

<dt>USRHLQ</dt>
    <dd>Enter a high-level qualifier for the application data sets.</dd>

<dt>COBOLHLQ</dt>
    <dd>Enter the high-level qualifier for the COBOL compiler.</dd>

<dt>CEEHLQ</dt>
    <dd>Enter the high-level qualifier for Language Environment®.</dd>

<dt>DB2HLQ</dt>
    <dd>Enter the high-level qualifier for Db2 libraries.</dd>

<dt>DB2RUN</dt>
    <dd>Enter the high-level qualifier for the Db2 runtime library.</dd>

<dt>SQLID</dt>
    <dd>Enter the RACF® user ID that is authorized to create objects in Db2.</dd>

<dt>DB2SSID</dt>
    <dd>Enter the subsystem ID of the Db2 instance that you want to use.</dd>

<dt>DB2DBID</dt>
    <dd>Enter a name for the database that is going to contain the general insurance application data. You can use
    any value that is valid for Db2.</dd>

<dt>DB2CCSID</dt>
    <dd>Enter the value of the EBCDIC CCSID field specified for your Db2 installation.</dd>

<dt>DB2PLAN</dt>
    <dd>Enter the name of the plan to use when accessing the Db2 instance.</dd>

<dt>WSIMHLQ</dt>
    <dd>Enter the high-level qualifier for the Workload Simulator for z/OS libraries. If you do not use this product,
    you can ignore this parameter.</dd>

<dt>ZFSHOME</dt>
    <dd>Specify the home directory on zFS of the user configuring GenApp.
</dl>

## Results

You have successfully installed and customized the general insurance application jobs.

## What to do next

The next step is to [build the environment](Building.md) for the application.
