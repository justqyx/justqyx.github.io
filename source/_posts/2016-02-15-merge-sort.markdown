---
layout: post
title: "归并排序"
date: 2016-02-15 09:23:24 +0800
comments: true
categories: []
---

归并排序（Merge sort），是建立在归并操作上的一种有效排序算法，时间复杂度为 O(n*log(n))。1945 年由约翰•冯•诺依曼首次提出。
该算法采用分治法（Divide and Conquer）的一个非常典型的应用，且各层分治递归可以同时进行。

## 算法步骤

**递归法**

1. 将序列每相邻两个数字进行归并操作，形成 floor(n/2) 个序列，排序后每个序列至多包含两个元素
2. 将上述序列再次合并，形成 floor(n/4) 个序列，买个序列包含至多四个元素
3. 重复步骤 2，直到所有元素排序完毕

要点：首先需要将数列分割成尽可能小的数列，达到分治目的后再逐步合并。

**迭代法**

1. 申请空间，使其大小为两个已经排序序列之和，该空间用来存放合并后的序列
2. 设定两个指针，最初位置分别为两个已经排序序列的起始位置
3. 比较两个指针所指向的元素，选择相对小的元素放入合并空间，并移动指针到下一位置
4. 重复 3 步骤直到某一指针到达序列尾
5. 将另一序列剩下的所有元素直接复制到合并序列尾

## GIF 演示图

{% img /downloads/images/Merge-sort-example-300px.gif %}

## 归并排序 VS 快速排序

- 在实践中，快速排序执行速率更快
- 归并排序首先将数列划分为最小的数列，在对数列进行排序的同时，递增地对数列进行合并
- 快速排序不断地通过 pivot 划分数列，直到数列递归地有序

## 实现

**ruby 实现**

```ruby
def merge(left, right)
    final = []

    until left.empty? or right.empty?
        final << (left.first < right.first ? left.shift : right.shift)
    end
    final + left + right
end

def merge_sort(array)
    return array if array.size < 2
    pivot = array.size / 2
    merge(merge_sort(array[0...pivot]), merge_sort(array[pivot...-1]))
end
```

**C 实现（递归法）**

```c
void merge_sort_recursive(int arr[], int reg[], int start, int end) {
    if (start >= end) {
        return;
    }

    int len = end - start;
    int mid = (len >> 1 + start); // 右移一位，相当于除以 2

    int start1 = start;
    int end1 = mid;
    int start2 = mid + 1;
    int end2 = end;

    merge_sort_recursive(arr, reg, start1, end1);
    merge_sort_recursive(arr, reg, start2, end2);

    int k = start;

    // 三个 while 实现了两个序列的有序合并

    while (start1 <= end1 && start2 <= end2) {
		reg[k++] = arr[start1] < arr[start2] ? arr[start1++] : arr[start2++];
    }

	while (start1 <= end1) {
		reg[k++] = arr[start1++];
    }

	while (start2 <= end2) {
		reg[k++] = arr[start2++];
    }

	for (k = start; k <= end; k++) {
		arr[k] = reg[k];
    }
}

void merge_sort(int arr[], const int len) {
    int reg[len];
    merge_sort_recursive(arr, reg, 0, len-1);
}
```

**C 实现（迭代法）**

```c
int min(int x, int y) {
	return x < y ? x : y;
}
void merge_sort(int arr[], int len) {
	int* a = arr;
	int* b = (int*) malloc(len * sizeof(int*));
	int seg, start;
    // 使得内循环的 2seg+1 片段指数级变大，达到递归的效果
	for (seg = 1; seg < len; seg += seg) {
        // 对 2seg+1 片段进行有序化
		for (start = 0; start < len; start += seg + seg) {
			int low = start, mid = min(start + seg, len), high = min(start + seg + seg, len);
			int k = low;
			int start1 = low, end1 = mid;
			int start2 = mid, end2 = high;
			while (start1 < end1 && start2 < end2)
				b[k++] = a[start1] < a[start2] ? a[start1++] : a[start2++];
			while (start1 < end1)
				b[k++] = a[start1++];
			while (start2 < end2)
				b[k++] = a[start2++];
		}
		int* temp = a;
		a = b;
		b = temp;
	}
	if (a != arr) {
		int i;
		for (i = 0; i < len; i++)
			b[i] = a[i];
		b = a;
	}
	free(b);
}
```

## Ref

- [wikipedia 归并排序](https://zh.wikipedia.org/wiki/归并排序)
- https://ruby-china.org/topics/20569
- http://blog.jobbole.com/90256/
