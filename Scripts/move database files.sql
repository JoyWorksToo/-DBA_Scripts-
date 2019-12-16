

-----------------------------------------------------------------------------------------------------------
----------------------Disable read-only access for all the secondary replicas------------------------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1

USE[master]
GO

ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'SCCHIB4DB-02-1' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'SCCHIB4DB-02-2' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'WSCHAB4DB-02-1' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'WSCHAB4DB-02-2' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO))
GO


-----------------------------------------------------------------------------------------------------------
---------------Modify the location of the data and transaction log files on all the replicas---------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1
 
--DATABASE Buy4
ALTER DATABASE [Buy4] MODIFY FILE (NAME='testing_Buy4',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf')
GO
--DATABASE Buy4_accounting
ALTER DATABASE [Buy4_accounting] MODIFY FILE (NAME='Buy4_accounting',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf')
GO
--DATABASE Buy4_clearing
ALTER DATABASE [Buy4_clearing] MODIFY FILE (NAME='Buy4_clearing',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf')
GO
--DATABASE CaixaAffiliation
ALTER DATABASE [CaixaAffiliation] MODIFY FILE (NAME='CaixaAffiliation',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CaixaAffiliation.mdf')
GO
--DATABASE CardScheme
ALTER DATABASE [CardScheme] MODIFY FILE (NAME='IRD_Finder',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf')
GO
--DATABASE DocumentManager
ALTER DATABASE [DocumentManager] MODIFY FILE (NAME='DocumentManager',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\DocumentManager.mdf')
GO
--DATABASE Logging
ALTER DATABASE [Logging] MODIFY FILE (NAME='Logging',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Logging.mdf')
GO
--DATABASE Membership
ALTER DATABASE [Membership] MODIFY FILE (NAME='Membership',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf')
GO
--DATABASE MiniCRM
ALTER DATABASE [MiniCRM] MODIFY FILE (NAME='MiniCRM',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MiniCRM.mdf')
GO
--DATABASE SchemeRepository
ALTER DATABASE [SchemeRepository] MODIFY FILE (NAME='SchemeRepository',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf')
GO

---------------------
--SERVER CENTRAL 02--
---------------------
:Connect SCCHIB4DB-02-2
 
--DATABASE Buy4
ALTER DATABASE [Buy4] MODIFY FILE (NAME='testing_Buy4',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf')
GO
--DATABASE Buy4_accounting
ALTER DATABASE [Buy4_accounting] MODIFY FILE (NAME='Buy4_accounting',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf')
GO
--DATABASE Buy4_clearing
ALTER DATABASE [Buy4_clearing] MODIFY FILE (NAME='Buy4_clearing',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf')
GO
--DATABASE CaixaAffiliation
ALTER DATABASE [CaixaAffiliation] MODIFY FILE (NAME='CaixaAffiliation',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CaixaAffiliation.mdf')
GO
--DATABASE CardScheme
ALTER DATABASE [CardScheme] MODIFY FILE (NAME='IRD_Finder',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf')
GO
--DATABASE DocumentManager
ALTER DATABASE [DocumentManager] MODIFY FILE (NAME='DocumentManager',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\DocumentManager.mdf')
GO
--DATABASE Logging
ALTER DATABASE [Logging] MODIFY FILE (NAME='Logging',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Logging.mdf')
GO
--DATABASE Membership
ALTER DATABASE [Membership] MODIFY FILE (NAME='Membership',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf')
GO
--DATABASE MiniCRM
ALTER DATABASE [MiniCRM] MODIFY FILE (NAME='MiniCRM',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MiniCRM.mdf')
GO
--DATABASE SchemeRepository
ALTER DATABASE [SchemeRepository] MODIFY FILE (NAME='SchemeRepository',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf')
GO

-----------------
--WINDSTREAM 01--
-----------------
:Connect WSCHAB4DB-02-1

--DATABASE Buy4
ALTER DATABASE [Buy4] MODIFY FILE (NAME='testing_Buy4',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf')
GO
--DATABASE Buy4_accounting
ALTER DATABASE [Buy4_accounting] MODIFY FILE (NAME='Buy4_accounting',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf')
GO
--DATABASE Buy4_clearing
ALTER DATABASE [Buy4_clearing] MODIFY FILE (NAME='Buy4_clearing',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf')
GO
--DATABASE CaixaAffiliation
ALTER DATABASE [CaixaAffiliation] MODIFY FILE (NAME='CaixaAffiliation',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CaixaAffiliation.mdf')
GO
--DATABASE CardScheme
ALTER DATABASE [CardScheme] MODIFY FILE (NAME='IRD_Finder',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf')
GO
--DATABASE DocumentManager
ALTER DATABASE [DocumentManager] MODIFY FILE (NAME='DocumentManager',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\DocumentManager.mdf')
GO
--DATABASE Logging
ALTER DATABASE [Logging] MODIFY FILE (NAME='Logging',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Logging.mdf')
GO
--DATABASE Membership
ALTER DATABASE [Membership] MODIFY FILE (NAME='Membership',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf')
GO
--DATABASE MiniCRM
ALTER DATABASE [MiniCRM] MODIFY FILE (NAME='MiniCRM',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MiniCRM.mdf')
GO
--DATABASE SchemeRepository
ALTER DATABASE [SchemeRepository] MODIFY FILE (NAME='SchemeRepository',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf')
GO

-----------------
--WINDSTREAM 02--
-----------------
:Connect WSCHAB4DB-02-2

--DATABASE Buy4
ALTER DATABASE [Buy4] MODIFY FILE (NAME='testing_Buy4',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf')
GO
--DATABASE Buy4_accounting
ALTER DATABASE [Buy4_accounting] MODIFY FILE (NAME='Buy4_accounting',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf')
GO
--DATABASE Buy4_clearing
ALTER DATABASE [Buy4_clearing] MODIFY FILE (NAME='Buy4_clearing',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf')
GO
--DATABASE CaixaAffiliation
ALTER DATABASE [CaixaAffiliation] MODIFY FILE (NAME='CaixaAffiliation',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CaixaAffiliation.mdf')
GO
--DATABASE CardScheme
ALTER DATABASE [CardScheme] MODIFY FILE (NAME='IRD_Finder',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf')
GO
--DATABASE DocumentManager
ALTER DATABASE [DocumentManager] MODIFY FILE (NAME='DocumentManager',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\DocumentManager.mdf')
GO
--DATABASE Logging
ALTER DATABASE [Logging] MODIFY FILE (NAME='Logging',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Logging.mdf')
GO
--DATABASE Membership
ALTER DATABASE [Membership] MODIFY FILE (NAME='Membership',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf')
GO
--DATABASE MiniCRM
ALTER DATABASE [MiniCRM] MODIFY FILE (NAME='MiniCRM',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MiniCRM.mdf')
GO
--DATABASE SchemeRepository
ALTER DATABASE [SchemeRepository] MODIFY FILE (NAME='SchemeRepository',FILENAME='H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf')
GO

-----------------------------------------------------------------------------------------------------------
--------------------------Perform the failover of AlwaysOn group-------------------------------------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 02--
---------------------
:Connect SCCHIB4DB-02-2
 
ALTER AVAILABILITY GROUP [BUY4BO-AG] FAILOVER;
GO


-----------------------------------------------------------------------------------------------------------
--------Move the physical files (MDF/LDF/NDF) to the new location on all the secondary replicas------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1
/*
:Connect SCCHIB4DB-02-1

ALTER DATABASE [Buy4] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_accounting] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_clearing] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CaixaAffiliation] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CardScheme] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DocumentManager] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Logging] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Membership] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [MiniCRM] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [SchemeRepository] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
*/

--DATABASE Buy4
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_accounting
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_clearing
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CaixaAffiliation
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\CaixaAffiliation.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CardScheme
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE DocumentManager
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\DocumentManager.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Logging
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Logging.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Membership
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE MiniCRM
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\MiniCRM.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE SchemeRepository
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
  
-----------------
--WINDSTREAM 01--
-----------------
:Connect WSCHAB4DB-02-1
/*
:Connect WSCHAB4DB-02-1

ALTER DATABASE [Buy4] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_accounting] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_clearing] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CaixaAffiliation] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CardScheme] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DocumentManager] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Logging] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Membership] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [MiniCRM] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [SchemeRepository] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
*/

--DATABASE Buy4
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_accounting
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_clearing
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CaixaAffiliation
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\CaixaAffiliation.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CardScheme
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE DocumentManager
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\DocumentManager.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Logging
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Logging.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Membership
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE MiniCRM
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\MiniCRM.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE SchemeRepository
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO

-----------------
--WINDSTREAM 02--
-----------------
:Connect WSCHAB4DB-02-2
/*
:Connect WSCHAB4DB-02-2

ALTER DATABASE [Buy4] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_accounting] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_clearing] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CaixaAffiliation] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CardScheme] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DocumentManager] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Logging] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Membership] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [MiniCRM] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [SchemeRepository] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
*/
--DATABASE Buy4
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_accounting
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_clearing
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CaixaAffiliation
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\CaixaAffiliation.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CardScheme
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE DocumentManager
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\DocumentManager.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Logging
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Logging.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Membership
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE MiniCRM
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\MiniCRM.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE SchemeRepository
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO

-----------------------------------------------------------------------------------------------------------
----------------------------------Initiate the database recovery-------------------------------------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1
 
ALTER DATABASE [Buy4] SET ONLINE
GO
ALTER DATABASE [Buy4_accounting] SET ONLINE
GO
ALTER DATABASE [Buy4_clearing] SET ONLINE
GO
ALTER DATABASE [CaixaAffiliation] SET ONLINE
GO
ALTER DATABASE [CardScheme] SET ONLINE
GO
ALTER DATABASE [DocumentManager] SET ONLINE
GO
ALTER DATABASE [Logging] SET ONLINE
GO
ALTER DATABASE [Membership] SET ONLINE
GO
ALTER DATABASE [MiniCRM] SET ONLINE
GO
ALTER DATABASE [SchemeRepository] SET ONLINE
GO
 
 -----------------
--WINDSTREAM 01--
-----------------
:Connect WSCHAB4DB-02-1

ALTER DATABASE [Buy4] SET ONLINE
GO
ALTER DATABASE [Buy4_accounting] SET ONLINE
GO
ALTER DATABASE [Buy4_clearing] SET ONLINE
GO
ALTER DATABASE [CaixaAffiliation] SET ONLINE
GO
ALTER DATABASE [CardScheme] SET ONLINE
GO
ALTER DATABASE [DocumentManager] SET ONLINE
GO
ALTER DATABASE [Logging] SET ONLINE
GO
ALTER DATABASE [Membership] SET ONLINE
GO
ALTER DATABASE [MiniCRM] SET ONLINE
GO
ALTER DATABASE [SchemeRepository] SET ONLINE
GO

-----------------
--WINDSTREAM 02--
-----------------
:Connect WSCHAB4DB-02-2

ALTER DATABASE [Buy4] SET ONLINE
GO
ALTER DATABASE [Buy4_accounting] SET ONLINE
GO
ALTER DATABASE [Buy4_clearing] SET ONLINE
GO
ALTER DATABASE [CaixaAffiliation] SET ONLINE
GO
ALTER DATABASE [CardScheme] SET ONLINE
GO
ALTER DATABASE [DocumentManager] SET ONLINE
GO
ALTER DATABASE [Logging] SET ONLINE
GO
ALTER DATABASE [Membership] SET ONLINE
GO
ALTER DATABASE [MiniCRM] SET ONLINE
GO
ALTER DATABASE [SchemeRepository] SET ONLINE
GO


-----------------------------------------------------------------------------------------------------------
--------------------------Perform the failover of AlwaysOn group-------------------------------------------
-----------------------------------------------------------------------------------------------------------
 
---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1
 
ALTER AVAILABILITY GROUP [BUY4BO-AG] FAILOVER;
GO

-----------------------------------------------------------------------------------------------------------
------------------To fix the file location and resume the synchronization on Node2-------------------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 02--
---------------------
:Connect SCCHIB4DB-02-2
/*
:Connect SCCHIB4DB-02-2

ALTER DATABASE [Buy4] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_accounting] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Buy4_clearing] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CaixaAffiliation] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CardScheme] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DocumentManager] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Logging] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Membership] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [MiniCRM] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
ALTER DATABASE [SchemeRepository] SET OFFLINE WITH 
ROLLBACK IMMEDIATE
GO
*/
--DATABASE Buy4
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_accounting
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_accounting.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Buy4_clearing
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Buy4_clearing.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CaixaAffiliation
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\CaixaAffiliation.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE CardScheme
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\IRD_Finder.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE DocumentManager
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\DocumentManager.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Logging
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Logging.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE Membership
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Membership.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE MiniCRM
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\MiniCRM.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO
--DATABASE SchemeRepository
xp_cmdshell'move "F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SchemeRepository.mdf" "H:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\"' 
GO

---------------------
--SERVER CENTRAL 02--
---------------------
:Connect SCCHIB4DB-02-2

ALTER DATABASE [Buy4] SET ONLINE
GO
ALTER DATABASE [Buy4_accounting] SET ONLINE
GO
ALTER DATABASE [Buy4_clearing] SET ONLINE
GO
ALTER DATABASE [CaixaAffiliation] SET ONLINE
GO
ALTER DATABASE [CardScheme] SET ONLINE
GO
ALTER DATABASE [DocumentManager] SET ONLINE
GO
ALTER DATABASE [Logging] SET ONLINE
GO
ALTER DATABASE [Membership] SET ONLINE
GO
ALTER DATABASE [MiniCRM] SET ONLINE
GO
ALTER DATABASE [SchemeRepository] SET ONLINE
GO

-----------------------------------------------------------------------------------------------------------
------------------Finally enable the read-only access for all the secondary replica------------------------
-----------------------------------------------------------------------------------------------------------

---------------------
--SERVER CENTRAL 01--
---------------------
:Connect SCCHIB4DB-02-1

ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'SCCHIB4DB-02-1' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'SCCHIB4DB-02-2' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'WSCHAB4DB-02-1' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO
ALTER AVAILABILITY GROUP [BUY4BO-AG] MODIFY REPLICA ON N'WSCHAB4DB-02-2' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO


