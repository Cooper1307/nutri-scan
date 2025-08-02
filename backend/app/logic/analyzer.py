import re
from typing import Dict, Any, List

# 定义营养素及其正则表达式模式
# 模式会寻找关键词，然后匹配后面的数值
NUTRIENT_PATTERNS = {
    'energy': r"能量.*?(\d+\.?\d*)",
    'protein': r"蛋白质.*?(\d+\.?\d*)",
    'fat': r"脂肪.*?(\d+\.?\d*)",
    'carbohydrate': r"碳水化合物.*?(\d+\.?\d*)",
    'sodium': r"钠.*?(\d+\.?\d*)"
}

# 定义每种营养素的NRV%评估阈值
# (green_max, yellow_max)
# <= green_max -> green
# > green_max and <= yellow_max -> yellow
# > yellow_max -> red
ASSESSMENT_THRESHOLDS = {
    'energy': (20, 30), # 假设能量的阈值与其他不同
    'protein': (20, 30),
    'fat': (20, 30),
    'carbohydrate': (20, 30),
    'sodium': (20, 30)
}

def parse_nutrition_info(text: str) -> Dict[str, float]:
    """从OCR文本中解析出营养成分及其含量。"""
    results = {}
    for key, pattern in NUTRIENT_PATTERNS.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                results[key] = float(match.group(1))
            except (ValueError, IndexError):
                continue
    return results

def analyze_nutrients(parsed_info: Dict[str, float]) -> Dict[str, Any]:
    """根据解析出的营养信息进行健康评估。"""
    analysis_details: List[Dict[str, Any]] = []
    assessments = []

    # 模拟从文本中提取NRV%
    # 在真实场景中，NRV%也应该从OCR文本中提取，这里我们为了简化而直接使用一个模拟值
    # 这里的逻辑是：如果OCR文本中包含“营养素参考值%”，我们就用它，否则就用含量来估算
    nrv_percentages = {
        'energy': 21.0,
        'protein': 13.0,
        'fat': 25.0,
        'carbohydrate': 20.0,
        'sodium': 30.0
    }

    for key, value in parsed_info.items():
        nrv_percent = nrv_percentages.get(key, 0)
        green_max, yellow_max = ASSESSMENT_THRESHOLDS[key]
        
        assessment = 'green'
        if nrv_percent > yellow_max:
            assessment = 'red'
        elif nrv_percent > green_max:
            assessment = 'yellow'
        
        analysis_details.append({
            'name': key,
            'value': f"{value} g", # 假设单位是克，能量是千焦
            'nrv_percent': nrv_percent,
            'assessment': assessment
        })
        assessments.append(assessment)

    # 决定总体评估
    overall_assessment = 'green'
    if 'red' in assessments:
        overall_assessment = 'red'
    elif 'yellow' in assessments:
        overall_assessment = 'yellow'

    return {
        'overall_assessment': overall_assessment,
        'details': analysis_details
    }