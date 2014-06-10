#!/bin/bash
if [ ! $# -eq 1 ];then
   echo "Incorrect parameter !"
   echo "Usage: ./test_removeinstances.sh /wiperdog_home_path"
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
		echo "starting wiperdog..."
		#Check if wiperdog not running ,start it
		/bin/sh $wiperdog_home/bin/startWiperdog.sh > /dev/null 2>&1 &
		sleep 30
	fi
	echo "wiperdog running..."
fi
currentDir="$(cd "$(dirname "$0")" && pwd)"

echo "======= TEST REMOVE INTANCES FILE ======="
echo "------CASE 1 :  "
echo "1. Test object: Test for case remove a instances running in wiperdog"
echo "2. Input : Job file ,instances file: testjob.job ,testjob.instances (embeed in this test script)"
echo "3. Expect Output : When remove instance ,instance stop running and no result data output in $currentDir/testRemoveInstances/result"
echo "*****   Start testcase 1 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob=testRemoveInstances/result/testjob.txt
resultInstance=testRemoveInstances/result/testjob_instance_1.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultJob > /dev/null
rm -rf $resultInstance > /dev/null

sleep 1
echo "** Copy job ,instance & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob.job <<eof
JOB = [name:"testjob"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveInstances/result/testjob.txt"]]
eof
cat > $wiperdog_home/var/job/testjob.instances <<eof
[instance_1:[schedule:"10i"]]
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "10i"
eof
echo "** Waiting for job & instance running..."
sleep 30

echo "** Check output of instance to file in $resultInstance..."
if  [ -f $resultJob ] && [ -f $resultInstance ] ;then
	echo "=> Job & instance output existed : PASSED !"
else
	echo "=> Job & instance output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove testjob.instances and waiting for instances of testjob  finish if running..."
rm -rf $wiperdog_home/var/job/testjob.instances > /dev/null
if [ -f $wiperdog_home/var/job/testjob.instances ];then
	echo "=> Failed to remove job : $wiperdog_home/var/job/testjob.instances" 
	exit
fi
sleep 30
echo "** Remove previous output from job & instances of testjob in : $resultInstance"
rm -rf $resultInstance > /dev/null
rm -rf $resultJob > /dev/null
if [ -f $resultInstance ];then
	echo "=> Failed to remove $resultInstance"
	exit
fi
if [ -f $resultJob ];then
	echo "=> Failed to remove $resultJob"
	exit
fi

echo "** Touch trigger file to fire job"
touch $wiperdog_home/var/job/test.trg

echo "** Waiting for 20 second and check again job & instance result ..."
sleep 20
if [ ! -f $resultInstance ];then
	echo "=> No instance output in $resultInstance...PASSED "	
else
	echo "=> Instance output exists in $resultInstance...NOT PASSED "
	exit
fi
echo "** Check job output existed "
if [ -f $resultJob ];then
	echo "=> Job output exists in $resultJob... PASSED"
else
	echo "=> No job output in $resultJob...NOT PASSED "	
	exit
fi
echo "** Copy testjob.instances back to var/job "
cat > $wiperdog_home/var/job/testjob.instances <<eof
[instance_1:[schedule:"5i"]]
eof
echo "** Waiting for instances running..."
sleep 20
echo "** Check output of testjob instances to file in $resultInstance..."
if  [ -f $resultInstance ];then
	echo "=> Instance output existed : PASSED !"
else
	echo "=> Instance output not existed : NOT PASSED !"
	exit
fi
sleep 1

echo "------CASE 2 :  "
echo "1. Test object: Test for case remove multi instances running in wiperdog"
echo "2. Input : Job file ,instances file: testjob.job ,testjob2.job,testjob.instances,testjob2.instances (embeed in this test script)"
echo "3. Expect Output : When remove instance ,instance stop running and no result data output in $currentDir/testRemoveInstances/result"
echo "*****   Start testcase 2 .."
echo "** Clean wiperdog var/job and testcase directory before running testcase"
resultJob1=testRemoveInstances/result/testjob.txt
resultJob2=testRemoveInstances/result/testjob2.txt
resultInstance1=testRemoveInstances/result/testjob_instance_1.txt
resultInstance2=testRemoveInstances/result/testjob2_instance_1.txt
rm -rf $wiperdog_home/var/job/* > /dev/null
rm -rf $resultJob1 > /dev/null
rm -rf $resultInstance1 > /dev/null
rm -rf $resultJob2 > /dev/null
rm -rf $resultInstance2 > /dev/null

sleep 1
echo "** Copy job ,instance & trigger to wiperdog/var/job"
cat > $wiperdog_home/var/job/testjob.job <<eof
JOB = [name:"testjob"]
FETCHACTION = {
	return [a:"1",b:"2"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveInstances/result/testjob.txt"]]
eof
cat > $wiperdog_home/var/job/testjob2.job <<eof
JOB = [name:"testjob2"]
FETCHACTION = {
	return [a:"2",b:"1"]
}
DBTYPE = "@MYSQL"
DEST = [[file:"$currentDir/testRemoveInstances/result/testjob2.txt"]]
eof
cat > $wiperdog_home/var/job/testjob.instances <<eof
[instance_1:[schedule:"10i"]]
eof
cat > $wiperdog_home/var/job/testjob2.instances <<eof
[instance_1:[schedule:"10i"]]
eof
cat > $wiperdog_home/var/job/test.trg <<eof
job: "testjob" ,schedule: "10i"
job: "testjob2" ,schedule: "10i"

eof
echo "** Waiting 60s for job & instance running..."
sleep 60

echo "** Check output of instance to file in $resultInstance..."
if  [ -f $resultJob1 ] && [ -f $resultJob2 ]  && [ -f $resultInstance1 ] && [ -f $resultInstance2 ];then
	echo "=> Job & instance output existed : PASSED !"
else
	echo "=> Job & instance output does not existed : NOT PASSED !"
	exit
fi
sleep 1
echo "** Remove testjob.instances  & testjob2.instances and waiting for instances finish if running..."
rm -rf $wiperdog_home/var/job/testjob.instances > /dev/null
rm -rf $wiperdog_home/var/job/testjob2.instances > /dev/null

if [ -f $wiperdog_home/var/job/testjob.instances ];then
	echo "=> Failed to remove instance : $wiperdog_home/var/job/testjob.instances" 
	exit
fi
if [ -f $wiperdog_home/var/job/testjob2.instances ];then
	echo "=> Failed to remove instance : $wiperdog_home/var/job/testjob2.instances" 
	exit
fi

sleep 60
echo "** Remove previous output from job & instances of testjob in $currentDir/testRemoveInstances/result"
rm -rf $resultInstance1 > /dev/null
rm -rf $resultJob1 > /dev/null
rm -rf $resultInstance2 > /dev/null
rm -rf $resultJob2 > /dev/null

if [ -f $resultInstance1 ];then
	echo "=> Failed to remove $resultInstance1"
	exit
fi
if [ -f $resultJob1 ];then
	echo "=> Failed to remove $resultJob1"
	exit
fi
if [ -f $resultInstance2 ];then
	echo "=> Failed to remove $resultInstance2"
	exit
fi
if [ -f $resultJob2 ];then
	echo "=> Failed to remove $resultJob2"
	exit
fi

echo "** Touch trigger file to fire job"
touch $wiperdog_home/var/job/test.trg

echo "** Waiting and check again job & instance result ..."
sleep 30
if [ ! -f $resultInstance1 ] && [ ! -f $resultInstance2 ];then
	echo "=> No instance output in $resultInstance1 & $resultInstance2...PASSED "	
else
	echo "=> Instance output exists ...NOT PASSED "
	exit
fi
echo "** Check job output existed "
if [ -f $resultJob1 ] && [ -f $resultJob2 ];then
	echo "=> Job output exists in $resultJob1 &  $resultJob2... PASSED"
else
	echo "=> No job output ..NOT PASSED "	
	exit
fi
echo "** Copy testjob.instances & testjob2.instances back to var/job "
cat > $wiperdog_home/var/job/testjob.instances <<eof
[instance_1:[schedule:"5i"]]
eof
cat > $wiperdog_home/var/job/testjob2.instances <<eof
[instance_1:[schedule:"5i"]]
eof
echo "** Waiting for instances running..."
sleep 40
echo "** Check output of testjob instances to file in $resultInstance..."
if  [ -f $resultInstance1 ] && [ -f $resultInstance2 ] ;then
	echo "=> Instance output existed : PASSED !"
else
	echo "=> Instance output not existed : NOT PASSED !"
	exit
fi
sleep 1
