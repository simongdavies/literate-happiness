# SQL Server Always On Availability Groups on Kubernetes

This Bundle installs a SQL Server always on availability group on a Kubernetes, on install it will:

* Deploy the SQL Server Operator
* Create Secrets for SQL Server sa password and master password
* Deploy SQL Server Containers, persistent volumes, persistent volume claims and load balancers
* Create services to connect to primary and secondary replicas

Full details can be found [here](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-kubernetes-deploy?view=sqlallproducts-allversions)

## Parameters and Credentials

| Name| Description
---|---
kube_config |   Base64 Encoded kubeconfig
sql_masterkeypassword |  The Password for the SQL Server Master Key
sql_sapassword | The Password for the sa user in SQL Server
