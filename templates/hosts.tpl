[master]
%{ for ip in master ~}
${ip.ip_address}
%{ endfor ~}

[worker]
%{ for ip in worker ~}
${ip.ip_address}
%{ endfor ~}

[k8s:children]
master
worker