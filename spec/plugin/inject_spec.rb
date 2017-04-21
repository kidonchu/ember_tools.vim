require 'spec_helper'

describe ":Inject" do
  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  specify "creates a new injection in an empty Ember object" do
    touch_file 'app/services/some-service.js'
    edit_file 'test.js', <<-EOF
      export default Ember.Object.extend({});
    EOF

    vim.command 'Inject some-service'
    vim.write

    expect_file_contents current_file, <<-EOF
      export default Ember.Object.extend({
        someService: Ember.inject.service(),

      });
    EOF
  end

  specify "creates a new injection in an Ember object with no other injections" do
    touch_file 'app/services/some-service.js'
    edit_file 'test.js', <<-EOF
      export default Ember.Object.extend({
        foo: "bar",
      });
    EOF

    vim.command 'Inject some-service'
    vim.write

    expect_file_contents current_file, <<-EOF
      export default Ember.Object.extend({
        someService: Ember.inject.service(),

        foo: "bar",
      });
    EOF
  end

  specify "creates a new injection after other injections" do
    pending "Doesn't work on TravisCI due to old Vim version"

    touch_file 'app/services/some-service.js'
    edit_file 'test.js', <<-EOF
      export default Ember.Object.extend({
        foo: "bar",

        other: Ember.inject.service(),

        bar: "baz",
      });
    EOF

    vim.command 'Inject some-service'
    vim.write

    expect_file_contents current_file, <<-EOF
      export default Ember.Object.extend({
        foo: "bar",

        other: Ember.inject.service(),
        someService: Ember.inject.service(),

        bar: "baz",
      });
    EOF
  end

  specify "works with code that isn't exported" do
    touch_file 'app/services/some-service.js'
    edit_file 'test.js', <<-EOF
      const reference = Ember.Object.extend({
        foo: "bar",
      });
    EOF

    vim.command 'Inject some-service'
    vim.write

    expect_file_contents current_file, <<-EOF
      const reference = Ember.Object.extend({
        someService: Ember.inject.service(),

        foo: "bar",
      });
    EOF
  end

  specify "injects a property that's accessed under the cursor" do
    touch_file 'app/services/some-service.js'
    edit_file 'test.js', <<-EOF
      export default Ember.Object.extend({
        foo() {
          this.get('someService').doStuff()
        }
      });
    EOF

    vim.search('get(\'someService')
    vim.command 'Inject'
    vim.write

    expect_file_contents current_file, <<-EOF
      export default Ember.Object.extend({
        someService: Ember.inject.service(),

        foo() {
          this.get('someService').doStuff()
        }
      });
    EOF
  end
end
