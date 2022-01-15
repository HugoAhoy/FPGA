import torch
inp = torch.arange(18,118).reshape(1,1,10,10)

conv1 = torch.nn.Conv2d(1,1,(3,3),bias=False)
conv2 = torch.nn.Conv2d(1,1,(3,3),bias=False)

conv1.weight = torch.nn.Parameter(torch.arange(0,9).reshape(1,1,3,3),requires_grad=False)
conv2.weight = torch.nn.Parameter(torch.arange(9,18).reshape(1,1,3,3),requires_grad=False)

pool = torch.nn.MaxPool2d(2)

# 开始计算
conv1_res = conv1(inp)
pool1_res = pool(conv1_res.float()).long()
conv2_res = conv2(pool1_res)
pool2_res = pool(conv2_res.float()).long()

# 打印结果
print("input is:",inp%(2**16))
print("conv1 result is:",conv1_res%(2**16))
print("pool1 result is:",pool1_res%(2**16))
print("conv2 result is:",conv2_res%(2**16))
print("pool2 result is:",pool2_res%(2**16))