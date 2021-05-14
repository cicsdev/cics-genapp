# Testing the general insurance application

To validate that your setup is correct, run the general insurance application using its 3270 interface.

## About this task

The application has several transactions that you can run to access customer information and policies.

## Procedure

1. Run the LGSE transaction to build the control tables for the application.

   The transaction also clears out the shared temporary storage queue and the named counter server when configured.

1. Run the SSC1 transaction to open the application customer menu.

1. In the **Cust Number** field, enter a number between 1 and 10.

1. In the **Select Option** field, enter 1 to inquire on the customer and validate that the application can access
   the Db2® database.

1. Exit the application by pressing F3.

1. Run the SSC1 transaction again to add a customer to the database:
    1. Enter the details for a new customer.
    1. In the **Select Option** field, enter 2 to add the customer record to the database.

   A unique customer number is allocated from the named counter server (when configured).
   The application adds the customer record to Db2 and the VSAM file in a two-phase commit.
   If the VSAM file update fails, the Db2 update is rolled back.

1. Run the SSP1 transaction to access the motor policy menu. To check that you can access policy information:
   1. In the **Policy Number** field, enter `00000000001`. In the **Cust Number** field, enter `0000000002`.
   1. In the **Select Option** field, enter 1 to return the motor policy information from the database.

## Results

The application is successfully set up and running in a single CICS® region. The application can access Db2 and write
to VSAM files.

## What to do next

Use the [reference guide](Reference.md) for names of transactions used to manage other types of policies.
The reference page also includes a listing of the supplied sample policies.
