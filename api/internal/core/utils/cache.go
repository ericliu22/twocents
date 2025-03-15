package utils

import (
	"crypto/sha256"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

// AttachCacheHeaders computes a SHA256-based ETag from the response data,
// checks the request's If-None-Match header, and attaches Cache-Control and ETag headers.
// If the client's cache is still valid, it writes a 304 status and returns true.
// Otherwise, it returns false so that the handler can continue to write the full response.
func AttachCacheHeaders(ctx *gin.Context, responseData []byte, maxAge int) bool {
	// Compute the SHA256 hash and generate the ETag
	hash := sha256.Sum256(responseData)
	etag := fmt.Sprintf(`"%x"`, hash)

	// Check the If-None-Match header from the request
	if ifNoneMatch := ctx.GetHeader("If-None-Match"); ifNoneMatch == etag {
		// The cached version is still valid, so return 304 Not Modified
		ctx.Status(http.StatusNotModified)
		return true
	}

	// Attach cache headers to the response
	ctx.Header("Cache-Control", fmt.Sprintf("public, max-age=%d", maxAge))
	ctx.Header("ETag", etag)
	return false
}
