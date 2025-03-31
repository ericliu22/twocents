package notifications

import (
	"crypto/tls"
	"log"
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
		cert, err = certificate.FromPemFile("/root/aps_cert.pem", "")
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
