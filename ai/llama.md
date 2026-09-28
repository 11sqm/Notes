# llama.cpp
---
## 一、张量基本结构
张量是神经网络中执行数学运算的主要数据结构。**llama.cpp** 使用的是 **ggml**，这是一种纯 C++ 实现的张量库，相当于 Python 生态系统中的 PyTorch 或 TensorFlow。

常见张量有两种：
1. **数据张量**：持有实际数据，包含一个多维数组的数值。
2. **运算张量**：仅表示一个或多个其他张量之间运算的结果，只有在实际计算时才会包含数据。

### 1. 基本结构
在 ggml 中，张量由 `ggml_tensor` 结构体表示。简化后为：
```cpp
// ggml.h
struct ggml_tensor {
    enum ggml_type    type;
    enum ggml_backend backend;

    int     n_dims; //张量的维度数量，例如一维向量、二维矩阵等
    // number of elements
    int64_t ne[GGML_MAX_DIMS];
    // stride in bytes
    size_t  nb[GGML_MAX_DIMS];

    enum ggml_op op; // 表示张量是哪个操作的结果（例如加法、乘法等）

    struct ggml_tensor * src[GGML_MAX_SRC];// 张量的输入源（如果它是计算结果）

    void * data; //指向实际数据的指针，可能是 NULL，如果该张量仅代表一个操作的结果

    char name[GGML_MAX_NAME];
};
```

其中各个字段含义为：
- **type**：包含张量元素的基本类型。例如，`GGML_TYPE_F32` 表示每个元素是一个 32 位浮点数。
- **ggml_backend**：指示张量是基于 CPU 还是基于 GPU 存储的。
- **n_dims**：张量的维度数量，可以是1到4维。
- **ne**：表示每个维度中的元素数量。ggml 采用行优先顺序，意味着 `ne[0]` 表示每行的大小，`ne[1]` 表示每列的大小，依此类推。
- **nb**：包含步长信息，即每个维度中连续元素之间的字节数。在第一个维度中，步长等于元素的大小；在第二个维度中，它等于每行的大小乘以元素的大小，以此类推。

使用步长的目的是为了在进行某些张量操作时无需复制任何数据。例如，在二维张量上执行转置操作，将行转换为列时，只需要交换 ne（维度大小）和 nb（步长），而指向相同的底层数据即可实现这个操作，无需对数据本身进行复制。

```cpp
// ggml.c (the function was slightly simplified).
struct ggml_tensor * ggml_transpose(
        struct ggml_context * ctx,
        struct ggml_tensor  * a) {
    // Initialize `result` to point to the same data as `a`
    struct ggml_tensor * result = ggml_view_tensor(ctx, a);

    result->ne[0] = a->ne[1];
    result->ne[1] = a->ne[0];

    result->nb[0] = a->nb[1];
    result->nb[1] = a->nb[0];

    result->op   = GGML_OP_TRANSPOSE;
    result->src[0] = a;

    return result;
}
```
在上述函数中，`result` 是一个新张量，它被初始化为指向与源张量 `a` 相同的多维数值数组。通过交换 `ne`（维度大小）和 `nb`（步长），可以执行转置操作，而无需复制任何数据。

上述函数中，`ggml_view_tensor`函数创建了一个新的张量 `result`，指向原始张量 `a` 相同数据。这意味着`result`和`a`共享相同的内存空间，但它们的维度和步长可以不同。将 `result->op` 设置为 `GGML_OP_TRANSPOSE` 之后，`ggml` 系统知道这个张量是通过转置另一个张量得到的，而不是一个直接包含数据的张量。这个标记在后续的计算中很重要，因为 `ggml` 在需要计算时会按照这个操作类型来执行相应的计算逻辑。

### 2. 张量操作与视图
回到 `ggml_tensor` 结构体：
- **op**：可以是张量之间支持的任何操作。如果设置为 `GGML_OP_NONE`，则表示张量包含数据。其他值表示不同的操作。例如，`GGML_OP_MUL_MAT` 表示该张量不包含数据，而是表示两个其他张量之间矩阵乘法的结果。
- **src**：一个指向要进行运算的张量的指针数组。例如，如果 `op == GGML_OP_MUL_MAT`，那么 `src` 将包含指向两个要相乘的张量的指针。如果 `op == GGML_OP_NONE`，则 `src` 为空。
- **data**：指向实际张量数据的指针，如果该张量表示一个操作，则为 `NULL`。它也可能指向另一个张量的数据，在这种情况下，它被称为视图。例如，在上面的 `ggml_transpose()` 函数中，结果张量就是原始张量的视图，只是维度和步长被交换了。`data` 指向相同的内存位置。

矩阵乘法函数很好地展示了这些概念：通过指向相同的数据并修改维度和步长，张量可以通过视图避免数据复制。
```cpp
// ggml.c (simplified and commented)
struct ggml_tensor * ggml_mul_mat(
        struct ggml_context * ctx,
        struct ggml_tensor  * a,
        struct ggml_tensor  * b) {
    // Check that the tensors' dimensions permit matrix multiplication.
    GGML_ASSERT(ggml_can_mul_mat(a, b));

    // Set the new tensor's dimensions
    // according to matrix multiplication rules.
    const int64_t ne[4] = { a->ne[1], b->ne[1], b->ne[2], b->ne[3] };
    // Allocate a new ggml_tensor.
    // No data is actually allocated except the wrapper struct.
    struct ggml_tensor * result = ggml_new_tensor(ctx, GGML_TYPE_F32, MAX(a->n_dims, b->n_dims), ne);

    // Set the operation and sources.
    result->op   = GGML_OP_MUL_MAT;
    result->src[0] = a;
    result->src[1] = b;

    return result;
}
```
