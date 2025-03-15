# Dockerfile
FROM golang:alpine AS builder

WORKDIR /app

# Copy go.mod and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the Go app
RUN go build -o api ./cmd

# Run the app in a minimal container
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/api .


# Command to run the app
CMD ["./api"]
