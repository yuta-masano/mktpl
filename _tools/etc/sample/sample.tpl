###  for .bash_profile
PGDATA={{ .pgdata }}
PGPORT={{ .pgport }}

PATH={{ .pgbin }}:$PATH
LD_LIBRARY_PATH={{ .pglib }}:$LD_LIBRARY_PATH

export PGDATA PGPORT PATH LD_LIBRARY_PATH


###  for postgresql.conf
port = {{ .pgport }}
synchronous_standby_names and so on ...= '{{ len .dbservers }} ({{ join .dbservers ", " }})'


###  single command output
{{ exec .current_timestamp }}
