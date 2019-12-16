
----------------------------------------------------------------------
----------------------------------------------------------------------
----       Localizando usu�rios conectados ao servidor.          ------
----    O exemplo a seguir localiza os usu�rios conectados      ------
---- ao servidor e retorna o n�mero de sess�es de cada usu�rio. ------
----------------------------------------------------------------------
----------------------------------------------------------------------

SELECT login_name ,COUNT(session_id) AS session_count 
FROM sys.dm_exec_sessions 
GROUP BY login_name
order by session_count desc

GO

SELECT Count(session_id) as Connections FROM sys.dm_exec_sessions Where is_user_process = 1

