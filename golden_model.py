import random




def exp_lut(x):
    if x == 0:
        return 16
    elif x == -1:
        return 6
    elif x == -2:
        return 2
    elif x == -3:
        return 1
    else:
        return 0
Q = [random.randint(-8, 8) for _ in range(4)]

K = []
V = []

for i in range(8):
    k = [random.randint(-8, 8) for _ in range(4)]
    v = [random.randint(-8, 8) for _ in range(4)]

    K.append(k)
    V.append(v)


print()
print("========== VERILOG INPUT ==========")
print()

print("// Q")
for i in range(4):
    print("send_q(%d);" % Q[i])

print()

print("// K / V")
for i in range(8):
    print("send_kv(%d, %d);" % (K[i][0], V[i][0]))
    print("send_kv(%d, %d);" % (K[i][1], V[i][1]))
    print("send_kv(%d, %d);" % (K[i][2], V[i][2]))
    print("send_kv(%d, %d);" % (K[i][3], V[i][3]))

print()


score = []

for i in range(8):
    s = 0

    for j in range(4):
        s = s + Q[j] * K[i][j]

    score.append(s)



x_max = max(score)



weight = []

for i in range(8):
    x = score[i] - x_max
    w = exp_lut(x)
    weight.append(w)



L = 0

for i in range(8):
    L = L + weight[i]


acc = [0, 0, 0, 0]

for i in range(8):
    for j in range(4):
        acc[j] = acc[j] + weight[i] * V[i][j]


out = []

for i in range(4):
    if acc[i] > 0:
        result = int((acc[i] + L // 2) / L)
    else:
        result = int((acc[i] - L // 2) / L)

    out.append(result)



print("Score =", score)
print("x_max =", x_max)
print("Weight =", weight)
print("L =", L)
print("ACC =", acc)
print("OUT =", out)

print()
print("===================================")