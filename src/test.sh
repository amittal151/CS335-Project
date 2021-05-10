rm a.out
./run.sh $1
./a.out > apna.txt
gcc -w $1 && ./a.out > gcc_ka.txt
diff apna.txt gcc_ka.txt
var=$(echo $?)
RED='\033[1;31m'
GREEN='\033[1;32m'
END='\033[0m'
if [ $var == 0 ]
then
	printf "${GREEN}AC\n"
else 
	printf "${RED}FAIL\n"
	diff apna.txt gcc_ka.txt
fi
printf "${END}"