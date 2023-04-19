[master-leader]
%{ for ip in master-leader ~}
${ip.ip_address}
%{ endfor ~}

%{ for node, ips in others ~}

[${node}]
%{ for ip in ips ~}
${ip}
%{ endfor ~}

%{ endfor ~}
