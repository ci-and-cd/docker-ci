#!/usr/bin/env bash

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -L https://get.rvm.io | bash -s stable --auto-dotfiles
echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> ~/.bashrc
source /usr/local/rvm/scripts/rvm
rvm install ruby-2.4.1
rvm use ruby-2.4.1
