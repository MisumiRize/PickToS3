package main

import (
	"bytes"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/apex/go-apex"
	apexs3 "github.com/apex/go-apex/s3"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/eknkc/amber"
)

func main() {
	apexs3.HandleFunc(func(event *apexs3.Event, ctx *apex.Context) error {
		record := event.Records[0]
		key := record.S3.Object.Key

		tmpl, err := amber.CompileFile("tmpl.amber", amber.DefaultOptions)

		if err != nil {
			return err
		}

		html := strings.TrimSuffix(key, filepath.Ext(key)) + ".html"

		params := struct {
			BaseURL string
			Key     string
			HTMLKey string
		}{
			os.Getenv("BASE_URL"),
			key,
			html,
		}

		var buf bytes.Buffer
		if err = tmpl.Execute(&buf, params); err != nil {
			return err
		}

		log.Println(buf.String())

		svc := s3.New(session.New(), &aws.Config{Region: aws.String("ap-northeast-1")})

		input := &s3.PutObjectInput{
			Bucket:      aws.String(event.Records[0].S3.Bucket.Name),
			Key:         aws.String(html),
			Body:        bytes.NewReader(buf.Bytes()),
			ACL:         aws.String("public-read"),
			ContentType: aws.String("text/html"),
		}

		_, err = svc.PutObject(input)

		return err
	})
}
