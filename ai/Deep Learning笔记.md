# Deep Learning笔记
---
本笔记基于MIT 6.7960 深度学习课程，具体参考[课程网站](https://ocw.mit.edu/courses/6-7960-deep-learning-fall-2024/)。未经允许，不得转载。

## 一、导论
### 1. 深度学习组成
1. **神经网络 (Neural nets)**：一类机器学习架构，通过堆叠线性变换层，并在其间穿插逐点非线性操作实现。
2. **微分编程 (Differential programming)**：一种编程范式，通过参数化程序中的某些部分，并利用基于梯度的优化方法调整这些参数，从而优化程序性能。

### 2. 梯度下降 (Gradient descent)
$$\theta^* = \arg\min_{\theta} \underbrace{\sum_{i=1}^{N} \mathcal{L}(f_\theta(\mathbf{x}^{(i)}), \mathbf{y}^{(i)})}_{J(\theta)}$$

梯度下降的一次迭代本质为如下过程：
$$\theta^{t+1}=\theta^t-\eta_t \left. \frac{\partial J(\theta)}{\partial \theta} \right|_{\theta = \theta^t}$$
其中 $\eta_t$ 称为学习率 (learning rate)。

### 3. 神经网络中的计算
神经网络首先进行线性组合，计算方式如下：
$$z_j=\sum_i w_{ij}x_i+b_j$$
其中，$w_{ij}$ 为权重，而 $b_j$ 为偏置项。

此外，也可以用向量化表示进行书写。
$$z_j = \mathbf{x}^T \mathbf{w}_j + b_j$$
其中，$\mathbf{w}_j$ 为向量化权重，$b_j$ 表示偏置。

模型参数表示如下：
$$\theta = \{\mathbf{W}, \mathbf{b}\}$$

神经网络还需要通过某种非线性函数来映射输出结果，非线性函数可以表示为 $g(z)$，通常是一种**逐点非线性函数**。

以下是一些常见的非线性函数：
1. 双曲正切函数
$$g(z)=\tanh(z)=\frac{e^z-e^{-z}}{e^z+e^{-z}}$$

2. Sigmoid函数
$$g(z)=\frac{1}{1+e^{-z}}$$

3. **修正线性单元 (ReLU)**
$$g(z)=\max(0,z)$$

其优势在于实现效率高，导数为阶跃函数。缺陷在于，如果输入值处于强烈负值区域，神经元进入“死亡”状态，梯度消失。

### 4. 层堆叠
![层堆叠](pictures/层堆叠.png)

理论上，对于两层及以上堆叠，在引入非线性函数情况下，可以表示任意函数。

### 5. Softmax 函数与交叉熵损失函数
Softmax 函数将模型输出的任意实数（得分），转化为符合概率分布的数值（概率）。其函数表示为：
$$\hat{y}_k = \text{Softmax}(z_k) = \frac{e^{z_k}}{\sum_{j=1}^{K} e^{z_j}}$$

交叉熵损失函数用以衡量正式标签分布与模型预测分布之间的差异，其函数表示为：
$$H(\mathbf{y}, \mathbf{\hat{y}}) = -\sum_{k=1}^{K} y_k \log \hat{y}_k$$

## 二、神经网络训练
