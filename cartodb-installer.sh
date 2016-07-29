n#!/bin/bash
#cartodb-installer.sh

# tranversal dependencies
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
sudo apt-get update && apt-get -y install autoconf binutils-doc bison build-essential flex git python-software-properties

# psql dependencies
sudo add-apt-repository ppa:cartodb/postgresql-9.3 && sudo add-apt-repository ppa:cartodb/gis && sudo apt-get update
sudo apt-get -y install libpq5 libpq-dev postgresql-client-9.3 postgresql-client-common postgresql-9.3 \
                     postgresql-contrib-9.3 postgresql-server-dev-9.3 postgresql-plpython-9.3 postgis postgresql-9.3-postgis-2.2 postgresql-9.3-postgis-scripts \
                     libxml2-dev liblwgeom-2.1.8 \
                     proj proj-bin proj-data libproj-dev \
                     libjson0 libjson0-dev \
                     python-simplejson \
                     libgeos-c1v5 libgeos-dev \
                     gdal-bin libgdal1-dev libgdal-dev gdal2.1-static-bin

echo "local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust" >  /etc/postgresql/9.3/main/pg_hba.conf

sudo service postgresql restart

sudo createuser publicuser --no-createrole --no-createdb --no-superuser -U postgres
sudo createuser tileuser --no-createrole --no-createdb --no-superuser -U postgres

git clone https://github.com/CartoDB/cartodb-postgresql.git
cd cartodb-postgresql
git checkout master
sudo make all install
cd ~vagrant

sudo createdb -T template0 -O postgres -U postgres -E UTF8 template_postgis
sudo createlang plpgsql -U postgres -d template_postgis
psql -U postgres template_postgis -c 'CREATE EXTENSION postgis;CREATE EXTENSION postgis_topology;'
sudo ldconfig

sudo PGUSER=postgres make installcheck # to run tests
sudo service postgresql restart

sudo add-apt-repository ppa:cartodb/redis && sudo apt-get update
sudo apt-get -y install redis-server

sudo add-apt-repository ppa:cartodb/nodejs-010 && sudo apt-get update
sudo apt-get -y install nodejs

cd ~vagrant
git clone git://github.com/CartoDB/CartoDB-SQL-API.git
cd CartoDB-SQL-API
git checkout master
npm install
cp config/environments/development.js.example config/environments/development.js
node app.js development &
cd ~vagrant

sudo apt-get -y install libpango1.0-dev
git clone git://github.com/CartoDB/Windshaft-cartodb.git
cd Windshaft-cartodb
git checkout master
npm install
cp config/environments/development.js.example config/environments/development.js
node app.js development &
cd ~vagrant


wget -O ruby-install-0.5.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.5.0.tar.gz
tar -xzvf ruby-install-0.5.0.tar.gz
cd ruby-install-0.5.0/
sudo make install
cd ~vagrant

sudo apt-get -y install libreadline6-dev openssl
sudo ruby-install ruby 2.2.3
export PATH=$PATH:/opt/rubies/ruby-2.2.3/bin

sudo gem install bundler
sudo gem install compass
git clone --recursive https://github.com/CartoDB/cartodb.git
cd cartodb
sudo wget  -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
sudo python /tmp/get-pip.py
sudo apt-get -y install python-all-dev
sudo apt-get -y install imagemagick unp zip
RAILS_ENV=development bundle install
npm install
pip install --no-use-wheel -r python_requirements.txt

export PATH=$PATH:$PWD/node_modules/grunt-cli/bin
bundle install
bundle exec grunt --environment development
cp config/app_config.yml.sample config/app_config.yml
cp config/database.yml.sample config/database.yml

RAILS_ENV=development bundle exec rake db:migrate
RAILS_ENV=development bundle exec rake cartodb:db:setup_user
redis-server &
RAILS_ENV=development bundle exec rails server
RAILS_ENV=development bundle exec ./script/resque
cd ~vagrant
