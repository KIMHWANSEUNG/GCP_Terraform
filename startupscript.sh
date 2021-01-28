#!/bin/bash

sudo apt-get update

sudo apt-get install -y gcc build-essential 

cat > index.html <<EOF
<h1>Hello, Bespin New Members !!!</h1>
<p> This is <b>${instance_group_name}</b> system</p>
<p> This system hostname is <b>$(hostname)</b></p>
<p> This system has ip addresses: <b>$(hostname -I)</b></p>
EOF

nohup busybox httpd -f -p ${service_port} &
