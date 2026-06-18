"""User 도메인 단위 테스트"""
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
    """유효한 이메일 형식이면 예외를 던지지 않는다"""
    validate_email("user@example.com")


def test_validate_email_no_at() -> None:
    """@ 기호가 없으면 ValidationError를 던진다"""
    with pytest.raises(ValidationError):
        validate_email("invalid")


def test_validate_name_empty() -> None:
    """빈 문자열이면 ValidationError를 던진다"""
    with pytest.raises(ValidationError):
        validate_name("")


def test_validate_name_whitespace() -> None:
    """공백만 있는 이름이면 ValidationError를 던진다"""
    with pytest.raises(ValidationError):
        validate_name("   ")


def test_validate_name_over_100() -> None:
    """100자 초과 이름이면 ValidationError를 던진다"""
    with pytest.raises(ValidationError):
        validate_name("가" * 101)


def test_create_user_valid() -> None:
    """유효한 입력으로 User 객체를 생성한다"""
    user = create_user(UserId("user-1"), " 홍길동 ", "USER@EXAMPLE.COM")

    assert user.id == UserId("user-1")
    assert user.name == "홍길동"
    assert user.email == "user@example.com"
    assert isinstance(user.created_at, datetime)


def test_create_user_invalid_email() -> None:
    """잘못된 이메일로 생성하면 ValidationError를 던진다"""
    with pytest.raises(ValidationError):
        create_user(UserId("user-1"), "홍길동", "not-an-email")
