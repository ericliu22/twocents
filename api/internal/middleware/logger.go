package middleware

import (
	"bytes"
	"fmt"
	"os"
	"runtime/debug"
	"time"

	"github.com/gin-gonic/gin"
)

// responseBodyWriter wraps gin.ResponseWriter to capture the response body.
type responseBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

// Write intercepts writes to capture the response body.
func (w *responseBodyWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

func setupLogging(logFile *os.File) {
	// Format file name as "YYYY-MM-DD.log"
	fileName := "logs/" + time.Now().Format("2006-01-02") + ".log"
	var err error
	logFile, err = os.OpenFile(fileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(fmt.Sprintf("Failed to open log file: %v", err))
	}
	// Set Gin's default writer to our file so any default logs go there.
	gin.DefaultWriter = logFile
}

func customLogFormatter(param gin.LogFormatterParams) string {
	timestamp := param.TimeStamp.Format("2006/01/02 15:04:05")
	level := "[LOG]"
	if param.StatusCode >= 400 {
		level = "[ERROR]"
	}
	return fmt.Sprintf("%s %s %s %s %d %s %s\n",
		timestamp,
		level,
		param.Method,
		param.Path,
		param.StatusCode,
		param.Latency,
		param.ClientIP,
	)
}

// ErrorResponseLoggerMiddleware wraps the response writer to capture the body.
// After processing the request, if the status code indicates an error,
// it logs the response body.
func ErrorResponseLoggerMiddleware(logFile *os.File) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Replace the ResponseWriter with our custom one
		w := &responseBodyWriter{body: bytes.NewBufferString(""), ResponseWriter: c.Writer}
		c.Writer = w

		c.Next()

		if c.Writer.Status() >= 400 {
			timestamp := time.Now().Format("2006/01/02 15:04:05")
			errorLog := fmt.Sprintf("%s [ERROR] Response body: %s\n", timestamp, w.body.String())
			logFile.WriteString(errorLog)
		}
	}
}

/*
func LogWarning(message string, args ...interface{}) gin.HandlerFunc {
	timestamp := time.Now().Format("2006/01/02 15:04:05")
	formatted := fmt.Sprintf(message, args...)

	logFile.WriteString(fmt.Sprintf("%s [WARN] %s\n", timestamp, formatted))
}
*/

func customRecovery(logFile *os.File) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		defer func() {
			if rec := recover(); rec != nil {
				timestamp := time.Now().Format("2006/01/02 15:04:05")
				panicMessage := fmt.Sprintf("%s [FATAL] Panic recovered: %v\n%s\n",
					timestamp, rec, debug.Stack())
				// Write the panic log directly to our log file.
				logFile.WriteString(panicMessage)
				ctx.AbortWithStatus(500)
			}
		}()
		ctx.Next()
	}
}
