# Compile this file (CUDA + opencv)

~~~
nvcc -o apt init.cu `pkg-config --cflags --libs opencv4`
~~~
# Execute
~~~
./apt 
~~~
## img
![img](https://github.com/yerson001/CUDA-parallet-programming/blob/main/Lenna.png)

## scala de gris
![img](https://github.com/yerson001/CUDA-parallet-programming/blob/main/greyImage.jpg)

## blur
![img](https://github.com/yerson001/CUDA-parallet-programming/blob/main/blurImage32.jpg)
