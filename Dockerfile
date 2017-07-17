# This Dockerfile was generated from templates/Dockerfile.j2
{% set tarball = 'logstash-%s.tar.gz' % elastic_version -%}
{% if staging_build_num -%}
{%   set url_root = 'https://staging.elastic.co/%s/downloads/logstash' % version_tag -%}
{%   set pack_url = 'https://staging.elastic.co/%s/downloads/logstash-plugins' % version_tag -%}
{% else -%}
{%   set url_root = 'https://artifacts.elastic.co/downloads/logstash' -%}
{%   set pack_url = 'https://artifacts.elastic.co/downloads/logstash-plugins' -%}
{% endif -%}


FROM centos:7
LABEL maintainer "Elastic Docker Team <docker@elastic.co>"

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y java-1.8.0-openjdk-devel which && \
    yum clean all

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir /usr/share/logstash --no-create-home \
      logstash

# Add Logstash itself.
RUN curl -Lo - {{ url_root }}/{{ tarball }} | \
    tar zxf - -C /usr/share && \
    mv /usr/share/logstash-{{ elastic_version }} /usr/share/logstash && \
    chown --recursive logstash:logstash /usr/share/logstash/ && \
    ln -s /usr/share/logstash /opt/logstash

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.
ADD config/logstash.yml config/log4j2.properties /usr/share/logstash/config/
ADD pipeline/default.conf /usr/share/logstash/pipeline/logstash.conf
RUN chown --recursive logstash:logstash /usr/share/logstash/config/ /usr/share/logstash/pipeline/

# Ensure Logstash gets a UTF-8 locale by default.
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'

# Place the startup wrapper script.
ADD bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER logstash

RUN cd /usr/share/logstash && LOGSTASH_PACK_URL={{ pack_url }} logstash-plugin install x-pack

ADD env2yaml/env2yaml /usr/local/bin/

EXPOSE 9600 5044

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
