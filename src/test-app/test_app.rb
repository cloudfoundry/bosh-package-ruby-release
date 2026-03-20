Myapp = lambda { |_| [200, {}, ['test']] }
class TestApp
  def self.call(_)
    [200, {}, ['test']]
  end
end
