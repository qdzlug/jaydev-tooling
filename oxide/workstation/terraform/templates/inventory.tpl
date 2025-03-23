[workstations]
%{ for ip in workstation_ips ~}
${ip} ansible_user=ubuntu ansible_become=true ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o ForwardAgent=yes'
%{ endfor ~}
