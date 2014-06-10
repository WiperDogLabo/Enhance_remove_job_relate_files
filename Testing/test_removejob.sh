#!/bin/bash
if [ ! $# -eq 1 ];then
   echo "Incorrect parameter !"
   echo "Usage: ./test_removejob.sh /wiperdog_home_path"
   exit
else
	wiperdog_home=$1
	#check if wiperdog directory exists
	if [ ! -d "$wiperdog_home" ];then
		echo "Wiperdog directory does not exists : $wiperdog_home"
		exit
	fi
	#Start wiperdog
	wiperdog_status=$(lsof -wni tcp:13111)
	if [ "$wiperdog_status" == "" ];then
		#Check if wiperdog not running ,start it
		/bin/sh $wiperdog_home/bin/startWiperdog.sh > /dev/null 2>&1 &
		sleep 10
	fi
fi
currentDir="$(cd "$(dirname "$0")" && pwd)"

echo "======= TEST REMOVE JOB FILE ======="
echo "------CASE 1 :  "
echo "1. Test object: Test for case remove a job running in wiperdog"
echo "2. Input : Job file : A.job  (embeed in this test script)"
echo "3. Expect Output : When remove job ,job stop running and no result data output in $currentDir/testRemoveJob/result"
echo "*****   Start testcase 1 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
result=testRemoveJob/result/A.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $result > /dev/null
sleep 1
echo "** Copy job test & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/A.job <<eof
JOB = [name:"A"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/A.txt"]]
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "A" ,schedule: "5i"
eof
echo "** Waiting for job running..."
sleep 20

echo "** Check job A output to file in $result..."
if  [ -f $result ];then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove job A and waiting for job A finish if running..."
rm -rf $wiperdog_home/var/job/A.job > /dev/null
if [ -f $wiperdog_home/var/job/A.job ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/A.job" 
	exit
fi
sleep 20
echo "** Remove previous output from job A in : $result"
rm -rf $result > /dev/null
if [ -f $result ];then
	echo "=> Failed to remove $result"
	exit
fi
echo "** Waiting for 10 second and check again job result in folder $result..."
sleep 10
if [ ! -f $result ];then
	echo "=> No job output in $result...PASSED "	
else
	echo "=> Job output exists in $result...NOT PASSED "
	exit
fi
echo "** Copy job back to var/job "
cat > $wiperdog_home/var/job/A.job <<eof
JOB = [name:"A"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/A.txt"]]
eof
echo "** Touch trigger file to fire job"
touch $wiperdog_home/var/job/test.trg
echo "** Waiting for job running..."
sleep 20
echo "** Check job A output to file in $result..."
if  [ -f $result ];then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi
sleep 1

echo "------CASE 2 :  "
echo "1. Test object: Test for case remove job if multiple job running in wiperdog"
echo "2. Input : Job file  A.job , B.job (embeed in this test script)"
echo "3. Expect Output : When remove job ,job stop running and no result data output in $currentDir/testRemoveJob/result"
echo "*****   Start testcase 2 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultA=testRemoveJob/result/A.txt
resultB=testRemoveJob/result/B.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultA > /dev/null
rm -rf $resultB > /dev/null
sleep 3
echo "** Copy job test & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/A.job <<eof
JOB = [name:"A"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/A.txt"]]
eof
cat > $wiperdog_home/var/job/B.job <<eof
JOB = [name:"B"]
FETCHACTION = {
	return [a:"2",b:"1"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/B.txt"]]
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "A" ,schedule: "5i"
job: "B",schedule: "5i"
eof
echo "** Waiting for job running..."
sleep 30
echo "** Check job A & B output to file in $result..."
if  [ -f $resultA ] && [ -f $resultB ];then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove job A and waiting for job A finish if running..."
rm -rf $wiperdog_home/var/job/A.job > /dev/null
if [ -f $wiperdog_home/var/job/A.job ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/A.job" 
	exit
fi
sleep 20
echo "** Remove previous output from job A in : $resultA"
rm -rf $resultA > /dev/null
if [ -f $resultA ];then
	echo "=> Failed to remove $resultA"
	exit
fi

echo "** Waiting for 10 second and check again job result in $resultA..."
sleep 20
echo "** Check output of job A .."
if [ ! -f $resultA ];then
	echo "=> No job output in $resultA...PASSED "	
else
	echo "=> Job output exists in $resultA...NOT PASSED "
	exit
fi

echo "** Check output of job B .."
if  [ -f $resultB ];then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi

echo "** Remove job B and waiting for job B finish if running..."
rm -rf $wiperdog_home/var/job/B.job > /dev/null
if [ -f $wiperdog_home/var/job/B.job ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/B.job" 
	exit
fi

sleep 20
echo "** Remove previous output from job B in : $resultB"
rm -rf $resultB > /dev/null
if [ -f $resultB ];then
	echo "=> Failed to remove $resultB"
	exit
fi

echo "** Waiting for 10 second and check again job result in : $resultB..."
sleep 20
echo "** Check output of job B .."
if [ ! -f $resultB ];then
	echo "=> No job output in $resultB...PASSED "	
else
	echo "=> Job output exists in $resultB...NOT PASSED "
	exit
fi

echo "** Copy job A & B back to wiperdog/var/job"
cat > $wiperdog_home/var/job/A.job <<eof
JOB = [name:"A"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/A.txt"]]
eof
cat > $wiperdog_home/var/job/B.job <<eof
JOB = [name:"B"]
FETCHACTION = {
	return [a:"2",b:"1"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJob/result/B.txt"]]
eof
echo "** Touch trigger file to fire job"
touch $wiperdog_home/var/job/test.trg

echo "** Waiting for job running..."
sleep 30
echo "** Check job A & B output to file in $result..."
if  [ -f $resultA ] && [ -f $resultB ];then
	echo "=> Job output existed : PASSED !"
else
	echo 
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi