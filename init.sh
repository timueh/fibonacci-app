#!/bin/bash
echo "current dir is"
pwd
aws s3 cp s3://tf-fibonacci-app-2809/fibonacci_app /usr/bin/fibonacci_app
chmod +x /usr/bin/fibonacci_app
echo "starting up gin"
GIN_MODE=release PORT=8000 fibonacci_app