FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN go build -o server .

FROM alpine:3.19

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
CMD ["./server"]
