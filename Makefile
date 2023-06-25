
app ?= fib_app

build:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ${app} .

test:
	go test . -v --failfast

init:
	terraform init

plan: init
	terraform plan -var-file=vals.tfvars -var="app=${app}"

apply: init
	terraform apply -var-file=vals.tfvars -var="app=${app}"