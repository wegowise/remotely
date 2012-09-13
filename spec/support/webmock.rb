module WebmockHelpers
  extend self
  extend WebMock::API

  def stub!
    stub :get,    %r[/has_manies/1/things],   body: [{name: "Thing"}]
    stub :get,    %r[/custom/things],         body: [{name: "Thing"}]
    stub :get,    %r[/custom/stuff/things],   body: [{name: "Thing"}]

    stub :get,    %r[/has_ones/1/thing],      body: {name: "Thing"}
    stub :get,    %r[/custom/thing],          body: {name: "Thing"}
    stub :get,    %r[/custom/stuff/thing],    body: {name: "Thing"}

    stub :get,    %r[/things/1],              body: {name: "Thing"}

    stub :get,    %r[/trucks.*],              body: [{size: 17, width: 10}]

    stub :get,    %r[/adventures],            body: [{type: "MATHEMATICAL"}, {type: "lame"}]
    stub :post,   %r[/adventures],            lambda { |req| {body: req.body} }
    stub :put,    %r[/adventures]

    stub :get,    %r[/adventures/1],          body: {type: "MATHEMATICAL"}
    stub :put,    %r[/adventures/1],          lambda { |req| {body: req.body} }
    stub :delete, %r[/adventures/1]

    stub :post,   %r[/members],               body: lambda { |req| {body: req.body} }
    stub :get,    %r[/adventures/1/members],  body: [{name: "Finn"}, {name: "Jake"}]
    stub :get,    %r[/members/3/weapons],     body: [{type: "Axe"}]

    stub :get,    %r[/adventures/search],     body: [{type: "MATHEMATICAL"}]
  end

  def stub(method, url, response={})
    unless response.is_a?(Proc) || response[:body].is_a?(Proc)
      response[:body]    = MultiJson.dump(response[:body])
      response[:headers] = { "Content-Type" => "application/json" }
    end
    stub_request(method, url).to_return(response)
  end
end
