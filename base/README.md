# GenApp base

The general insurance application is a working COBOL application that you can use to try out different features of
CICS, including modernizing applications.

The general insurance application simulates transactions made by an insurance company to create and manage its
customers and insurance policies. The application provides sample data and a 3270 interface for creating and inquiring
on customers and policy information. Because the application is designed to simulate the flow of an application, some
aspects of the application architecture do not use best practices. However, the application is designed to be extended
to demonstrate other ways of accessing and transforming traditional applications that are best practices.

You can use the general insurance application to try the following CICS features:

* Creating a topology that is managed by CICSPlex SM
* Creating web services
* Creating workload simulations with Workload Simulator
* Creating business events and viewing them through a Web 2.0 dashboard application

The SupportPac documentation describes the application architecture, how to install and set up the application, and
how to test the application is working correctly. When you have a working application, you can try out these features
of CICS. Each feature is described as a scenario in
[IBM Documentation](https://www.ibm.com/docs/en/cics-ts/5.4?topic=scenarios).

## Prerequisites

* CICS TS V4.1, or later

## Application architecture

The general insurance application is a 3270 application that runs in a single region. The application writes to a VSAM
file and Db2. As you start to use the application to try different features of CICS, the configuration of the
application changes to include additional components.

[more...](Architecture.md)

## Installing the general insurance application

The [general insurance application](https://github.com/cicsdev/cics-genapp) is freely available to download from the
[CICS Transaction Server for z/OS](https://github.com/cicsdev) organization on github.com. The repository contains
the jobs you need to set up the application.

[more...](Installation.md)

## Building the application environment

Run the customized jobs to create the Db2 database, application files, and CICS resources.

[more...](Building.md)

## Testing the general insurance application

To validate that your setup is correct, run the general insurance application using its 3270 interface.

[more...](Testing.md)

## General insurance application reference

The general insurance application supplies jobs, scripts, and programs to customize and extend the scope of the
application to demonstrate different functions in CICS. The supplied files are listed here as a reference.

[more...](Reference.md)
