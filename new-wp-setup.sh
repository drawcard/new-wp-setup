#!/bin/bash


#How to use this script: run "bash new-wp-setup.sh" in a terminal

#Configuration - Check / change these settings first before running!
wwwlink="local.dev/clients/" #The URL where your development sites are located
devfolder="/var/www/clients/" #The folder path to your development sites directory
dbprefix="wp" #The prefix you want to add to DB names - default is wp. Don't change unless you have to.
dbloc="localhost" #Where your MYSQL database is located - default is localhost. Don't change unless you have to.

#Text colours - http://stackoverflow.com/a/20983251
fix=`tput sgr0` #Reset style
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

#Misc info
rightnow=`date +%Y%m%d` #Get the date and time to add onto the database name to prevent overwriting other db's named similarly

#Generate 12 digit random passwords: http://www.shellhacks.com/en/Generating-Random-Passwords-in-the-Linux-Command-Line
pwgen=`tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-12} | xargs`
pwgen2=`tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-12} | xargs`

# Plugin arrays: http://www.thegeekstuff.com/2010/06/bash-array-tutorial/
# These are the plugins that will be installed if the user chooses 
pSage=(https://github.com/roots/roots-wrapper-toolbar/archive/master.zip https://github.com/roots/roots-wrapper-toolbar/archive/sagesupport.zip https://github.com/roots/soil/archive/master.zip)
pDevelopment=(coming-soon wpautop-control wp-emmet https://github.com/wp-sync-db/wp-sync-db/archive/master.zip https://github.com/wp-sync-db/wp-sync-db-media-files/archive/master.zip);
pUtilities=(bootstrap-3-shortcodes wp-super-cache wordpress-seo akismet contact-form-7 really-simple-captcha tinymce-advanced wpautop-control regenerate-thumbnails html-editor-syntax-highlighter);

# Welcome
echo "${yellow}"
echo "-----------------------"
echo "NEW WORDPRESS INSTALLER"
echo "This script does a fresh install of WP into it's own /www/ subfolder within a project folder, with some optional extras at the end."
echo "-----------------------"
echo "/!\ You will need to install WP-CLI if you haven't done so - http://wp-cli.org"
echo "/!\ Edit this script first and change the configuration settings to suit your workspace!"
echo "/!\ Sudo access may be requested, to set the correct permissions for your Wordpress installation."
echo "-----------------------"
echo "${fix}" 

pause(){
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}
pause

# Set up WP files
echo "${cyan}>> What Wordpress account name would you like to use? (TIP: Don't use 'admin' for security reasons! No spaces, alphanumeric characters only.)${fix}" 
read adminname
echo "${cyan}>> What is your email address, to help retrieve lost account information? ${fix}" 
read email
echo "${cyan}>> What is the domain name for the installation? ${blue}eg. projectname.com.au ${fix}" 
read domainname
echo "${green}Setting up ${domainname} at ${devfolder}${domainname}/www/ ... ${fix}" ; sleep 2

cd $devfolder
mkdir $domainname
cd $domainname
mkdir www
cd www
wp core download

#Set up MYSQL DB
echo "${green}Setting up database in MYSQL...${fix}" ; sleep 2
echo "Please enter your MYSQL user name: ${fix}"
read mysqluser
echo "Please enter your MYSQL user password: ${fix}"
read -s mysqlpw

#Sanitize project name for DB
clean=${domainname//_/} #Remove underscores
clean=${clean// /_} #Replace spaces with underscores
clean=${clean//[^a-zA-Z0-9_]/} #Remove anything else not alphanumeric
cleanname=`echo -n $clean | tr A-Z a-z` #Lowercase everything

dbname="${dbprefix}_${cleanname}_${rightnow}"
dbuser=`echo ${dbprefix}_${cleanname} | cut -c 1-16` #shorten the name to 16 characters or less
dbpw="${pwgen}"

#Generate random table prefix for additional security: https://digwp.com/2010/10/change-database-prefix/
#trandom=`tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-5} | xargs`
ttruncate=`echo ${cleanname} | cut -c 1-3 | rev` #use some letters to make up a prefix
tableprefix=`echo ${ttruncate}_`

mysql -u "$mysqluser" -p"$mysqlpw" << End-MySQL-Commands

create database $dbname;
create user $dbuser;
grant all on $dbname.* to '$dbuser'@'$dbloc' identified by '$pwgen';
flush privileges;

End-MySQL-Commands

echo "${green}Database setup complete!${fix}" ; sleep 2
echo "${green}Configuring wp-config.php...${fix}" ; sleep 2
wp core config --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpw --dbprefix=$tableprefix # http://wp-cli.org/commands/core/config/ for more options

echo "${green}Installing Wordpress...${fix}" ; sleep 2
wp core install --url=$wwwlink$domainname/www/ --admin_user=$adminname --title=WordPress --admin_password=$pwgen2 --admin_email=$email # http://wp-cli.org/commands/core/install/ for more options

roots_theme () {
read -p "${green}Install Sage framework theme & helper plugins?  
* Requires NPM / Gulp / Bower. More info: https://github.com/roots/sage. 
* Additional setup is required after activation. 
* Please review the instructions as they are presented.${fix}
[y/n] > " answer
if [[ $answer = y ]] ; then
  # run the command
  cd ${devfolder}${domainname}/www/

# Insert Development Environment variable into line 3 of wp-config.php
ed -s wp-config.php << DEV_ENV
3i
define('WP_ENV', 'development'); // Remove this line when you have finished theme development and you've run 'gulp build' in the Sage theme directory. More info: https://roots.io/sage/docs/theme-installation/ 
.
w
q
DEV_ENV
  
  sagetheme="https://github.com/roots/sage.git"
  theme="$cleanname-theme"
  barerepo="$theme-barerepo"
  echo "${blue}Creating bare repo + cloning Sage from Github to wp-content/themes/${theme}...${fix}" ; sleep 2
  cd wp-content/themes
  git clone --bare $sagetheme $barerepo
  cd $barerepo
  touch .htaccess
  echo "deny from all" >> .htaccess
  cd ..
  git clone $barerepo $theme
  cd $theme
  git remote add upstream $sagetheme
  git fetch origin
  git fetch upstream
  echo "${blue}Creating a 'dev' branch for you to work in...${fix}" ; sleep 2
  git checkout -b dev
  echo "Activating theme..."
  cd ${devfolder}${domainname}/www/
  wp theme activate $theme
  
#Install Sage plugins
echo "${blue}Installing and activating Sage plugins...${fix}" ; sleep 2
cd ${devfolder}${domainname}/www/
#iterate through the array
  for i in "${pSage[@]}"
    do
      #print the plugin name
	    echo "${green} --- Installing Plugin:"
	    echo $i
	    echo "${fix}" 
	    sleep 1
      #install each plugin
	    wp plugin install --activate $i
    done 

  echo "${blue}Sage theme framework is installed and activated.${fix}"
  echo "${yellow}/!\ You will need to run the following from your theme folder *before* you begin development otherwise your theme will look broken on the frontend:${fix}"
  echo "${yellow}    $ npm install -g npm@latest"
  echo "${yellow}    $ npm install -g gulp bower"
  echo "${yellow}    $ npm install ; bower install ; gulp build"
  echo "${yellow} Visit https://github.com/roots/sage for more information on using Sage.${fix}"
  echo "${magenta}-----------${fix}"
  echo "${magenta}Sage has been installed to: ${devfolder}${domainname}/www/wp-content/themes/$theme/${fix}"
  echo "${magenta}Sage's bare repo location is: ${devfolder}${domainname}/www/wp-content/themes/$barerepo/${fix}"
  echo "${magenta}-----------${fix}"
  echo "${yellow}/!\ Use the bare repo location to clone the theme folder to other locations.${fix}"
  sleep 2
fi
}
roots_theme

plugin_dev () {
read -p "${green}Install and activate development plugins? 
------------------
Plugins: `echo ${pDevelopment[@]}`
------------------
[y/n] > 
${fix}
" answer
if [[ $answer = y ]] ; then
cd ${devfolder}${domainname}/www/
#iterate through the array
  for i in "${pDevelopment[@]}"
    do
      #print the plugin name
	    echo "${green} --- Installing Plugin:"
	    echo $i
	    echo "${fix}" 
	    sleep 1
      #install each plugin
	    wp plugin install --activate $i
    done 
fi
}
plugin_dev

plugin_utilities () {
read -p "${green}Install and activate utilities plugins? 
------------------
Plugins: `echo ${pUtilities[@]}`
------------------
[y/n] > 
${fix}
" answer
if [[ $answer = y ]] ; then
cd ${devfolder}${domainname}/www/
#iterate through the array
  for i in "${pUtilities[@]}"
    do
      #print the plugin name
	    echo "${green} --- Installing Plugin:"
	    echo $i
	    echo "${fix}" 
	    sleep 1
      #install each plugin
	    wp plugin install --activate $i
    done 
fi
}
plugin_utilities

cleanup () {
read -p "${green}Clean up unused plugins & themes, and activate PHP debug mode for WP? [y/n] > ${fix}" answer
if [[ $answer = y ]] ; then
  # run the command
  cd ${devfolder}${domainname}/www/
  wp plugin uninstall hello
  wp theme delete twentyfourteen twentythirteen twentyfifteen 
  
# Insert Debug variables into line 3 of wp-config.php
ed -s wp-config.php << DEBUG_CODE
3i
define('WP_DEBUG', true); // Enable Wordpress PHP debugging
define('WP_DEBUG_LOG', true); // Keep a log of all PHP issues in /wp-content/debug.log
define('WP_DEBUG_DISPLAY', false); // Suppress warning / error messages from being publicly viewable
@ini_set('display_errors',0); // Suppress warning / error messages from being publicly viewable
.
w
q
DEBUG_CODE

fi
}
cleanup

# Set correct permissions
echo "${green}Set correct file (644) and folder (755) permissions... (sudo access may be required)${fix}"
cd ${devfolder}${domainname}/www/
touch .htaccess
mkdir wp-content/uploads/
sudo chown www-data:www-data .htaccess
sudo chown www-data:www-data -R wp-content/
find . -type f -exec sudo chmod 644 {} \;
find . -type d -exec sudo chmod 755 {} \;
sudo chmod 660 wp-config.php
ed -s wp-config.php << DIRECT_ACCESS
3i
define('FS_METHOD','direct'); // Solves an issue when attempting to install plugins and an FTP connection is requested
.
w
q
DIRECT_ACCESS


#Misc setup stuff
echo "${green}Nearly done...${fix}"
wp rewrite structure --hard '/%year%/%monthnum%/%day%/%postname%' #Fixes permalink issues

# Report results at the end of the script
echo "${magenta}"
echo "Congratulations! Your new WP installation details are:"
echo "BACKEND ----------------"
echo "   Installation location: ${devfolder}${domainname}/www/"
echo "   Database name: ${dbname}"
echo "   Database user: ${dbuser}"
echo "   Database pass: ${pwgen}"
echo "   Database table prefix: ${tableprefix}_"
echo "FRONTEND ---------------"
echo "   Website location: ${wwwlink}${domainname}/www/"
echo "   WP admin page: ${wwwlink}${domainname}/www/wp-admin/"
echo "   WP admin name: ${adminname}"
echo "   WP admin pass: ${pwgen2}"
echo "   WP admin mail: ${email}"
echo "WEBSITE NAME -----------"
echo "   Log into WordPress and update your site name."
echo "${yellow}/!\ Copy and paste this info somewhere safe."
echo "${fix}"
