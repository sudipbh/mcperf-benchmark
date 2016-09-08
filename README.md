# mcperf-benchmark
##Result of mcperf benchmark for XAP 10 and Amazon Elastic Cache

The following link shows the results from mcperf (https://github.com/twitter/twemperf) for comparing the memcached API performance of XAP and Amazon ElastiCache.

https://docs.google.com/spreadsheets/d/13lFNPVaIHyRyhNYdANfuL3sGBHto1iXHCIG9O87y7_c/pubhtml
 
The charts are in tabs 1-connection, 2-connections, 4-connections and 8-connections.

The payload size for each call was 5K. For each connection, 100000 calls were made. Parallel connections were handled by using the GNU parallel utility (https://www.gnu.org/software/parallel/).

The XAP instance was run with the JVM heap size set to 6 GB. An Amazon _m3.large_ instance was used for hosting the XAP installation.

The AWS Elastic Cache had the configuration _cache.m3.large_ which corresponds to a 6.05 GB size.

The following operations were tested for **throughput** for the Memcached API provided by XAP and AWS ElastiCache:

- set
- get
- cas
- add
- replace
- append
- prepend
- incr
- decr

The test scripts were run on an Amazon AWS m4.2xlarge instance which has 8 vCPUs. This enables true parallel execution with GNU parallel when testing for 1, 2, 4 and 8 connections.

## Test Script

The script (**mcperftest.sh**) used for testing is as follows:

        runmcperf() {
              job_no=$1
              echo "mcperf --server=$SERVER --num-conns=1 --num-calls=$NUM_CALLS --method=$METHOD --sizes=d$PAYLOAD_SIZE 2>$SERVER-c$NUM_CONNS-$METHOD-$job_no.txt"
              mcperf --server=$SERVER --num-conns=1 --num-calls=$NUM_CALLS --method=$METHOD --sizes=d$PAYLOAD_SIZE 2>$SERVER-c$NUM_CONNS-$METHOD-$job_no.txt
        }
        
        export -f runmcperf
         
        SERVER=$1
        NUM_CALLS=$2
        PAYLOAD_SIZE=$3
        NUM_CONNS=$4
        METHOD=$5
         
        x=1
        JOB_ARG=""
        while [ $x -le $NUM_CONNS ]
        do
              JOB_ARG="$JOB_ARG $x"
              x=$(( $x + 1 ))
        done
        export SERVER NUM_CONNS NUM_CALLS PAYLOAD_SIZE METHOD JOB_ARG
         
        echo parallel -j$NUM_CONNS runmcperf ::: $JOB_ARG
        parallel -j$NUM_CONNS runmcperf ::: $JOB_ARG
         
        grep -H "Request rate" $SERVER-c$NUM_CONNS-$METHOD*.txt
         
        awk -v method=$METHOD '
              $0 ~ /^.*Request rate.*$/ {
                    numConn++;
                    total += $3;
              }
              END {
                    printf "%s operation: total throughput for %d connections = %d requests/second\n", method, numConn, total;
              }
        ' $SERVER-c$NUM_CONNS-$METHOD*.txt
        
An example usage was as follows:

        mcperftest.sh 10.8.1.215 100000 5120 1 set


