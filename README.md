## README - mcstart

# Overview
mcstart is a simple shell script used to start minecraft servers.
It supports a specific directory structure but works with a variety of
Minecraft server jars.  
A secondary goal of the script is to be fully POSIX sh compliant. This
is to maintain as much universale compatibility as possible.

# Requirements
Packages:
- Minecraft server application
- ~~screen~~ tmux
- java (at least version 8, 17, and 21 according to my testing)

# Directory Structure
- Place mcstart script in whatever directory you prefer that is included
in your $PATH.
- mcstart expects each minecraft server jar to be located in $HOME in a 
directory named the same as the server software name, ie forge, paper,
spigot, vanilla, pixelmon, fabric etc.
- Within the server directory there should be a directory for each version
of Minecraft, ie 1.12.2, 1.17.1, 1.19.2, 1.19.3, etc.
  
The script now supports adding a `-<suffix>` to a version name to allow
multiple unique servers for a specific version. The suffix can be any
string of characters except a hyphen "-". Example: 1.19.3-solo 
There should also be a directory titled 'current' that is linked to the
most recent version present.  
  
For Forge server the script will always use the run.sh script.  
  
For Spigot, Paper, Fabric, and Vanilla the server jar should be named
by the server type and version like <server-name>-<MC-version>.jar  
  
The directory structure should resemble the following tree:  

    forge
    ├── 1.17.1
    │   ├── forge-1.17.1-37.0.95-installer.jar
    │   └── run.sh
    ├── 1.19.2
    │   ├── forge-1.19.2-43.2.0-installer.jar
    │   └── run.sh
    ├── 1.19.3
    │   ├── forge-1.19.3-44.1.0-installer.jar
    │   └── run.sh
    └── current -> 1.19.3

    spigot
    ├── 1.17.1
    │   └── spigot-1.17.1.jar
    ├── 1.19.3
    │   └── spigot-1.19.3.jar
    └── current -> 1.19.3

For Forge servers, run the java installer from within the directory
corresponding to the Minecraft version.

Once the server is running use `tmux list-sessions` to list running tmux 
sessions. Then use `tmux attach-session -t <name-of-tmux-session>` to
connect to the server console.

The second option <version> is optional. The default is 'current' if no
version option is entered.

To start your server use the following syntax:
    mcstart <server-type> <version>

Example
    mcstart forge 1.19.3
