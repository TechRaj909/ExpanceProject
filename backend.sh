#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expance-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enable 20 v nodejs"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "install nodejs"

id expense
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "add user expance"
else 
echo -e "user expance already existed"
fi

    mkdir -p /app &>>$LOG_FILE_NAME
    VALIDATE $? "mkdir app" 


curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "download nodejs"

cd /app
VALIDATE $? "moving to app directory"

unzip /tmp/backend.zip 
VALIDATE $? "unzip app directory"

cp /home/ec2-user/ExpanceProject/backend-servce /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "install mysql client"

mysql -h mysql.daws82s.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "settingup mysql "

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "reaload  backend "

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "enable backend "

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "starting backend"
