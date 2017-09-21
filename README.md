# deb-mtx-riot-install

[![Build Status](https://travis-ci.org/grigruss/deb-mtx-riot-install.svg?branch=master)](https://travis-ci.org/grigruss/deb-mtx-riot-install)
[![GitHub License](https://img.shields.io/github/license/grigruss/deb-mtx-riot-install.svg)](https://github.com/grigruss/deb-mtx-riot-install/blob/master/LICENSE.md)
[![GitHub Release](https://img.shields.io/github/release/grigruss/deb-mtx-riot-install.svg)](https://github.com/grigruss/deb-mtx-riot-install/releases)

  Bash script for installing matrix-synapse and Riot-web on a Debian server 8 jessie

Just download and run:
```
sudo ./mtx-riot-install.sh
```

After installation, you will be offered a cron configuration for daily checking and installing updates for Riot-web.

The script does not configure the configuration files, you must configure them manually.
In the future this will be finalized (https://github.com/grigruss/deb-mtx-riot-install/issues/2).
