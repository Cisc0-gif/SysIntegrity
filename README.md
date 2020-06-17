# SysIntegrity - File MD5sum Verification Tool

SysIntegrity allows users to add files on their system to a registry which would then be checked on startup. If a file has an unwarranted change, the hash would be changed which would trigger a red flag and warn the user of possible intrusion.

## Getting Started

To setup and add files to the whitelist, run ``` ./main.sh ``` 
For better security, create a cronjob by typing ``` sudo crontab -e ``` and input the following line ``` @reboot /file/path/SysIntegrity/cron.sh > /home/USER/.sysintegrity.log ```. This will check for hash changes on startup and write to a log file in the user's home directory

If you make a change to a file on the whitelist you're going to have to add the file again and remove the old entry from the whitelist. This tool is meant for critical system files that require little to no reoccuring configuration.

## Built With

* Ubuntu - Debian Linux OS
* Kali Linux - Pentesting OS developed by Offensive Security
* GitHub - This Website!


## Authors

* **Cisc0-gif** - *Main Contributor/Author*: Ecorp7@protonmail.com

## License

This project is licensed under the GNU General Public License v3 - see the LICENSE file for details


## Acknowledgments

All credits are given to the authors and contributors to tools used in this software
