from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

router = APIRouter(prefix="/api/users", tags=["users"])

# 실제 운영 환경에서는 DB를 사용하겠으나, 현재는 메모리/파일 구조를 가정합니다.
# 시연을 위해 간단한 메모리 저장소를 사용합니다.
user_db = {}

class UserProfile(BaseModel):
    user_id: str
    nickname: str

@router.get("/{user_id}")
def get_profile(user_id: str):
    if user_id not in user_db:
        # 처음 접속 시 기본값 반환
        return {"user_id": user_id, "nickname": "친구"}
    return user_db[user_id]

@router.post("/profile")
def update_profile(profile: UserProfile):
    user_db[profile.user_id] = profile.dict()
    return {"status": "success", "profile": user_db[profile.user_id]}
