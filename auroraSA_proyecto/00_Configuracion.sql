
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;

EXECUTE sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
