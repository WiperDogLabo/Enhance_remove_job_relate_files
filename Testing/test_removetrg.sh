#!/bin/bash
if [ ! $# -eq 1 ];then
   echo "Incorrect parameter !"
   echo "Usage: ./test_removetrg.sh /wiperdog_home_path"
   exit
else
	wiperdog_home=$1
	#check if wiperdog directory exists
	if [ ! -d "$wiperdog_home" ];then
		echo "Wiperdog directory does not exists : $wiperdog_home"
		exit
	fi
	rm -rf $wiperdog_home/var/job/* > /dev/null

	#Start wiperdog
	wiperdog_status=$(lsof -wni tcp:13111)
	if [ "$wiperdog_status" == "" ];then
		echo "** Starting wiperdog ..."
		#Check if wiperdog not running ,start it
		/bin/sh $wiperdog_home/bin/startWiperdog.sh > /dev/null 2>&1 &
		sleep 60
		echo "** Wiperdog running ..."
	fi
fi
currentDir="$(cd "$(dirname "$0")" && pwd)"

echo "======= TEST REMOVE TRIGGER FILE ======="
echo "------CASE 1 :  "
echo "1. Test object: Test for case remove a trigger file running in wiperdog"
echo "2. Input : Job ,trigger file ( testjob.job ,test.trg (embeed in this test script))"
echo "3. Expect Output : When remove trigger ,all job declare in trigger will be  stop running and no result data output in $currentDir/testRemoveTrigger/result"
echo "*****   Start testcase 1 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob=testRemoveTrigger/result/testjob.txt
rm -rf $resultJob > /dev/null

sleep 1
echo "** Copy job & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob.job <<eof
JOB = [name:"testjob"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveTrigger/result/testjob.txt"]]
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "10i"
eof
echo "** Waiting for job running..."
sleep 40

echo "** Check output of job to file in $resultJob..."
if  [ -f $resultJob ] ;then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove test.trg and waiting for job finish if running..."
rm -rf $wiperdog_home/var/job/test.trg > /dev/null
if [ -f $wiperdog_home/var/job/test.trg ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/test.trg" 
	exit
fi
sleep 30
echo "** Remove previous output from job of testjob in : $resultJob"
rm -rf $resultJob > /dev/null
if [ -f $resultJob ];then
	echo "=> Failed to remove $resultJob"
	exit
fi
echo "** Waiting for 15 second and check again job result ..."
sleep 30

echo "** Check job output existed "
if [ ! -f $resultJob ];then
	echo "=> No job output in $resultJob... PASSED"
else
	echo "=> Job output exists in $resultJob...NOT PASSED "	
	exit
fi
echo "** Copy trigger file back to var/job"
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "10i"
eof
echo "** Waiting for job running..."
sleep 30
echo "** Check output of job to file in $resultJob..."
if  [ -f $resultJob ];then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "------CASE 2 :  "
echo "1. Test object: Test for case have many trigger file running in wiperdog"
echo "2. Input : Job ,trigger file ( testjob1.job ,testjob2.job ,test.trg ,test2.trg(embeed in this test script))"
echo "3. Expect Output : When remove specifice trigger ,all job declare in that trigger will be  stop running and no result data output in $currentDir/testRemoveTrigger/result"
echo "Another job with other trigger still work normally"
echo "*****   Start testcase 2 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob1=testRemoveTrigger/result/testjob1.txt
resultJob2=testRemoveTrigger/result/testjob2.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultJob1 > /dev/null
rm -rf $resultJob2 > /dev/null


sleep 1
echo "** Copy job & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob1.job <<eof
JOB = [name:"testjob1"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveTrigger/result/testjob1.txt"]]
eof
cat > $wiperdog_home/var/job/testjob2.job <<eof
JOB = [name:"testjob2"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveTrigger/result/testjob2.txt"]]
eof
cat > $wiperdog_home/var/job/test1.trg <<eof
job: "testjob1" ,schedule: "10i"
eof
cat > $wiperdog_home/var/job/test2.trg <<eof
job: "testjob2" ,schedule: "10i"
eof
echo "** Waiting for job running..."
sleep 40

echo "** Check output of job to file in $resultJob1..."
if  [ -f $resultJob1 ] ;then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output does not existed : NOT PASSED !"
	exit
fi
echo "** Check output of job to file in $resultJob2..."
if  [ -f $resultJob2 ] ;then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove test1.trg and waiting for job finish if running..."
rm -rf $wiperdog_home/var/job/test1.trg > /dev/null
if [ -f $wiperdog_home/var/job/test1.trg ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/test.trg" 
	exit
fi
sleep 30
echo "** Remove previous output from job of testjob1 & testjob2 in $currentDir/testRemoveTrg/result"
rm -rf $resultJob1 > /dev/null
rm -rf $resultJob2 > /dev/null

if [ -f $resultJob1 ];then
	echo "=> Failed to remove $resultJob"
	exit
fi
echo "** Waiting for 15 second and check again job result ..."
sleep 20

echo "** Check job output of testjob1 "
if [ ! -f $resultJob1 ];then
	echo "=> No job output in $resultJob1... PASSED"
else
	echo "=> Job output exists in $resultJob1...NOT PASSED "	
	exit
fi
echo "** Check job output of testjob2"
if [ -f $resultJob2 ];then
	echo "=> Job output exists in $resultJob2... PASSED"
else
	echo "=> No job output in $resultJob2...NOT PASSED "	
	exit
fi
echo "** Remove test2.trg and waiting for job finish if running..."
rm -rf $wiperdog_home/var/job/test2.trg > /dev/null
if [ -f $wiperdog_home/var/job/test2.trg ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/test2.trg" 
	exit
fi
sleep 20
echo "** Remove previous output from job of testjob2 in $currentDir/testRemoveTrg/result"
rm -rf $resultJob2 > /dev/null

if [ -f $resultJob2 ];then
	echo "=> Failed to remove $resultJob2"
	exit
fi
echo "** Waiting for 15 second and check again job result ..."
sleep 30

echo "** Check job output of testjob "
if [ -f $resultJob1 ];then
	cat $resultJob1
	echo "=> Job output exists in $resultJob1...NOT PASSED "	
	exit
else
	echo "=> No job output in $resultJob1... PASSED"
fi
echo "** Check job output of testjob2 "
if [ -f $resultJob2 ];then
	echo "=> Job output exists in $resultJob2...NOT PASSED "	
	exit	
else
	echo "=> No job output in $resultJob2... PASSED"
fi
