#include <iostream>
#include <time.h>
#include <stdio.h>
#include "opencv2/opencv.hpp"
using namespace cv;
using namespace std;


#define BLUR_SIZE 32

__global__ void rgb2grayincuda(uchar3 *const d_in, unsigned char *const d_out,
							   uint imgheight, uint imgwidth)
{
	const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int idy = blockIdx.y * blockDim.y + threadIdx.y;

	if (idx < imgwidth && idy < imgheight)
	{
		uchar3 rgb = d_in[idy * imgwidth + idx];
		d_out[idy * imgwidth + idx] = 0.299f * rgb.x + 0.587f * rgb.y + 0.114f * rgb.z;
	}
}


__global__ void blurKernel(uchar3 *const d_in, uchar3 *const d_out,
						   uint imgheight, uint imgwidth)
{
	const unsigned int Col = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int Row = blockIdx.y * blockDim.y + threadIdx.y;

	if (Col < imgheight && Row < imgwidth)
	{
		int pixValx = 0;
		int pixValy = 0;
		int pixValz = 0;
		int pixels = 0;

	
		for (int blurRow = -BLUR_SIZE; blurRow < BLUR_SIZE + 1; ++blurRow)
		{
			for (int blurCol = -BLUR_SIZE; blurCol < BLUR_SIZE + 1; ++blurCol)
			{
				int curRow = Row + blurRow;
				int curCol = Col + blurCol;


				if (curRow > -1 && curRow < imgheight && curCol > -1 && curCol < imgwidth)
				{
					pixValx += d_in[curRow * imgwidth + curCol].x;
					pixValy += d_in[curRow * imgwidth + curCol].y;
					pixValz += d_in[curRow * imgwidth + curCol].z;
					pixels++; 
				}
			}
		}

		d_out[Row * imgwidth + Col].x = (unsigned char)(pixValx / pixels);
		d_out[Row * imgwidth + Col].y = (unsigned char)(pixValy / pixels);
		d_out[Row * imgwidth + Col].z = (unsigned char)(pixValz / pixels);
	}
}

int main(void)
{
	Mat srcImage = imread("./Lenna.png");
	const uint imgheight = srcImage.rows;
	const uint imgwidth = srcImage.cols;

	Mat grayImage(imgheight, imgwidth, CV_8UC1, Scalar(0));

	uchar3 *d_in;
	unsigned char *d_out;

	cudaMalloc((void **)&d_in, imgheight * imgwidth * sizeof(uchar3));
	cudaMalloc((void **)&d_out, imgheight * imgwidth * sizeof(unsigned char));

	cudaMemcpy(d_in, srcImage.data, imgheight * imgwidth * sizeof(uchar3), cudaMemcpyHostToDevice);

	dim3 threadsPerBlock(32, 32);
	dim3 blocksPerGrid((imgwidth + threadsPerBlock.x - 1) / threadsPerBlock.x,
					   (imgheight + threadsPerBlock.y - 1) / threadsPerBlock.y);

	rgb2grayincuda<<<blocksPerGrid, threadsPerBlock>>>(d_in, d_out, imgheight, imgwidth);

	cudaMemcpy(grayImage.data, d_out, imgheight * imgwidth * sizeof(unsigned char), cudaMemcpyDeviceToHost);

	cudaFree(d_out);

	imwrite("greyImage.jpg", grayImage);


	// blur
	Mat blurImage(imgheight, imgwidth, CV_8UC3);
	uchar3 *d_out2;
	cudaMalloc((void **)&d_out2, imgheight * imgwidth * sizeof(uchar3));
	blurKernel<<<blocksPerGrid, threadsPerBlock>>>(d_in, d_out2, imgheight, imgwidth);
	cudaMemcpy(blurImage.data, d_out2, imgheight * imgwidth * sizeof(uchar3), cudaMemcpyDeviceToHost);
	cudaFree(d_in);
	cudaFree(d_out2);
	imwrite("blurImage32.jpg", blurImage);

	return 0;
}