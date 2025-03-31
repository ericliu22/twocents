package notifications

import (
	"crypto/tls"
	"log"
	"os"
	"sync"

	"github.com/sideshow/apns2/certificate"
)

var (
	cert     tls.Certificate
	initOnce sync.Once
)

// InitCertificate loads the certificate only once.
// It should be called during application startup.
func InitCertificate(certFile string) error {
	var err error
	initOnce.Do(func() {
		password := os.Getenv("APS_CERT_PASSWORD")
		cert, err = certificate.FromP12File("/root/aps_cert.p12", password)
		if err != nil {
			log.Printf("Failed to load certificate: %v", err)
		}
	})
	return err
}

// GetAPSCertificate returns the loaded certificate.
// Since it's read-only after initialization, it's safe to share.
func GetAPSCertificate() tls.Certificate {
	return cert
}
