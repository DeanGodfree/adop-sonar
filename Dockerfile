FROM sonarqube:6.7
MAINTAINER Dean Godfree, <dean.j.godfree>

# Adding section to support sonar-kotlin plugin
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		maven \
		curl
#end of sonar-kotlin plugin support


#Install Filebeat
RUN curl -o /tmp/filebeat_6.2.2_amd64.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.2.2-amd64.deb && \
    dpkg -i /tmp/filebeat_6.2.2_amd64.deb && apt-get install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 #Copying new filebeat config in post install
 COPY resources/filebeat.yml /etc/filebeat/filebeat.yml
 #copying example log file for testing filebeat/grafana **should be removed folowing integration testing
 COPY resources/sdk_data.json /var/log/sdk_data.json



ENV SONARQUBE_PLUGINS_DIR=/opt/sonarqube/default/extensions/plugins \
    SONARQUBE_SERVER_BASE="http://localhost:9000" \
    SONARQUBE_WEB_CONTEXT="/sonar" \
    SONARQUBE_FORCE_AUTHENTICATION=true \
    ADOP_LDAP_ENABLED=true \
    SONARQUBE_JMX_ENABLED=false

COPY resources/plugins.txt ${SONARQUBE_PLUGINS_DIR}/
COPY resources/sonar.sh resources/plugins.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN /usr/local/bin/plugins.sh ${SONARQUBE_PLUGINS_DIR}/plugins.txt

# Section to support sonar-kotlin (https://github.com/arturbosch/sonar-kotlin)
RUN git clone https://github.com/arturbosch/sonar-kotlin \
&& cd sonar-kotlin \
&& mvn package \
&& cp target/sonar-kotlin-0.4.1.jar $SONARQUBE_PLUGINS_DIR
#end of sonar-kotlin section

VOLUME ["/opt/sonarqube/logs/"]

ENTRYPOINT ["/usr/local/bin/sonar.sh"]
