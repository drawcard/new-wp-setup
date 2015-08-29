# new-wp-setup
A handy script to help create new Wordpress installations using WP-CLI. Better docs will be here momentarily. New-WP-Setup is the name until I come up with something more flashy.

# Quick rundown
This script does the following:
* Asks you some basic setup questions (account username, contact email, and project folder naming)
* Generates a secure random password for your new account
* Downloads the lastest stable build of Wordpress to your project folder using WP-CLI
* Sets up a database in MYSQL with:
  * Database name based on the project name + the date the project was initiated
  * Database user based on the project name
  * Randomly generated database table prefixes for extra security
* Configures your wp-config.php file with all your new database information
* Plus some optional extras which you can answer [y/n] to:
  * Downloads and activates [Sage Theme](https://roots.io/sage/), using a bare repo workflow so you can work on the theme with others via Git, without fear of commit conflicts
  * Downloads some useful plugins for fresh site setups (check out the source code to see what they are)
  * Deletes useless plugins (eg. hello-dolly!) and old WP themes that no-one cares about (2014, 2013 etc...)
* At the end of all of that, the script spits out a nice output of all the DB info + WP login info for you to copy and paste in a text file for future reference.

# How do I use the script?
* You need to have the basic LAMP stack installed and set up on your server
* You also need to have [WP-CLI](http://wp-cli.org/) installed
* Finally, you will need your MYSQL login details so the script can do the database setup
* Clone this script somewhere safe, eg your home directory: ```cd ~ ; git clone https://github.com/drawcard/new-wp-setup.git```
* Navigate to the script: ```cd ~/new-wp-setup/``` and give it executable rights: ```chmod +x ./new-wp-setup.sh```
* Navigate to the script and run ```nano new-wp-setup.sh``` to change the basic configuration settings at the top of the script file
* Run the script using ```./new-wp-setup.sh``` and follow the prompts.

# Help, the script screwed up!
* Did you edit the config settings before running the script?
* Do you have [WP-CLI](http://wp-cli.org/) installed?
* Is your LAMP stack in good working order, eg no issues with your MySQL setup?
* If you answered yes to all questions, please log an issue here on Github, copying all the output of the error so I can try and figure out what the problem is.
