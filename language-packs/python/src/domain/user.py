"""User 도메인 모델 및 비즈니스 규칙"""
from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime

# RFC 5322 간소화 버전 — 서버 측 정밀 검증과 병행 사용 전제
_EMAIL_REGEX = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


class ValidationError(ValueError):
    pass


@dataclass(frozen=True)
class UserId:
    value: str

    def __post_init__(self) -> None:
        if not self.value or not self.value.strip():
            raise ValueError("UserId는 비어 있을 수 없습니다")


@dataclass(frozen=True)
class User:
    id: UserId
    name: str
    email: str
    created_at: datetime


def validate_email(email: str) -> None:
    if not _EMAIL_REGEX.match(email):
        raise ValidationError(f"유효하지 않은 이메일 형식: {email}")


def validate_name(name: str) -> None:
    stripped = name.strip()
    if not stripped:
        raise ValidationError("이름은 빈 값일 수 없습니다")
    if len(stripped) > 100:
        raise ValidationError("이름은 100자를 초과할 수 없습니다")


def create_user(user_id: UserId, name: str, email: str) -> User:
    validate_email(email)
    validate_name(name)
    return User(
        id=user_id,
        name=name.strip(),
        email=email.lower().strip(),
        created_at=datetime.now(),
    )
