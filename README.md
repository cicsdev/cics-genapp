# General insurance application (GenApp) for IBM CICS TS

This GitHub repository contains the code originally distributed by the
[IBM SupportPac CB12](https://www.ibm.com/support/pages/cb12-general-insurance-application-genapp-ibm-cics-ts).
The repository demonstrates application modernization for IBM CICS Transaction Server for
z/OS (CICS TS), by modeling a general insurance application.

## Application description

The primary purpose of this repository is to demonstrate application modernization, by providing a general insurance
application (known as GenApp) for IBM CICS Transaction Server for z/OS (CICS TS). GenApp has been developed in-house by
the IBM Hursley CICS Development team to help with their testing of new CICS releases.

GenApp is designed to exercise various components of CICS TS; containing functions to insert, query, and delete policy
information. In its original form GenApp is driven using 3270 input, where the insurance policy information is stored
in an IBM Db2 database.

GenApp illustrates how a 3270-based 'green screen' application can be transformed to use many of the rich features and
functions of the newer releases of CICS TS.

### GenApp base ([base/](base/README.md))

The general insurance application is a working COBOL application that you can use to try out different features of CICS,
including modernizing applications.

## Possible Uses

To test a variety of functions and components of CICS TS, using a typical application. GenApp can be used to modify an
existing legacy application to utilize new CICS functions and capabilities.

## Skill level required

Intermediate, with knowledge of CICS systems configuration, operation, and applications.

## Prerequisites

* [IBM CICS Transaction Server for z/OS V4.1 or later](https://www.ibm.com/products/cics-transaction-server)
* [IBM Db2](https://www.ibm.com/analytics/db2)

For details of compatibility with CICS TS of the GenApp base application, or its extensions, consult the individual
component directories linked above.

## Change history and contributors

See the [change history](Changes.md) document for details of changes to this sample and a list of contributors to
the project.

## License

This sample is supplied under the [Eclipse Public License 2.0](LICENSE).

## See also

[IBM SupportPac CA0D](https://www.ibm.com/support/pages/ca0d-ibm-genapp-mobile-application-sample-cics-ts) can be used
to demonstrate how to expose a legacy CICS Transaction Server for z/OS application to a mobile front-end by using IBM
Worklight as the mobile framework. The SupportPac is based on the GenApp sample application.
