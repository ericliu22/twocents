package main

import (
	"context"
	"fmt"
	"os"

	"api/internal/core/db"
	"api/internal/middleware"
	"api/internal/routes"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
)

func main() {
	router := gin.Default()

	conn, err := pgx.Connect(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close(context.Background())

	queries := database.New(conn)

	var logFile *os.File
	defer logFile.Close()

	middleware.SetupMiddleware(router, logFile)
	routes.SetupCoreRouter(router, queries)

	router.Run()

}
