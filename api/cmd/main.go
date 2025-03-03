package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"api/internal/core/db"
	"api/internal/middleware"
	"api/internal/routes"

	"firebase.google.com/go/v4"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"google.golang.org/api/option"
)

func main() {
	router := gin.Default()
	router.MaxMultipartMemory = 500 << 20 // 500 MB
	conn, err := pgx.Connect(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close(context.Background())

	queries := database.New(conn)

	serviceAccountKeyPath := "/root/twocents-82a02-firebase-adminsdk-fbsvc-e7391780d6.json"

	// Create the App with an options object containing the credentials.
	ctx := context.Background()
	opt := option.WithCredentialsFile(serviceAccountKeyPath)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("error initializing Firebase app: %v", err)
	}

	// Initialize the Auth client
	authClient, err := app.Auth(ctx)
	if err != nil {
		log.Fatalf("error initializing Auth client: %v", err)
	}


	var logFile *os.File
	defer logFile.Close()

	middleware.SetupMiddleware(router, logFile)

	routes.SetupCoreRouter(router, queries, authClient)
	router.SetTrustedProxies([]string{"192.168.100.0/24"})
	router.Run()
}
