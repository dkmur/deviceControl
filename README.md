# deviceControl

script to control (start, stop or powercycle) or get status on PoE or HiLink ports.<br>
<br>
## Installation
- git clone and copy config file `git clone https://github.com/dkmur/deviceControl.git && cd deviceControl && cp config.ini.example config.ini`<br>
- fill out details in config.ini, duplicate example section for each device you want to control<br>
- for controlling HiLink relay: install ncat. Debian `sudo apt install ncat`, Ubuntu `sudo apt install nmap`<br>
- for controlling PoE switch: install snmp, `sudo apt install snmp`<br>
<br>
If your server isn't local, for PoE there is the option to have the snmp control over local server i.e. a rPI by setting up SSH key-based authentication. See https://linuxize.com/post/how-to-setup-passwordless-ssh-login/.<br>

## Usage
execute `./devicecontrol.sh`<br>
<br>
## MadGruber
script allows for inputs on command line so it can be controlled via MadGruber.<br>
order of input: `./devicecontrol deviceName action port` where:<br>
- deviceName = name of device as specified in config.ini
- action = start, stop or cycle
- port = port number or `all`
