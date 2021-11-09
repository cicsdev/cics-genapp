# *userid*.GENAPP.SRC data set

This procedure is not required if you have cloned the Git repository directly to a UNIX System
Services (USS) environment.

Use this procedure if you have cloned the Git repository to your workstation and are transferring the
files to MVS data sets using FTP.

In all of the following commands, substitute *userid* with your z/OS userid.

To create a suitable partitioned data set:

1. Ensure `src/` is the current local working directory
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
mkdir GENAPP.SRC
cd GENAPP.SRC
pwd
```

The final command should produce the following message:

```
257 "'userid.GENAPP.SRC'" partitioned data set is working directory.
```

Now transfer all files by issuing the following commands:

```
ascii
put ssmap.bms    ssmap
put lgacdb01.cbl lgacdb01
put lgacdb02.cbl lgacdb02
put lgacus01.cbl lgacus01
put lgacvs01.cbl lgacvs01
put lgapdb01.cbl lgapdb01
put lgapol01.cbl lgapol01
put lgapvs01.cbl lgapvs01
put lgastat1.cbl lgastat1
put lgdpdb01.cbl lgdpdb01
put lgdpol01.cbl lgdpol01
put lgdpvs01.cbl lgdpvs01
put lgicdb01.cbl lgicdb01
put lgicus01.cbl lgicus01
put lgicvs01.cbl lgicvs01
put lgipdb01.cbl lgipdb01
put lgipol01.cbl lgipol01
put lgipvs01.cbl lgipvs01
put lgsetup.cbl  lgsetup
put lgstsq.cbl   lgstsq
put lgtestc1.cbl lgtestc1
put lgtestp1.cbl lgtestp1
put lgtestp2.cbl lgtestp2
put lgtestp3.cbl lgtestp3
put lgtestp4.cbl lgtestp4
put lgucdb01.cbl lgucdb01
put lgucus01.cbl lgucus01
put lgucvs01.cbl lgucvs01
put lgupdb01.cbl lgupdb01
put lgupol01.cbl lgupol01
put lgupvs01.cbl lgupvs01
put lgwebst5.cbl lgwebst5
put lgcmarea.cpy lgcmarea
put lgpolicy.cpy lgpolicy
put polloo2.cpy  polloo2
put pollook.cpy  pollook
put soaic01.cpy  soaic01
put soaipb1.cpy  soaipb1
put soaipe1.cpy  soaipe1
put soaiph1.cpy  soaiph1
put soaipm1.cpy  soaipm1
put soavcii.cpy  soavcii
put soavcio.cpy  soavcio
put soavpii.cpy  soavpii
put soavpio.cpy  soavpio
put linkparm.txt linkparm
dir
```

The final command should result in a listing of the partitioned data set and should contain all 46 files.

## Manual data set allocation and file transfer

Create a PDSE named *userid*.GENAPP.SRC with the following attributes:

* RECFM=FB
* LRECL=80
* BLKSIZE=0
* Primary allocation of 2 cylinders, secondary allocation of 1 cylinder

Use FTP to transfer all .bms, .cbl, .cpy, and .txt files in this directory to the new PDSE. Use ASCII mode data transfer.

Depending on your FTP client, you may need to remove the file extensions before transferring files to MVS
partitioned data sets.

When using Windows command prompt, execute the following commands:

```
rename *.bms *.
rename *.cbl *.
rename *.cpy *.
rename *.txt *.
```

When using a UNIX-style shell, execute the following commands:

```
for x in *.bms ; do mv -- "${x}" "${x%.bms}" ; done
for x in *.cbl ; do mv -- "${x}" "${x%.cbl}" ; done
for x in *.cpy ; do mv -- "${x}" "${x%.cpy}" ; done
for x in *.txt ; do mv -- "${x}" "${x%.txt}" ; done
```

If transferring using the FTP `mput *` command, remove this README.md file to prevent the command from failing.

## Additional FTP allocation options

If you need to specify other attributes when allocating the data set, such as the volume serial number, see the
[SITE/LOCSITE Commands for MVS FTP](https://www.ibm.com/support/pages/sitelocsite-commands-mvs-ftp) document on the
IBM Support website.
