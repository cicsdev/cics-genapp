# General insurance application reference

The general insurance application supplies jobs, scripts, and programs to customize and extend the scope of the
application to demonstrate different functions in CICS®. The supplied files are listed here as a reference.

## Supplied jobs

This repository supplies a set of jobs that you must customize to work in your CICS environment. The jobs are
listed in the following table. Any job prefixed with @ has been customized by the
[installation process](Installation.md).

| Member     | Description
| ---------- | --------------------------------------------------------------------------
| `@ADEF121` | Delete, define, and load application data sets
| `@ASMMAP`  | Assemble BMS maps
| `@CDEF121` | CICS resource definitions for single region
| `@CDEF122` | CICS resource definitions for topology environment
| `@CDEF123` | CICS resource definitions for workload managed environment
| `@CDEF124` | CICS resource definition for web services
| `@CDEF125` | CICS resource definition for workload simulation
| `@COBOL`   | Compilation job for application programs
| `@CPSMDE2` | CICSPlex SM definitions
| `@DB2BIND` | Bind job for Db2 application
| `@DB2CRE`  | Create Db2 objects to support application
| `@DB2DEL`  | Delete existing GenApp database
| `@DEFDREP` | Define CMAS data repository data set
| `@DEFWREP` | Define WUI repository data set
| `@ITPENTR` | Start Workload Simulator to create customer and policy records
| `@ITPLL`   | Format Workload Simulator log file
| `@ITPSTL`  | Translate Workload Simulator programs into scripts
| `@SAMPCMA` | Sample JCL to start a CMAS
| `@SAMPNCS` | Sample JCL to start a named counter server
| `@SAMPTSQ` | Sample JCL to start a shared temporary storage queue server
| `@SAMPWUI` | Sample JCL to start the CICSPlex SM Web User Interface
| `@WSAAC01` | Sample JCL for web services assistant to create web service for customer add function
| `@WSAAP01` | Sample JCL for web services assistant to create web service for policy add function
| `@WSAIC01` | Sample JCL for web services assistant to create web service for customer inquiry function
| `@WSAIP01` | Sample JCL for web services assistant to create web service for policy inquiry function
| `@WSAVC01` | Sample JCL for web services assistant to create web service for reading VSAM file function

## Application transactions

The general insurance application has transactions for starting application menus and internal transactions for
processing the business logic. The following transactions are supplied:

| Name   | Description
| ------ | --------------------------------------------------------------------------
| `LGSE` | Initialize counters and temporary storage queues
| `LGCF` | Retrieve random customer number from VSAM file
| `LGPF` | Retrieve policy and customer number from VSAM file
| `LGST` | Event adapter trigger to update counters
| `SSC1` | Menu for customer details
| `SSP1` | Menu for motor policy options
| `SSP2` | Menu for endowment policy options
| `SSP3` | Menu for house policy options
| `SSP4` | Menu for commercial property options
| `SSST` | Initialize and copy values for dynamic scripting application

## Application programs

The general insurance application comprises the following programs:

| Name       | Description
| ---------- | --------------------------------------------------------------------------
| `LGACDB01` | Add customer details to Db2® database
| `LGACUS01` | Add customer business logic
| `LGACVS01` | Add customer details to VSAM file
| `LGAPDB01` | Add policy details to Db2 database
| `LGAPOL01` | Add policy business logic
| `LGAPVS01` | Add policy details to VSAM file
| `LGASTAT1` | Update transaction counts by using named counters
| `LGDPDB01` | Delete policy record from Db2 database
| `LGDPOL01` | Delete policy business logic
| `LGDPVS01` | Delete policy record from VSAM file
| `LGICDB01` | Retrieve customer details from Db2 database
| `LGICUS01` | Inquire customer business logic
| `LGICVS01` | Retrieve customer record from VSAM file
| `LGIPDB01` | Retrieve policy record from Db2 database
| `LGIPOL01` | Inquire policy business logic
| `LGIPVS01` | Retrieve policy record from VSAM file
| `LGSETUP`  | Initialize counters and temporary storage queues
| `LGSTSQ`   | Write a message to a temporary storage queue
| `LGTESTC1` | Presentation logic for customer menu
| `LGTESTP1` | Motor policy presentation logic
| `LGTESTP2` | Endowment policy presentation logic
| `LGTESTP3` | House policy presentation logic
| `LGTESTP4` | Commercial property policy presentation logic
| `LGUPDB01` | Update Db2 policy record
| `LGUPOL01` | Update policy business logic
| `LGWEBST5` | Copy business transaction counts from named counters to temporary storage queue
| `SSMAP`    | BMS map screen layout for presentation menus

## Other resources

The general insurance application also supplies definitions for other resources:

| Name       | Resource type | Description
| ---------- | ------------- | --------------------------------------------------------------------------
| *DB2SSID*  | DB2CONN       | Attachment definition for the Db2 connection
| `GENAMOD`  | ENQMODEL      | Enqueue that is used for updating shared temporary storage queues
| `GENAEV01` | BUNDLE        | Bundle that contains event binding and adapter definitions
| `GENAPIP1` | PIPELINE      | Provider mode pipeline for processing web service requests
| `GENASTST` | TSMODEL       | Model for access to shared temporary storage queues
| `GENATCP1` | TCPIPSERVICE  | TCP/IP connection that is used for web services
| `KSDSCUST` | FILE          | VSAM file definition for customer records
| `KSDSPOLY` | FILE          | VSAM file definition for policy records

## Sample data

The general insurance application provides sample data for the following policies:

| Type       | Policy number | Customer number |
| ---------- | ------------- | --------------- |
| Motor      | 1             | 2               |
| Motor      | 2             | 10              |
| Motor      | 3             | 5               |
| Endowment  | 4             | 8               |
| Endowment  | 5             | 3               |
| House      | 6             | 4               |
| House      | 7             | 6               |
| House      | 8             | 9               |
| Commercial | 9             | 5               |
| Commercial | 10            | 1               |
