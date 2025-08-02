// pages/index/index.js
Page({
  data: {
    result: null, // 用于存储后端返回的分析结果
    error: null,  // 用于存储错误信息
    loading: false, // 用于显示加载提示
  },

  // 核心功能：选择图片并上传分析
  chooseAndAnalyzeImage() {
    const that = this;
    // 重置状态
    this.setData({ result: null, error: null, loading: false });

    wx.chooseMedia({
      count: 1, // 最多只能选一张图
      mediaType: ['image'], // 只能选择图片
      sourceType: ['album', 'camera'], // 可以从相册选，也可以用相机拍
      success(res) {
        const tempFilePath = res.tempFiles[0].tempFilePath;
        that.uploadAndAnalyze(tempFilePath);
      },
      fail(err) {
        // 用户取消选择图片等情况
        console.log("用户取消选择", err);
      }
    })
  },

  // 上传图片到后端服务器进行分析
  uploadAndAnalyze(filePath) {
    const that = this;
    that.setData({ loading: true }); // 开始上传，显示加载提示

    wx.uploadFile({
      // TODO: 请将此URL替换为您的生产环境后端地址
      url: 'http://127.0.0.1:8000/analyze', // 本地测试时指向Python后端
      filePath: filePath,
      name: 'file', // 和后端FastAPI的File(...)参数名一致
      success(res) {
        try {
          // res.data 是后端返回的JSON字符串，需要解析
          if (res.statusCode === 200) {
            const data = JSON.parse(res.data);
            console.log("分析结果:", data);

            // 计算一个总体的评级用于摘要的背景色
            const summary_rating = data.nutrients.some(n => n.rating === 'high') ? 'high' : 'medium';

            that.setData({
              result: { ...data, summary_rating },
              error: null
            });
          } else {
            // 处理非200的HTTP状态码
            throw new Error(`服务器错误, 状态码: ${res.statusCode}`);
          }
        } catch (e) {
          console.error("解析后端数据失败", e);
          that.setData({ error: '分析结果解析失败，请稍后重试' });
        }
      },
      fail(err) {
        console.error("上传分析失败", err);
        that.setData({ error: '分析服务连接失败，请检查网络或稍后重试' });
      },
      complete() {
        that.setData({ loading: false }); // 无论成功失败，都隐藏加载提示
      }
    })
  }
})