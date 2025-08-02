// pages/result/result.js
Page({
  data: {
    result: null,
    assessmentText: '',
    suggestionText: ''
  },

  onLoad(options) {
    const result = getApp().globalData.analysisResult;
    if (result) {
      this.setData({
        result: result,
        assessmentText: this.getAssessmentText(result.overall_assessment),
        suggestionText: this.getSuggestionText(result.overall_assessment)
      });
    } else {
      // 处理直接进入此页面的异常情况
      wx.showToast({
        title: '没有分析数据',
        icon: 'none',
        duration: 2000,
        complete: () => {
          setTimeout(() => {
            wx.navigateBack();
          }, 2000);
        }
      });
    }
  },

  getAssessmentText(assessment) {
    const map = {
      green: '推荐食用',
      yellow: '注意适量',
      red: '建议少吃'
    };
    return map[assessment] || '分析结果';
  },

  getSuggestionText(assessment) {
    const map = {
      green: '这款食品的营养成分均衡，是不错的选择。',
      yellow: '部分营养成分偏高，偶尔享用没问题，但不建议经常吃哦。',
      red: '含有较高的脂肪、钠或糖，为了您的健康，请尽量少吃。'
    };
    return map[assessment] || '请结合自身情况，健康饮食。';
  },

  goBack() {
    wx.navigateBack();
  }
});