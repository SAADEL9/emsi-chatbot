"""Optional Supabase JWT checks for /chat and /upload."""

from fastapi import Header, HTTPException
import jwt

from . import config


def current_user_id(authorization: str | None = Header(default=None)) -> str | None:
    """Return the signed-in user id, or None when JWT auth is not configured."""
    secret = config.SUPABASE_JWT_SECRET
    if not secret:
        return None
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Sign in required")
    token = authorization.split(" ", 1)[1].strip()
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired session") from exc
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    return str(user_id)
