# Azure IaaS Performance tests

Download the ADETest.ps1 and run it to deploy ready to use scenarios for testing the storage performance of Azure IaaS VMs in the following scenarios VM with Standard Managed Disks and SSE enabled, VM with Standard Managed Disks and ADE enabled, VM with Premium Managed Disks and SSE enabled and VM with Premium Managed Disks and ADE enabled.

Each VM will get deployed with all the necessary resources in a separate Azure Resource Group. So in the end you will have four RGs in your Azure subscription.

Just login via RDP and go to C:\IaaS and run the Start.ps1 file to start the storage performance tests.
