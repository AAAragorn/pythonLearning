# Python 学习项目

## 项目简介

这是一个面向数据分析师的 Python 学习笔记项目（Data Analyst with Python track），主要涵盖了 Python 数据处理、SQL 查询以及数据产品经理知识体系等内容。本项目通过整理学习笔记和实践案例，帮助学习者系统掌握数据分析所需的核心技能。

## 项目结构

```
pythonLearning/
├── README.md                 # 项目英文说明文档
├── README_CN.md             # 项目中文说明文档（本文件）
├── pythonLearningNotebook   # Python 学习笔记
├── sqlLearningNotebool      # SQL 学习笔记
├── knowledge frame          # 数据产品经理知识体系框架
└── 数据埋点方案调研          # 数据埋点相关调研
```

## 学习内容

### 1. Python 数据处理（pythonLearningNotebook）

主要涵盖 pandas 库的数据操作技能：

- **Python 基础语法**
  - 列表推导式（List Comprehension）
  
- **数据透视表（Pivot Table）**
  - 数据透视、聚合与汇总
  - 多重索引处理
  - 时间序列处理

- **数据切片与索引**
  - `.loc[]` 和 `.iloc[]` 的使用
  - 单层/多层索引切片
  - 基于时间的索引切片
  - 布尔条件筛选

- **Pandas 核心函数**
  - 统计函数：`.mean()`、`.value_counts()` 等
  - 数据清洗：`.isna()`、`.fillna()`、`.dropna()`
  - 排序与查询：`.sort_values()`、`.query()`
  - 分组聚合：`.groupby()`、`.agg()`

- **表联结操作**
  - 内联结（Inner Join）
  - 左联结（Left Join）
  - 半联结（Semi Join）
  - 时间序列联结：`pd.merge_ordered()`、`pd.merge_asof()`

- **数据可视化**
  - 直方图（Histogram）
  - 散点图（Scatter Plot）
  - 折线图（Line Plot）
  - 柱状图（Bar Chart）

### 2. SQL 查询（sqlLearningNotebool）

主要包含 LeetCode SQL 题目笔记和常用技巧：

- **SQL 基础查询**
  - `LIMIT` 和 `OFFSET` 的使用
  - `DISTINCT` 去重
  - `ORDER BY` 排序（升序/降序）

- **SQL 函数**
  - `IFNULL()` 空值处理
  - `CONCAT()` 字符串拼接
  - `COUNT()` 计数

- **表联结**
  - `INNER JOIN` 内联结
  - `RIGHT JOIN` 右联结
  - 多表联结

- **高级查询**
  - `GROUP BY` 分组聚合
  - `HAVING` 聚合结果筛选
  - 子查询与嵌套查询
  - 自联结技巧

### 3. 其他内容

- **数据产品经理知识体系**（knowledge frame）
- **数据埋点方案调研**

## 使用方法

### 查看学习笔记

直接打开对应的笔记文件即可：

```bash
# 查看 Python 学习笔记
cat pythonLearningNotebook

# 查看 SQL 学习笔记
cat sqlLearningNotebool
```

### 实践练习

建议结合笔记内容，在本地环境中进行实践：

1. **安装依赖**（如需运行代码示例）：
```bash
pip install pandas matplotlib
```

2. **创建 Jupyter Notebook** 进行交互式学习：
```bash
jupyter notebook
```

3. **参考笔记中的代码片段**，在自己的数据集上进行练习

### 学习建议

1. **循序渐进**：按照笔记顺序，从基础语法到高级应用逐步学习
2. **动手实践**：每个知识点都要亲自编写代码验证
3. **举一反三**：尝试在不同数据集上应用所学技能
4. **总结归纳**：定期回顾笔记，整理知识体系

## 适用人群

- 数据分析初学者
- 希望系统学习 Python 数据处理的学习者
- 准备数据分析相关面试的求职者
- 需要复习 pandas 和 SQL 知识的从业者

## 贡献

欢迎提交 Issue 或 Pull Request 来完善本学习项目！

## 许可证

本项目仅用于个人学习和交流。
