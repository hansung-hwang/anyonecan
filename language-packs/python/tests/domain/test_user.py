"""User domain unit tests"""
from __future__ import annotations

from datetime import datetime

import pytest

from domain.user import (
    User,
    UserId,
    ValidationError,
    create_user,
    validate_email,
    validate_name,
)


def test_validate_email_valid() -> None:
    """A valid email format does not raise"""
    validate_email("user@example.com")


def test_validate_email_no_at() -> None:
    """Missing @ sign raises ValidationError"""
    with pytest.raises(ValidationError):
        validate_email("invalid")


def test_validate_name_empty() -> None:
    """An empty string raises ValidationError"""
    with pytest.raises(ValidationError):
        validate_name("")


def test_validate_name_whitespace() -> None:
    """A whitespace-only name raises ValidationError"""
    with pytest.raises(ValidationError):
        validate_name("   ")


def test_validate_name_over_100() -> None:
    """A name longer than 100 characters raises ValidationError"""
    with pytest.raises(ValidationError):
        validate_name("a" * 101)


def test_create_user_valid() -> None:
    """Creates a User object from valid input"""
    user = create_user(UserId("user-1"), " John Doe ", "USER@EXAMPLE.COM")

    assert user.id == UserId("user-1")
    assert user.name == "John Doe"
    assert user.email == "user@example.com"
    assert isinstance(user.created_at, datetime)


def test_create_user_invalid_email() -> None:
    """Creating with an invalid email raises ValidationError"""
    with pytest.raises(ValidationError):
        create_user(UserId("user-1"), "John Doe", "not-an-email")
