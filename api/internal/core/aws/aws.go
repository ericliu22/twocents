package aws

import (
	"context"
	"mime/multipart"
	"os"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func ObjectUpload(filename string, file *multipart.File, contentType string) (*string, error) {

	cfg, configErr := config.LoadDefaultConfig(context.TODO())
	// 4. Create AWS session
	if configErr != nil {
		return nil, configErr
	}

	// 5. Create S3 service client
	s3Client := s3.NewFromConfig(cfg)

	// 6. Upload the file to S3
	//@TODO: Set a timer for context timeout
	_, putErr := s3Client.PutObject(context.Background(), &s3.PutObjectInput {
		Bucket:      aws.String(os.Getenv("BUCKET_NAME")),
		Key:         aws.String(filename),
		Body:        *file,
		ContentType: aws.String(contentType),
	})
	if putErr != nil {
		return nil, putErr
	}

	// 7. Generate CloudFront URL
	cloudFrontURL := fmt.Sprintf("%s/%s", os.Getenv("CLOUDFRONT_DOMAIN"), filename)

	return &cloudFrontURL, nil
}

func ObjectGet(filename string) (*s3.GetObjectOutput, error) {

	cfg, configErr := config.LoadDefaultConfig(context.TODO())
	// 4. Create AWS session
	if configErr != nil {
		return nil, configErr
	}

	// 5. Create S3 service client
	s3Client := s3.NewFromConfig(cfg)

	// 6. Upload the file to S3
	//@TODO: Set a timer for context timeout
	out, getErr := s3Client.GetObject(context.Background(), &s3.GetObjectInput {
		Bucket:      aws.String(os.Getenv("BUCKET_NAME")),
		Key:         aws.String(filename),
	})
	if getErr != nil {
		return nil, getErr
	}

	// 7. Generate CloudFront URL
	//cloudFrontURL := fmt.Sprintf("%s/%s", os.Getenv("CLOUDFRONT_DOMAIN"), filename)

	return out, nil
}
