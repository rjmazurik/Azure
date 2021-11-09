#!/bin/bash
MSSQL_SA_PASSWORD='Thisisapassword1'
MSSQL_PID='evaluation'
#Install and register Microsoft packages
sudo curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
repoargs="$(wget -qO- https://packages.microsoft.com/config/ubuntu/18.04/mssql-server-2019.list)"
sudo add-apt-repository "${repoargs}"
repoargs="$(curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list)"
sudo add-apt-repository "${repoargs}"
sudo apt-get update -y
sudo apt-get install -y mssql-server
sudo MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
     MSSQL_PID=$MSSQL_PID \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
# Add SQL Server tools to the path by default:
echo PATH="$PATH:/opt/mssql-tools/bin" >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
#SQL Server Agent installation:
sudo apt-get install -y mssql-server-agent
# Configure firewall to allow TCP port 1433:
sudo ufw allow 1433/tcp
sudo ufw reload
# Restart SQL Server after installing:
sudo systemctl restart mssql-server
# Connect to server and get the version:
counter=1
errstatus=1
while [ $counter -le 5 ] && [ $errstatus = 1 ]
do
  sleep 3s
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "SELECT @@VERSION" 2>/dev/null
  errstatus=$?
  ((counter++))
done
# Display error if connection failed:
if [ $errstatus = 1 ]
then
  echo Cannot connect to SQL Server, installation aborted
  exit $errstatus
fi
# Create a symlink for sqlcmd:
sudo ln -sfn /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd
# Configure Proper DB and Table for DotNetCore App:
sqlcmd -S localhost -U SA -P Thisisapassword1 -Q 'CREATE DATABASE TestDB'
sqlcmd -S localhost -U SA -P Thisisapassword1 -Q 'USE TestDB CREATE TABLE Todo (ID INT IDENTITY(1, 1) PRIMARY KEY, Description VARCHAR(255) NOT NULL, CreatedDate DATETIME NOT NULL)'
sqlcmd -S localhost -U SA -P Thisisapassword1 -Q 'USE TestDB INSERT INTO Todo VALUES ("I worked", 2021-11-04)'
sqlcmd -S localhost -U SA -P Thisisapassword1 -Q 'USE TestDB SELECT * FROM Todo'
