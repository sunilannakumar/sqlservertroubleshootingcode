select  
    scheduler_id, 
    current_tasks_count, 
    runnable_tasks_count, 
    current_workers_count, 
    active_workers_count, 
    work_queue_count, 
    load_factor, 
    status 
from sys.dm_os_schedulers 
--where scheduler_id < 255 
order by scheduler_id 
