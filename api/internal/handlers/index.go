package handlers

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

func IndexHandler(ctx *gin.Context) {
	ctx.String(http.StatusOK, "Coming Soon")
}
