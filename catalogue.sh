#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
MONGODB_HOST="mongodb.saws86s.fun"

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y  &>>LOG_FILE
VALIDATE $? "disabling nodejs version is"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs version is" &>>LOG_FILE

dnf install nodejs -y  &>>LOG_FILE
VALIDATE $? "installing nodejs is"  

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating nonhuman user"

mkdir /app 
VALIDATE $? "creating directory" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading the code"

cd /app 
VALIDATE $? "changing to app directory"

unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "downloading code in app directory"

cd /app
VALIDATE $? "checking in app directory"

npm install &>>LOG_FILE
VALIDATE $? "installing the packages"  

cp catalogue.service /etc/systemd/system/catalogue.service &>>LOG_FILE
VALIDATE $? "copying systemctl service"

systemctl daemon-reload
VALIDATE $? "reloading"

systemctl enable catalogue  &>>LOG_FILE
VALIDATE $? "enableing"

systemctl start catalogue

cp mongo.repo  /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y  &>>LOG_FILE
VALIDATE $? "installing mongodb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>LOG_FILE
VALIDATE $? "load catalogue products"

systemctl restart catalogue