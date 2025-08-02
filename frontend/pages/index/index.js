// index.js
const app = getApp()

Page({
  data: {
    // 此页面数据将用于跳转到结果页，本身不直接展示
  },
  data: {
    // 此页面数据将用于跳转到结果页，本身不直接展示
  },

    // “拍照分析”或“从相册选择”按钮点击事件
  chooseImage(e) {
    const sourceType = e.currentTarget.dataset.source;
    this.handleChooseImage(sourceType);
  }, 

  // 统一的图片选择处理函数
  handleChooseImage(sourceType) {
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sourceType: [sourceType], // 'camera' 或 'album'
      sizeType: ['compressed'],
      success: (res) => {
        const tempFilePath = res.tempFiles[0].tempFilePath;
        this.uploadFile(tempFilePath);
      },
      fail: (err) => {
        if (err.errMsg.indexOf('cancel') === -1) {
          wx.showToast({
            title: '选择图片失败',
            icon: 'none'
          });
        }
      }
    });
  },

  

  // 上传文件到后端
  uploadFile(filePath) {
    wx.showLoading({
      title: '智能分析中...',
      mask: true
    });

    wx.uploadFile({
      url: `${app.globalData.API_URL}/api/analyze`,
      filePath: filePath,
      name: 'file',
      formData: {
        user_id: app.globalData.userId
      },
      success: (res) => {
        wx.hideLoading();
        // 检查HTTP状态码
        if (res.statusCode === 200) {
          try {
            const analysisResult = JSON.parse(res.data);
            // 将分析结果存储到全局变量或通过URL参数传递给结果页
            getApp().globalData.analysisResult = analysisResult;
            wx.navigateTo({
              url: '/pages/result/result'
            });
          } catch (e) {
            wx.showToast({
              title: '服务器返回数据格式错误',
              icon: 'none'
            });
          }
        } else {
          // 处理非200的HTTP状态
          wx.showToast({
            title: `服务器错误: ${res.statusCode}`,
            icon: 'none'
          });
        }
      },
      fail: (err) => {
        wx.hideLoading();
        wx.showToast({
          title: '请求失败，请检查网络',
          icon: 'none'
        });
        console.error('Upload failed:', err);
      }
    });
  }
});