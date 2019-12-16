

--------------------------------------------------------------------
--------------------------------------------------------------------
----      A linha de comando abaixo dentro do database, 	--------
---- executa somente o que o usuário em questão tem acesso. --------
--------------------------------------------------------------------
--------------------------------------------------------------------

USE buy4_aas;

EXECUTE AS USER = 'mbaffa';
SELECT SUSER_NAME()


EXECUTE AS USER = 'MonitoraAppUser';
SELECT SUSER_NAME()