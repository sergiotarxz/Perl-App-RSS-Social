FROM docker.io/debian:trixie
WORKDIR /usr/local/app

RUN apt update
RUN apt dist-upgrade -y
RUN apt install -y perlbrew
RUN useradd -m rss_social -d /var/lib/rss_social
RUN su rss_social -l -c 'perlbrew init'
RUN su rss_social -l -c 'echo "source ~/perl5/perlbrew/etc/bashrc" >> .bashrc.old'
RUN su rss_social -l -c 'cat .bashrc > .bashrc.old'
RUN su rss_social -l -c 'cat .bashrc.old >> .bashrc'
RUN su rss_social -l -c 'rm .bashrc.old'
RUN su rss_social -l -c 'echo "source ~/perl5/perlbrew/etc/bashrc" >> .bash_profile.old'
RUN su rss_social -l -c 'cat .bash_profile.old >> .bash_profile'
RUN su rss_social -l -c 'rm .bash_profile.old'
RUN apt install -y build-essential perl
RUN su rss_social -l -c 'perlbrew install 5.42.0 -j$(nproc) --notest'
COPY ./deps /var/lib/rss_social/deps
RUN apt install -y postgresql-server-dev-all
RUN su rss_social -l -c 'yes | perlbrew exec cpan -T DBD::Pg'
RUN su rss_social -l -c 'yes | perlbrew exec cpan -T $(cat deps)'


RUN apt install -y iproute2
USER "rss_social"
CMD ["bash", "-l", "-c", "cd ~/Perl-App-RSS-Social; bash init_pokefirered.sh; perlbrew exec perl scripts/server.pl"]
