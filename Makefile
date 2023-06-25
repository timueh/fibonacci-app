build:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o fibonacci_app .

test:
	go test . -v --failfast