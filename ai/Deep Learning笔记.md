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
### 1. 梯度下降
$$\theta^* = \arg\min_{\theta} \underbrace{\sum_{i=1}^{N} \mathcal{L}(f_\theta(\mathbf{x}^{(i)}), \mathbf{y}^{(i)})}_{J(\theta)}$$

单次梯度下降迭代为：
$$\theta^{k+1}\leftarrow\theta^k-\eta\nabla_\theta J(\theta^k)$$

$\eta$ 为学习率，决定沿着梯度方向前进的步长。

### 2. 随机梯度下降 (Stochastic Gradient Descent)
SGD 中，对数据集的某个子集计算梯度，可以合理近似替代对整个数据集计算梯度。将这一子集称为批次 (batch)。

- 如果批次大小为1，则意味着每看到数据集中一个样本，则更新一次参数。
- 如果批次大小为 N，与完整数据集大小相同，则变为梯度下降。

与所有示例的平均值相比，即标准梯度下降，SGD 梯度方向存在噪声。

SGD 同时具有如下优势：
- 速度更快：即使使用小样本，也能很好地逼近总体梯度。
- 隐式正则化：随机噪声实际上起到了一种隐式正则化作用，帮助模型跳出局部最小值，更有可能找到接近全局最优解的路径。

SGD 同样也会导致方差较大，且参数更新不稳定。

### 3. 动量 (Momentum)
通过引入动量，让梯度更新倾向于延续之前更新的方向：
$$\theta^{t+1}\leftarrow\theta^t-\eta\nabla f(\theta^k)-\alpha m^t$$

$\alpha$ 为动量强度，是超参数。

### 4. 进化策略
进化策略具有类似梯度的特性，能够在参数空间中寻找局部损失最小化的方向。

进化策略在现有参数值周围进行微小扰动采样，然后沿能够降低损失值的扰动方向移动。
$$\begin{aligned}
\epsilon_i &\sim \mathcal{N}(\mathbf{0}, \mathbf{I}) \\
s_i &= J(\theta + \sigma\epsilon_i)
\end{aligned}
\qquad
\theta^{k+1} \leftarrow \theta^k - \eta \frac{1}{\sigma M} \sum_{i=1}^M s_i\epsilon_i$$

### 5. 梯度裁剪
梯度裁剪主要应对损失函数中可能出现的“尖峰”或“陡峭”区域。

如果梯度值超过某个设定的较大阈值，则只需将其按比例约回该阈值范围内。
$$\begin{aligned}
&\mathbf{v} = \nabla_\theta J(\theta^k) \\
&\theta^{k+1} \leftarrow \theta^k - \eta [\operatorname{clip}(v_1, -m, m), \dots, \operatorname{clip}(v_M, -m, m)]^\top
\end{aligned}$$

### 6. 前向传播与反向传播
#### (1) 计算图
计算图是一个由不同函数变换（节点）构成的图，并且当这些节点串联起来时，便能执行某些有用的计算。

深度学习主要处理的是有向无环图 (DAGs)，且每一个节点都是可微的。

深度学习中并非所有 DAGs 均为链式，存在非链式 DAGs。

![非链式DAGs](pictures/非链式DAGs.png)

其中关于非链式 DAGs 一个典型示例即参数共享。

#### (2) 前向传播
![前向传播](pictures/前向传播.png)

多层前向传播可以表示一个多层感知机 (MLP)。
![MLP](pictures/MLP.png)

#### (3) 反向传播
依据链式法则，可以将参数偏导数分解为：
$$\frac{\partial J}{\partial \theta_i} = \frac{\partial J}{\partial \mathbf{x}_L} \frac{\partial \mathbf{x}_L}{\partial \mathbf{x}_{L-1}} \cdots \frac{\partial \mathbf{x}_{i+1}}{\partial \mathbf{x}_i}  \frac{\partial \mathbf{x}_i}{\partial \theta_i}$$

由于$\frac{\partial \mathbf{x}_i}{\partial\theta_i}$项前的系数可以共享，所以只需要计算其值一次即可。

![反向传播](pictures/反向传播.png)

反向传播需要跟踪两类偏导数数组：
- **L**：层输出相对于层输入的梯度，为一个矩阵。

$$\begin{aligned}
\mathbf{L} &\triangleq \frac{\partial \mathbf{x}_{\text{out}}}{\partial [\mathbf{x}_{\text{in}}, \theta]} \\
\mathbf{L}^{\mathbf{x}} &\triangleq \frac{\partial \mathbf{x}_{\text{out}}}{\partial \mathbf{x}_{\text{in}}} \\
\mathbf{L}^{\theta} &\triangleq \frac{\partial \mathbf{x}_{\text{out}}}{\partial \theta}
\end{aligned}
$$

- **g**：损失函数关于激活值的梯度，为行向量。

$$\begin{aligned}
\mathbf{g} &\triangleq \frac{\partial J}{\partial \mathbf{x}} \\
\mathbf{g}_{\text{out}} &\triangleq \frac{\partial J}{\partial \mathbf{x}_{\text{out}}} \\
\mathbf{g}_{\text{in}} &\triangleq \frac{\partial J}{\partial \mathbf{x}_{\text{in}}}
\end{aligned}
$$

在已知 **L** 与 **g** 情况下，容易完成对于单层参数的更新：
$$\frac{\partial J}{\partial\theta}=\frac{\partial J}{\partial\mathbf{x}_{out}}\frac{\partial\mathbf{x}_{out}}{\partial\theta}=\mathbf{g}_{out}\mathbf{L}^{\theta}$$

$$\theta^{i+1}\leftarrow\theta^i-\eta\left(\frac{\partial J}{\partial\theta}\right)^{\text{T}}$$

其中，对于 $\mathbf{L}$ 与 $\mathbf{g}$，其计算方式如下：
$$\mathbf{L}=f'(\mathbf{x}_{in},\theta)$$

$$\mathbf{g}_{in}=\mathbf{g}_{out}\mathbf{L}^{\mathbf{x}}$$

![反向传播偏导](pictures/反向传播偏导.png)

#### (4) 完整算法流程
完整算法流程为，先进行前向传播，再进行反向传播，更新参数，并重复这一过程。
![完整算法流程](pictures/完整算法流程.png)

#### (5) MLP 反向传播
线性层中，$\mathbf{x}_{out}=\mathbf{W}\mathbf{x}_{in}$，因此有：
$$\mathbf{g}_{in}=\mathbf{g}_{out}\frac{\partial\mathbf{x}_{out}}{\partial\mathbf{x}_{in}}=\mathbf{g}_{out}\cdot\mathbf{W}$$

利用反向传播更新权重方式如下：
$$\frac{\partial J}{\partial\mathbf{W}}=\mathbf{g}_{out}\cdot\frac{\partial \mathbf{x}_{out}}{\partial\mathbf{W}}$$

通过观察参数 $\mathbf{W}_{ij}$，注意到其发生改变时，仅有输出的第 i 个分量发生变化。因此可以通过以下分解逐步分析过程：
$$\frac{\partial J}{\partial\mathbf{W}_{ij}}=\frac{\partial J}{\partial\mathbf{x}_{out_i}}\cdot\frac{\partial \mathbf{x}_{out_i}}{\partial\mathbf{W}_{ij}}=\frac{\partial J}{\partial\mathbf{x}_{out_i}}\cdot\mathbf{x}_{in_j}$$

基于以上推导，$\frac{\partial J}{\partial\mathbf{W}}$ 可以进一步写为：
$$\frac{\partial J}{\partial\mathbf{W}}=\mathbf{x}_{in}\cdot\mathbf{g}_{out}$$

因此，实际更新权重公式为：
$$\mathbf{W}^{k+1}\leftarrow\mathbf{W}^k+\eta\left(\frac{\partial J}{\partial \mathbf{W}}\right)^T$$

![MLP反向传播](pictures/MLP反向传播.png)

反向传播过程中，由于不希望梯度在此经过 ReLU 激活，因此并不会像前向传播那样直接应用函数。取而代之的是，将其转换为一个门控矩阵，并由前向传播中激活函数的输出结果进行参数化。通过这一操作，从而能够确保在前向传播中处于 ReLU 函数零点区域的权重分量，其梯度不会被传递下去。

## 三、近似理论
近似问题定义为：给定一个曲线族 $G$ 以及一个神经网络族 $F$，对于 $\forall g \in G$，是否 $\exist f \in F$，使得能够以较小的误差拟合该函数，即 $error(f,g)<\varepsilon$。

以下是一些常见 error 函数：
$$error_{\infin}(f,g)=\max_x|f(x)-g(x)|$$

$$error_1(f,g)=\int|f(x)-g(x)|dx$$

以下将讨论 **Lipschitz 连续函数**能否被神经网络有效逼近。

### 1. Lipschitz 连续函数
设函数 $g:\mathbb{R}\to\mathbb{R}$，若存在常数 $L\geq 0$，使得

$$\forall x \in \mathbb{R}, \Delta x \in \mathbb{R}, g : \mathbb{R} \to \mathbb{R}\ 满足\ |g(x + \Delta x) - g(x)| \leq L |\Delta x|$$

则称 $g$ 为 **$L$-Lipschitz 连续函数**，其中 $L$ 为 Lipschitz 常数。

Lipschitz 连续函数可以进一步推广到多维，具体定义如下：

函数 $g:\mathbb{R}^d\to\mathbb{R}$，存在常数 $L\geq 0$，使得

$$\forall x \in \mathbb{R}^d, \Delta x \in \mathbb{R}^d, g : \mathbb{R}^d \to \mathbb{R}\ 满足\ |g(x + \Delta x) - g(x)| \leq L ||\Delta x||$$

此时由于 $\Delta x$ 为向量，应当选择其范数作为度量。一种常见的范数为均方根范数，其定义如下：

$$||x||_{RMS}=\sqrt{\frac{1}{d}\sum_{i=1}^d x_i^2}=\frac{1}{\sqrt{d}}||x||_2$$

### 2. 通用函数逼近
以下定理与证明可以看作通用函数逼近定理的一个定量化、构造性的特殊结果，但其结论与论证过程依旧具有启发性。

令 $g:[0,1]^d\to \mathbb{R}$为任意 $L$-Lipschitz 连续函数，则对于 $\forall \varepsilon>0$，$\exist$  3-layer ReLU 网络，其神经元数量为 $N=4d(\frac{L}{\varepsilon})^d$，使得
$$\int|f(x)-g(x)|dx<2\varepsilon$$

该定理证明如下：
#### (1) Approximation with rectangles
首先，通过矩形条带近似，得到一维输入结果。

定义 $f(x)=\sum_i\alpha_i\mathbb{I}_i$ 为函数 $g(x)$ 的逼近函数。

假设矩形左边缘恰好与函数曲线相切，由 $L$-Lipschitz 连续函数定义，有 
$$|f(x)-g(x)|=|g(x + \Delta x) - g(x)| \leq L |\Delta x|$$

由于共 N 个条带，因此条带宽度为 $\frac{1}{N}$。

![一维逼近误差](一维逼近误差.png)

上方三角面积为 $\frac{1}{2}\frac{L}{N^2}$，因此对于总误差有：
$$\int|f(x)-g(x)|dx\leq N\cdot \frac{1}{2}\frac{L}{N^2}=\frac{L}{2N}$$

因此 $\varepsilon=\frac{L}{2N}$，从而得到 $N\geq\frac{L}{2\varepsilon}$。

#### (2) Higher input dimension
假设有 N 个超矩形，则每条边欧几里得长度为 $\frac{1}{N^{\frac{1}{d}}}$。

![高维逼近误差](高维逼近误差.png)

因此对于总误差，有：
$$\int|f(x)-g(x)|dx\leq N\cdot \frac{L}{N^{\frac{1}{d}}}\cdot\frac{1}{N}=\frac{L}{N^{\frac{1}{d}}}$$

因此 $N\geq(\frac{L}{\varepsilon})^d$。

#### (3) ReLU networks can fit rectangles
定义函数 $f_c(x)$ 为：
$$f_c(x) = \begin{bmatrix} +1 \\ -1 \\ -1 \\ +1 \end{bmatrix}^T \mathrm{ReLU} \begin{bmatrix} cx \\ cx - 1 \\ c(x-1) - 2 \\ c(x-1) - 3 \end{bmatrix}$$

令 $c\to\infty$，则函数变为一维矩形函数：
![函数图像](pictures/f_c(x)函数图像.png)

对于 $d$ 维输入 $\mathbf{x}=(x_1,x_2,\ldots,x_d)^T$，可以将 $d$ 个一维矩形函数相加：
$$
S(\mathbf{x})=\sum_{i=1}^{d}f_\infty(x_i)
$$

由于每个 $f_\infty(x_i)\in\{0,1\}$，因此：
$$
S(\mathbf{x})=
\begin{cases}
d, & \text{所有一维矩形函数均被激活}\\
\leq d-1, & \text{至少一个一维矩形函数未被激活}
\end{cases}
$$

因此，只需在 $d-1$ 处进行阈值处理，即可构造 $d$ 维超矩形函数：
$$
h_\infty(\mathbf{x})=
\operatorname{ReLU}\left(
\sum_{i=1}^{d}f_\infty(x_i)-(d-1)
\right)
$$

结合 $f_c(x)$，可进一步写成：
$$
h_c(\mathbf{x})=
\operatorname{ReLU}\left(
\sum_{i=1}^{d}f_c(x_i)-(d-1)
\right)
$$

当 $c\to\infty$ 时：
$$
h_\infty(\mathbf{x})=
\lim_{c\to\infty}h_c(\mathbf{x})
$$

从而实现由一维矩形函数到 $d$ 维超矩形函数的构造。

因此，逼近函数为
$$f(x)=\sum_i\alpha_ih_c(x-u_i)$$

令 $c\to\infty$，则能够逼近任意$L$-Lipschitz 连续函数曲面。

同时，由于 $f_c(x)$ 中使用四个神经元，且在超矩形中在 $d$ 维进行求和，因此每个超矩形需要 $4d$ 神经元。因此神经元总数为 $N=4d(\frac{L}{\varepsilon})^d$

### 3. 深度与广度
通用函数逼近定理表明，应当让网络的宽度增长，从而逼近任意函数。然而，**深度分离理论**的核心观点在于，存在一种深层网络，能够高效表示特定函数。

ReLU 神经网络是分段线性的 (PWL)。对于 PWL 函数，如果 $f$ 与 $g$ 都是 PWL，则其复合函数也必然是 PWL。同样的，其线性组合 $\alpha f+\beta g$ 也必然是 PWL。

当对于函数进行加法运算时，其转折点数量最多为各函数转折点数量之和。对函数应用 ReLU 后，转折点数量最多只会翻倍。

假设有一个包含多个隐藏层的深度 ReLU 网络，考虑第 $l$ 层：
$$f_l(\mathbf{x})=\operatorname{ReLU}(\mathbf{W}_lf_{l-1}(\mathbf{x})+\mathbf{b}_l)$$

令 $\operatorname{KINKS}_L$ 表示 $f_l(\mathbf{x})$ 输出 n 个坐标中转折点的最大数量，则有如下结论：
$$\operatorname{KINKS}_L\leq2n\operatorname{KINKS}_{L-1}$$

由于 $\operatorname{KINKS}_0\leq1$，因此$\operatorname{KINKS}_L\leq(2n)^L$

由于 n 表示宽度，L 表示深度，因此上界最多随宽度呈现多项式增长，而随深度呈指数级增长。

然而，scaling law 表明，在一定的模型规模和合理的网络架构范围内，神经网络的性能主要取决于模型参数量、训练数据量和计算量，而对网络深度与宽度的具体分配相对不敏感。
![scaling law](<scaling law.png>)