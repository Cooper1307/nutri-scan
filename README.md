# 小程序 OCR 应用

本项目是一个包含微信小程序前端和 Python 后端服务的 OCR（光学字符识别）应用。

## 项目结构

```
.
├── backend         # 后端服务
│   ├── app         # FastAPI 应用代码
│   ├── main.py     # 应用入口
│   └── requirements.txt # Python 依赖
├── frontend        # 微信小程序前端
└── ...
```

## 功能

- 用户可以通过微信小程序上传图片。
- 后端服务接收图片，调用阿里云 OCR 服务识别图片中的文字。
- 将识别结果返回给小程序前端显示。

## 技术栈

- **后端**: Python, FastAPI
- **前端**: 微信小程序
- **云服务**: 阿里云 OCR

## 如何运行

### 1. 后端服务

- 进入 `backend` 目录: `cd backend`
- 安装依赖: `pip install -r requirements.txt`
- 设置阿里云访问密钥（Access Key）环境变量:
  - **Windows (CMD)**:
    ```bash
    set ALIYUN_ACCESS_KEY_ID=your_access_key_id
    set ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
    set WECHAT_APPID=your_wechat_appid
    set WECHAT_SECRET=your_wechat_secret
    set DATABASE_URL=postgresql://user:password@host:port/dbname
    ```
  - **Windows (PowerShell)**:
    ```powershell
    $env:ALIYUN_ACCESS_KEY_ID="your_access_key_id"
    $env:ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"
    $env:WECHAT_APPID="your_wechat_appid"
    $env:WECHAT_SECRET="your_wechat_secret"
    $env:DATABASE_URL="postgresql://user:password@host:port/dbname"
    ```
  - **Linux / macOS**:
    ```bash
    export ALIYUN_ACCESS_KEY_ID=your_access_key_id
    export ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
    export WECHAT_APPID=your_wechat_appid
    export WECHAT_SECRET=your_wechat_secret
    export DATABASE_URL=postgresql://user:password@host:port/dbname
    ```
- 启动服务: `python main.py`

### 2. 前端小程序

- 使用微信开发者工具导入 `frontend` 目录。
- 修改小程序代码中的后端服务地址为实际部署的地址。