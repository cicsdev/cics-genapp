# *userid*.GENAPP.WSIM data set

This procedure is not required if you have cloned the Git repository directly to a UNIX System
Services (USS) environment.

Use this procedure if you have cloned the Git repository to your workstation and are transferring the
files to MVS data sets using FTP.

In all of the following commands, substitute *userid* with your z/OS userid.

To create a suitable partitioned data set:

1. Ensure `wsim/` is the current local working directory
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
quote site recfm=fb lrecl=80 blksize=0 cyl pri=4 sec=1 pdstype=pdse
mkdir GENAPP.WSIM
cd GENAPP.WSIM
pwd
```

The final command should produce the following message:

```
257 "'userid.GENAPP.WSIM'" partitioned data set is working directory.
```

Now transfer all files by issuing the following commands:

```
ascii
put ccolor.txt   ccolor
put cmake.txt    cmake
put cmodel.txt   cmodel
put ctype.txt    ctype
put fname.txt    fname
put genapp.txt   genapp
put htype.txt    htype
put oncics.txt   oncics
put pcode.txt    pcode
put ptype.txt    ptype
put rtype.txt    rtype
put sname.txt    sname
put ssc1a1.txt   ssc1a1
put ssc1a2.txt   ssc1a2
put ssc1i1.txt   ssc1i1
put ssp1a1.txt   ssp1a1
put ssp1a2.txt   ssp1a2
put ssp1d1.txt   ssp1d1
put ssp1i1.txt   ssp1i1
put ssp1u1.txt   ssp1u1
put ssp2a1.txt   ssp2a1
put ssp2a2.txt   ssp2a2
put ssp2d1.txt   ssp2d1
put ssp2i1.txt   ssp2i1
put ssp2u1.txt   ssp2u1
put ssp3a1.txt   ssp3a1
put ssp3a2.txt   ssp3a2
put ssp3d1.txt   ssp3d1
put ssp3i1.txt   ssp3i1
put ssp3u1.txt   ssp3u1
put ssp4a1.txt   ssp4a1
put ssp4d1.txt   ssp4d1
put ssp4i1.txt   ssp4i1
put #ssvars.txt  #ssvars
put stop.txt     stop
put waserror.txt waserror
put wsc1a1.txt   wsc1a1
put wsc1i1.txt   wsc1i1
put wslgcf.txt   wslgcf
dir
```

The final command should result in a listing of the partitioned data set and should contain all 39 files.

## Manual data set allocation and file transfer

Create a PDSE named *userid*.GENAPP.WSIM with the following attributes:

* RECFM=FB
* LRECL=80
* BLKSIZE=0
* Primary allocation of 4 cylinders, secondary allocation of 1 cylinder

Use FTP to transfer all .txt files in this directory to the new PDS. Use ASCII mode data transfer.

Depending on your FTP client, you may need to remove the file extensions before transferring files to MVS
partitioned data sets.

When using Windows command prompt, execute the following command:

`rename *.txt *.`

When using a UNIX-style shell, execute the following command:

`for x in *.txt ; do mv -- "${x}" "${x%.txt}" ; done`

If transferring using the FTP `mput *` command, remove this README.md file to prevent the command from failing.

## Additional FTP allocation options

If you need to specify other attributes when allocating the data set, such as the volume serial number, see the
[SITE/LOCSITE Commands for MVS FTP](https://www.ibm.com/support/pages/sitelocsite-commands-mvs-ftp) document on the
IBM Support website.
