# Install a standalone Oracle 19c database in a VM

## Note: This is work in progress, 2019.05.27

This is based on https://github.com/oracle/vagrant-boxes/tree/master/OracleDatabase/19.3.0

Sketch of how to set things up:
 - Provision Oracle Linux 7 VM
 - Using VM extension
   - set up environment variables
```
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="/opt/oracle/product/19c/dbhome_1"
export ORACLE_SID="ORCLCDB"
export ORACLE_PDB="ORCLPDB1"
export ORACLE_CHARACTERSET="AL32UTF8"
export ORACLE_EDITION="EE"
export SYSTEM_TIMEZONE="UTC"

```
   - Download Oracle 19c as a zip from oracle.com https://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle19c-linux-5462157.html
   - launch install.sh from https://github.com/oracle/vagrant-boxes/blob/master/OracleDatabase/19.3.0/scripts/install.sh
   - Connect to Enterprise Manager to check that everything is OK https://sysman@localhost:5500/em/shell
   - Reset password with setPassword.sh

Alternative method from Microsoft:
https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/virtual-machines/workloads/oracle/oracle-database-quick-create.md
: 
