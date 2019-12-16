SELECT
'grant '+permission_name+' on '+ QUOTENAME(s.name)+ '.'+ QUOTENAME(o.name) + ' TO '+dpr.name COLLATE SQL_Latin1_General_CP1_CI_AS
  --o.name,dp.permission_name,dpr.name
FROM sys.database_permissions AS dp
  INNER JOIN sys.objects AS o ON dp.major_id=o.object_id
  INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
  INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id=dpr.principal_id
WHERE dpr.name  IN ('TmsAppUser')
  --AND o.name IN ('BUY4_RECEIVABLES_ADVANCE','ATX_CONFIRMED_TRANSACTION','AMR_MOVEMENT','ATX_TX_MOVEMENT_DETAIL','ATX_OUTGOING_FILE_DATA')      -- Uncomment to filter to specific object(s)
--  AND dp.permission_name='EXECUTE'    -- Uncomment to filter to just the EXECUTEs
--AND dp.permission_name IN ('UPDATE','INSERT','DELETE')
ORDER BY o.name


--SELECT * FROM sys.database_permissions



select rp.name as database_role, mp.name as database_user
from sys.database_role_members drm
join sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
join sys.database_principals mp on (drm.member_principal_id = mp.principal_id)