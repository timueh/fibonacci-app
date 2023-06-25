package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
)

func fibonacciHandler(c *gin.Context) {
	nValue := c.Param("n")
	n, err := strconv.ParseUint(nValue, 10, 64)
	if err != nil {
		c.IndentedJSON(http.StatusConflict, gin.H{
			"message": fmt.Sprintf("seems like the value %q you provided for n is invalid; only non-negative numbers are allowed. Error is %s", nValue, err.Error()),
		})
		return
	}

	f := fibonacci(n)

	c.IndentedJSON(http.StatusOK, gin.H{
		"message": fmt.Sprintf("Fibonacci number #%v is %v.", n, f),
	})
}

func main() {
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
		f, err := os.Create("/var/log/gin.log")
		if err != nil {
			panic(err)
		}
		gin.DisableConsoleColor()
		gin.DefaultWriter = io.MultiWriter(f, os.Stdout)
	}

	router := gin.Default()
	router.GET("/fibonacci/:n", fibonacciHandler)

	port, ok := os.LookupEnv("PORT")
	if !ok {
		port = "8000"
	}
	address := fmt.Sprintf("0.0.0.0:%s", port)
	router.Run(address)
}
