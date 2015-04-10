module MiniTest::Assertions
  def assert_commit_callbacks(expected, klass)
    assert_equal expected, klass._commit_callbacks.select { |cb|
      cb.kind == :after && cb.name == :commit
    }.size
  end
end

Class.infect_an_assertion :assert_commit_callbacks, :must_have_commit_callbacks
