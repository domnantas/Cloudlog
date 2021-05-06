#!/bin/bash

# Adapted from https://github.com/m0spf/cloudlog-docker

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ ! -f $DIR/.env ]; then
  echo "*** ERROR .env file is missing, copy .env.sample to .env and edit"
  exit 1
fi
source $DIR/.env

echo ""
echo "*** Updating permissions"
chown -R root:www-data $DIR/application/config/ $DIR/assets/qslcard/ $DIR/backup/ $DIR/updates/ $DIR/uploads/
chmod -R g+rw $DIR/application/config/ $DIR/assets/qslcard/ $DIR/backup/ $DIR/updates/ $DIR/uploads/

echo ""
echo "*** Creating config.php and database.php"
CONFIG_PATH="$DIR/application/config/config.php"
CONFIG_BLUEPRINT_PATH="$DIR/install/config/config.php"
DB_CONFIG_PATH="$DIR/application/config/database.php"
DB_CONFIG_BLUEPRINT_PATH="$DIR/install/config/database.php"
# LANGUAGE_DIR="$DIR/application/language/$LANGUAGE"

cp ${CONFIG_BLUEPRINT_PATH} ${CONFIG_PATH}
sed -i.bak "s|%directory%|${DIRECTORY}|" $CONFIG_PATH
sed -i.bak "s|%baselocator%|${LOCATOR}|" $CONFIG_PATH
sed -i.bak "s|%websiteurl%|${BASE_URL:-http://localhost}|" $CONFIG_PATH

cp ${DB_CONFIG_BLUEPRINT_PATH} ${DB_CONFIG_PATH}
sed -i.bak "s|%HOSTNAME%|${MYSQL_HOST}|" $DB_CONFIG_PATH
sed -i.bak "s|%USERNAME%|${MYSQL_USER}|" $DB_CONFIG_PATH
sed -i.bak "s|%PASSWORD%|${MYSQL_PASSWORD}|" $DB_CONFIG_PATH
sed -i.bak "s|%DATABASE%|${MYSQL_DATABASE}|" $DB_CONFIG_PATH

echo ""
echo "*** Creating cron file"

rm cloudlog-cron

# Update the Cloudlog installation every day at midnight
# echo "0 0 * * * /bin/bash -c $DIR/update_cloudlog.sh > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Upload QSOs to Club Log (ignore cron job if this integration is not required)
# echo "0 */6 * * * curl --silent https://${BASE_URL:-http://localhost}/index.php/clublog/upload/<username-with-clublog-login> > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Upload QSOs to LoTW if certs have been provided every hour.
# echo "0 */1 * * * curl --silent ${BASE_URL:-http://localhost}/index.php/lotw/lotw_upload > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Upload QSOs to QRZ Logbook (ignore cron job if this integration is not required)
# echo "0 */6 * * * curl --silent ${BASE_URL:-http://localhost}/index.php/qrz/upload/> > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Update LOTW Users Database
echo "@weekly curl --silent ${BASE_URL:-http://localhost}/index.php/lotw/load_users > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Update Clublog SCP Database File
echo "@weekly curl --silent ${BASE_URL:-http://localhost}/index.php/update/update_clublog_scp > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Update DOK File for autocomplete
echo "@monthly curl --silent ${BASE_URL:-http://localhost}/index.php/update/update_dok > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

# Update SOTA File for autocomplete
echo "@monthly curl --silent ${BASE_URL:-http://localhost}/index.php/update/update_sota > /proc/1/fd/1 2>/proc/1/fd/2" >>cloudlog-cron

chmod +x cloudlog-cron
crontab cloudlog-cron
cron

echo ""
echo "*** Adding rewrite rules"
cp .htaccess.sample .htaccess

echo ""
echo "*** Removing install directory"
rm -r $DIR/install

echo ""
echo "*** Cloudlog has been installed."
