---
layout: post
title: 快速排序
date: 2016-02-14 17:38:13 +0800
comments: true
categories: []
---

快速排序使用分治法（Divide and conquer）策略来把一个序列（list）分为两个子序列（sub-lists）。

## 算法步骤

**递归法**

1. 从数列中挑出一个元素，称为基准（pivot）
2. 重新排序数列，所有比 pivot 小的元素摆放在 pivot 左边，大的摆放在 pivot 右边。这个操作称为分割（partition）
3. 递归地把 pivot 两边的子数列按 1 和 2 步骤继续排序

要点：通过 pivot 不断地将数列分割成两个数列，达到分治的目的。

## 时间复杂度

- 最好：O(n)
- 平均：O(n*log(n))
- 最差：O(n^2)

空间复杂度，不同实现不同。

快排在实践中，执行速度明显比其他具有相同时间复杂度的排序算法快。

## gif 演示图

{% img /downloads/images/Quicksort-example.gif %}

## 实现

Ruby 实现

```ruby
def quick_sort arr
    return arr if arr.size < 2
    left_arr, right_arr = arr[1..-1].partition { |item| item <= arr.first }
    quick_sort(left_arr) + [arr.first] + quick_sort(right_arr)
end
```

**C 实现（递归）**

```c
void swap(int *x, int *y) {
    int t = *x;
    *x = *y;
    *y = t;
}

void quick_sort(int arr[], int start, int end) {
    if (start >= end) {
        return;
    }

    int pivot = arr[end];
    int left = start, right = end - 1;

    while (left < right) {
        while (arr[left] < pivot && left < right)
            left++;
        while (arr[right] >= pivot && left < right)
            right++;
        swap(&arr[left], &arr[right]);
    }

    if (arr[left] >= arr[end]) {
        swap(&arr[left], &arr[end]);
    } else {
        left++;
    }

    quick_sort(arr, start, left - 1);
    quick_sort(arr, left+1, end);
}
```

## 参考

- http://visualgo.net/sorting.html
- [经典排序算法及 Ruby 实现](https://ruby-china.org/topics/20569)
- [wikipedia-快速排序](https://zh.wikipedia.org/wiki/%E5%BF%AB%E9%80%9F%E6%8E%92%E5%BA%8F#C.E8.AA.9E.E8.A8.80)
