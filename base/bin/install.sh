#!/bin/sh

# Find path to this script
SCRIPT_DIR=$(dirname "$0")

# Path to the GenApp base component
BASEDIR="${SCRIPT_DIR}/.."


# Allocate all the data sets
tsocmd "ALLOCATE DSNAME('IBURNET.GENAPP.GENAPP.CNTL') NEW SPACE(2,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
tsocmd "ALLOCATE DSNAME('IBURNET.GENAPP.GENAPP.EXEC') NEW SPACE(1,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
tsocmd "ALLOCATE DSNAME('IBURNET.GENAPP.GENAPP.SRC')  NEW SPACE(2,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"
tsocmd "ALLOCATE DSNAME('IBURNET.GENAPP.GENAPP.WSIM') NEW SPACE(4,1) CYLINDERS BLKSIZE(0) LRECL(80) RECFM(F,B) DSORG(PO) DSNTYPE(LIBRARY)"

# Copy all of the cntl/ files
cp -O u -S d=.jcl -T ${BASEDIR}/cntl/*.jcl "//'IBURNET.GENAPP.GENAPP.CNTL'"

# Copy all of the exec/ files
cp -O u -S d=.rexx -T ${BASEDIR}/exec/*.rexx "//'IBURNET.GENAPP.GENAPP.EXEC'"

# Copy all of the src/ files
cp -O u -S d=.bms -T ${BASEDIR}/src/*.bms "//'IBURNET.GENAPP.GENAPP.SRC'"
cp -O u -S d=.cbl -T ${BASEDIR}/src/*.cbl "//'IBURNET.GENAPP.GENAPP.SRC'"
cp -O u -S d=.cpy -T ${BASEDIR}/src/*.cpy "//'IBURNET.GENAPP.GENAPP.SRC'"
cp -O u -S d=.txt -T ${BASEDIR}/src/*.txt "//'IBURNET.GENAPP.GENAPP.SRC'"

# Copy all of the wsim/ files
cp -O u -S d=.txt -T ${BASEDIR}/wsim/*.txt "//'IBURNET.GENAPP.GENAPP.WSIM'"


