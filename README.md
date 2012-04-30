# Rqrcode::Renderer

Render QR codes from rails as images or SVG.

Auto-negotiates based on requested format and browser acceptance.

## Usage

Put it in your Gemfile:

```ruby
gem rqrcode-renderer
```

Use it in an action:

```ruby
class MyController < ActionController::Base
  def my_action
    render qrcode: "something"
  end
end
```

Add `scale: 5` etc. to make it bigger.
