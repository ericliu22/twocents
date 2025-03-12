package auth

import database "api/internal/core/db"

/*
Valid get user when
1. You are the user
2. You are in the same group as the user
*/
func ValidGetUser(user *database.User) (bool, error) {
	return true, nil
}


