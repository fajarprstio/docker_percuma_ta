#!/bin/bash


/percuma_ta/ python percuma.py &
/percuma_ta/kibana/bin/kibana &
/percuma_ta/elasticsearch/bin/elasticsearch &
/percuma_ta/logstash/bin/logstash -f /percuma_ta/logstash/logstash.conf 
