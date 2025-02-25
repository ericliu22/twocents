package handlers

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func IndexHandler(ctx *gin.Context) {
	ctx.String(http.StatusOK, "Coming Soon")
}
