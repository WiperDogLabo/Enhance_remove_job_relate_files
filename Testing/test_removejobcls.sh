#!/bin/bash
if [ ! $# -eq 1 ];then
   echo "Incorrect parameter !"
   echo "Usage: ./test_removejobcls.sh /wiperdog_home_path"
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
		sleep 60
	fi
fi
currentDir="$(cd "$(dirname "$0")" && pwd)"

echo "======= TEST REMOVE JOB CLASS FILE ======="
echo "------CASE 1 :  "
echo "1. Test object: Test for case remove a jobclass file running in wiperdog"
echo "2. Input : Job ,jobclass file ( testjob.job ,testclass.cls (embeed in this test script))"
echo "3. Expect Output : When remove jobclass ,all job of this class will be  stop running and no result data output in $currentDir/testRemoveJobcls/result"
echo "*****   Start testcase 1 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob=testRemoveJobcls/result/testjob.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultJob > /dev/null

sleep 1
echo "** Copy job ,jobclass & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob.job <<eof
JOB = [name:"testjob" , jobclass: "test_class"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJobcls/result/testjob.txt"]]
eof
cat > $wiperdog_home/var/job/testclass.cls <<eof
name:"test_class" , concurrency : 10
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "5"
eof
echo "** Waiting for job running..."
sleep 30

echo "** Check output of job to file in $resultJob..."
if  [ -f $resultJob ] ;then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove testclass.cls "
rm -rf $wiperdog_home/var/job/testclass.cls > /dev/null
if [ -f $wiperdog_home/var/job/testclass.cls ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/testclass.cls" 
	exit
fi
echo "** Remove previous output from job of testjob in : $resultJob"
rm -rf $resultJob > /dev/null
if [ -f $resultJob ];then
	echo "=> Failed to remove $resultJob"
	exit
fi

echo "** Waiting for 30 second and check again job result ..."
sleep 30

echo "** Check job output existed "
if [ ! -f $resultJob ];then
	echo "=> No job output in $resultJob...PASSED "	
else	
	echo "=> Job output exists in $resultJob... NOT PASSED "
	exit
fi

echo "** Copy testclass.cls back to var/job "
cat > $wiperdog_home/var/job/testclass.cls <<eof
name:"test_class" , concurrency : 10
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
echo "1. Test object: Test for case have multi job class file in wiperdog "
echo "2. Input : Job ,jobclass file ( testjob.job ,testclass.cls (embeed in this test script))"
echo "3. Expect Output : When remove a jobclass ,all job of this class will be  stop running and no result data output in $currentDir/testRemoveJobcls/result"
echo "And another job in other jobclass file still work"

echo "*****   Start testcase 2 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob1=testRemoveJobcls/result/testjob.txt
resultJob2=testRemoveJobcls/result/testjob2.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultJob1 > /dev/null
rm -rf $resultJob2 > /dev/null

sleep 1
echo "** Copy job ,jobclass & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob.job <<eof
JOB = [name:"testjob" , jobclass: "test_class"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJobcls/result/testjob.txt"]]
eof
cat > $wiperdog_home/var/job/testjob2.job <<eof
JOB = [name:"testjob2" , jobclass: "test_class_2"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveJobcls/result/testjob2.txt"]]
eof
cat > $wiperdog_home/var/job/testclass.cls <<eof
name:"test_class" , concurrency : 10
eof
cat > $wiperdog_home/var/job/testclass2.cls <<eof
name:"test_class_2" , concurrency : 10
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "now"
job: "testjob2" ,schedule: "now"
eof
echo "** Waiting for job running..."
sleep 30

echo "** Check output of job to file in $resultJob..."
if  [ -f $resultJob1 ] && [ -f $resultJob2 ]  ;then
	echo "=> Job output existed : PASSED !"
else
	echo "=> Job output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove testclass.cls and waiting for job finish if running..."
rm -rf $wiperdog_home/var/job/testclass.cls > /dev/null
if [ -f $wiperdog_home/var/job/testclass.cls ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/testclass.cls" 
	exit
fi
sleep 30
echo "** Remove previous output from job of testjob & testjob2 in : $currentDir/testRemoveJobcls/result"
rm -rf $resultJob1 > /dev/null
rm -rf $resultJob2 > /dev/null

if [ -f $resultJob1 ];then
	echo "=> Failed to remove $resultJob1"
	exit
fi
if [ -f $resultJob2 ];then
	echo "=> Failed to remove $resultJob2"
	exit
fi
echo "** Touch trigger "
touch $wiperdog_home/var/job/test.trg

echo "** Waiting for 20 second and check again job result ..."
sleep 20

echo "** Check job output of testjob: "
if [ ! -f $resultJob1 ];then
	echo "=> No job output in $resultJob1... PASSED"
else
	echo "=> Job output exists in $resultJob1...NOT PASSED "	
	exit
fi
echo "** Check job output of testjob2: "
if [ -f $resultJob2 ];then
	echo "=> Job output exists in $resultJob2... PASSED"
else
	echo "=> No job output in $resultJob2...NOT PASSED "	
	exit
fi

echo "** Remove testclass2.cls and waiting for job finish if running..."
rm -rf $wiperdog_home/var/job/testclass2.cls > /dev/null
if [ -f $wiperdog_home/var/job/testclass2.cls ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/testclass2.cls" 
	exit
fi
sleep 30
echo "** Remove previous output from job of testjob2 in : $currentDir/testRemoveJobcls/result"
rm -rf $resultJob2 > /dev/null

if [ -f $resultJob2 ];then
	echo "=> Failed to remove $resultJob2"
	exit
fi

echo "** Touch trigger to fire job "
touch $wiperdog_home/var/job/test.trg

echo "** Waiting for 30 second and check again job result ..."
sleep 30

echo "** Check job output of testjob: "
if [ ! -f $resultJob1 ];then
	echo "=> No job output in $resultJob1... PASSED"
else
	echo "=> Job output exists in $resultJob1...NOT PASSED "	
	exit
fi
echo "** Check job output of testjob2: "
if [ ! -f $resultJob2 ];then
	echo "=> No job output in $resultJob2... PASSED"
else
	echo "=> Job output exists in $resultJob2...NOT PASSED "	
	exit
fi

echo "** Copy testclass.cls back to var/job "
cat > $wiperdog_home/var/job/testclass.cls <<eof
name:"test_class" , concurrency : 10
eof
echo "** Waiting for job running..."
sleep 30
echo "** Check job output of testjob: "
if [ -f $resultJob1 ];then
	echo "=> Job output exists in $resultJob1... PASSED"
else
	echo "=> No job output in $resultJob1...NOT PASSED "	
	exit
fi
echo "** Check job output of testjob2: "
if [ ! -f $resultJob2 ];then
	echo "=> No job output in $resultJob2... PASSED"
else
	echo "=> Job output exists in $resultJob2...NOT PASSED "	
	exit
fi
sleep 1