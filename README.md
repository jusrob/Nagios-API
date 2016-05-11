# nagios-api

## API

##End Points
| Endpoint | HTTP Method | Action |
|:--------:|:-----------:|:--------:|:-----------:|:--------:|
| POST | /new  | Add a host to nagios |
| DELETE | /:hostname  | Delete a host from nagios |


### POST
#### input (any number of services can be provided)
##### for config help https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/objectdefinitions.html
```
{
	"hostname": "test.example.com",
	"hostgroups": "all,production,p10",
	"ip": "1.1.1.1",
	"service1": {
		"check_command": "check_nrpe!check_zombie_procs",
		"service_description": "procs in zombie",
		"use": "generic-service"
	},
  "service2": {
    "check_command": "check_nrpe!check_load",
    "service_description": "load",
    "use": "generic-service"
  },
  "service3": {
    "check_command": "check_nrpe!check_iowait_procs",
    "service_description": "procs in iowait",
    "use": "generic-service"
  },
  "service4": {
    "check_command": "check_nrpe!check_disk_boot",
    "service_description": "disk utilization boot",
    "use": "generic-service"
  },
  "service5": {
    "check_command": "check_nrpe!check_disk_root",
    "service_description": "disk utilization root",
    "use": "generic-service"
  },
  "service6": {
    "check_command": "check_nrpe!check_mem",
    "service_description": "memory utilizationt",
    "use": "generic-service"
  },
  "service7": {
    "check_command": "check_nrpe!check_swap",
    "service_description": "swap utilization",
    "use": "generic-service"
  },
  "service8": {
    "check_command": "check_nrpe!check_total_proc",
    "service_description": "total procs",
    "use": "generic-service"
  },
}
```

##### POST example:
```
curl -H "Content-Type: application/json" -X POST -d '{"hostname": "test.example.com","hostgroups": "all,production,p10","ip": "1.1.1.1","service1": {"check_command": "check_nrpe!check_zombie_procs", "service_description": "procs in zombie", "use": "generic-service"},"service2": {"check_command": "check_nrpe!check_load","service_description": "loade","use": "generic-service"}}' http://<host>:8080/new
```

### DELETE

##### DELETE example:
```
curl -H "Content-Type: application/json" -X DELETE http://<host>:8080/test.example.com
```
