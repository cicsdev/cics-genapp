# Sample input data sets

This procedure is not required if you have cloned the Git repository directly to a UNIX System
Services (USS) environment.

Use this procedure if you have cloned the Git repository to your workstation and are transferring the
files to MVS data sets using FTP.

The files ksdscust.txt and ksdspoly.txt contain sample data used in the general insurance application.
Do not edit these files before transferring to the z/OS system as this may introduce unwanted control characters.

In all of the following commands, substitute *userid* with your z/OS userid.

To allocate and transfer the sample data files, use the following steps to connect to the remote z/OS system:

1. Ensure `data/` is the current local working directory
1. Open an FTP connection to the target z/OS system
1. Perform the necessary authentication steps
1. Ensure the current remote working directory is the high level qualifier of the required
   user by issuing the following command:

```
ftp> cd 'userid.'
250 "userid." is the working directory name prefix.
```

Transfer the ksdscust.txt file using the following sequence of commands:

```
quote site recfm=fb lrecl=225 blksize=0 cyl pri=1 sec=1
ascii
put ksdscust.txt genapp.ksdscust.txt
```

Transfer the ksdspoly.txt file using the following sequence of commands:

```
quote site recfm=fb lrecl=64 blksize=0 cyl pri=1 sec=1
ascii
put ksdspoly.txt genapp.ksdspoly.txt
```

To confirm the files have been transmitted correctly, issue the following command:

```
ftp> dir genapp.ksds*
200 Port request OK.
125 List started OK
Volume Unit    Referred Ext Used Recfm Lrecl BlkSz Dsorg Dsname
vvvvvv 3390   yyyy/mm/dd  1   15  FB     225 27900  PS  GENAPP.KSDSCUST.TXT
vvvvvv 3390   yyyy/mm/dd  1   15  FB      64 27968  PS  GENAPP.KSDSPOLY.TXT
250 List completed successfully.
```

## Manual data set allocation and file transfer - KSDSCUST

Create a sequential data set named *userid*.GENAPP.KSDSCUST.TXT with the following attributes:

* RECFM=FB
* LRECL=225
* BLKSIZE=0
* Primary allocation of 1 cylinders, secondary allocation of 1 cylinder

FTP the ksdscust.txt file to the z/OS system in ASCII mode.

## Manual data set allocation and file transfer - KSDSPOLY

Create a sequential data set named *userid*.GENAPP.KSDSPOLY.TXT with the following attributes:

* RECFM=FB
* LRECL=64
* BLKSIZE=0
* Primary allocation of 1 cylinders, secondary allocation of 1 cylinder

FTP the ksdspoly.txt file to the z/OS system in ASCII mode.

## Additional FTP allocation options

If you need to specify other attributes when allocating the data set, such as the volume serial number, see the
[SITE/LOCSITE Commands for MVS FTP](https://www.ibm.com/support/pages/sitelocsite-commands-mvs-ftp) document on the
IBM Support website.
