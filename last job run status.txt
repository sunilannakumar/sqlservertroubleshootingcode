/* Developed by Mayur jh.Sanap
   Date:-  30-12-2012
   This will give provide you status of all sql jobs 
   Query is useful for all sql versions from 2000 to 2008 r2
*/
Use msdb
go
select distinct j.Name as "Job Name", --j.job_id,
case j.enabled 
when 1 then 'Enable' 
when 0 then 'Disable' 
end as "Job Status", jh.run_date as [Last_Run_Date(YY-MM-DD)] , 
case jh.run_status 
when 0 then 'Failed' 
when 1 then 'Successful' 
when 2 then 'Retry'
when 3 then 'Cancelled' 
when 4 then 'In Progress' 
end as Job_Execution_Status
from sysJobHistory jh, sysJobs j
where j.job_id = jh.job_id and jh.run_date =  
(select max(hi.run_date) from sysJobHistory hi where jh.job_id = hi.job_id )-- to get latest date



