---
layout: post
title: "字段加密存储-Rails"
date: 2017-11-26 15:11:10 +0800
comments: true
categories: ['rails']
---

## 方案

1. 存储前，加密后再存储到数据库
2. 读取后，利用 KEY 进行解密

## 实现

[ActiveSupport::MessageEncryptor](http://api.rubyonrails.org/v4.2.7.1/classes/ActiveSupport/MessageEncryptor.html)
是 Rails 基于 openssl 封装实现的一个类，可用于对一个对象进行加密、解密操作。例如：

```ruby
salt  = SecureRandom.random_bytes(64)
key   = ActiveSupport::KeyGenerator.new('password').generate_key(salt) # => "\x89\xE0\x156\xAC..."
crypt = ActiveSupport::MessageEncryptor.new(key)                       # => #<ActiveSupport::MessageEncryptor ...>
encrypted_data = crypt.encrypt_and_sign('my secret data')              # => "NlFBTTMwOUV5UlA1QlNEN2xkY2d6eThYWWh..."
crypt.decrypt_and_verify(encrypted_data)                               # => "my secret data"
```

[serialize](http://api.rubyonrails.org/v4.2.7.1/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html#method-i-serialize)
是 Rails ActiveRecord 里的一个类方法，可用于执行一个 column 如何存储到数据库，以及从数据库读取出来后要如何处理，例如：

```ruby
class User < ActiveRecord::Base
  serialize :preferences, Hash
end

user = User.new
user.preferences = {
  gender: 'male',
  age: 18
}
user.save!
```

另外，Rails 还允许自定义 Serizlizer，使得开发者能够自行决定如何做进行序列化和反序列化。例如：

```ruby
class CustomerSerializer
  def self.load(value)
    value.to_s.blank? ? "" : JSON.parse(value)
  end

  def self.dump(value)
    (value || {}).to_json
  end
end

class User < ActiveRecord::Base
  serialize :preferences, CustomerSerializer
end
```

基于此，我们可以自己实现一个 serializer，使得我们能够进行对字段进行加密存储，同时读取出来时能够自行进行解密。

```ruby
class EncryptedStringSerializer
  def self.load(value)
    value.to_s.blank? ? '' : decrypt(value)
  end

  def self.dump(value)
    encrypt(value || '')
  end

  private

  def self.encrypt(value)
    encryptor.encrypt_and_sign(value)
  end

  def self.decrypt(value)
    encryptor.decrypt_and_verify(value)
  end

  def self.encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(Settings.message_encryptor_key)
  end
end

class UserAddress < ActiveRecord::Base
  serialize :phone, EncryptedStringSerializer
  serialize :first_name, EncryptedStringSerializer
  serialize :last_name, EncryptedStringSerializer
  serialize :country, EncryptedStringSerializer
  serialize :state, EncryptedStringSerializer
  serialize :city, EncryptedStringSerializer
  serialize :address1, EncryptedStringSerializer
  serialize :address2, EncryptedStringSerializer
  serialize :zipcode, EncryptedStringSerializer
end
```

可以改进的点

1. 加解密用的 KEY 是否过于简单？
2. 针对现有数据，如何平滑过渡？
3. 多个字段需要加密时这种方式不友好
