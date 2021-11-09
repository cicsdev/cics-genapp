# *userid*.GENAPP.EXEC data set

This procedure is not required if you have cloned the Git repository directly to a UNIX System
Services (USS) environment.

Use this procedure if you have cloned the Git repository to your workstation and are transferring the
files to MVS data sets using FTP.

In all of the following commands, substitute *userid* with your z/OS userid.

To create a suitable partitioned data set:

1. Ensure `exec/` is the current local working directory
1. Open an FTP connection to the target z/OS system
1. Perform the necessary authentication steps
1. Ensure the current remote working directory is the high level qualifier of the required
   user by issuing the following command:

```
ftp> cd 'userid.'
250 "userid." is the working directory name prefix.
```

Now allocate the PDSE using the following sequence of commands:

```
quote site recfm=fb lrecl=80 blksize=0 cyl pri=1 sec=1 pdstype=pdse
mkdir GENAPP.EXEC
cd GENAPP.EXEC
pwd
```

The final command should produce the following message:

```
257 "'userid.GENAPP.EXEC'" partitioned data set is working directory.
```

Now transfer all files by issuing the following commands:

```
ascii
put cust1.rexx cust1
put mac1.rexx  mac1
dir
```

The final command should result in a listing of the partitioned data set and should contain all 2 files.

## Manual data set allocation and file transfer

Create a PDSE named *userid*.GENAPP.EXEC with the following attributes:

* RECFM=FB
* LRECL=80
* BLKSIZE=0
* Primary allocation of 1 cylinders, secondary allocation of 1 cylinder

Use FTP to transfer all .rexx files in this directory to the new PDSE. Use ASCII mode data transfer.

Depending on your FTP client, you may need to remove the file extensions before transferring files to MVS
partitioned data sets.

When using Windows command prompt, execute the following command:

`rename *.rexx *.`

When using a UNIX-style shell, execute the following command:

`for x in *.rexx ; do mv -- "${x}" "${x%.rexx}" ; done`

If transferring using the FTP `mput *` command, remove this README.md file to prevent the command from failing.

## Additional FTP allocation options

If you need to specify other attributes when allocating the data set, such as the volume serial number, see the
[SITE/LOCSITE Commands for MVS FTP](https://www.ibm.com/support/pages/sitelocsite-commands-mvs-ftp) document on the
IBM Support website.
