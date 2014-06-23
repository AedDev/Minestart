Minestart - Control your MC Server!
===================================

Requirements
------------

* Linux systems (Debian, CentOS, ...)
* __bash__ is required (On Debian based systems: apt-get install bash)
* __screen__ is required (On Debian based systems: apt-get install screen)
* __tar__ is required to create backups
* _Optional:_ __git__ if you want to clone the Minestart repository

The Script is also working on ARM devices, such as an Tablet PC with Android or
the Raspberry Pi (But Minecraft is working very well on the PI :P)

Tutorial
--------

### How to start?

At first you have to download Minestart. You can download the master.zip file,
which contains all minestart files you need, directly from GitHub. Or you can
clone the Git Repository.

__Which way is better?__

I recommend to clone the Git Repository into a seperate folder. Like this:
* Your Minecraft Server is located here: /home/minecraft/MyServer
* Your Minestart Script is located here: /home/minecraft/Minestart

Why this way is better? With git you can keep your Minestart up2date.
So, if you have more than one server, you can simply link the Script to the
different servers. And every server can use it's own configuration.

If there is a new version available, you only have to type `git pull` in the
Minestart directory and the work is done. Now, all your servers use the new
Minestart Script, but the configurations are still the same.

__I don't want to use Git__

If you don't want to create a local Git Clone, you can simply download Minestart
here: https://github.com/morphesus/Minestart/archive/master.zip

### Setting up Minestart

Now you have to customize your Minestart Configuration, which is located in the
`minestart.cfg` file. This is pretty easy, you'll see ;)

There are multiple sections in the configurations, at first the application
setting (We don't need that), the Server Configuration and the World Management
Configurations.

Let's take a look to the Server Configuration!

#### Configuration: Server

__SERVER_JAR__

At first you need to set the path to your executable server JAR. In most cases
it should be something like `$BASE_DIR/craftbukkit.jar`. $BASE_DIR is the
working directory, the directory where your Minestart script or the link to your
Minestart Script is located.

__LOG_FILE__

The next step is to set the location of minecrafts log file. Vanilla  or Bukkit
Minecraft Server are saving the entire log to $`BASE_DIR/server.log. Spigot is
saving the log using _LogRotate_. So, you'll find the current log here:
`$BASE_DIR/logs/latest.log``

__RAM_MIN__ and __RAM_MAX__

Of course, for Java Applications you have to set the minimum and maximum of RAM
you want to allocate. As default, 1GB is the minimum and 2GB are maximum. For
small servers, you probably don't need more than 2GB of RAM. For large servers
it's better to allocate too much than too less.

__SCREEN_NAME__

The Screen name is the unique name for the Minecraft Server. You can choose the
name you want, but you shouldn't use spaces or special characters. Something
like "Server-001" is no problem! But "Server 001" can break the functionality,
because of the space.

__JDK_INSTALLED__

If you're using `openjdk-6-jdk`, `openjdk-7-jdk`, etc. or the JDK from Oracle,
you can set this option to 1. This flag maybe improve the performance of your
server.

### Configuration: World Management

__BACKUP_REMOVED_WORLDS__

If you want to remove your worlds safely, you can set this option to 1 (Default
is 1 too). Deleting a world using the `wdel {world_name}` command will create a
backup first before removing the world.

__WORLD_BACKUP_DIR__

This is the location for all world backups. By default the location is
`$BASE_DIR/.world_backups`, so it's a hidden folder located next to your
Minestart script or link.

### Starting the Server and working with Minestart

Now you're ready to start! You can simply start your server using the following
command: `./minestart.sh start`. If all went well, you should get a notice that
the server startet successfully with the PID XYZ.

_The server is not running? Get help here:_ http://forum.mds-tv.de

If your server is running, you have some additional commands to work with your
server. For example: You can send server commands using
`./minestart.sh cmd {cmd_name} {cmd_params}`

How to use? Assuming you want to add someone to your servers whitelist.
You can simply type: `./minestart.sh cmd whitelist add PLAYER` - and it's done.

Do you want to create a backup of one of your worlds? No problem! You can type:
`./minestart.sh backup MyWorld`. The backup will saved to $WORLD_BACKUP_DIR, this
is by default the directory .world_backups.

To see the full command list, simple execute the minestart.sh script without
any arguments.

Now you're ready to _Minestart_! :D

Planned features
----------------

* External configuration -> minestart.cfg
  * Add new command: ./minestart.sh setup (Settings up basic configuration)
  * Add new command: ./minestart.sh config [key] [value] (To set config values)
  * Add aliases for config command (Like: ./minestart.sh setjar craftbukkit-dev.jar)

* Install Minecraft server (Example: ./minestart.sh install bukkit-1.7.9)
* Command: remlogs (Removes the server.log file or logs/ directory)
* Interactive console
* Removing worlds
* Backup Manager (create, list, restore, delete)
* More default server commands (Such as: say, msg, tp, ...)

_If you have some fresh ideas, please inform me via mail: [admin@mds-tv.de](mailto:admin@mds-tv "Mail the developer")_

