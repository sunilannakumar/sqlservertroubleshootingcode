DECLARE @v_spid INT

DECLARE Users CURSOR

FAST_FORWARD FOR

SELECT SPID

FROM master.dbo.sysprocesses (NOLOCK)

WHERE spid>50

AND status='sleeping'

AND DATEDIFF(mi,last_batch,GETDATE())>=60 --Check sleeping connections that exists before 60 min..

AND spid<>@@spid

OPEN Users

FETCH NEXT FROM Users INTO @v_spid

WHILE (@@FETCH_STATUS=0)

BEGIN

PRINT 'KILLing '+CONVERT(VARCHAR,@v_spid)+'...'

EXEC('KILL '+@v_spid)

FETCH NEXT FROM Users INTO @v_spid

END

CLOSE Users

DEALLOCATE Users