FROM golang:1.22-alpine

WORKDIR /app

COPY go.mod .
COPY main.go .

RUN go build -o main .

EXPOSE 8081

CMD ["./main"]
