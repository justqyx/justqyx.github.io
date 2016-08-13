---
layout: post
title: "Upload file in Rails Test Case"
date: 2013-09-06 18:07
comments: true
categories: ['rails']
---

## 正确的代码

```ruby
require 'test_helper'

class PicturesControllerTest < ActionController::TestCase

  setup do
    @user = create :user
    sign_in @user
  end

  test "user upload a tweet picture" do
    post :create, data: test_file

    assert_response :success
  end

  # ...

  private

    def test_file
      @file ||= Rack::Test::UploadedFile.new("test/fixtures/images/test.png", "image/png")
    end

end
```

## 错误的代码

  以下方式测试时，在 controller 里调试的时候发现，data 参数的值变成：`"#<File:0x007fde91ab83e0>"`，即变成了字符串类型，shit ...

```
require 'test_helper'

class PicturesControllerTest < ActionController::TestCase

# ...

  private

    def test_file
      @file ||= File.open File.expand_path("../../fixtures/images/test.png", __FILE__)
    end

end

```

# References

[How I test a file upload in Rails 3](http://edgar.tumblr.com/post/2841931378/how-i-test-a-file-upload-in-rails-3)
