# deviceControl

scripts to:
- control (start, stop or powercycle) or get status on PoE or HiLink ports.<br>
- allow MadGruber to pause device, reboot device etc https://github.com/RagingRectangle/MadGruber.<br>

## Installation
- git clone and copy config file `git clone https://github.com/dkmur/deviceControl.git && cd deviceControl && cp config.ini.example config.ini`<br>
- fill out details in config.ini, duplicate example section for each device you want to control<br>
- for controlling HiLink relay: install ncat. Debian `sudo apt install ncat`, Ubuntu `sudo apt install nmap`<br>
- for controlling PoE switch: install snmp, `sudo apt install snmp`<br>
<br>
If your server isn't local, for PoE there is the option to have the snmp control over local server i.e. a rPI by setting up SSH key-based authentication. See https://linuxize.com/post/how-to-setup-passwordless-ssh-login/.<br>

## Usage
execute `./relay_poe_control.sh`<br>
<br>
## MadGruber
### Scripts
relay_poe_control.sh allows for inputs on command line so it can be controlled via MadGruber.<br>
order of input: `./relay_poe_control.sh deviceName action port` where:<br>
- deviceName = name of device as specified in config.ini
- action = start, stop or cycle
- port = port number or `all`
Example can be found in MadGruber config folder

### Devicecontrol
- will allow MadGruber to use MAD api for stuff like pause device, reboot device and restart pogo.
- set `pathStats` at least, as for now Im linking to Stats config.ini, no need to have it running just clone and fill out DB and MADmin sections https://github.com/dkmur/Stats
- in case you want to power cycle based on origin add table below to STATSdb and fill out the details.
```
CREATE TABLE IF NOT EXISTS `relay` (
  `origin` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `port` int(6) NOT NULL,
  PRIMARY KEY (`origin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```
