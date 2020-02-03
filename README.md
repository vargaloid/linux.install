# varg.install
Bash script to install some packages

Installation Features:
- mc,vim,sudo,wget,git
- vsftpd
- fail2ban-ssh
- zabbix-server 4.0 
- Docker Engine (CE)
- Proxmox VE 5 (stretch), VE 6 (buster)
- MariaDB 10.3
- GitLab (CE)
- Jenkins
- Prometheus with Grafana

Version 11.0.0

*Numbering changed with this release*

Release notes:

Version 11.0.0
- Prometheus with Grafana installation added

Version ~~16.00~~10.0.0
- Jenkins install added

Version ~~15.00~~9.4.0
- version of zabbix-server chamged to 4.0

Version ~~14.00~~9.3.0
- added Proxmox VE 6 to Debian 10 (Buster)

Version ~~13.00~~9.2.0
- added gitlab installation for Debian 10 (Buster) and CentOS7

Version ~~12.00~~9.1.0
- added docker-compose installation

Version ~~11.02~~9.0.2
- docker installation bug fix

Version ~~11.01~~9.0.1
- vsftpd installation bug fix

Version ~~11.00~~9.0.0
- GitLab installation added
- Changed "Check OS TYPE & VERSION"

Version ~~10.03~~8.0.1
- changed jail.local for fail2ban CentOS7 installation

Version ~~10.02~~8.0.0
- added MariaDB 10.3 installation from official MariaDB repository

Version ~~9.02~~7.0.0
- added Proxmox VE installation (Need check in real environment!!!)

Version ~~8.02~~6.0.0
- added Docker installation

Version ~~7.02~~5.2.0
- added "Are you sure?" question when select some installation

Version ~~7.01~~5.1.0
- added zabbix-server 3.4 installation
- added color output
- added log file

Version ~~6.01~~4.0.0
- added fail2ban-ssh installation

Version ~~5.01~~3.0.0
- added vsftpd installation

Version ~~4.01~~2.0.0
- added utils installation

Version ~~3.01~~1.0.0
- added Main Menu

Version ~~2.01~~0.2.0
- added OS check

Version ~~1.01~~0.1.0
- added sudo check
