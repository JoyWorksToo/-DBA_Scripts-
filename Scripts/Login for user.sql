
Use buy4

Print 'Table Level Privileges to the User:'
SELECT 'grant ' + privilege_type + ' on ' + table_schema + '.' + table_name + ' to [' + grantee + ']' +
CASE IS_GRANTABLE 
	WHEN 'YES' 
		THEN ' With GRANT OPTION' 
		ELSE '' 
END
FROM INFORMATION_SCHEMA.TABLE_PRIVILEGES
WHERE grantee = '<User>'