use Com2900G19
GO
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO
EXECUTE sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO