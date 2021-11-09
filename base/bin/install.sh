#!/bin/sh

# High level qualifier of the GenApp target data sets - by default is username.GENAPP
GENAPP=${USER}.GENAPP

# Find path to this script
SCRIPT_DIR=$(dirname "$0")

# Path to the GenApp base component
BASEDIR="${SCRIPT_DIR}/.."

# Copy all of the cntl/ files
tsocmd "ALLOCATE DSNAME('${GENAPP}.CNTL') NEW SPACE(2,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
cp -O u -S d=.jcl -T ${BASEDIR}/cntl/*.jcl "//'${GENAPP}.CNTL'"

# Copy all of the exec/ files
tsocmd "ALLOCATE DSNAME('${GENAPP}.EXEC') NEW SPACE(1,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
cp -O u -S d=.rexx -T ${BASEDIR}/exec/*.rexx "//'${GENAPP}.EXEC'"

# Copy all of the src/ files
tsocmd "ALLOCATE DSNAME('${GENAPP}.SRC')  NEW SPACE(2,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
cp -O u -S d=.bms -T ${BASEDIR}/src/*.bms "//'${GENAPP}.SRC'"
cp -O u -S d=.cbl -T ${BASEDIR}/src/*.cbl "//'${GENAPP}.SRC'"
cp -O u -S d=.cpy -T ${BASEDIR}/src/*.cpy "//'${GENAPP}.SRC'"
cp -O u -S d=.txt -T ${BASEDIR}/src/*.txt "//'${GENAPP}.SRC'"

# Copy all of the wsim/ files
tsocmd "ALLOCATE DSNAME('${GENAPP}.WSIM') NEW SPACE(4,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
cp -O u -S d=.txt -T ${BASEDIR}/wsim/*.txt "//'${GENAPP}.WSIM'"

# Copy the data/ files
cp -O u -T -W seqparms="RECFM=FB LRECL=225 BLKSIZE=0 SPACE=(CYL,(1,1))" ${BASEDIR}/data/ksdscust.txt "//'${GENAPP}.KSDSCUST.TXT"
cp -O u -T -W seqparms="RECFM=FB LRECL=64  BLKSIZE=0 SPACE=(CYL,(1,1))" ${BASEDIR}/data/ksdspoly.txt "//'${GENAPP}.KSDSPOLY.TXT"
