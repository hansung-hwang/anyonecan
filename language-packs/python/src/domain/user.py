"""User domain model and business rules"""
from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime

# Simplified RFC 5322 — meant to run alongside precise server-side validation
_EMAIL_REGEX = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


class ValidationError(ValueError):
    pass


@dataclass(frozen=True)
class UserId:
    value: str

    def __post_init__(self) -> None:
        if not self.value or not self.value.strip():
            raise ValueError("UserId must not be empty")


@dataclass(frozen=True)
class User:
    id: UserId
    name: str
    email: str
    created_at: datetime


def validate_email(email: str) -> None:
    if not _EMAIL_REGEX.match(email):
        raise ValidationError(f"Invalid email format: {email}")


def validate_name(name: str) -> None:
    stripped = name.strip()
    if not stripped:
        raise ValidationError("Name must not be empty")
    if len(stripped) > 100:
        raise ValidationError("Name must not exceed 100 characters")


def create_user(user_id: UserId, name: str, email: str) -> User:
    validate_email(email)
    validate_name(name)
    return User(
        id=user_id,
        name=name.strip(),
        email=email.lower().strip(),
        created_at=datetime.now(),
    )
