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
	n, err := strconv.Atoi(nValue)
	if err != nil {
		c.IndentedJSON(http.StatusNotAcceptable, gin.H{
			"message": fmt.Sprintf("could not convert n to int (n is %v, err is %s)", nValue, err.Error()),
		})
		return
	}
	f, err := fibonacci(n)
	if err != nil {
		c.IndentedJSON(http.StatusNotAcceptable, gin.H{
			"message": err.Error(),
		})
		return
	}
	msg := fmt.Sprintf("The %v-th Fibonacci number is %v.", n, f)
	c.IndentedJSON(http.StatusOK, gin.H{
		"message": msg,
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
