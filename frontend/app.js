// app.js
App({
  globalData: {
    userInfo: null,
    analysisResult: null,
    // 后端服务器地址
    API_URL: 'http://192.168.11.101:8000',
    openid: null,
    userId: null,
    // 定义一个回调函数，用于登录成功后通知页面
    userIdReadyCallback: null,
  },
  onLaunch() {
    // 小程序启动时执行，进行静默登录
    wx.login({
      success: res => {
        // 发送 res.code 到后台换取 openId, sessionKey, unionId
        if (res.code) {
          wx.request({
            url: `${this.globalData.API_URL}/api/login`,
            method: 'POST',
            data: {
              code: res.code
            },
            success: (loginRes) => {
              if (loginRes.statusCode === 200 && loginRes.data.openid) {
                // 登录成功，静默处理
                this.globalData.openid = loginRes.data.openid;
                this.globalData.userId = loginRes.data.user_id;
                // 如果有页面设置了回调函数，则执行
                if (this.globalData.userIdReadyCallback) {
                  this.globalData.userIdReadyCallback(loginRes.data.user_id);
                }
              } else {
                console.error('登录失败', loginRes.data.detail || '无法获取openid');
              }
            },
            fail: (err) => {
              console.error('请求登录接口失败', err);
            }
          })
        } else {
          console.error('wx.login 失败！' + res.errMsg)
        }
      }
    });
  }
})