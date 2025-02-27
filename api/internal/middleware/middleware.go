package middleware

import (
	"os"

	"github.com/gin-gonic/gin"
)

func SetupMiddleware(router *gin.Engine, logFile *os.File) {
	setupLogging(logFile)
	router.Use(gin.LoggerWithFormatter(customLogFormatter))
	router.Use(customRecovery(logFile))
	router.Use(ErrorResponseLoggerMiddleware(logFile))
}
