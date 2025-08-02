const app = getApp();

Page({
  data: {
    history: [],
    assessmentTexts: {
      green: '推荐食用',
      yellow: '注意适量',
      red: '建议少吃'
    }
  },

  onShow() {
    this.getHistory();
  },

  getHistory() {
    const userId = app.globalData.userId;
    if (!userId) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }

    wx.request({
      url: `${app.globalData.API_URL}/api/history/${userId}`,
      method: 'GET',
      success: (res) => {
        if (res.statusCode === 200) {
          const formattedHistory = res.data.map(item => ({
            ...item,
            created_at_formatted: new Date(item.created_at).toLocaleString()
          }));
          this.setData({ history: formattedHistory });
        } else {
          wx.showToast({ title: '获取历史记录失败', icon: 'none' });
        }
      },
      fail: () => {
        wx.showToast({ title: '网络请求失败', icon: 'none' });
      }
    });
  },

  viewDetail(e) {
    const result = e.currentTarget.dataset.result;
    app.globalData.analysisResult = result;
    wx.navigateTo({ url: '/pages/result/result' });
  }
});