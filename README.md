# automated-KDC-build

Deploy EC2 instances with MIT Kerberos Key Distribution Center (KDC) with optional High availability with Replication

## External Key Distribution Center (KDC) with HA for EMR. 

This artifact will provide details about setting up MIT compatible Key Distribution Center (KDC) with high availability. Cloud formation template can be used to deploy highly available Key Distribution Center (KDC) in EC2 instance with Amazon Linux AMI. 

### Kerberos in EMR:

AWS EMR supports internal KDCs and External KDCs
  
**Internal KDC:**  Configured and maintained by EMR in the primary node if Kerberos authentication with internal KDC option is selected in EMR security configuration. 

**External KDC:**  EMR supports MIT Kerberos compatible external Key Distribution Center (KDC). Customers should build and maintain external Key Distribution Center (KDC). **This artifact will be discussing about setting up External KDC.** 

![Alt text](Fig1-1.jpg?raw=true "Title")

### Why External KDC:  

•   External Kerberos Key Distribution Center (KDC) is a Prerequisites for High availability of Kerberized EMR (Amazon EMR Cluster with multiple Primary nodes + Kerberos as authentication mechanism).
 
•   Customers with multiple EMR clusters may use a shared External Kerberos Key Distribution Center (KDC). This allows cluster applications on Kerberized clusters to interoperate. It also simplifies the authentication of communication between clusters

•   If customers planning to use cross realm trust for active directory integration, setting up one shared external KDC will help to reduce the burden of creating AD trust for every clusters. 

### Requirements for External KDC 

•   Each node in each EMR cluster must have a network route to the KDC. 

•   Its recommended to use KDC in private subnets. 

•   VPC and Subnets should be set up and proper DHCP option set is configured right DNS settings. Also make sure subnets have egress access to install RPMs through yum.   

•   If you are planning to create custom Kerberos service principals (users) in External KDC realm, you must create the same Linux users on the EC2 instance of each Kerberized cluster's master node that correspond to KDC user principals. You may use a bootstrap script for this. 

•   For ssh access, HDFS directories for each user needs to be created. This may be automated using boot strap script s3://aws-bigdata-blog/artifacts/emr-kerberos-ad/create-hdfs-home-ba.sh. 

•   If you are deploying KDC in HA mode, the KDC DB synced from primary to replica through “kprop” cron job. Note that the replication is asynchronous, and scheduled in every 2 minutes (Can be changed in cron). 

•    If you are deploying KDC in HA mode, as of writing, EMR do not provide an option to input secondary KDC server. You need to boot strap the EMR with provided script (extras/add_external_secondary-kdc.sh) for configuring secondary KDC for high availability. This script will add secondary KDC in the Kerberos config file /etc/krb5.conf in all EMR nodes. Refer bootstrapping EMR for secondary KDC section for details. 

### Cloud Formation Parameters & Outputs

|     Parameter Name         |     Description and details                                                                                        |
|----------------------------|--------------------------------------------------------------------------------------------------------------------|
|     HAforKdc               |     High Availability for KDC. True will set up two EC2 instances   with KDC DB replication. Default value True    |
|     InstanceType           |     Instance Type for EC2 instances. Default T2.Small                                                              |
|     KAdminPassword         |     KDC Admin password. This password will be used as Kadmin/admin principal   in realm.                           |
|     KDCMasterDBPassword    |     KDC DB password. This password will be needed to recover/restore   KDC DB.                                     |
|     KeyName                |     Key Name to ssh in to EC2 instances.                                                                           |
|     LatestAmiId            |     Latest Amazon Linux AMI ID.                                                                                    |
|     RealmName              |     Realm Name - Domain Name with block letters E.g.: EC2.INTERNAL                                                 |
|     SubnetIdPrimary        |     Subnet for the Primary KDC Node (Use Private Subnet)                                                           |
|     SubnetIdSecondary      |     Subnet for the Secondary Node (Use Private Subnet & Diff AZ   for better availability)                         |
|     VPCId                  |     The VPC where the EC2 instances will be launched on                                                            |


|     Output Name                    |     Description and details                                                                                                                                   |
|------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
|     KdcAdminPassword               |     AWS Secrets manager name reference storing password for Admin   kadmin/admin@${REALMNAME}                                                                 |
|     KdcDbPassword                  |     AWS Secrets manager name reference storing password for KDC DB                                                                                            |
|     KerberosClientSecurityGroup    |     Client Security Group for Kerberos Access. This security group   needs to be attached to all EMR nodes in EMR launch for allowing EMR to KDC   traffic    |
|     PrimaryKerberosInstance        |     Private FQDN for Primary KDC Server                                                                                                                       |
|     SecondaryKerberosInstance        |     Private FQDN for Secondary KDC Server                                                                                                                     |

### Limitations

•   If you are using HA option in Cloud formation, replication happens asynchronously through a cronjob in every 2 minutes.

•   You can't create new principals if the Master KDC server is offline (users will still be able to authenticate). This also means that you can't launch new Kerberized clusters if the Master KDC server is down. Existing clusters will continue to work and users will be able to authenticate. 

•   EMR supports only one external KDC server as of writing. Additional replica KDC can be added using the provided custom boot strap script. When EMR starts supporting multiple external KDCs, stop using the boot strap script (extras/add_external_secondary-kdc.sh).

### Security Configuration & Boot Strap EMR for secondary node.

o   Create EMR security configuration for External KDC

    aws emr create-security-configuration --name test1 --security-configuration "{\"AuthenticationConfiguration\":{\"KerberosConfiguration\":{\"Provider\":\"ExternalKdc\",\"ExternalKdcConfiguration\":{\"TicketLifetimeInHours\":24,\"AdminServer\":\"PrimaryKdc-server-fqdn:749\",\"KdcServer\":\" PrimaryKdc-server-fqdn:88\",\"KdcServerType\":\"Single\"}}}}" 

o   Update secondary KDC server in boot strap script extras/add_external_secondary-kdc.sh and upload it to S3.

o   While creating EMR use this additional boot strap option to configure Secondary KDC instances (This step may not be needed in future when EMR allows to input secondary external KDC)

    --bootstrap-actions '[{"Path":"s3://<BUCKET Path/To/script-in-S3/add_external_secondary-kdc.sh>","Args": “SecondaryKdc-server-fqdn” }]'


