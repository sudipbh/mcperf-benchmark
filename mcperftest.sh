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
