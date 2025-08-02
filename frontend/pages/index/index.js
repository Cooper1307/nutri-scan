// pages/index/index.js
Page({
  data: {
    // 这里存放页面上需要用到的数据
    result: null, // 用于存储后端返回的分析结果
    error: null,  // 用于存储错误信息
  },

  // 核心功能：选择图片并上传分析
  chooseAndAnalyzeImage() {
    const that = this;
    wx.chooseMedia({
      count: 1, // 最多只能选一张图
      mediaType: ['image'], // 只能选择图片
      sourceType: ['album', 'camera'], // 可以从相册选，也可以用相机拍
      success(res) {
        const tempFilePath = res.tempFiles[0].tempFilePath;
        that.uploadAndAnalyze(tempFilePath);
      },
      fail(err) {
        console.error("选择图片失败", err);
        that.setData({ error: '选择图片失败，请重试' });
      }
    })
  },

  // 上传图片到后端服务器进行分析
  uploadAndAnalyze(filePath) {
    const that = this;
    that.setData({ result: null, error: null }); // 清空上次结果

    wx.uploadFile({
      url: 'http://127.0.0.1:8000/analyze', // 这是我们后端服务的地址
      filePath: filePath,
      name: 'file', // 和后端约定的文件名
      success(res) {
        // res.data 是后端返回的字符串，需要解析成JSON对象
        const data = JSON.parse(res.data);
        console.log("分析结果:", data);
        that.setData({ result: data });
      },
      fail(err) {
        console.error("上传分析失败", err);
        that.setData({ error: '分析失败，请检查网络或稍后重试' });
      }
    })
  }
})