[workstations]
%{ for ip in workstation_ips ~}
${ip}
%{ endfor ~}
