import httpx
from fastapi import HTTPException
import os

WECHAT_APPID = os.getenv("WECHAT_APPID")
WECHAT_SECRET = os.getenv("WECHAT_SECRET")

async def get_user_openid(code: str) -> dict:
    """
    使用 code 换取 openid 和 session_key。
    """
    if not WECHAT_APPID or not WECHAT_SECRET:
        raise HTTPException(status_code=500, detail="WeChat AppID or Secret is not configured.")

    url = f"https://api.weixin.qq.com/sns/jscode2session?appid={WECHAT_APPID}&secret={WECHAT_SECRET}&js_code={code}&grant_type=authorization_code"

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            response.raise_for_status()  # 如果请求失败则抛出异常
            data = response.json()
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503, detail=f"Error while requesting from WeChat API: {exc}")

    if "errcode" in data and data["errcode"] != 0:
        raise HTTPException(status_code=422, detail=f"WeChat API Error: {data['errmsg']}")

    return data