module WebmockHelpers
  extend self
  extend WebMock::API

  def stub!
    stub :get,    %r[/trucks.*],             body: [{size: 17, width: 10}]

    stub :get,    %r[/adventures],           body: [{type: "MATHEMATICAL"}, {type: "lame"}]
    stub :post,   %r[/adventures],           lambda { |req| {body: req.body} }

    stub :get,    %r[/adventures/1],         body: {type: "MATHEMATICAL"}
    stub :put,    %r[/adventures/1],         lambda { |req| {body: req.body} }
    stub :delete, %r[/adventures/1]

    stub :get,    %r[/adventures/1/members], body: [{name: "Finn"}, {name: "Jake"}]
    stub :get,    %r[/members/3/weapons],    body: [{type: "Axe"}]

    stub :get,    %r[/adventures/search],    body: [{type: "MATHEMATICAL"}]
  end

  def stub(method, url, response={})
    unless response.is_a?(Proc)
      response[:body]    = Yajl::Encoder.encode(response[:body])
      response[:headers] = { "Content-Type" => "application/json" }
    end
    stub_request(method, url).to_return(response)
  end
end
