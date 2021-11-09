# *userid*.GENAPP.CNTL data set

This procedure is not required if you have cloned the Git repository directly to a UNIX System
Services (USS) environment.

Use this procedure if you have cloned the Git repository to your workstation and are transferring the
files to MVS data sets using FTP.

In all of the following commands, substitute *userid* with your z/OS userid.

To create a suitable partitioned data set:

1. Ensure `cntl/` is the current local working directory
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
quote site recfm=fb lrecl=80 blksize=0 cyl pri=2 sec=1 pdstype=pdse
mkdir GENAPP.CNTL
cd GENAPP.CNTL
pwd
```

The final command should produce the following message:

```
257 "'userid.GENAPP.CNTL'" partitioned data set is working directory.
```

Now transfer all files by issuing the following commands:

```
ascii
put adef121.jcl adef121
put asmmap.jcl  asmmap
put cdef121.jcl cdef121
put cdef122.jcl cdef122
put cdef123.jcl cdef123
put cdef124.jcl cdef124
put cdef125.jcl cdef125
put cobol.jcl   cobol
put cpsmde2.jcl cpsmde2
put db2bind.jcl db2bind
put db2cre.jcl  db2cre
put db2del.jcl  db2del
put defdrep.jcl defdrep
put defwrep.jcl defwrep
put itpentr.jcl itpentr
put itpll.jcl   itpll
put itpstl.jcl  itpstl
put sampcma.jcl sampcma
put sampncs.jcl sampncs
put samptsq.jcl samptsq
put sampwui.jcl sampwui
put wsaac01.jcl wsaac01
put wsaap01.jcl wsaap01
put wsaic01.jcl wsaic01
put wsaip01.jcl wsaip01
put wsauc01.jcl wsauc01
put wsaup01.jcl wsaup01
put wsavc01.jcl wsavc01
put wsavp01.jcl wsavp01
dir
```

The final command should result in a listing of the partitioned data set and should contain all 29 files.

## Manual data set allocation and file transfer

Create a PDSE named *userid*.GENAPP.CNTL with the following attributes:

* RECFM=FB
* LRECL=80
* BLKSIZE=0
* Primary allocation of 2 cylinders, secondary allocation of 1 cylinder

Use FTP to transfer all .jcl files in this directory to the new PDS. Use ASCII mode data transfer.

Depending on your FTP client, you may need to remove the file extensions before transferring files to MVS
partitioned data sets.

When using Windows command prompt, execute the following command:

`rename *.jcl *.`

When using a UNIX-style shell, execute the following command:

`for x in *.jcl ; do mv -- "${x}" "${x%.jcl}" ; done`

If transferring using the FTP `mput *` command, remove this README.md file to prevent the command from failing.

## Additional FTP allocation options

If you need to specify other attributes when allocating the data set, such as the volume serial number, see the
[SITE/LOCSITE Commands for MVS FTP](https://www.ibm.com/support/pages/sitelocsite-commands-mvs-ftp) document on the
IBM Support website.
